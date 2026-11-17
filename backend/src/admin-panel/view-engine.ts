import { NestExpressApplication } from '@nestjs/platform-express';
import cookieParser from 'cookie-parser';
import { existsSync } from 'fs';
import hbs from 'hbs';
import { join, resolve } from 'path';
import { qtyId, tonId } from '../common/decimal';
import { zonedParts } from '../common/time';

/** Folder template: backend/views/admin-panel (berlaku untuk src/ maupun dist/src/). */
export function adminViewsDir() {
  const candidates = [
    resolve(process.cwd(), 'views/admin-panel'),
    resolve(__dirname, '../../views/admin-panel'),
    resolve(__dirname, '../../../views/admin-panel'),
  ];
  return (
    candidates.find((p) => existsSync(join(p, 'layout.hbs'))) ?? candidates[0]
  );
}

/** Nilai primitif / Decimal / Date → string; objek lain → ''. */
export function str(v: unknown): string {
  if (v === null || v === undefined) return '';
  if (typeof v === 'string') return v;
  if (typeof v === 'number' || typeof v === 'boolean' || typeof v === 'bigint')
    return String(v);
  if (v instanceof Date) return v.toISOString();
  if (typeof (v as { toFixed?: unknown }).toFixed === 'function')
    return (v as { toString(): string }).toString(); // Decimal
  return '';
}

export const TRX_TYPE_LABEL: Record<string, string> = {
  IN_RAW: 'Bahan Baku Masuk',
  IN_PRODUCTION: 'Masuk – Produksi',
  IN_SUPPLIER: 'Masuk – Supplier',
  OUT_SALE: 'Barang Keluar',
  ADJUSTMENT: 'Penyesuaian',
  PRODUCTION: 'Produksi',
  TRANSFER_OUT: 'Transfer Keluar',
  TRANSFER_IN: 'Transfer Masuk',
  SHRINKAGE: 'Penyusutan',
  VOID: 'Pembatalan (VOID)',
};

export const STATUS_LABEL: Record<string, string> = {
  posted: 'Tercatat',
  in_transit: 'Dalam perjalanan',
  void: 'Dibatalkan',
  pending_approval: 'Menunggu persetujuan',
};

export const ROLE_LABEL: Record<string, string> = {
  owner: 'Owner',
  admin: 'Admin',
  operator: 'Operator',
  viewer: 'Viewer / Akuntan',
};

export const ACTION_LABEL: Record<string, string> = {
  login: 'Login',
  login_failed: 'Login gagal',
  create: 'Buat',
  update: 'Ubah',
  deactivate: 'Nonaktifkan',
  void: 'Void',
  void_request: 'Ajukan void',
  approve: 'Setujui',
  print: 'Cetak',
  photo: 'Foto',
  unlock: 'Buka kunci akun',
  edit: 'Edit',
};

/** "16/11/2026 18:05" di zona waktu tertentu (default WIB). */
export function fmtDateTime(v: unknown, tz = 'Asia/Jakarta') {
  if (!v) return '';
  const d = v instanceof Date ? v : new Date(str(v));
  if (Number.isNaN(d.getTime())) return '';
  const p = zonedParts(d, tz);
  return `${p.day}/${p.month}/${p.year} ${p.hour}:${p.minute}`;
}

/** "2026-11-16" (untuk input type=date) di zona waktu tertentu. */
export function ymd(d: Date, tz = 'Asia/Jakarta') {
  const p = zonedParts(d, tz);
  return `${p.year}-${p.month}-${p.day}`;
}

export function configureAdminViews(app: NestExpressApplication) {
  app.use(cookieParser());
  app.setBaseViewsDir(adminViewsDir());
  app.setViewEngine('hbs');
  app.set('view options', { layout: 'layout' });
  hbs.registerPartials(join(adminViewsDir(), 'partials'));

  const h = hbs.registerHelper.bind(hbs);
  h('eq', (a: unknown, b: unknown) => String(a) === String(b));
  h('ne', (a: unknown, b: unknown) => String(a) !== String(b));
  h('or', (...args: unknown[]) => args.slice(0, -1).some(Boolean));
  h('and', (...args: unknown[]) => args.slice(0, -1).every(Boolean));
  h('not', (a: unknown) => !a);
  h('gt0', (a: unknown) => Number(a) > 0);
  h('ton', (v: unknown) =>
    v === null || v === undefined || v === '' ? '–' : tonId(str(v)),
  );
  // Jumlah sesuai satuan produk: ton → "12,500", rit → "3 Rit".
  h('qty', (v: unknown, unit?: unknown) =>
    v === null || v === undefined || v === ''
      ? '–'
      : unit === 'rit'
        ? qtyId(str(v), 'rit')
        : tonId(str(v)),
  );
  // Total transaksi (JSON serializeTrx): "15,900 Ton", "3 Rit", atau keduanya.
  h('trxQty', (t: { total_ton?: string; total_rit?: string }) => {
    const parts: string[] = [];
    const rit = Number(t?.total_rit ?? 0);
    if (Number(t?.total_ton ?? 0) !== 0 || !rit)
      parts.push(qtyId(t?.total_ton ?? '0', 'ton'));
    if (rit) parts.push(qtyId(t.total_rit!, 'rit'));
    return parts.join(' + ');
  });
  h('dt', (v: unknown, tz?: unknown) =>
    fmtDateTime(v, typeof tz === 'string' ? tz : undefined),
  );
  h('trxTypeLabel', (v: string) => TRX_TYPE_LABEL[v] ?? v);
  h('statusLabel', (v: string) => STATUS_LABEL[v] ?? v);
  h('roleLabel', (v: string) => ROLE_LABEL[v] ?? v);
  h('actionLabel', (v: string) => ACTION_LABEL[v] ?? v);
  h('json', (v: unknown) =>
    v === null || v === undefined ? '' : JSON.stringify(v, null, 2),
  );
  h('sel', (a: unknown, b: unknown) =>
    String(a) === String(b) ? 'selected' : '',
  );
  h('chk', (v: unknown) => (v ? 'checked' : ''));
  h(
    'includes',
    (list: unknown, v: unknown) =>
      Array.isArray(list) && list.map(String).includes(String(v)),
  );
}
