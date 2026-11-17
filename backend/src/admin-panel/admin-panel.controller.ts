import {
  Body,
  Controller,
  Get,
  Param,
  ParseIntPipe,
  Post,
  Query,
  Req,
  Res,
  UseFilters,
  UseGuards,
} from '@nestjs/common';
import { Prisma } from '@prisma/client';
import { Response } from 'express';
import { join } from 'path';
import { AppError } from '../common/app-error';
import { canAccessLocation, locationScope, Public } from '../common/auth-user';
import { dec } from '../common/decimal';
import { DashboardService } from '../dashboard/dashboard.service';
import { DeliveryNotesController } from '../delivery-notes/delivery-notes.controller';
import { PrismaService } from '../prisma/prisma.service';
import { PostingService } from '../transactions/posting.service';
import { ApproveDto, VoidDto } from '../transactions/transaction.dto';
import { TRX_INCLUDE } from '../transactions/transaction.serializer';
import { UPLOAD_DIR } from '../transactions/transactions.controller';
import { TransactionsService } from '../transactions/transactions.service';
import {
  ADMIN_BASE,
  AdminExceptionFilter,
  AdminGuard,
  AdminRequest,
  setFlash,
} from './admin-auth';
import { AdminView, validated, wibDay, withQuery } from './admin-view';
import {
  fmtDateTime,
  STATUS_LABEL,
  str,
  TRX_TYPE_LABEL,
  ymd,
} from './view-engine';

const INPUT_TYPES = [
  'OUT_SALE',
  'IN_RAW',
  'IN_PRODUCTION',
  'IN_SUPPLIER',
  'ADJUSTMENT',
];

interface TrxQuery {
  date_from?: string;
  date_to?: string;
  location_id?: string;
  type?: string;
  status?: string;
  q?: string;
  page?: string;
}

/** Admin panel: dashboard, transaksi, laporan. */
@Public()
@Controller('admin-panel')
@UseGuards(AdminGuard)
@UseFilters(AdminExceptionFilter)
export class AdminPanelController {
  constructor(
    private view: AdminView,
    private prisma: PrismaService,
    private dashboard: DashboardService,
    private trx: TransactionsService,
    private posting: PostingService,
    private notes: DeliveryNotesController,
  ) {}

  private async locations(req: AdminRequest) {
    return this.prisma.location.findMany({
      where: {
        isActive: true,
        id: locationScope(req.user) as Prisma.IntFilter | undefined,
      },
      orderBy: { code: 'asc' },
    });
  }

  // ───────────────────────── Dashboard ─────────────────────────

  @Get()
  async home(
    @Req() req: AdminRequest,
    @Res() res: Response,
    @Query('location_id') loc?: string,
  ) {
    const locationId = loc ? Number(loc) : undefined;
    const [d, recent, pending, voidReq, locations] = await Promise.all([
      this.dashboard.get(req.user, locationId),
      this.trx.list(req.user, {
        location_id: loc || undefined,
        per_page: '10',
      }),
      this.trx.list(req.user, { status: 'pending_approval', per_page: '20' }),
      this.trx.list(req.user, { void_requested: '1', per_page: '20' }),
      this.locations(req),
    ]);
    return this.view.render(req, res, 'dashboard', 'dashboard', {
      title: 'Dashboard',
      d,
      recent: recent.data,
      pending: pending.data,
      voidRequests: voidReq.data,
      locations,
      locationId: loc ?? '',
      updatedAt: fmtDateTime(new Date()),
    });
  }

  // ───────────────────────── Transaksi ─────────────────────────

  @Get('trx')
  async trxList(
    @Req() req: AdminRequest,
    @Res() res: Response,
    @Query() q: TrxQuery,
  ) {
    const page = Math.max(1, Number(q.page) || 1);
    const r = await this.trx.list(req.user, {
      date_from: wibDay(q.date_from)?.toISOString(),
      date_to: wibDay(q.date_to, 1)?.toISOString(),
      location_id: q.location_id || undefined,
      type: q.type || undefined,
      status: q.status || undefined,
      q: q.q || undefined,
      page: String(page),
      per_page: '30',
    });
    return this.view.render(req, res, 'trx-list', 'trx', {
      title: 'Transaksi',
      rows: r.data,
      q,
      page,
      prevUrl:
        page > 1 ? withQuery('/trx', { ...q }, { page: page - 1 }) : null,
      nextUrl: r.has_more
        ? withQuery('/trx', { ...q }, { page: page + 1 })
        : null,
      csvUrl: withQuery(
        '/reports/transactions.csv',
        { ...q },
        { page: undefined },
      ),
      locations: await this.locations(req),
      types: Object.entries(TRX_TYPE_LABEL).map(([value, label]) => ({
        value,
        label,
      })),
      statuses: Object.entries(STATUS_LABEL).map(([value, label]) => ({
        value,
        label,
      })),
    });
  }

