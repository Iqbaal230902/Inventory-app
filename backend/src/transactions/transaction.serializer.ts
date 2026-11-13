import { Prisma } from '@prisma/client';
import { ton } from '../common/decimal';

export const TRX_INCLUDE = {
  location: true,
  destLocation: true,
  partner: true,
  createdBy: { select: { id: true, name: true, username: true } },
  voidedBy: { select: { id: true, name: true } },
  items: {
    include: { product: true, packagingUnit: true },
    orderBy: { id: 'asc' },
  },
  refTrx: { select: { id: true, docNo: true, trxType: true } },
  referencedBy: { select: { id: true, docNo: true, trxType: true } },
} satisfies Prisma.TransactionInclude;

export type TrxWithRelations = Prisma.TransactionGetPayload<{
  include: typeof TRX_INCLUDE;
}>;

/** Bentuk JSON transaksi untuk API (snake_case, tonase string 3 desimal). */
export function serializeTrx(
  t: TrxWithRelations,
  extra: Record<string, unknown> = {},
) {
  return {
    id: Number(t.id),
    client_uuid: t.clientUuid,
    doc_no: t.docNo,
    manual_doc_no: t.manualDocNo,
    trx_type: t.trxType,
    status: t.status,
    location: {
      id: t.location.id,
      code: t.location.code,
      name: t.location.name,
      timezone: t.location.timezone,
    },
    dest_location: t.destLocation
      ? {
          id: t.destLocation.id,
          code: t.destLocation.code,
          name: t.destLocation.name,
        }
      : null,
    partner_id: t.partnerId,
    partner_name: t.partnerName,
    partner_phone: t.partner?.phone ?? null,
    partner_address: t.partner?.address ?? null,
    vehicle_id: t.vehicleId,
    plate_number: t.plateNumber,
    driver_name: t.driverName,
    gross_ton: ton(t.grossTon),
    tare_ton: ton(t.tareTon),
    net_ton: ton(t.netTon),
    total_ton: ton(
      t.items
        .filter((i) => !i.supersededAt)
        .reduce((s, i) => s.plus(i.qtyTon), new Prisma.Decimal(0)),
    ),
    trx_at: t.trxAt.toISOString(),
    notes: t.notes,
    has_photo: !!t.photoPath,
    void_reason: t.voidReason,
    void_requested: !!t.voidRequestedAt && t.status !== 'void',
    void_request_reason: t.voidRequestReason,
    review_note: t.reviewNote,
    print_count: t.printCount,
    verify_token: t.verifyToken,
    created_by: t.createdBy,
    voided_by: t.voidedBy,
    device_id: t.deviceId,
    client_created_at: t.clientCreatedAt.toISOString(),
    created_at: t.createdAt.toISOString(),
    updated_at: t.updatedAt.toISOString(),
    ref_transaction: t.refTrx ? { ...t.refTrx, id: Number(t.refTrx.id) } : null,
    void_transaction:
      t.referencedBy
        .filter((r) => r.trxType === 'VOID')
        .map((r) => ({ ...r, id: Number(r.id) }))[0] ?? null,
    items: t.items
      .filter((i) => !i.supersededAt)
      .map((i) => ({
        id: Number(i.id),
        product_id: i.productId,
        product_code: i.product?.code ?? null,
        product_name: i.product?.name ?? null,
        line_role: i.lineRole,
        direction: i.direction,
        packaging_unit_id: i.packagingUnitId,
        packaging_name: i.packagingUnit?.name ?? null,
        package_qty: i.packageQty?.toFixed(2) ?? null,
        qty_ton: ton(i.qtyTon),
      })),
    ...extra,
  };
}
