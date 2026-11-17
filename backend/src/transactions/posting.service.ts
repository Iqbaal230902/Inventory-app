import { HttpStatus, Injectable } from '@nestjs/common';
import {
  Direction,
  LineRole,
  Prisma,
  StockUnit,
  TrxStatus,
  TrxType,
} from '@prisma/client';
import { randomBytes, randomUUID } from 'crypto';
import { AuditService } from '../audit/audit.service';
import { AppError } from '../common/app-error';
import { AuthUser, canAccessLocation } from '../common/auth-user';
import { dec, Decimal, qtyId, tonId } from '../common/decimal';
import { periodOf, startOfLocalDay } from '../common/time';
import { PrismaService, Tx } from '../prisma/prisma.service';
import { SettingsService } from '../settings/settings.service';
import {
  CreateTransactionDto,
  InputTrxType,
  TrxBodyDto,
  UpdateTransactionDto,
} from './transaction.dto';
import { TRX_INCLUDE, TrxWithRelations } from './transaction.serializer';

export const DOC_PREFIX: Partial<Record<TrxType, string>> = {
  OUT_SALE: 'SJ',
  IN_RAW: 'BB',
  IN_PRODUCTION: 'BM',
  IN_SUPPLIER: 'BM',
  ADJUSTMENT: 'ADJ',
  VOID: 'VD',
  PRODUCTION: 'PRD',
  TRANSFER_OUT: 'TRF',
  TRANSFER_IN: 'TRF',
  SHRINKAGE: 'SO',
};

/** Normalisasi No. Polisi: "bg 1234 xy" → "BG1234XY" */
export function normalizePlate(p?: string | null) {
  if (!p) return null;
  const s = p.toUpperCase().replace(/[^A-Z0-9]/g, '');
  return s || null;
}

export interface PostLine {
  productId: number;
  direction: Direction;
  lineRole?: LineRole;
  packagingUnitId?: number | null;
  packageQty?: Decimal | null;
  /** Untuk produk bersatuan rit, nilai ini = jumlah rit. */
  qtyTon: Decimal;
  unit?: StockUnit;
}

interface Shortage {
  product_id: number;
  product_name: string;
  unit: StockUnit;
  available_ton: string;
  requested_ton: string;
}

export type PostSource = 'online' | 'sync';

export interface PostResult {
  status: 'ok' | 'duplicate';
  transaction: TrxWithRelations;
  warnings: { code: string; message: string }[];
}

@Injectable()
export class PostingService {
  constructor(
    private prisma: PrismaService,
    private audit: AuditService,
    private settings: SettingsService,
  ) {}

  // ---------------------------------------------------------------------------
  // Pembuatan transaksi (online & sync)
  // ---------------------------------------------------------------------------

