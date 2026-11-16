import {
  ArgumentsHost,
  CanActivate,
  Catch,
  ExceptionFilter,
  ExecutionContext,
  HttpException,
  Injectable,
  Logger,
  SetMetadata,
} from '@nestjs/common';
import { Reflector } from '@nestjs/core';
import { JwtService } from '@nestjs/jwt';
import { Prisma } from '@prisma/client';
import { createHash } from 'crypto';
import { Request, Response } from 'express';
import { AuthUser } from '../common/auth-user';
import { PrismaService } from '../prisma/prisma.service';

export const ADMIN_BASE = '/admin-panel';
export const ADMIN_COOKIE = 'bam_admin';
export const FLASH_COOKIE = 'bam_flash';
/** Lama sesi admin panel (detik). */
export const ADMIN_SESSION_SECONDS = 12 * 3600;

const OWNER_ONLY = 'adminOwnerOnly';
/** Halaman/aksi admin panel yang hanya untuk Owner. */
export const OwnerOnly = () => SetMetadata(OWNER_ONLY, true);

/** Sidik jari password: sesi admin batal otomatis bila password diganti. */
export const pwFingerprint = (hash: string) =>
  createHash('sha256').update(hash).digest('hex').slice(0, 16);

/** Belum login / sesi habis → arahkan ke halaman login. */
export class AdminLoginRequired extends Error {}

export interface AdminRequest extends Request {
  user: AuthUser;
}

export function cookieOpts(req: Request, maxAgeSec?: number) {
  return {
    httpOnly: true,
    sameSite: 'strict' as const,
    secure: req.secure,
    path: ADMIN_BASE,
    maxAge: maxAgeSec === undefined ? undefined : maxAgeSec * 1000,
  };
}

/** Pesan satu kali (sukses / error) yang tampil setelah redirect. */
export function setFlash(
  req: Request,
  res: Response,
  type: 'ok' | 'error',
  message: string,
) {
  res.cookie(
    FLASH_COOKIE,
    JSON.stringify({ type, message: message.slice(0, 300) }),
    cookieOpts(req, 60),
  );
}

export function takeFlash(
  req: Request,
  res: Response,
): { type: string; message: string } | null {
  const raw = (req.cookies as Record<string, string> | undefined)?.[
    FLASH_COOKIE
  ];
  if (!raw) return null;
  res.clearCookie(FLASH_COOKIE, cookieOpts(req));
  try {
    const v = JSON.parse(raw) as { type: string; message: string };
    return typeof v?.message === 'string' ? v : null;
  } catch {
    return null;
  }
}

/** Hanya izinkan redirect kembali ke halaman admin panel sendiri. */
export function safeBack(req: Request, fallback = ADMIN_BASE) {
  const ref = req.get('referer');
  if (!ref) return fallback;
  try {
    const u = new URL(ref);
    if (u.host === req.get('host') && u.pathname.startsWith(ADMIN_BASE)) {
      return u.pathname + u.search;
    }
  } catch {
    /* abaikan */
  }
  return fallback;
}

/**
 * Guard admin panel: sesi dari cookie (JWT bertanda typ=admin-panel), hanya
 * Owner & Admin aktif. Untuk POST, Origin wajib sama dengan host (anti-CSRF,
 * selain cookie SameSite=Strict).
 */
@Injectable()
export class AdminGuard implements CanActivate {
  constructor(
    private jwt: JwtService,
    private prisma: PrismaService,
    private reflector: Reflector,
  ) {}