  @Get('trx/:id')
  async trxDetail(
    @Req() req: AdminRequest,
    @Res() res: Response,
    @Param('id', ParseIntPipe) id: number,
  ) {
    const t = (await this.trx.detail(req.user, BigInt(id))) as Record<
      string,
      any
    >;
    return this.view.render(req, res, 'trx-detail', 'trx', {
      title: t.doc_no ?? `Transaksi #${id}`,
      t,
      p: t.permissions,
      isOutSale: t.trx_type === 'OUT_SALE',
      isInput: INPUT_TYPES.includes(t.trx_type as string),
      tz: t.location?.timezone,
    });
  }

  @Post('trx/:id/approve')
  async approve(
    @Req() req: AdminRequest,
    @Res() res: Response,
    @Param('id', ParseIntPipe) id: number,
    @Body() body: Record<string, unknown>,
  ) {
    const dto = await validated(
      ApproveDto,
      {
        note: (body.note as string)?.trim() || undefined,
      },
      { note: 'Catatan' },
    );
    await this.posting.approve(req.user, BigInt(id), dto.note);
    setFlash(req, res, 'ok', 'Transaksi disetujui.');
    return res.redirect(`${ADMIN_BASE}/trx/${id}`);
  }

  @Post('trx/:id/void')
  async void(
    @Req() req: AdminRequest,
    @Res() res: Response,
    @Param('id', ParseIntPipe) id: number,
    @Body() body: Record<string, unknown>,
  ) {
    const dto = await validated(
      VoidDto,
      {
        reason: (body.reason as string)?.trim() ?? '',
      },
      { reason: 'Alasan' },
    );
    const r = await this.posting.void(req.user, BigInt(id), dto.reason);
    setFlash(
      req,
      res,
      'ok',
      r.requested
        ? 'Pengajuan void dikirim. Menunggu keputusan Owner.'
        : 'Transaksi dibatalkan (VOID) dan stok sudah dikembalikan.',
    );
    return res.redirect(`${ADMIN_BASE}/trx/${id}`);
  }

  @Get('trx/:id/pdf')
  async pdf(
    @Req() req: AdminRequest,
    @Res() res: Response,
    @Param('id', ParseIntPipe) id: number,
  ) {
    const t = await this.prisma.transaction.findUnique({
      where: { id: BigInt(id) },
      include: TRX_INCLUDE,
    });
    if (!t || !canAccessLocation(req.user, t.locationId))
      throw AppError.notFound('Transaksi tidak ditemukan.');
    if (t.trxType !== 'OUT_SALE')
      throw AppError.validation(
        'Surat jalan hanya untuk transaksi barang keluar.',
      );
    const buf = await this.notes.render(t);
    res.setHeader('Content-Type', 'application/pdf');
    res.setHeader(
      'Content-Disposition',
      `inline; filename="${(t.docNo ?? 'SJ').replace(/\//g, '-')}.pdf"`,
    );
    res.end(buf);
  }

  @Get('trx/:id/photo')
  async photo(
    @Req() req: AdminRequest,
    @Res() res: Response,
    @Param('id', ParseIntPipe) id: number,
  ) {
    const rel = await this.trx.photoPath(req.user, BigInt(id));
    return res.sendFile(join(UPLOAD_DIR, rel));
  }

  // ───────────────────────── Laporan ─────────────────────────

  /** Rentang laporan (default: awal bulan ini s/d hari ini, WIB). */
  private range(q: { from?: string; to?: string }) {
    const today = ymd(new Date());
    const from = q.from && wibDay(q.from) ? q.from : `${today.slice(0, 8)}01`;
    const to = q.to && wibDay(q.to) ? q.to : today;
    return { from, to, start: wibDay(from)!, end: wibDay(to, 1)! };
  }

  private locFilter(req: AdminRequest, loc?: string) {
    const requested = loc ? Number(loc) : undefined;
    if (requested && !canAccessLocation(req.user, requested))
      throw AppError.forbidden('Anda tidak memiliki akses ke lokasi ini.');
    const ids = requested ? [requested] : (req.user.locationIds ?? null); // null = semua (owner)
    return ids === null
      ? Prisma.sql`1=1`
      : ids.length
        ? Prisma.sql`t.location_id IN (${Prisma.join(ids)})`
        : Prisma.sql`1=0`;
  }