  async create(
    user: AuthUser,
    dto: CreateTransactionDto,
    source: PostSource = 'online',
  ): Promise<PostResult> {
    // 1. Idempotensi cepat (tanpa lock)
    const existing = await this.findByUuid(dto.client_uuid);
    if (existing)
      return { status: 'duplicate', transaction: existing, warnings: [] };

    this.assertCanInput(user, dto.trx_type, dto.location_id);
    if (!dto.trx_at)
      throw AppError.validation('Tanggal transaksi wajib diisi.');

    const location = await this.prisma.location.findUnique({
      where: { id: dto.location_id },
    });
    if (!location || !location.isActive)
      throw AppError.validation('Lokasi tidak valid.');

    const header = await this.buildHeader(dto, dto.trx_type);
    const lines = await this.buildLines(dto.trx_type, dto.items);
    this.assertRaw(dto.trx_type, header);
    await this.validateCommon(dto, dto.trx_type, lines, header);
    const warnings = await this.collectWarnings(
      dto.trx_type,
      header,
      dto.location_id,
    );

    const clientCreatedAt = new Date(dto.client_created_at);
    const skewHours =
      Math.abs(Date.now() - clientCreatedAt.getTime()) / 3_600_000;

    try {
      const { trxId, dup } = await this.prisma.withTx(async (tx) => {
        // Idempotensi di dalam transaksi (dua request bersamaan dengan UUID sama)
        const dup = await tx.transaction.findUnique({
          where: { clientUuid: dto.client_uuid },
          select: { id: true },
        });
        if (dup) return { trxId: dup.id, dup: true };

        const balances = await this.lockBalances(tx, dto.location_id, lines);
        const shortages = await this.findShortages(tx, balances, lines);

        let status: TrxStatus = 'posted';
        let reviewNote: string | null = null;
        if (shortages.length) {
          if (source === 'sync') {
            // Barang sudah keluar secara fisik saat offline → terima, tandai untuk ditinjau.
            status = 'pending_approval';
            reviewNote = 'Stok server tidak cukup saat sinkronisasi offline.';
          } else if (dto.allow_negative && user.role === 'owner') {
            if (!dto.negative_reason?.trim()) {
              throw AppError.validation('Alasan stok negatif wajib diisi.');
            }
            reviewNote = `Stok negatif diizinkan Owner: ${dto.negative_reason.trim()}`;
          } else {
            throw this.insufficient(shortages, location.name);
          }
        }

        const docNo = await this.nextDocNo(
          tx,
          dto.trx_type,
          location.id,
          location.code,
          location.timezone,
          header.trxAt,
        );
        const trx = await tx.transaction.create({
          data: {
            clientUuid: dto.client_uuid,
            docNo,
            trxType: dto.trx_type,
            locationId: location.id,
            ...header,
            status,
            reviewNote,
            verifyToken: randomBytes(16).toString('hex'),
            createdById: user.id,
            deviceId: user.deviceId?.slice(0, 64),
            clientCreatedAt,
          },
        });
        await this.writeLines(tx, trx.id, location.id, lines, balances);
        await this.audit.log(
          {
            user,
            action: 'create',
            entity: 'transaction',
            entityId: trx.id,
            newValues: {
              ...dto,
              doc_no: docNo,
              status,
              source,
              clock_skew_hours:
                skewHours > 24 ? Math.round(skewHours) : undefined,
            },
          },
          tx,
        );
        return { trxId: trx.id, dup: false };
      });
      const transaction = await this.load(trxId);
      return {
        status: dup ? 'duplicate' : 'ok',
        transaction,
        warnings: dup ? [] : warnings,
      };
    } catch (e) {
      // Balapan UUID: request lain lebih dulu menyimpan UUID yang sama
      if (
        e instanceof Prisma.PrismaClientKnownRequestError &&
        e.code === 'P2002' &&
        JSON.stringify(e.meta?.target ?? '').includes('client_uuid')
      ) {
        const again = await this.findByUuid(dto.client_uuid);
        if (again)
          return { status: 'duplicate', transaction: again, warnings: [] };
      }
      throw e;
    }
  }

  // ---------------------------------------------------------------------------
  // Edit (sebelum terkunci) — append-only: ledger lama dibalik, ledger baru ditulis
  // ---------------------------------------------------------------------------

