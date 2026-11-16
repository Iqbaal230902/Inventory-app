import {
  Body,
  Controller,
  Get,
  Post,
  Query,
  Req,
  Res,
  UseFilters,
} from '@nestjs/common';
import { JwtService } from '@nestjs/jwt';
import { Request, Response } from 'express';
import { existsSync } from 'fs';
import { resolve } from 'path';
import { AuthService } from '../auth/auth.service';
import { Public } from '../common/auth-user';
import { SettingsService } from '../settings/settings.service';
import {
  ADMIN_BASE,
  ADMIN_COOKIE,
  ADMIN_SESSION_SECONDS,
  AdminExceptionFilter,
  cookieOpts,
  errorMessage,
  pwFingerprint,
  setFlash,
  takeFlash,
} from './admin-auth';

/** Hanya izinkan kembali ke halaman di dalam admin panel. */
function safeNext(next?: string) {
  return next && next.startsWith(`${ADMIN_BASE}`) && !next.startsWith('//')
    ? next
    : ADMIN_BASE;
}

@Public()
@Controller('admin-panel')
@UseFilters(AdminExceptionFilter)
export class AdminLoginController {
  constructor(
    private auth: AuthService,
    private jwt: JwtService,
    private settings: SettingsService,
  ) {}

  /** Logo PT untuk halaman admin (publik, tanpa login). */
  @Get('logo.png')
  logo(@Res() res: Response) {
    const file = [
      resolve(process.cwd(), 'assets/logo.png'),
      resolve(__dirname, '../../assets/logo.png'),
      resolve(__dirname, '../../../assets/logo.png'),
    ].find((p) => existsSync(p));
    if (!file) return res.status(404).end();
    res.setHeader('Cache-Control', 'public, max-age=86400');
    return res.sendFile(file);
  }

  @Get('login')
  async loginPage(
    @Req() req: Request,
    @Res() res: Response,
    @Query('next') next?: string,
  ) {
    res.render('login', {
      layout: false,
      base: ADMIN_BASE,
      next: safeNext(next),
      flash: takeFlash(req, res),
      company: await this.settings.get('company_name'),
    });
  }

  @Post('login')
  async login(
    @Req() req: Request,
    @Res() res: Response,
    @Body() body: { username?: string; password?: string; next?: string },
  ) {
    const back = `${ADMIN_BASE}/login?next=${encodeURIComponent(safeNext(body.next))}`;
    if (!body.username?.trim() || !body.password) {
      setFlash(req, res, 'error', 'Username dan password wajib diisi.');
      return res.redirect(back);
    }
    try {
      const user = await this.auth.verifyCredentials(
        body.username,
        body.password,
        req.ip,
        'admin-panel',
        'admin-panel',
      );
      if (user.role !== 'owner' && user.role !== 'admin') {
        setFlash(
          req,
          res,
          'error',
          'Admin panel hanya untuk Owner dan Admin. Gunakan aplikasi di HP.',
        );
        return res.redirect(back);
      }
      const token = await this.jwt.signAsync(
        {
          sub: user.id,
          typ: 'admin-panel',
          pw: pwFingerprint(user.passwordHash),
        },
        { expiresIn: ADMIN_SESSION_SECONDS },
      );
      res.cookie(ADMIN_COOKIE, token, cookieOpts(req, ADMIN_SESSION_SECONDS));
      return res.redirect(safeNext(body.next));
    } catch (e) {
      setFlash(req, res, 'error', errorMessage(e));
      return res.redirect(back);
    }
  }

  @Post('logout')
  logout(@Req() req: Request, @Res() res: Response) {
    res.clearCookie(ADMIN_COOKIE, cookieOpts(req));
    setFlash(req, res, 'ok', 'Anda sudah keluar.');
    return res.redirect(`${ADMIN_BASE}/login`);
  }
}
