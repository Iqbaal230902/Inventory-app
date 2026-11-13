import { Controller, Get, Query } from '@nestjs/common';
import { Prisma } from '@prisma/client';
import { AuthUser, CurrentUser, Roles } from '../common/auth-user';
import { PrismaService } from '../prisma/prisma.service';

@Controller('audit-logs')
@Roles('owner', 'admin')
export class AuditController {
  constructor(private prisma: PrismaService) {}

  @Get()
  async list(
    @CurrentUser() user: AuthUser,
    @Query('entity') entity?: string,
    @Query('entity_id') entityId?: string,
    @Query('user_id') userId?: string,
    @Query('action') action?: string,
    @Query('page') page = '1',
  ) {
    const take = 50;
    const where: Prisma.AuditLogWhereInput = {
      entity: entity || undefined,
      entityId: entityId ? BigInt(entityId) : undefined,
      userId: userId ? +userId : undefined,
      action: action || undefined,
    };
    // Admin hanya melihat log transaksi di lokasinya + log miliknya sendiri
    if (user.role === 'admin') {
      const trxIds = await this.prisma.transaction.findMany({
        where: { locationId: { in: user.locationIds ?? [] } },
        select: { id: true },
        orderBy: { id: 'desc' },
        take: 5000,
      });
      where.OR = [
        { entity: 'transaction', entityId: { in: trxIds.map((t) => t.id) } },
        { userId: user.id },
      ];
    }
    const rows = await this.prisma.auditLog.findMany({
      where,
      orderBy: { id: 'desc' },
      take,
      skip: (Math.max(1, +page) - 1) * take,
    });
    const users = await this.prisma.user.findMany({
      where: {
        id: { in: [...new Set(rows.map((r) => r.userId!).filter(Boolean))] },
      },
      select: { id: true, name: true },
    });
    const names = new Map(users.map((u) => [u.id, u.name]));
    return {
      data: rows.map((r) => ({
        ...r,
        user_name: r.userId ? names.get(r.userId) : null,
      })),
      page: +page,
      has_more: rows.length === take,
    };
  }
}