  async update(user: AuthUser, id: bigint, dto: UpdateTransactionDto) {
    const current = await this.load(id);
    if (!canAccessLocation(user, current.locationId))
      throw AppError.forbidden();
    if (!['owner', 'admin'].includes(user.role)) {
      throw AppError.forbidden(
        'Hanya Owner/Admin yang dapat mengedit transaksi.',
      );
    }
    if (!(INPUT_TYPES as readonly TrxType[]).includes(current.trxType)) {
      throw AppError.validation('Jenis transaksi ini tidak dapat diedit.');
    }
    if (current.status === 'void')
      throw AppError.validation('Transaksi sudah di-void.');
    await this.assertNotLocked(current);
    const type = current.trxType as InputTrxType;

    const merged: TrxBodyDto = {
      partner_id: dto.partner_id ?? current.partnerId ?? undefined,
      partner_name: dto.partner_name ?? current.partnerName ?? undefined,
      vehicle_id: dto.vehicle_id ?? current.vehicleId ?? undefined,
      plate_number: dto.plate_number ?? current.plateNumber ?? undefined,
      driver_name: dto.driver_name ?? current.driverName ?? undefined,
      gross_ton: dto.gross_ton ?? current.grossTon?.toString(),
      tare_ton: dto.tare_ton ?? current.tareTon?.toString(),
      trx_at: dto.trx_at ?? current.trxAt.toISOString(),
      manual_doc_no: dto.manual_doc_no ?? current.manualDocNo ?? undefined,
      notes: dto.notes ?? current.notes ?? undefined,
      items:
        dto.items ??
        current.items
          .filter((i) => !i.supersededAt)
          .map((i) => ({
            product_id: i.productId!,
            packaging_unit_id: i.packagingUnitId ?? undefined,
            package_qty: i.packageQty?.toString(),
            qty_ton: i.qtyTon.toString(),
            direction: i.direction,
          })),
      confirm_large: dto.confirm_large,
    };
    // gross/tare dikosongkan secara eksplisit
    if (dto.gross_ton === '' || dto.tare_ton === '') {
      merged.gross_ton = undefined;
      merged.tare_ton = undefined;
    }

    const header = await this.buildHeader(merged, type);
    const lines = await this.buildLines(type, merged.items);
    this.assertRaw(type, header);
    await this.validateCommon(merged, type, lines, header);
    const itemsChanged = dto.items !== undefined;

    await this.prisma.withTx(async (tx) => {
      const locked = await tx.$queryRaw<{ status: string }[]>`
        SELECT status FROM transactions WHERE id = ${id} FOR UPDATE`;
      if (locked[0]?.status === 'void')
        throw AppError.validation('Transaksi sudah di-void.');

      if (itemsChanged) {
        const oldItems = await tx.transactionItem.findMany({
          where: { transactionId: id, supersededAt: null },
        });
        const reversal: PostLine[] = oldItems.map((i) => ({
          productId: i.productId!,
          direction: i.direction === 'in' ? 'out' : 'in',
          qtyTon: dec(i.qtyTon),
        }));
        const balances = await this.lockBalances(tx, current.locationId, [
          ...reversal,
          ...lines,
        ]);
        // Cek stok setelah pembalikan + baris baru
        const net = new Map<number, Decimal>();
        for (const l of [...reversal, ...lines]) {
          const d = l.direction === 'in' ? l.qtyTon : l.qtyTon.neg();
          net.set(l.productId, (net.get(l.productId) ?? dec(0)).plus(d));
        }
        const shortages: Shortage[] = [];
        for (const [pid, change] of net) {
          const bal = balances.get(pid)!;
          if (change.isNeg() && bal.plus(change).isNeg()) {
            shortages.push(await this.shortage(tx, pid, bal, change.neg()));
          }
        }
        if (
          shortages.length &&
          !(user.role === 'owner' && dto.allow_negative)
        ) {
          const loc = await tx.location.findUniqueOrThrow({
            where: { id: current.locationId },
          });
          throw this.insufficient(shortages, loc.name);
        }
        // Tulis ledger pembalik untuk item lama (mengacu ke item lama)
        for (const it of oldItems) {
          const change =
            it.direction === 'in' ? dec(it.qtyTon).neg() : dec(it.qtyTon);
          await this.ledgerRow(
            tx,
            id,
            it.id,
            current.locationId,
            it.productId!,
            change,
            balances,
          );
        }
        await tx.transactionItem.updateMany({
          where: { transactionId: id, supersededAt: null },
          data: { supersededAt: new Date() },
        });
        await this.writeLines(tx, id, current.locationId, lines, balances);
      }

      await tx.transaction.update({ where: { id }, data: header });
      await this.audit.log(
        {
          user,
          action: 'update',
          entity: 'transaction',
          entityId: id,
          oldValues: snapshot(current),
          newValues: { ...dto, reason: dto.edit_reason },
        },
        tx,
      );
    });
    return this.load(id);
  }

  // ---------------------------------------------------------------------------
  // Void — membuat transaksi VOID dengan mutasi pembalik
  // ---------------------------------------------------------------------------