  @Get('reports')
  async reports(
    @Req() req: AdminRequest,
    @Res() res: Response,
    @Query() q: { from?: string; to?: string; location_id?: string },
  ) {
    const { from, to, start, end } = this.range(q);
    const loc = this.locFilter(req, q.location_id);
    const base = Prisma.sql`t.status <> 'void' AND i.superseded_at IS NULL
      AND t.trx_at >= ${start} AND t.trx_at < ${end} AND ${loc}`;

    const perProduct = await this.prisma.$queryRaw<
      {
        code: string;
        name: string;
        unit: 'ton' | 'rit';
        in_raw: unknown;
        in_prod: unknown;
        in_supp: unknown;
        out_sale: unknown;
        adj_in: unknown;
        adj_out: unknown;
      }[]
    >`
      SELECT p.code, p.name, p.unit,
        SUM(CASE WHEN t.trx_type='IN_RAW' THEN i.qty_ton ELSE 0 END) AS in_raw,
        SUM(CASE WHEN t.trx_type='IN_PRODUCTION' THEN i.qty_ton ELSE 0 END) AS in_prod,
        SUM(CASE WHEN t.trx_type='IN_SUPPLIER' THEN i.qty_ton ELSE 0 END) AS in_supp,
        SUM(CASE WHEN t.trx_type='OUT_SALE' THEN i.qty_ton ELSE 0 END) AS out_sale,
        SUM(CASE WHEN t.trx_type='ADJUSTMENT' AND i.direction='in' THEN i.qty_ton ELSE 0 END) AS adj_in,
        SUM(CASE WHEN t.trx_type='ADJUSTMENT' AND i.direction='out' THEN i.qty_ton ELSE 0 END) AS adj_out
      FROM transactions t
      JOIN transaction_items i ON i.transaction_id = t.id
      JOIN products p ON p.id = i.product_id
      WHERE ${base}
      GROUP BY p.id, p.code, p.name, p.unit, p.sort_order
      ORDER BY p.sort_order, p.id`;

    const perCustomer = await this.prisma.$queryRaw<
      { partner: string | null; trips: bigint; total: unknown }[]
    >`
      SELECT COALESCE(t.partner_name, '(tanpa nama)') AS partner,
        COUNT(DISTINCT t.id) AS trips, SUM(i.qty_ton) AS total
      FROM transactions t
      JOIN transaction_items i ON i.transaction_id = t.id
      WHERE ${base} AND t.trx_type = 'OUT_SALE'
      GROUP BY COALESCE(t.partner_name, '(tanpa nama)')
      ORDER BY total DESC
      LIMIT 100`;

    const perDay = await this.prisma.$queryRaw<
      {
        day: string;
        in_rit: unknown;
        in_ton: unknown;
        out_ton: unknown;
        trips: bigint;
      }[]
    >`
      SELECT DATE_FORMAT(CONVERT_TZ(t.trx_at, '+00:00', '+07:00'), '%Y-%m-%d') AS day,
        SUM(CASE WHEN t.trx_type = 'IN_RAW' THEN i.qty_ton ELSE 0 END) AS in_rit,
        SUM(CASE WHEN t.trx_type IN ('IN_PRODUCTION','IN_SUPPLIER') THEN i.qty_ton ELSE 0 END) AS in_ton,
        SUM(CASE WHEN t.trx_type = 'OUT_SALE' THEN i.qty_ton ELSE 0 END) AS out_ton,
        COUNT(DISTINCT CASE WHEN t.trx_type = 'OUT_SALE' THEN t.id END) AS trips
      FROM transactions t
      JOIN transaction_items i ON i.transaction_id = t.id
      WHERE ${base}
      GROUP BY day
      ORDER BY day`;

    let tIn = dec(0);
    let tOut = dec(0);
    let tRaw = dec(0);
    const products = perProduct.map((r) => {
      if (r.unit === 'rit') {
        tRaw = tRaw.plus(dec(String(r.in_raw)));
      } else {
        tIn = tIn.plus(dec(String(r.in_prod)).plus(dec(String(r.in_supp))));
        tOut = tOut.plus(dec(String(r.out_sale)));
      }
      return {
        code: r.code,
        name: r.name,
        unit: r.unit,
        in_raw: String(r.in_raw),
        in_prod: String(r.in_prod),
        in_supp: String(r.in_supp),
        out_sale: String(r.out_sale),
        adj: dec(String(r.adj_in))
          .minus(dec(String(r.adj_out)))
          .toFixed(3),
      };
    });
    const trips = perCustomer.reduce((s, r) => s + Number(r.trips), 0);

    return this.view.render(req, res, 'reports', 'reports', {
      title: 'Laporan',
      from,
      to,
      locationId: q.location_id ?? '',
      locations: await this.locations(req),
      products,
      customers: perCustomer.map((r) => ({
        partner: r.partner,
        trips: Number(r.trips),
        total: String(r.total),
      })),
      days: perDay.map((r) => ({
        day: r.day.split('-').reverse().join('/'),
        in_rit: String(r.in_rit),
        in_ton: String(r.in_ton),
        out_ton: String(r.out_ton),
        trips: Number(r.trips),
      })),
      totalIn: tIn.toFixed(3),
      totalRaw: tRaw.toString(),
      totalOut: tOut.toFixed(3),
      trips,
      csvUrl: withQuery(
        '/reports/transactions.csv',
        {},
        {
          date_from: from,
          date_to: to,
          location_id: q.location_id,
        },
      ),
    });
  }

