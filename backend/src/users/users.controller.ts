import {
  Body,
  Controller,
  Get,
  Param,
  ParseIntPipe,
  Post,
  Put,
} from '@nestjs/common';
import * as bcrypt from 'bcryptjs';
import {
  IsArray,
  IsBoolean,
  IsEmail,
  IsIn,
  IsInt,
  IsNotEmpty,
  IsOptional,
  IsString,
  Matches,
  MaxLength,
  MinLength,
} from 'class-validator';
import { Role } from '@prisma/client';
import { AuditService } from '../audit/audit.service';
import { AppError } from '../common/app-error';
import { AuthUser, CurrentUser, Roles } from '../common/auth-user';
import { PrismaService } from '../prisma/prisma.service';

class UserDto {
  @IsString()
  @IsNotEmpty()
  @MaxLength(100)
  name!: string;
  @IsString()
  @MaxLength(50)
  @Matches(/^[a-z0-9._-]{3,50}$/i, {
    message: 'Username 3-50 karakter huruf/angka.',
  })
  username!: string;
  @IsOptional()
  @IsEmail({}, { message: 'Email tidak valid.' })
  email?: string | null;
  @IsIn(['owner', 'admin', 'operator', 'viewer'])
  role!: Role;
  @IsOptional()
  @IsString()
  @MinLength(8, { message: 'Password minimal 8 karakter.' })
  password?: string;
  @IsArray()
  @IsInt({ each: true })
  location_ids!: number[];
  @IsOptional()
  @IsBoolean()
  is_active?: boolean;
}

const USER_SELECT = {
  id: true,
  name: true,
  username: true,
  email: true,
  role: true,
  isActive: true,
  lastLoginAt: true,
  lockedUntil: true,
  createdAt: true,
  locations: {
    select: { location: { select: { id: true, code: true, name: true } } },
  },
  devices: { select: { id: true, appVersion: true, lastSyncAt: true } },
} as const;

@Controller('users')
@Roles('owner')
export class UsersController {
  constructor(
    private prisma: PrismaService,
    private audit: AuditService,
  ) {}

  @Get()
  async list() {
    const users = await this.prisma.user.findMany({
      select: USER_SELECT,
      orderBy: { name: 'asc' },
    });
    return users.map(shape);
  }

  @Post()
  async create(@CurrentUser() me: AuthUser, @Body() d: UserDto) {
    if (!d.password)
      throw AppError.validation('Password wajib diisi untuk user baru.');
    this.checkLocations(d);
    const u = await this.prisma.user.create({
      data: {
        name: d.name.trim(),
        username: d.username.toLowerCase(),
        email: d.email?.toLowerCase() || null,
        role: d.role,
        passwordHash: await bcrypt.hash(d.password, 10),
        isActive: d.is_active ?? true,
        locations: {
          create: d.location_ids.map((locationId) => ({ locationId })),
        },
      },
      select: USER_SELECT,
    });
    await this.audit.log({
      user: me,
      action: 'create',
      entity: 'user',
      entityId: u.id,
      newValues: { ...d, password: undefined },
    });
    return shape(u);
  }

  @Put(':id')
  async update(
    @CurrentUser() me: AuthUser,
    @Param('id', ParseIntPipe) id: number,
    @Body() d: UserDto,
  ) {
    if (id === me.id && (d.is_active === false || d.role !== 'owner')) {
      throw AppError.validation(
        'Anda tidak dapat menonaktifkan atau menurunkan role akun sendiri.',
      );
    }
    this.checkLocations(d);
    const old = await this.prisma.user.findUniqueOrThrow({
      where: { id },
      select: USER_SELECT,
    });
    const u = await this.prisma.$transaction(async (tx) => {
      await tx.userLocation.deleteMany({ where: { userId: id } });
      const updated = await tx.user.update({
        where: { id },
        data: {
          name: d.name.trim(),
          username: d.username.toLowerCase(),
          email: d.email?.toLowerCase() || null,
          role: d.role,
          isActive: d.is_active ?? true,
          ...(d.password
            ? {
                passwordHash: await bcrypt.hash(d.password, 10),
                failedLoginCount: 0,
                lockedUntil: null,
              }
            : {}),
          locations: {
            create: d.location_ids.map((locationId) => ({ locationId })),
          },
        },
        select: USER_SELECT,
      });
      // Nonaktif / ganti password → cabut semua sesi
      if (d.is_active === false || d.password) {
        await tx.refreshToken.updateMany({
          where: { userId: id, revokedAt: null },
          data: { revokedAt: new Date() },
        });
      }
      return updated;
    });
    await this.audit.log({
      user: me,
      action: 'update',
      entity: 'user',
      entityId: id,
      oldValues: shape(old),
      newValues: { ...d, password: d.password ? '***' : undefined },
    });
    return shape(u);
  }

  @Post(':id/unlock')
  async unlock(
    @CurrentUser() me: AuthUser,
    @Param('id', ParseIntPipe) id: number,
  ) {
    await this.prisma.user.update({
      where: { id },
      data: { lockedUntil: null, failedLoginCount: 0 },
    });
    await this.audit.log({
      user: me,
      action: 'unlock',
      entity: 'user',
      entityId: id,
    });
    return { ok: true };
  }

  private checkLocations(d: UserDto) {
    if (d.role !== 'owner' && !d.location_ids.length) {
      throw AppError.validation('Pilih minimal satu lokasi untuk user ini.');
    }
    if (d.role === 'operator' && d.location_ids.length > 1) {
      throw AppError.validation('Operator hanya boleh ditugaskan ke 1 lokasi.');
    }
  }
}

function shape(u: any) {
  return { ...u, locations: u.locations.map((l: any) => l.location) };
}