  async void(user: AuthUser, id: bigint, reason: string) {
    const current = await this.load(id);
    if (!canAccessLocation(user, current.locationId))
      throw AppError.forbidden();
    if (current.status === 'void')
      throw AppError.validation('Transaksi sudah di-void.');
    if (current.trxType === 'VOID')
      throw AppError.validation('Transaksi VOID tidak dapat di-void.');

    if (user.role === 'admin') {
      // Admin hanya dapat mengajukan void
      await this.prisma.transaction.update({
        where: { id },
        data: {
          voidRequestedBy: user.id,
          voidRequestedAt: new Date(),
          voidRequestReason: reason,
        },
      });
      await this.audit.log({
        user,
        action: 'void_request',
        entity: 'transaction',
        entityId: id,
        newValues: { reason },
      });
      return { requested: true, transaction: await this.load(id) };
    }
    if (user.role !== 'owner')
      throw AppError.forbidden('Hanya Owner yang dapat melakukan void.');
    await this.assertNotLocked(current);

    const location = current.location;
    await this.prisma.withTx(async (tx) => {
      const row = await tx.$queryRaw<{ status: string }[]>`
        SELECT status FROM transactions WHERE id = ${id} FOR UPDATE`;
      if (row[0]?.status === 'void')
        throw AppError.validation('Transaksi sudah di-void.');

      const items = await tx.transactionItem.findMany({
        where: {
          transactionId: id,
          supersededAt: null,
          productId: { not: null },
        },
      });
      const lines: PostLine[] = items.map((i) => ({
        productId: i.productId!,
        direction: i.direction === 'in' ? 'out' : 'in',
        lineRole: i.lineRole,
        packagingUnitId: i.packagingUnitId,
        packageQty: i.packageQty ? dec(i.packageQty) : null,
        qtyTon: dec(i.qtyTon),
      }));
      const balances = await this.lockBalances(tx, current.locationId, lines);
      const now = new Date();
      const docNo = await this.nextDocNo(
        tx,
        'VOID',
        location.id,
        location.code,
        location.timezone,
        now,
      );
      const voidTrx = await tx.transaction.create({
        data: {
          clientUuid: randomUUID(),
          docNo,
          trxType: 'VOID',
          locationId: current.locationId,
          refTransactionId: id,
          partnerId: current.partnerId,
          partnerName: current.partnerName,
          plateNumber: current.plateNumber,
          driverName: current.driverName,
          netTon: current.netTon,
          trxAt: now,
          notes: `Void ${current.docNo}: ${reason}`,
          verifyToken: randomBytes(16).toString('hex'),
          createdById: user.id,
          deviceId: user.deviceId?.slice(0, 64),
          clientCreatedAt: now,
        },
      });
      await this.writeLines(
        tx,
        voidTrx.id,
        current.locationId,
        lines,
        balances,
      );
      await tx.transaction.update({
        where: { id },
        data: { status: 'void', voidReason: reason, voidedById: user.id },
      });
      await this.audit.log(
        {
          user,
          action: 'void',
          entity: 'transaction',
          entityId: id,
          oldValues: { status: current.status },
          newValues: { status: 'void', reason, void_doc_no: docNo },
        },
        tx,
      );
    });
    return { requested: false, transaction: await this.load(id) };
  }

