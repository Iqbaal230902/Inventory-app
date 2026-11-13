import {
  createParamDecorator,
  ExecutionContext,
  SetMetadata,
} from '@nestjs/common';
import { Role } from '@prisma/client';

/** User terautentikasi pada request (class agar bisa dipakai di signature ber-decorator). */
export class AuthUser {
  id!: number;
  name!: string;
  username!: string;
  role!: Role;
  /** Lokasi yang boleh diakses. null = semua lokasi (owner). */
  locationIds!: number[] | null;
  deviceId?: string;
  ip?: string;
}

export const CurrentUser = createParamDecorator(
  (_: unknown, ctx: ExecutionContext): AuthUser =>
    ctx.switchToHttp().getRequest().user,
);

export const ROLES_KEY = 'roles';
export const Roles = (...roles: Role[]) => SetMetadata(ROLES_KEY, roles);

export const IS_PUBLIC_KEY = 'isPublic';
export const Public = () => SetMetadata(IS_PUBLIC_KEY, true);

/** Pastikan user boleh mengakses lokasi tertentu. */
export function canAccessLocation(user: AuthUser, locationId: number) {
  return user.locationIds === null || user.locationIds.includes(locationId);
}

/** Filter Prisma `locationId` sesuai hak akses user (+ filter opsional). */
export function locationScope(user: AuthUser, requested?: number) {
  if (requested !== undefined) return requested;
  return user.locationIds === null ? undefined : { in: user.locationIds };
}
