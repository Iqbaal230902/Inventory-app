import Decimal from 'decimal.js';
import { Prisma } from '@prisma/client';

export { Decimal };

/** Parse angka tonase dari string/angka; koma desimal dinormalisasi ke titik. */
export function dec(
  v: Decimal.Value | Prisma.Decimal | null | undefined,
): Decimal {
  if (v === null || v === undefined || v === '') return new Decimal(0);
  if (typeof v === 'string') return new Decimal(v.trim().replace(',', '.'));
  return new Decimal(v.toString());
}

/** Format tonase 3 desimal sebagai string (dipakai di JSON). */
export function ton(
  v: Decimal.Value | Prisma.Decimal | null | undefined,
): string | null {
  if (v === null || v === undefined) return null;
  return dec(v).toFixed(3);
}

/** Format Indonesia untuk pesan error: 12,500 */
export function tonId(v: Decimal.Value | Prisma.Decimal): string {
  const [i, f] = dec(v).toFixed(3).split('.');
  return `${i.replace(/\B(?=(\d{3})+(?!\d))/g, '.')},${f}`;
}
