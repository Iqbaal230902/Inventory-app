/**
 * Rekonsiliasi saldo cache vs ledger (PRD 8). Jadwalkan harian via cron:
 *   0 1 * * *  cd /srv/backend && npm run db:reconcile >> /var/log/silika-reconcile.log 2>&1
 * Exit code 1 jika ada selisih (hubungkan ke alert ke Owner).
 */
import { PrismaClient } from '@prisma/client';

export const RECONCILE_SQL = `
SELECT b.location_id, b.product_id, b.qty_ton AS saldo_cache,
       COALESCE(SUM(l.qty_change_ton), 0) AS saldo_ledger
FROM stock_balances b
LEFT JOIN stock_ledger l ON l.location_id = b.location_id AND l.product_id = b.product_id
GROUP BY b.location_id, b.product_id, b.qty_ton
HAVING saldo_cache <> saldo_ledger`;

async function main() {
  const prisma = new PrismaClient();
  const rows = await prisma.$queryRawUnsafe<any[]>(RECONCILE_SQL);
  await prisma.$disconnect();
  if (rows.length) {
    console.error(
      `[${new Date().toISOString()}] SELISIH SALDO DITEMUKAN:`,
      rows,
    );
    process.exit(1);
  }
  console.log(
    `[${new Date().toISOString()}] Rekonsiliasi OK — saldo cache = ledger.`,
  );
}
void main();
