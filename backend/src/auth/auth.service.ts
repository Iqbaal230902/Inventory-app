import { HttpStatus, Injectable } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { JwtService } from '@nestjs/jwt';
import * as bcrypt from 'bcryptjs';
import { createHash, randomBytes } from 'crypto';
import { AuditService } from '../audit/audit.service';
import { AppError } from '../common/app-error';
import { PrismaService } from '../prisma/prisma.service';
import { LoginDto } from './auth.dto';

const MAX_FAILED = 5;
const LOCK_MINUTES = 15;

export const sha256 = (s: string) =>
  createHash('sha256').update(s).digest('hex');

@Injectable()
export class AuthService {
  constructor(
    private prisma: PrismaService,
    private jwt: JwtService,
    private config: ConfigService,
    private audit: AuditService,
  ) {}

  async login(dto: LoginDto, ip?: string) {
    const user = await this.verifyCredentials(
      dto.username,
      dto.password,
      ip,
      dto.device_id,
    );
    if (dto.device_id) {
      await this.prisma.device.upsert({
        where: { id: dto.device_id },
        update: { userId: user.id, appVersion: dto.app_version },
        create: {
          id: dto.device_id,
          userId: user.id,
          appVersion: dto.app_version,
        },
      });
    }
    return this.issueTokens(user.id, dto.device_id);
  }

  /**
   * Cek username/password + kunci 15 menit setelah 5x gagal + audit login.
   * Dipakai login app (JWT) dan login admin panel (cookie).
   */
  async verifyCredentials(
    username: string,
    password: string,
    ip?: string,
    deviceId?: string,
    channel?: string,
  ) {
    const ident = username.trim().toLowerCase();
    const user = await this.prisma.user.findFirst({
      where: { OR: [{ username: ident }, { email: ident }] },
    });
    const invalid = new AppError(
      'INVALID_CREDENTIALS',
      'Username atau password salah.',
      HttpStatus.UNAUTHORIZED,
    );
    if (!user) throw invalid;

    if (user.lockedUntil && user.lockedUntil > new Date()) {
      const mins = Math.ceil((user.lockedUntil.getTime() - Date.now()) / 60000);
      throw new AppError(
        'ACCOUNT_LOCKED',
        `Terlalu banyak percobaan login gagal. Coba lagi dalam ${mins} menit.`,
        HttpStatus.TOO_MANY_REQUESTS,
      );
    }

    const ok = await bcrypt.compare(password, user.passwordHash);
    if (!ok) {
      const failed = user.failedLoginCount + 1;
      await this.prisma.user.update({
        where: { id: user.id },
        data:
          failed >= MAX_FAILED
            ? {
                failedLoginCount: 0,
                lockedUntil: new Date(Date.now() + LOCK_MINUTES * 60000),
              }
            : { failedLoginCount: failed },
      });
      await this.audit.log({
        user: { id: user.id, ip, deviceId },
        action: 'login_failed',
        entity: 'user',
        entityId: user.id,
        newValues: channel ? { channel } : undefined,
      });
      throw invalid;
    }
    if (!user.isActive) {
      throw new AppError(
        'USER_INACTIVE',
        'Akun Anda telah dinonaktifkan. Hubungi Owner.',
        HttpStatus.UNAUTHORIZED,
      );
    }

    await this.prisma.user.update({
      where: { id: user.id },
      data: { failedLoginCount: 0, lockedUntil: null, lastLoginAt: new Date() },
    });
    await this.audit.log({
      user: { id: user.id, ip, deviceId },
      action: 'login',
      entity: 'user',
      entityId: user.id,
      newValues: channel ? { channel } : undefined,
    });
    return user;
  }

  async refresh(refreshToken: string) {
    const hash = sha256(refreshToken);
    const row = await this.prisma.refreshToken.findUnique({
      where: { tokenHash: hash },
      include: { user: true },
    });
    if (!row || row.revokedAt || row.expiresAt < new Date()) {
      throw AppError.unauthenticated();
    }
    if (!row.user.isActive) {
      throw new AppError(
        'USER_INACTIVE',
        'Akun Anda telah dinonaktifkan. Hubungi Owner.',
        HttpStatus.UNAUTHORIZED,
      );
    }
    // Rotasi: token lama dicabut, token baru diterbitkan
    await this.prisma.refreshToken.update({
      where: { id: row.id },
      data: { revokedAt: new Date() },
    });
    return this.issueTokens(row.userId, row.deviceId ?? undefined);
  }

  async logout(refreshToken: string) {
    await this.prisma.refreshToken.updateMany({
      where: { tokenHash: sha256(refreshToken), revokedAt: null },
      data: { revokedAt: new Date() },
    });
    return { ok: true };
  }

  async profile(userId: number) {
    const user = await this.prisma.user.findUniqueOrThrow({
      where: { id: userId },
      include: { locations: { include: { location: true } } },
    });
    const locations =
      user.role === 'owner'
        ? await this.prisma.location.findMany({
            where: { isActive: true },
            orderBy: { code: 'asc' },
          })
        : user.locations.map((l) => l.location).filter((l) => l.isActive);
    return {
      id: user.id,
      name: user.name,
      username: user.username,
      email: user.email,
      role: user.role,
      all_locations: user.role === 'owner',
      locations: locations.map((l) => ({
        id: l.id,
        code: l.code,
        name: l.name,
        type: l.type,
        timezone: l.timezone,
      })),
    };
  }

  private async issueTokens(userId: number, deviceId?: string) {
    const user = await this.prisma.user.findUniqueOrThrow({
      where: { id: userId },
    });
    const expiresIn = Number(this.config.get('JWT_EXPIRES_IN') ?? 3600);
    const access = await this.jwt.signAsync(
      { sub: user.id, role: user.role, did: deviceId },
      { expiresIn },
    );
    const refresh = randomBytes(48).toString('base64url');
    // REFRESH_TOKEN_DAYS=0 (default) → sesi tidak pernah kedaluwarsa; user tetap
    // login sampai logout atau dinonaktifkan Owner. Token tetap dirotasi tiap refresh.
    const days = Number(this.config.get('REFRESH_TOKEN_DAYS') ?? 0);
    const expiresAt =
      days > 0
        ? new Date(Date.now() + days * 86400_000)
        : new Date('9999-12-31T00:00:00.000Z');
    await this.prisma.refreshToken.create({
      data: { userId, tokenHash: sha256(refresh), deviceId, expiresAt },
    });
    return {
      access_token: access,
      refresh_token: refresh,
      expires_in: expiresIn,
      refresh_expires_at: expiresAt.toISOString(),
      user: await this.profile(userId),
    };
  }
}
