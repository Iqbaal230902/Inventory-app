import { Injectable } from '@nestjs/common';
import { Prisma, TrxStatus, TrxType } from '@prisma/client';
import { AuditService } from '../audit/audit.service';
import { AppError } from '../common/app-error';
import {
  AuthUser,
  canAccessLocation,
  locationScope,
} from '../common/auth-user';
import { PrismaService } from '../prisma/prisma.service';
import { normalizePlate, PostingService } from './posting.service';
import { serializeTrx, TRX_INCLUDE } from './transaction.serializer';

export interface ListQuery {
  date_from?: string;
  date_to?: string;
  location_id?: string;
  product_id?: string;
  type?: string;
  partner_id?: string;
  plate?: string;
  created_by?: string;
  status?: string;
  q?: string;
  void_requested?: string;
  page?: string;
  per_page?: string;
}

@Injectable()
export class TransactionsService {
  constructor(
    private prisma: PrismaService,
    private posting: PostingService,
    private audit: AuditService,
  ) {}

  async list(user: AuthUser, q: ListQuery) {
    const perPage = Math.min(100, Math.max(1, Number(q.per_page) || 20));
    const page = Math.max(1, Number(q.page) || 1);
    const requestedLoc = q.location_id ? Number(q.location_id) : undefined;
    if (requestedLoc && !canAccessLocation(user, requestedLoc))
      throw AppError.forbidden();

    const where: Prisma.TransactionWhereInput = {
      locationId: locationScope(user, requestedLoc),
      trxType: q.type ? { in: q.type.split(',') as TrxType[] } : undefined,
      status: q.status ? { in: q.status.split(',') as TrxStatus[] } : undefined,
      partnerId: q.partner_id ? Number(q.partner_id) : undefined,
      createdById: q.created_by ? Number(q.created_by) : undefined,
      plateNumber: q.plate ? { contains: normalizePlate(q.plate)! } : undefined,
      trxAt: {
        gte: q.date_from ? new Date(q.date_from) : undefined,
        lt: q.date_to ? new Date(q.date_to) : undefined,
      },
      items: q.product_id
        ? { some: { productId: Number(q.product_id), supersededAt: null } }
        : undefined,
      voidRequestedAt: q.void_requested === '1' ? { not: null } : undefined,
    };
    if (q.void_requested === '1') where.status = { not: 'void' };
    if (q.q?.trim()) {
      const term = q.q.trim();
      where.OR = [
        { docNo: { contains: term } },
        { manualDocNo: { contains: term } },
        { plateNumber: { contains: normalizePlate(term) ?? term } },
        { partnerName: { contains: term } },
      ];
    }
    const rows = await this.prisma.transaction.findMany({
      where,
      include: TRX_INCLUDE,
      orderBy: [{ trxAt: 'desc' }, { id: 'desc' }],
      take: perPage + 1,
      skip: (page - 1) * perPage,
    });
    const hasMore = rows.length > perPage;
    return {
      data: rows.slice(0, perPage).map((t) => serializeTrx(t)),
      page,
      per_page: perPage,
      has_more: hasMore,
    };
  }

  async detail(user: AuthUser, id: bigint) {
    const t = await this.prisma.transaction.findUnique({
      where: { id },
      include: TRX_INCLUDE,
    });
    if (!t || !canAccessLocation(user, t.locationId))
      throw AppError.notFound('Transaksi tidak ditemukan.');
    const locked = await this.posting.isLocked(t);
    const history = await this.prisma.auditLog.findMany({
      where: { entity: 'transaction', entityId: id },
      orderBy: { id: 'asc' },
    });
    const userIds = [...new Set(history.map((h) => h.userId!).filter(Boolean))];
    const names = new Map(
      (
        await this.prisma.user.findMany({
          where: { id: { in: userIds } },
          select: { id: true, name: true },
        })
      ).map((u) => [u.id, u.name]),
    );
    const isInput = [
      'IN_RAW',
      'IN_PRODUCTION',
      'IN_SUPPLIER',
      'OUT_SALE',
      'ADJUSTMENT',
    ].includes(t.trxType);
    const mgr = user.role === 'owner' || user.role === 'admin';
    return serializeTrx(t, {
      is_locked: locked,
      permissions: {
        can_edit: mgr && isInput && !locked && t.status !== 'void',
        can_void:
          user.role === 'owner' &&
          t.trxType !== 'VOID' &&
          !locked &&
          t.status !== 'void',
        can_request_void:
          user.role === 'admin' &&
          t.trxType !== 'VOID' &&
          t.status !== 'void' &&
          !t.voidRequestedAt,
        can_approve: mgr && t.status === 'pending_approval',
        can_print: t.trxType === 'OUT_SALE' && t.status !== 'void',
      },
      history: history.map((h) => ({
        id: Number(h.id),
        action: h.action,
        user_id: h.userId,
        user_name: h.userId ? (names.get(h.userId) ?? null) : null,
        old_values: h.oldValues,
        new_values: h.newValues,
        device_id: h.deviceId,
        created_at: h.createdAt.toISOString(),
      })),
    });
  }

  /** Dicatat setiap cetak surat jalan; cetak ke-2 dst ditandai COPY. */
  async markPrinted(user: AuthUser, id: bigint, channel: string) {
    const t = await this.prisma.transaction.findUnique({ where: { id } });
    if (!t || !canAccessLocation(user, t.locationId)) throw AppError.notFound();
    const updated = await this.prisma.transaction.update({
      where: { id },
      data: { printCount: { increment: 1 } },
    });
    await this.audit.log({
      user,
      action: 'print',
      entity: 'transaction',
      entityId: id,
      newValues: { print_count: updated.printCount, channel },
    });
    return { print_count: updated.printCount, is_copy: updated.printCount > 1 };
  }

  async setPhoto(user: AuthUser, id: bigint, path: string) {
    const t = await this.prisma.transaction.findUnique({ where: { id } });
    if (!t || !canAccessLocation(user, t.locationId)) throw AppError.notFound();
    if (user.role === 'operator' && t.createdById !== user.id)
      throw AppError.forbidden();
    await this.prisma.transaction.update({
      where: { id },
      data: { photoPath: path },
    });
    await this.audit.log({
      user,
      action: 'photo',
      entity: 'transaction',
      entityId: id,
      newValues: { path },
    });
    return { ok: true };
  }

  async photoPath(user: AuthUser, id: bigint) {
    const t = await this.prisma.transaction.findUnique({ where: { id } });
    if (!t || !canAccessLocation(user, t.locationId) || !t.photoPath)
      throw AppError.notFound('Foto tidak ada.');
    return t.photoPath;
  }

  /** Cek input ganda: kendaraan yang sama keluar dalam N menit terakhir. */
  async plateCheck(
    user: AuthUser,
    plate: string,
    locationId: number,
    minutes: number,
  ) {
    const p = normalizePlate(plate);
    if (!p) return { duplicate: false };
    const since = new Date(Date.now() - minutes * 60_000);
    const t = await this.prisma.transaction.findFirst({
      where: {
        plateNumber: p,
        trxType: 'OUT_SALE',
        locationId: locationScope(user, locationId),
        status: { not: 'void' },
        trxAt: { gte: since },
      },
      orderBy: { trxAt: 'desc' },
    });
    return t
      ? { duplicate: true, doc_no: t.docNo, trx_at: t.trxAt.toISOString() }
      : { duplicate: false };
  }
}
