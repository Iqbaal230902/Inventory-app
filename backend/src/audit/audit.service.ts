import { Injectable } from '@nestjs/common';
import { Prisma } from '@prisma/client';
import { AuthUser } from '../common/auth-user';
import { PrismaService, Tx } from '../prisma/prisma.service';

/** Ubah nilai apa pun (BigInt, Decimal, Date) menjadi JSON polos untuk audit log. */
export function toAuditJson(v: unknown): Prisma.InputJsonValue | undefined {
  if (v === undefined || v === null) return undefined;
  return JSON.parse(
    JSON.stringify(v, (_k, val) =>
      typeof val === 'bigint' ? Number(val) : val,
    ),
  );
}

@Injectable()
export class AuditService {
  constructor(private prisma: PrismaService) {}

  log(
    params: {
      user?: Pick<AuthUser, 'id' | 'deviceId' | 'ip'> | null;
      action: string;
      entity: string;
      entityId?: number | bigint | null;
      oldValues?: unknown;
      newValues?: unknown;
    },
    tx?: Tx,
  ) {
    const db = tx ?? this.prisma;
    return db.auditLog.create({
      data: {
        userId: params.user?.id ?? null,
        action: params.action,
        entity: params.entity,
        entityId:
          params.entityId === undefined || params.entityId === null
            ? null
            : BigInt(params.entityId),
        oldValues: toAuditJson(params.oldValues),
        newValues: toAuditJson(params.newValues),
        ipAddress: params.user?.ip?.slice(0, 45),
        deviceId: params.user?.deviceId?.slice(0, 64),
      },
    });
  }
}
