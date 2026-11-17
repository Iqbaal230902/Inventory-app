import { Injectable } from '@nestjs/common';
import { Prisma } from '@prisma/client';
import { AppError } from '../common/app-error';
import { AuthUser, canAccessLocation } from '../common/auth-user';
import { dec, Decimal } from '../common/decimal';
import { startOfLocalDay, startOfLocalMonth } from '../common/time';
import { PrismaService } from '../prisma/prisma.service';

export type StockStatus = 'ok' | 'warning' | 'critical';

/** Hijau = aman, kuning = ≤ 120% batas minimum, merah = di bawah minimum (FR-02). */
export function stockStatus(qty: Decimal, min: Decimal): StockStatus {
  if (qty.isNeg()) return 'critical';
  if (min.lte(0)) return 'ok';
  if (qty.lt(min)) return 'critical';
  if (qty.lte(min.times(1.2))) return 'warning';
  return 'ok';
}
const rank = { ok: 0, warning: 1, critical: 2 } as const;

@Injectable()
export class DashboardService {
  constructor(private prisma: PrismaService) {}

  async get(user: AuthUser, locationId?: number) {
    if (locationId && !canAccessLocation(user, locationId)) {
      throw AppError.forbidden('Anda tidak memiliki akses ke lokasi ini.');
    }
    const locations = await this.prisma.location.findMany({
      where: {
        isActive: true,
        id:
          locationId ??
          (user.locationIds === null ? undefined : { in: user.locationIds }),
      },
      orderBy: { code: 'asc' },
    });
    const locIds = locations.map((l) => l.id);
    const [products, balances, mins] = await Promise.all([
      this.prisma.product.findMany({
        where: { isActive: true },
        orderBy: [{ sortOrder: 'asc' }, { id: 'asc' }],
      }),
      this.prisma.stockBalance.findMany({
        where: { locationId: { in: locIds } },
      }),
      this.prisma.stockMinLevel.findMany({
        where: { locationId: { in: locIds } },
      }),
    ]);

    const alerts: object[] = [];
    let total = dec(0); // hanya produk bersatuan ton (pasir mesh)
    const productRows = products.map((p) => {
      let qty = dec(0);
      let inTransit = dec(0);
      let minSum = dec(0);
      let worst: StockStatus = 'ok';
      const perLocation = locations.map((l) => {
        const b = balances.find(
          (x) => x.locationId === l.id && x.productId === p.id,
        );
        const m = mins.find(
          (x) => x.locationId === l.id && x.productId === p.id,
        );
        const q = dec(b?.qtyTon);
        const min = dec(m?.minTon);
        const st = stockStatus(q, min);
        qty = qty.plus(q);
        inTransit = inTransit.plus(dec(b?.inTransitTon));
        minSum = minSum.plus(min);
        if (rank[st] > rank[worst]) worst = st;
        if (st !== 'ok') {
          alerts.push({
            level: st,
            location_id: l.id,
            location_name: l.name,
            product_id: p.id,
            product_name: p.name,
            unit: p.unit,
            qty_ton: q.toFixed(3),
            min_ton: min.toFixed(3),
          });
        }
        return {
          location_id: l.id,
          qty_ton: q.toFixed(3),
          min_ton: min.toFixed(3),
          status: st,
        };
      });
      if (p.unit === 'ton') total = total.plus(qty);
      return {
        product_id: p.id,
        code: p.code,
        name: p.name,
        mesh_size: p.meshSize,
        category: p.category,
        unit: p.unit,
        qty_ton: qty.toFixed(3),
        in_transit_ton: inTransit.toFixed(3),
        min_ton: minSum.toFixed(3),
        status: worst,
        per_location: perLocation,
      };
    });

    // Ringkasan hari ini (zona waktu lokasi pertama / WIB)
    const tz = locations[0]?.timezone ?? 'Asia/Jakarta';
    const dayStart = startOfLocalDay(new Date(), tz);
    const today = await this.prisma.$queryRaw<
      { direction: 'in' | 'out'; total: Prisma.Decimal | null }[]
    >`
      SELECT i.direction, SUM(i.qty_ton) AS total
      FROM transactions t JOIN transaction_items i ON i.transaction_id = t.id
      JOIN products p ON p.id = i.product_id AND p.unit = 'ton'
      WHERE t.location_id IN (${locIds.length ? Prisma.join(locIds) : Prisma.sql`NULL`})
        AND t.trx_at >= ${dayStart}
        AND t.status <> 'void' AND i.superseded_at IS NULL
        AND t.trx_type IN ('IN_PRODUCTION','IN_SUPPLIER','OUT_SALE')
      GROUP BY i.direction`;
    const trucks = await this.prisma.transaction.count({
      where: {
        locationId: { in: locIds },
        trxAt: { gte: dayStart },
        status: { not: 'void' },
        trxType: { in: ['IN_PRODUCTION', 'IN_SUPPLIER', 'OUT_SALE'] },
        plateNumber: { not: null },
      },
    });
    const trxCount = await this.prisma.transaction.count({
      where: {
        locationId: { in: locIds },
        trxAt: { gte: dayStart },
        status: { not: 'void' },
        trxType: { in: ['IN_PRODUCTION', 'IN_SUPPLIER', 'OUT_SALE'] },
      },
    });
    const raw = await this.rawSummary(
      locIds,
      tz,
      dayStart,
      productRows.filter((p) => p.unit === 'rit'),
    );

    const isMgr = user.role === 'owner' || user.role === 'admin';
    const [pendingApproval, voidRequests] = isMgr
      ? await Promise.all([
          this.prisma.transaction.count({
            where: { locationId: { in: locIds }, status: 'pending_approval' },
          }),
          this.prisma.transaction.count({
            where: {
              locationId: { in: locIds },
              voidRequestedAt: { not: null },
              status: { not: 'void' },
            },
          }),
        ])
      : [0, 0];

    return {
      server_time: new Date().toISOString(),
      location_id: locationId ?? null,
      locations: locations.map((l) => ({
        id: l.id,
        code: l.code,
        name: l.name,
      })),
      total_ton: total.toFixed(3),
      products: productRows,
      today: {
        in_ton: dec(today.find((r) => r.direction === 'in')?.total).toFixed(3),
        out_ton: dec(today.find((r) => r.direction === 'out')?.total).toFixed(
          3,
        ),
        truck_count: trucks,
        trx_count: trxCount,
      },
      raw,
      alerts,
      pending_approval_count: pendingApproval,
      void_request_count: voidRequests,
    };
  }
  /**
   * Ringkasan bahan baku mentah: dihitung per truk (1 rit = 1 truk), tanpa tonase.
   * Stok = saldo rit; masuk hari ini & bulan ini = jumlah truk Bahan Baku Masuk.
   */
  private async rawSummary(
    locIds: number[],
    timezone: string,
    dayStart: Date,
    rows: { qty_ton: string }[],
  ) {
    if (!rows.length) return null;
    const qty = rows.reduce((s, r) => s.plus(dec(r.qty_ton)), dec(0));
    const monthStart = startOfLocalMonth(new Date(), timezone);
    const locIn = locIds.length ? Prisma.join(locIds) : Prisma.sql`NULL`;
    const [agg] = await this.prisma.$queryRaw<
      { today: Prisma.Decimal | null; month: Prisma.Decimal | null }[]
    >`
      SELECT SUM(CASE WHEN t.trx_at >= ${dayStart} THEN i.qty_ton END) AS today,
        SUM(i.qty_ton) AS month
      FROM transactions t
      JOIN transaction_items i ON i.transaction_id = t.id AND i.superseded_at IS NULL
      WHERE t.location_id IN (${locIn})
        AND t.trx_type = 'IN_RAW' AND t.status <> 'void'
        AND t.trx_at >= ${monthStart}`;
    const fmt = (v: Decimal) => v.toDecimalPlaces(3).toString();
    return {
      qty_rit: fmt(qty),
      today_in_rit: fmt(dec(agg?.today)),
      month_in_rit: fmt(dec(agg?.month)),
    };
  }
}