  async canActivate(ctx: ExecutionContext) {
    const req = ctx.switchToHttp().getRequest<AdminRequest>();
    if (req.method !== 'GET' && req.method !== 'HEAD') {
      const origin = req.get('origin');
      if (origin) {
        let host = '';
        try {
          host = new URL(origin).host;
        } catch {
          /* origin tidak valid */
        }
        if (host !== req.get('host')) {
          throw new HttpException('Permintaan ditolak (origin berbeda).', 403);
        }
      }
    }
    const token = (req.cookies as Record<string, string> | undefined)?.[
      ADMIN_COOKIE
    ];
    if (!token) throw new AdminLoginRequired();
    let payload: { sub: number; typ?: string; pw?: string };
    try {
      payload = await this.jwt.verifyAsync(token);
    } catch {
      throw new AdminLoginRequired();
    }
    if (payload.typ !== 'admin-panel') throw new AdminLoginRequired();
    const user = await this.prisma.user.findUnique({
      where: { id: payload.sub },
      include: { locations: true },
    });
    if (
      !user ||
      !user.isActive ||
      (user.role !== 'owner' && user.role !== 'admin') ||
      payload.pw !== pwFingerprint(user.passwordHash)
    ) {
      throw new AdminLoginRequired();
    }
    req.user = {
      id: user.id,
      name: user.name,
      username: user.username,
      role: user.role,
      locationIds:
        user.role === 'owner' ? null : user.locations.map((l) => l.locationId),
      deviceId: 'admin-panel',
      ip: req.ip,
    };
    const ownerOnly = this.reflector.getAllAndOverride<boolean>(OWNER_ONLY, [
      ctx.getHandler(),
      ctx.getClass(),
    ]);
    if (ownerOnly && user.role !== 'owner') {
      throw new HttpException('Halaman ini hanya untuk Owner.', 403);
    }
    return true;
  }
}

/** Ambil pesan berbahasa Indonesia dari error apa pun. */
export function errorMessage(e: unknown): string {
  if (e instanceof HttpException) {
    const body = e.getResponse() as
      string | { error?: { message?: string }; message?: string | string[] };
    if (typeof body === 'string') return body;
    if (body?.error?.message) return body.error.message;
    if (Array.isArray(body?.message)) return String(body.message[0]);
    if (typeof body?.message === 'string') return body.message;
    return e.message;
  }
  if (e instanceof Prisma.PrismaClientKnownRequestError && e.code === 'P2002') {
    return 'Data dengan nilai unik yang sama (mis. kode / username / plat) sudah ada.';
  }
  if (e instanceof Prisma.PrismaClientKnownRequestError && e.code === 'P2025') {
    return 'Data tidak ditemukan.';
  }
  return 'Terjadi kesalahan pada server. Silakan coba lagi.';
}

/**
 * Error di admin panel tidak dikembalikan sebagai JSON:
 * - belum login → redirect ke /admin-panel/login
 * - error pada aksi (POST) → kembali ke halaman sebelumnya dengan pesan
 * - error pada halaman (GET) → halaman error
 */
@Catch()
export class AdminExceptionFilter implements ExceptionFilter {
  private readonly logger = new Logger('AdminPanel');

  catch(e: unknown, host: ArgumentsHost) {
    const req = host.switchToHttp().getRequest<Request>();
    const res = host.switchToHttp().getResponse<Response>();
    if (e instanceof AdminLoginRequired) {
      res.clearCookie(ADMIN_COOKIE, cookieOpts(req));
      const next = req.method === 'GET' ? req.originalUrl : ADMIN_BASE;
      return res.redirect(
        `${ADMIN_BASE}/login?next=${encodeURIComponent(next)}`,
      );
    }
    const known =
      e instanceof HttpException ||
      e instanceof Prisma.PrismaClientKnownRequestError;
    if (!known) this.logger.error(e instanceof Error ? e.stack : e);
    const message = errorMessage(e);
    if (req.method !== 'GET') {
      setFlash(req, res, 'error', message);
      return res.redirect(safeBack(req));
    }
    const status =
      e instanceof HttpException
        ? e.getStatus()
        : e instanceof Prisma.PrismaClientKnownRequestError &&
            e.code === 'P2025'
          ? 404
          : 500;
    return res.status(status).render('error', {
      title: 'Terjadi kesalahan',
      status,
      message,
      layout: 'layout',
      base: ADMIN_BASE,
    });
  }
}