  /** Ekspor transaksi ke CSV (pemisah ";" dan desimal koma → langsung rapi di Excel Indonesia). */
  @Get('reports/transactions.csv')
  async csv(
    @Req() req: AdminRequest,
    @Res() res: Response,
    @Query() q: TrxQuery,
  ) {
    const requested = q.location_id ? Number(q.location_id) : undefined;
    if (requested && !canAccessLocation(req.user, requested))
      throw AppError.forbidden();
    const rows = await this.prisma.transaction.findMany({
      where: {
        locationId: locationScope(req.user, requested),
        trxAt: {
          gte: wibDay(q.date_from),
          lt: wibDay(q.date_to, 1),
        },
        trxType: q.type ? { in: q.type.split(',') as never } : undefined,
        status: q.status ? { in: q.status.split(',') as never } : undefined,
        ...(q.q?.trim()
          ? {
              OR: [
                { docNo: { contains: q.q.trim() } },
                { manualDocNo: { contains: q.q.trim() } },
                { partnerName: { contains: q.q.trim() } },
                {
                  plateNumber: {
                    contains: q.q.trim().toUpperCase().replace(/\s+/g, ''),
                  },
                },
              ],
            }
          : {}),
      },
      include: TRX_INCLUDE,
      orderBy: [{ trxAt: 'asc' }, { id: 'asc' }],
      take: 50000,
    });
    const num = (v: unknown) =>
      v === null || v === undefined
        ? ''
        : dec(str(v)).toFixed(3).replace('.', ',');
    const cell = (v: unknown) => {
      const s = str(v);
      return /[";\n\r]/.test(s) ? `"${s.replace(/"/g, '""')}"` : s;
    };
    const header = [
      'Tanggal',
      'No. Dokumen',
      'No. Manual',
      'Jenis',
      'Status',
      'Lokasi',
      'Pelanggan/Supplier',
      'No. Polisi',
      'Sopir',
      'Produk',
      'Arah',
      'Jumlah',
      'Satuan',
      'Bruto',
      'Tara',
      'Netto',
      'Dibuat oleh',
      'Catatan',
    ];
    const lines = [header.join(';')];
    for (const t of rows) {
      for (const i of t.items.filter((x) => !x.supersededAt)) {
        lines.push(
          [
            fmtDateTime(t.trxAt, t.location.timezone),
            t.docNo,
            t.manualDocNo,
            TRX_TYPE_LABEL[t.trxType] ?? t.trxType,
            STATUS_LABEL[t.status] ?? t.status,
            t.location.name,
            t.partnerName,
            t.plateNumber,
            t.driverName,
            i.product?.name,
            i.direction === 'in' ? 'Masuk' : 'Keluar',
            i.product?.unit === 'rit'
              ? dec(str(i.qtyTon)).toString()
              : num(i.qtyTon),
            i.product?.unit === 'rit' ? 'Rit' : 'Ton',
            num(t.grossTon),
            num(t.tareTon),
            num(t.netTon),
            t.createdBy.name,
            t.notes,
          ]
            .map(cell)
            .join(';'),
        );
      }
    }
    const name = `transaksi_${q.date_from ?? 'awal'}_${q.date_to ?? ymd(new Date())}.csv`;
    res.setHeader('Content-Type', 'text/csv; charset=utf-8');
    res.setHeader('Content-Disposition', `attachment; filename="${name}"`);
    res.end('﻿' + lines.join('\r\n'));
  }
}