  /** Owner/Admin menandai transaksi pending_approval sudah ditinjau. */
  async approve(user: AuthUser, id: bigint, note?: string) {
    const current = await this.load(id);
    if (!canAccessLocation(user, current.locationId))
      throw AppError.forbidden();
    if (current.status !== 'pending_approval') {
      throw AppError.validation('Transaksi tidak sedang menunggu persetujuan.');
    }
    await this.prisma.transaction.update({
      where: { id },
      data: {
        status: 'posted',
        reviewNote: [
          current.reviewNote,
          `Disetujui ${user.name}${note ? `: ${note}` : ''}`,
        ]
          .filter(Boolean)
          .join(' | ')
          .slice(0, 255),
      },
    });
    await this.audit.log({
      user,
      action: 'approve',
      entity: 'transaction',
      entityId: id,
      oldValues: { status: 'pending_approval' },
      newValues: { status: 'posted', note },
    });
    return this.load(id);
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  load(id: bigint) {
    return this.prisma.transaction.findUniqueOrThrow({
      where: { id },
      include: TRX_INCLUDE,
    });
  }

  private findByUuid(uuid: string) {
    return this.prisma.transaction.findUnique({
      where: { clientUuid: uuid },
      include: TRX_INCLUDE,
    });
  }

  async isLocked(trx: {
    isLocked: boolean;
    trxAt: Date;
    location: { timezone: string };
  }) {
    if (trx.isLocked) return true;
    const days = await this.settings.num('lock_after_days');
    const cutoff = startOfLocalDay(new Date(), trx.location.timezone, -days);
    return trx.trxAt < cutoff;
  }

  private async assertNotLocked(trx: TrxWithRelations) {
    if (await this.isLocked(trx)) {
      throw new AppError(
        'LOCKED',
        'Transaksi sudah terkunci. Gunakan transaksi Penyesuaian untuk koreksi.',
        HttpStatus.CONFLICT,
      );
    }
  }

  assertCanInput(user: AuthUser, type: InputTrxType, locationId: number) {
    if (user.role === 'viewer')
      throw AppError.forbidden('Viewer tidak dapat menginput transaksi.');
    if (type === 'ADJUSTMENT' && !['owner', 'admin'].includes(user.role)) {
      throw AppError.forbidden(
        'Penyesuaian hanya dapat dilakukan Admin/Owner.',
      );
    }
    if (!canAccessLocation(user, locationId)) {
      throw AppError.forbidden('Anda tidak memiliki akses ke lokasi ini.');
    }
  }

  private async buildHeader(dto: TrxBodyDto, type: InputTrxType) {
    const plate = normalizePlate(dto.plate_number);
    let vehicleId = dto.vehicle_id ?? null;
    let driver = dto.driver_name?.trim() || null;
    if (!vehicleId && plate) {
      const v = await this.prisma.vehicle.findUnique({
        where: { plateNumber: plate },
      });
      if (v) {
        vehicleId = v.id;
        driver ??= v.defaultDriver;
      }
    }

    let partnerName = dto.partner_name?.trim() || null;
    if (dto.partner_id) {
      const p = await this.prisma.partner.findUnique({
        where: { id: dto.partner_id },
      });
      if (!p) throw AppError.validation('Pelanggan/supplier tidak ditemukan.');
      if (type === 'OUT_SALE' && p.type === 'supplier') {
        throw AppError.validation(`${p.name} bukan pelanggan.`);
      }
      if (type === 'IN_SUPPLIER' && p.type === 'customer') {
        throw AppError.validation(`${p.name} bukan supplier.`);
      }
      partnerName = p.name;
    }

    const gross = dto.gross_ton ? dec(dto.gross_ton) : null;
    const tare = dto.tare_ton ? dec(dto.tare_ton) : null;
    let net: Decimal | null = null;
    if (gross || tare) {
      if (!gross || !tare)
        throw AppError.validation('Bruto dan tara harus diisi keduanya.');
      net = gross.minus(tare);
      if (net.lte(0))
        throw AppError.validation('Netto harus lebih dari 0 (bruto > tara).');
    }

    return {
      partnerId: dto.partner_id ?? null,
      partnerName,
      vehicleId,
      plateNumber: plate,
      driverName: driver,
      grossTon: gross?.toFixed(3) ?? null,
      tareTon: tare?.toFixed(3) ?? null,
      netTon: net?.toFixed(3) ?? null,
      trxAt: new Date(dto.trx_at!),
      manualDocNo: dto.manual_doc_no?.trim() || null,
      notes: dto.notes?.trim() || null,
    };
  }

  private async buildLines(
    type: InputTrxType,
    items: TrxBodyDto['items'],
  ): Promise<PostLine[]> {
    if (!items?.length) throw AppError.validation('Minimal satu produk.');
    const products = await this.prisma.product.findMany({
      where: { id: { in: items.map((i) => i.product_id) } },
    });
    const packaging = await this.prisma.packagingUnit.findMany({
      where: {
        id: { in: items.map((i) => i.packaging_unit_id!).filter(Boolean) },
      },
    });
    const seen = new Set<string>();
    return items.map((it) => {
      const p = products.find((x) => x.id === it.product_id);
      if (!p) throw AppError.validation('Produk tidak ditemukan.');
      if (!p.isActive)
        throw AppError.validation(`Produk ${p.name} tidak aktif.`);
      const isRit = p.unit === 'rit';
      if (type === 'IN_RAW' && !isRit) {
        throw AppError.validation(
          `${p.name} bukan bahan baku mentah. Gunakan Masuk – Produksi/Supplier.`,
        );
      }
      if (isRit && type !== 'IN_RAW' && type !== 'ADJUSTMENT') {
        throw AppError.validation(
          `${p.name} dicatat per rit lewat menu Bahan Baku Masuk.`,
        );
      }
      if (isRit && it.packaging_unit_id) {
        throw AppError.validation(`${p.name} tidak memakai kemasan.`);
      }
      const pu = it.packaging_unit_id
        ? packaging.find((x) => x.id === it.packaging_unit_id)
        : null;
      if (it.packaging_unit_id && !pu)
        throw AppError.validation('Kemasan tidak ditemukan.');

      const pkgQty = it.package_qty ? dec(it.package_qty) : null;
      let qty: Decimal;
      if (it.qty_ton) qty = dec(it.qty_ton);
      else if (pkgQty && pu)
        qty = pkgQty.times(dec(pu.tonPerUnit)).toDecimalPlaces(3);
      else
        throw AppError.validation(
          `Jumlah ${isRit ? 'rit' : 'ton'} untuk ${p.name} wajib diisi.`,
        );
      if (qty.lte(0))
        throw AppError.validation(`Jumlah ${p.name} harus lebih dari 0.`);
      if (isRit && !qty.isInteger())
        throw AppError.validation(
          `Jumlah rit ${p.name} harus bilangan bulat (1 rit = 1 truk).`,
        );

      let direction: Direction;
      if (type === 'ADJUSTMENT') {
        if (!it.direction)
          throw AppError.validation(
            'Arah penyesuaian (tambah/kurang) wajib diisi.',
          );
        direction = it.direction;
      } else {
        direction = type === 'OUT_SALE' ? 'out' : 'in';
      }
      const key = `${p.id}:${direction}`;
      if (seen.has(key))
        throw AppError.validation(`Produk ${p.name} tercantum dua kali.`);
      seen.add(key);

      return {
        productId: p.id,
        direction,
        lineRole: 'main',
        packagingUnitId: pu?.id ?? null,
        packageQty: pkgQty,
        qtyTon: qty,
        unit: p.unit,
      };
    });
  }

  /** Bahan Baku Masuk (IN_RAW): dihitung per truk (rit), tanpa timbangan/tonase. */
  private assertRaw(
    type: InputTrxType,
    header: Awaited<ReturnType<PostingService['buildHeader']>>,
  ) {
    if (type === 'IN_RAW' && header.netTon) {
      throw AppError.validation(
        'Bahan baku masuk dicatat per rit (jumlah truk), tanpa bruto/tara timbangan.',
      );
    }
  }

  private async validateCommon(
    dto: TrxBodyDto,
    type: InputTrxType,
    lines: PostLine[],
    header: Awaited<ReturnType<PostingService['buildHeader']>>,
  ) {
    if (type === 'ADJUSTMENT' && !header.notes) {
      throw AppError.validation('Alasan penyesuaian wajib diisi di catatan.');
    }
    if (type === 'OUT_SALE' && !header.partnerName) {
      throw AppError.validation('Pelanggan wajib diisi untuk barang keluar.');
    }
    // Hanya baris bersatuan ton (rit bahan baku tidak ikut tonase/timbangan).
    const total = lines
      .filter((l) => l.unit !== 'rit')
      .reduce((s, l) => s.plus(l.qtyTon), dec(0));
    if (header.netTon && !dec(header.netTon).eq(total)) {
      throw AppError.validation(
        `Total produk (${tonId(total)} Ton) harus sama dengan netto timbangan (${tonId(header.netTon)} Ton).`,
      );
    }
    const max = await this.settings.num('max_net_ton_per_trx');
    if (
      max > 0 &&
      total.gt(max) &&
      !dto.confirm_large &&
      type !== 'ADJUSTMENT'
    ) {
      throw new AppError(
        'NEEDS_CONFIRMATION',
        `Tonase ${tonId(total)} Ton melebihi batas wajar ${max} Ton per transaksi. Periksa kembali atau konfirmasi.`,
        HttpStatus.UNPROCESSABLE_ENTITY,
        { max_ton: max, total_ton: total.toFixed(3) },
      );
    }
    if (header.trxAt.getTime() > Date.now() + 10 * 60_000) {
      throw AppError.validation('Tanggal transaksi tidak boleh di masa depan.');
    }
  }

  private async collectWarnings(
    type: InputTrxType,
    header: { plateNumber: string | null; trxAt: Date },
    locationId: number,
  ) {
    const warnings: { code: string; message: string }[] = [];
    if (type === 'OUT_SALE' && header.plateNumber) {
      const win = await this.settings.num('duplicate_plate_window_min');
      const from = new Date(header.trxAt.getTime() - win * 60_000);
      const to = new Date(header.trxAt.getTime() + win * 60_000);
      const dup = await this.prisma.transaction.findFirst({
        where: {
          trxType: 'OUT_SALE',
          plateNumber: header.plateNumber,
          locationId,
          status: { not: 'void' },
          trxAt: { gte: from, lte: to },
        },
      });
      if (dup) {
        warnings.push({
          code: 'DUPLICATE_PLATE',
          message: `No. Polisi ${header.plateNumber} sudah tercatat keluar (${dup.docNo}) dalam ${win} menit terakhir. Pastikan bukan input ganda.`,
        });
      }
    }
    return warnings;
  }

  /** Pastikan baris saldo ada lalu kunci (urut product_id untuk mencegah deadlock). */
  async lockBalances(
    tx: Tx,
    locationId: number,
    lines: Pick<PostLine, 'productId'>[],
  ) {
    const ids = [...new Set(lines.map((l) => l.productId))].sort(
      (a, b) => a - b,
    );
    const map = new Map<number, Decimal>();
    if (!ids.length) return map;
    // Baris saldo dibuat di luar transaksi (autocommit) dan hanya bila belum ada.
    // INSERT IGNORE di dalam transaksi mengambil shared lock lalu FOR UPDATE meminta
    // exclusive lock → deadlock antar operator. Dengan cara ini, di dalam transaksi
    // hanya ada exclusive lock yang diambil berurutan product_id.
    const existing = await this.prisma.stockBalance.findMany({
      where: { locationId, productId: { in: ids } },
      select: { productId: true },
    });
    const missing = ids.filter(
      (id) => !existing.some((e) => e.productId === id),
    );
    if (missing.length) {
      await this.prisma.$executeRaw`
        INSERT IGNORE INTO stock_balances (location_id, product_id, qty_ton, in_transit_ton)
        VALUES ${Prisma.join(missing.map((id) => Prisma.sql`(${locationId}, ${id}, 0, 0)`))}`;
    }
    const rows = await tx.$queryRaw<
      { product_id: number; qty_ton: Prisma.Decimal }[]
    >`
      SELECT product_id, qty_ton FROM stock_balances
      WHERE location_id = ${locationId} AND product_id IN (${Prisma.join(ids)})
      ORDER BY product_id FOR UPDATE`;
    for (const r of rows) map.set(Number(r.product_id), dec(r.qty_ton));
    return map;
  }

  private async findShortages(
    tx: Tx,
    balances: Map<number, Decimal>,
    lines: PostLine[],
  ) {
    const out: Shortage[] = [];
    for (const l of lines) {
      if (l.direction !== 'out') continue;
      const bal = balances.get(l.productId)!;
      if (bal.minus(l.qtyTon).isNeg())
        out.push(await this.shortage(tx, l.productId, bal, l.qtyTon));
    }
    return out;
  }

  private async shortage(
    tx: Tx,
    productId: number,
    bal: Decimal,
    requested: Decimal,
  ): Promise<Shortage> {
    const p = await tx.product.findUnique({ where: { id: productId } });
    return {
      product_id: productId,
      product_name: p?.name ?? `#${productId}`,
      unit: p?.unit ?? 'ton',
      available_ton: bal.toFixed(3),
      requested_ton: requested.toFixed(3),
    };
  }

  private insufficient(shortages: Shortage[], locationName: string) {
    const s = shortages[0];
    return new AppError(
      'INSUFFICIENT_STOCK',
      `Stok ${s.product_name} di ${locationName} hanya ${qtyId(s.available_ton, s.unit)} (diminta ${qtyId(s.requested_ton, s.unit)}).`,
      HttpStatus.UNPROCESSABLE_ENTITY,
      { shortages },
    );
  }

  /** Penomoran: SJ/{KODE_LOKASI}/{YYYYMM}/{0001} — atomik per prefix+lokasi+periode. */
  async nextDocNo(
    tx: Tx,
    type: TrxType,
    locationId: number,
    locationCode: string,
    timezone: string,
    at: Date,
  ) {
    const prefix = DOC_PREFIX[type] ?? 'TRX';
    const period = periodOf(at, timezone);
    // Baris sequence dibuat di luar transaksi bila belum ada (awal bulan), lalu
    // di dalam transaksi cukup UPDATE (exclusive lock langsung, tanpa gap/shared lock).
    const seqKey = { prefix_locationId_period: { prefix, locationId, period } };
    if (!(await this.prisma.docSequence.findUnique({ where: seqKey }))) {
      await this.prisma.$executeRaw`
        INSERT IGNORE INTO doc_sequences (prefix, location_id, period, last_no)
        VALUES (${prefix}, ${locationId}, ${period}, 0)`;
    }
    await tx.$executeRaw`
      UPDATE doc_sequences SET last_no = last_no + 1
      WHERE prefix = ${prefix} AND location_id = ${locationId} AND period = ${period}`;
    const [row] = await tx.$queryRaw<{ last_no: number }[]>`
      SELECT last_no FROM doc_sequences
      WHERE prefix = ${prefix} AND location_id = ${locationId} AND period = ${period}`;
    return `${prefix}/${locationCode}/${period}/${String(row.last_no).padStart(4, '0')}`;
  }

  /** Tulis item + ledger + update saldo. `balances` harus sudah dikunci. */
  async writeLines(
    tx: Tx,
    trxId: bigint,
    locationId: number,
    lines: PostLine[],
    balances: Map<number, Decimal>,
  ) {
    for (const l of lines) {
      const item = await tx.transactionItem.create({
        data: {
          transactionId: trxId,
          productId: l.productId,
          lineRole: l.lineRole ?? 'main',
          direction: l.direction,
          packagingUnitId: l.packagingUnitId ?? null,
          packageQty: l.packageQty?.toFixed(2) ?? null,
          qtyTon: l.qtyTon.toFixed(3),
        },
      });
      const change = l.direction === 'in' ? l.qtyTon : l.qtyTon.neg();
      await this.ledgerRow(
        tx,
        trxId,
        item.id,
        locationId,
        l.productId,
        change,
        balances,
      );
    }
  }

  private async ledgerRow(
    tx: Tx,
    trxId: bigint,
    itemId: bigint,
    locationId: number,
    productId: number,
    change: Decimal,
    balances: Map<number, Decimal>,
  ) {
    const after = (balances.get(productId) ?? dec(0)).plus(change);
    balances.set(productId, after);
    await tx.stockLedger.create({
      data: {
        transactionId: trxId,
        itemId,
        locationId,
        productId,
        qtyChangeTon: change.toFixed(3),
        balanceAfterTon: after.toFixed(3),
      },
    });
    await tx.$executeRaw`
      UPDATE stock_balances SET qty_ton = qty_ton + ${change.toFixed(3)}
      WHERE location_id = ${locationId} AND product_id = ${productId}`;
  }
}

const INPUT_TYPES = [
  'IN_RAW',
  'IN_PRODUCTION',
  'IN_SUPPLIER',
  'OUT_SALE',
  'ADJUSTMENT',
] as const;

function snapshot(t: TrxWithRelations) {
  return {
    partner_name: t.partnerName,
    plate_number: t.plateNumber,
    driver_name: t.driverName,
    gross_ton: t.grossTon,
    tare_ton: t.tareTon,
    net_ton: t.netTon,
    trx_at: t.trxAt,
    notes: t.notes,
    manual_doc_no: t.manualDocNo,
    items: t.items
      .filter((i) => !i.supersededAt)
      .map((i) => ({
        product_id: i.productId,
        qty_ton: i.qtyTon,
        direction: i.direction,
      })),
  };
}
