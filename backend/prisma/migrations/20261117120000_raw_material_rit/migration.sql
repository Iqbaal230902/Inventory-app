-- Bahan baku mentah per rit (1 rit = 1 truk, dihitung jumlah truknya saja, tanpa tonase):
-- satuan stok produk + jenis transaksi IN_RAW (Bahan Baku Masuk).

-- AlterTable
ALTER TABLE `products` ADD COLUMN `unit` ENUM('ton', 'rit') NOT NULL DEFAULT 'ton';

-- AlterTable
ALTER TABLE `transactions` MODIFY `trx_type` ENUM('IN_RAW', 'IN_PRODUCTION', 'IN_SUPPLIER', 'OUT_SALE', 'ADJUSTMENT', 'PRODUCTION', 'TRANSFER_OUT', 'TRANSFER_IN', 'SHRINKAGE', 'VOID') NOT NULL;

-- Data awal: produk bahan baku mentah (stok dalam rit).
-- Kode BBM (bukan RAW): produk lama 'RAW' (Pasir Silika Mentah, ton, nonaktif) punya
-- riwayat ledger dalam ton sehingga tidak boleh diubah satuannya.
INSERT IGNORE INTO `products` (`code`, `name`, `mesh_size`, `category`, `unit`, `sort_order`, `is_active`)
VALUES ('BBM', 'Bahan Baku Mentah', NULL, 'raw', 'rit', 0, true);
