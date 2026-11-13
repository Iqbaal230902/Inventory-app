import { HttpStatus, Injectable } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { PassportStrategy } from '@nestjs/passport';
import { Request } from 'express';
import { ExtractJwt, Strategy } from 'passport-jwt';
import { AppError } from '../common/app-error';
import { AuthUser } from '../common/auth-user';
import { PrismaService } from '../prisma/prisma.service';

@Injectable()
export class JwtStrategy extends PassportStrategy(Strategy) {
  constructor(
    config: ConfigService,
    private prisma: PrismaService,
  ) {
    super({
      jwtFromRequest: ExtractJwt.fromAuthHeaderAsBearerToken(),
      ignoreExpiration: false,
      secretOrKey: config.getOrThrow<string>('JWT_SECRET'),
      passReqToCallback: true,
    });
  }

  /** Dicek setiap request: user nonaktif langsung ditolak (FR-01). */
  async validate(
    req: Request,
    payload: { sub: number; did?: string },
  ): Promise<AuthUser> {
    const user = await this.prisma.user.findUnique({
      where: { id: payload.sub },
      include: { locations: true },
    });
    if (!user || !user.isActive) {
      throw new AppError(
        'USER_INACTIVE',
        'Akun Anda telah dinonaktifkan. Hubungi Owner.',
        HttpStatus.UNAUTHORIZED,
      );
    }
    return {
      id: user.id,
      name: user.name,
      username: user.username,
      role: user.role,
      locationIds:
        user.role === 'owner' ? null : user.locations.map((l) => l.locationId),
      deviceId: (req.headers['x-device-id'] as string) || payload.did,
      ip: req.ip,
    };
  }
}
