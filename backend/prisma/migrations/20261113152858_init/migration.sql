-- CreateTable
CREATE TABLE `locations` (
    `id` INTEGER UNSIGNED NOT NULL AUTO_INCREMENT,
    `code` VARCHAR(10) NOT NULL,
    `name` VARCHAR(100) NOT NULL,
    `type` ENUM('tambang', 'pabrik', 'gudang', 'stockpile') NOT NULL,
    `address` VARCHAR(255) NULL,
    `timezone` VARCHAR(40) NOT NULL DEFAULT 'Asia/Jakarta',
    `is_active` BOOLEAN NOT NULL DEFAULT true,
    `created_at` DATETIME(0) NOT NULL DEFAULT CURRENT_TIMESTAMP(0),
    `updated_at` DATETIME(0) NOT NULL DEFAULT CURRENT_TIMESTAMP(0),

    UNIQUE INDEX `locations_code_key`(`code`),
    PRIMARY KEY (`id`)
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- CreateTable
CREATE TABLE `users` (
    `id` INTEGER UNSIGNED NOT NULL AUTO_INCREMENT,
    `name` VARCHAR(100) NOT NULL,
    `username` VARCHAR(50) NOT NULL,
    `email` VARCHAR(120) NULL,
    `password_hash` VARCHAR(255) NOT NULL,
    `role` ENUM('owner', 'admin', 'operator', 'viewer') NOT NULL,
    `is_active` BOOLEAN NOT NULL DEFAULT true,
    `failed_login_count` SMALLINT UNSIGNED NOT NULL DEFAULT 0,
    `locked_until` DATETIME(0) NULL,
    `last_login_at` DATETIME(0) NULL,
    `created_at` DATETIME(0) NOT NULL DEFAULT CURRENT_TIMESTAMP(0),
    `updated_at` DATETIME(0) NOT NULL DEFAULT CURRENT_TIMESTAMP(0),

    UNIQUE INDEX `users_username_key`(`username`),
    UNIQUE INDEX `users_email_key`(`email`),
    PRIMARY KEY (`id`)
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- CreateTable
CREATE TABLE `user_locations` (
    `user_id` INTEGER UNSIGNED NOT NULL,
    `location_id` INTEGER UNSIGNED NOT NULL,

    PRIMARY KEY (`user_id`, `location_id`)
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- CreateTable
CREATE TABLE `refresh_tokens` (
    `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    `user_id` INTEGER UNSIGNED NOT NULL,
    `token_hash` CHAR(64) NOT NULL,
    `device_id` VARCHAR(64) NULL,
    `expires_at` DATETIME(0) NOT NULL,
    `revoked_at` DATETIME(0) NULL,
    `created_at` DATETIME(0) NOT NULL DEFAULT CURRENT_TIMESTAMP(0),

    UNIQUE INDEX `refresh_tokens_token_hash_key`(`token_hash`),
    INDEX `refresh_tokens_user_id_idx`(`user_id`),
    PRIMARY KEY (`id`)
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- CreateTable
CREATE TABLE `products` (
    `id` INTEGER UNSIGNED NOT NULL AUTO_INCREMENT,
    `code` VARCHAR(20) NOT NULL,
    `name` VARCHAR(100) NOT NULL,
    `mesh_size` VARCHAR(20) NULL,
    `category` ENUM('raw', 'finished', 'byproduct') NOT NULL,
    `density_ton_m3` DECIMAL(6, 3) NULL DEFAULT 1.600,
    `sort_order` SMALLINT NOT NULL DEFAULT 0,
    `is_active` BOOLEAN NOT NULL DEFAULT true,
    `created_at` DATETIME(0) NOT NULL DEFAULT CURRENT_TIMESTAMP(0),
    `updated_at` DATETIME(0) NOT NULL DEFAULT CURRENT_TIMESTAMP(0),

    UNIQUE INDEX `products_code_key`(`code`),
    PRIMARY KEY (`id`)
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- CreateTable
CREATE TABLE `packaging_units` (
    `id` INTEGER UNSIGNED NOT NULL AUTO_INCREMENT,
    `name` VARCHAR(50) NOT NULL,
    `ton_per_unit` DECIMAL(10, 3) NOT NULL,
    `is_bulk` BOOLEAN NOT NULL DEFAULT false,
    `is_active` BOOLEAN NOT NULL DEFAULT true,
    `updated_at` DATETIME(0) NOT NULL DEFAULT CURRENT_TIMESTAMP(0),

    PRIMARY KEY (`id`)
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- CreateTable
CREATE TABLE `partners` (
    `id` INTEGER UNSIGNED NOT NULL AUTO_INCREMENT,
    `type` ENUM('customer', 'supplier', 'both') NOT NULL,
    `name` VARCHAR(150) NOT NULL,
    `phone` VARCHAR(30) NULL,
    `address` VARCHAR(255) NULL,
    `is_active` BOOLEAN NOT NULL DEFAULT true,
    `created_at` DATETIME(0) NOT NULL DEFAULT CURRENT_TIMESTAMP(0),
    `updated_at` DATETIME(0) NOT NULL DEFAULT CURRENT_TIMESTAMP(0),

    PRIMARY KEY (`id`)
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- CreateTable
CREATE TABLE `vehicles` (
    `id` INTEGER UNSIGNED NOT NULL AUTO_INCREMENT,
    `plate_number` VARCHAR(15) NOT NULL,
    `default_driver` VARCHAR(100) NULL,
    `standard_tare_ton` DECIMAL(10, 3) NULL,
    `is_active` BOOLEAN NOT NULL DEFAULT true,
    `updated_at` DATETIME(0) NOT NULL DEFAULT CURRENT_TIMESTAMP(0),

    UNIQUE INDEX `vehicles_plate_number_key`(`plate_number`),
    PRIMARY KEY (`id`)
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- CreateTable
CREATE TABLE `stock_min_levels` (
    `location_id` INTEGER UNSIGNED NOT NULL,
    `product_id` INTEGER UNSIGNED NOT NULL,
    `min_ton` DECIMAL(14, 3) NOT NULL DEFAULT 0,
    `updated_at` DATETIME(0) NOT NULL DEFAULT CURRENT_TIMESTAMP(0),

    PRIMARY KEY (`location_id`, `product_id`)
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- CreateTable
CREATE TABLE `transactions` (
    `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    `client_uuid` CHAR(36) NOT NULL,
    `doc_no` VARCHAR(40) NULL,
    `manual_doc_no` VARCHAR(40) NULL,
    `trx_type` ENUM('IN_PRODUCTION', 'IN_SUPPLIER', 'OUT_SALE', 'ADJUSTMENT', 'PRODUCTION', 'TRANSFER_OUT', 'TRANSFER_IN', 'SHRINKAGE', 'VOID') NOT NULL,
    `location_id` INTEGER UNSIGNED NOT NULL,
    `dest_location_id` INTEGER UNSIGNED NULL,
    `ref_transaction_id` BIGINT UNSIGNED NULL,
    `partner_id` INTEGER UNSIGNED NULL,
    `vehicle_id` INTEGER UNSIGNED NULL,
    `plate_number` VARCHAR(15) NULL,
    `driver_name` VARCHAR(100) NULL,
    `gross_ton` DECIMAL(14, 3) NULL,
    `tare_ton` DECIMAL(14, 3) NULL,
    `net_ton` DECIMAL(14, 3) NULL,
    `trx_at` DATETIME(0) NOT NULL,
    `status` ENUM('posted', 'in_transit', 'void', 'pending_approval') NOT NULL DEFAULT 'posted',
    `is_locked` BOOLEAN NOT NULL DEFAULT false,
    `notes` VARCHAR(500) NULL,
    `photo_path` VARCHAR(255) NULL,
    `void_reason` VARCHAR(255) NULL,
    `review_note` VARCHAR(255) NULL,
    `verify_token` CHAR(32) NOT NULL,
    `print_count` SMALLINT UNSIGNED NOT NULL DEFAULT 0,
    `created_by` INTEGER UNSIGNED NOT NULL,
    `voided_by` INTEGER UNSIGNED NULL,
    `device_id` VARCHAR(64) NULL,
    `client_created_at` DATETIME(0) NOT NULL,
    `created_at` DATETIME(0) NOT NULL DEFAULT CURRENT_TIMESTAMP(0),
    `updated_at` DATETIME(0) NOT NULL DEFAULT CURRENT_TIMESTAMP(0),

    UNIQUE INDEX `transactions_client_uuid_key`(`client_uuid`),
    UNIQUE INDEX `transactions_doc_no_key`(`doc_no`),
    UNIQUE INDEX `transactions_verify_token_key`(`verify_token`),
    INDEX `idx_trx_loc_date`(`location_id`, `trx_at`),
    INDEX `idx_trx_type_date`(`trx_type`, `trx_at`),
    INDEX `idx_trx_plate`(`plate_number`, `trx_at`),
    PRIMARY KEY (`id`)
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- CreateTable
CREATE TABLE `transaction_items` (
    `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    `transaction_id` BIGINT UNSIGNED NOT NULL,
    `product_id` INTEGER UNSIGNED NULL,
    `line_role` ENUM('main', 'input', 'output', 'loss') NOT NULL DEFAULT 'main',
    `direction` ENUM('in', 'out') NOT NULL,
    `packaging_unit_id` INTEGER UNSIGNED NULL,
    `package_qty` DECIMAL(12, 2) NULL,
    `qty_ton` DECIMAL(14, 3) NOT NULL,

    PRIMARY KEY (`id`)
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- CreateTable
CREATE TABLE `stock_ledger` (
    `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    `transaction_id` BIGINT UNSIGNED NOT NULL,
    `item_id` BIGINT UNSIGNED NOT NULL,
    `location_id` INTEGER UNSIGNED NOT NULL,
    `product_id` INTEGER UNSIGNED NOT NULL,
    `qty_change_ton` DECIMAL(14, 3) NOT NULL,
    `balance_after_ton` DECIMAL(14, 3) NOT NULL,
    `posted_at` DATETIME(0) NOT NULL DEFAULT CURRENT_TIMESTAMP(0),

    INDEX `idx_ledger_loc_prod_date`(`location_id`, `product_id`, `posted_at`),
    PRIMARY KEY (`id`)
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- CreateTable
CREATE TABLE `stock_balances` (
    `location_id` INTEGER UNSIGNED NOT NULL,
    `product_id` INTEGER UNSIGNED NOT NULL,
    `qty_ton` DECIMAL(14, 3) NOT NULL DEFAULT 0,
    `in_transit_ton` DECIMAL(14, 3) NOT NULL DEFAULT 0,
    `updated_at` DATETIME(0) NOT NULL DEFAULT CURRENT_TIMESTAMP(0),

    PRIMARY KEY (`location_id`, `product_id`)
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- CreateTable
CREATE TABLE `stock_opnames` (
    `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    `doc_no` VARCHAR(40) NOT NULL,
    `location_id` INTEGER UNSIGNED NOT NULL,
    `opname_at` DATETIME(0) NOT NULL,
    `status` ENUM('draft', 'submitted', 'approved', 'rejected') NOT NULL DEFAULT 'draft',
    `created_by` INTEGER UNSIGNED NOT NULL,
    `approved_by` INTEGER UNSIGNED NULL,
    `approved_at` DATETIME(0) NULL,
    `result_transaction_id` BIGINT UNSIGNED NULL,
    `notes` VARCHAR(500) NULL,

    UNIQUE INDEX `stock_opnames_doc_no_key`(`doc_no`),
    PRIMARY KEY (`id`)
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- CreateTable
CREATE TABLE `stock_opname_items` (
    `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    `opname_id` BIGINT UNSIGNED NOT NULL,
    `product_id` INTEGER UNSIGNED NOT NULL,
    `system_ton` DECIMAL(14, 3) NOT NULL,
    `physical_ton` DECIMAL(14, 3) NOT NULL,
    `diff_ton` DECIMAL(14, 3) NOT NULL,
    `reason` ENUM('susut_angin', 'hujan_erosi', 'kadar_air', 'kesalahan_timbang', 'lainnya') NULL,
    `volume_m3` DECIMAL(12, 3) NULL,

    PRIMARY KEY (`id`)
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- CreateTable
CREATE TABLE `doc_sequences` (
    `prefix` VARCHAR(5) NOT NULL,
    `location_id` INTEGER UNSIGNED NOT NULL,
    `period` CHAR(6) NOT NULL,
    `last_no` INTEGER UNSIGNED NOT NULL DEFAULT 0,

    PRIMARY KEY (`prefix`, `location_id`, `period`)
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- CreateTable
CREATE TABLE `audit_logs` (
    `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    `user_id` INTEGER UNSIGNED NULL,
    `action` VARCHAR(40) NOT NULL,
    `entity` VARCHAR(40) NOT NULL,
    `entity_id` BIGINT UNSIGNED NULL,
    `old_values` JSON NULL,
    `new_values` JSON NULL,
    `ip_address` VARCHAR(45) NULL,
    `device_id` VARCHAR(64) NULL,
    `created_at` DATETIME(0) NOT NULL DEFAULT CURRENT_TIMESTAMP(0),

    INDEX `idx_audit_entity`(`entity`, `entity_id`),
    INDEX `idx_audit_user_date`(`user_id`, `created_at`),
    PRIMARY KEY (`id`)
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- CreateTable
CREATE TABLE `devices` (
    `id` VARCHAR(64) NOT NULL,
    `user_id` INTEGER UNSIGNED NOT NULL,
    `fcm_token` VARCHAR(255) NULL,
    `app_version` VARCHAR(20) NULL,
    `last_sync_at` DATETIME(0) NULL,

    PRIMARY KEY (`id`)
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- CreateTable
CREATE TABLE `app_settings` (
    `setting_key` VARCHAR(60) NOT NULL,
    `setting_value` TEXT NULL,
    `updated_at` DATETIME(0) NOT NULL DEFAULT CURRENT_TIMESTAMP(0),

    PRIMARY KEY (`setting_key`)
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- AddForeignKey
ALTER TABLE `user_locations` ADD CONSTRAINT `user_locations_user_id_fkey` FOREIGN KEY (`user_id`) REFERENCES `users`(`id`) ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `user_locations` ADD CONSTRAINT `user_locations_location_id_fkey` FOREIGN KEY (`location_id`) REFERENCES `locations`(`id`) ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `refresh_tokens` ADD CONSTRAINT `refresh_tokens_user_id_fkey` FOREIGN KEY (`user_id`) REFERENCES `users`(`id`) ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `stock_min_levels` ADD CONSTRAINT `stock_min_levels_location_id_fkey` FOREIGN KEY (`location_id`) REFERENCES `locations`(`id`) ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `stock_min_levels` ADD CONSTRAINT `stock_min_levels_product_id_fkey` FOREIGN KEY (`product_id`) REFERENCES `products`(`id`) ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `transactions` ADD CONSTRAINT `transactions_location_id_fkey` FOREIGN KEY (`location_id`) REFERENCES `locations`(`id`) ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `transactions` ADD CONSTRAINT `transactions_dest_location_id_fkey` FOREIGN KEY (`dest_location_id`) REFERENCES `locations`(`id`) ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `transactions` ADD CONSTRAINT `transactions_partner_id_fkey` FOREIGN KEY (`partner_id`) REFERENCES `partners`(`id`) ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `transactions` ADD CONSTRAINT `transactions_vehicle_id_fkey` FOREIGN KEY (`vehicle_id`) REFERENCES `vehicles`(`id`) ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `transactions` ADD CONSTRAINT `transactions_created_by_fkey` FOREIGN KEY (`created_by`) REFERENCES `users`(`id`) ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `transactions` ADD CONSTRAINT `transactions_voided_by_fkey` FOREIGN KEY (`voided_by`) REFERENCES `users`(`id`) ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `transactions` ADD CONSTRAINT `transactions_ref_transaction_id_fkey` FOREIGN KEY (`ref_transaction_id`) REFERENCES `transactions`(`id`) ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `transaction_items` ADD CONSTRAINT `transaction_items_transaction_id_fkey` FOREIGN KEY (`transaction_id`) REFERENCES `transactions`(`id`) ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `transaction_items` ADD CONSTRAINT `transaction_items_product_id_fkey` FOREIGN KEY (`product_id`) REFERENCES `products`(`id`) ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `transaction_items` ADD CONSTRAINT `transaction_items_packaging_unit_id_fkey` FOREIGN KEY (`packaging_unit_id`) REFERENCES `packaging_units`(`id`) ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `stock_ledger` ADD CONSTRAINT `stock_ledger_transaction_id_fkey` FOREIGN KEY (`transaction_id`) REFERENCES `transactions`(`id`) ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `stock_ledger` ADD CONSTRAINT `stock_ledger_item_id_fkey` FOREIGN KEY (`item_id`) REFERENCES `transaction_items`(`id`) ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `stock_balances` ADD CONSTRAINT `stock_balances_location_id_fkey` FOREIGN KEY (`location_id`) REFERENCES `locations`(`id`) ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `stock_balances` ADD CONSTRAINT `stock_balances_product_id_fkey` FOREIGN KEY (`product_id`) REFERENCES `products`(`id`) ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `stock_opnames` ADD CONSTRAINT `stock_opnames_location_id_fkey` FOREIGN KEY (`location_id`) REFERENCES `locations`(`id`) ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `stock_opname_items` ADD CONSTRAINT `stock_opname_items_opname_id_fkey` FOREIGN KEY (`opname_id`) REFERENCES `stock_opnames`(`id`) ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `stock_opname_items` ADD CONSTRAINT `stock_opname_items_product_id_fkey` FOREIGN KEY (`product_id`) REFERENCES `products`(`id`) ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `devices` ADD CONSTRAINT `devices_user_id_fkey` FOREIGN KEY (`user_id`) REFERENCES `users`(`id`) ON DELETE RESTRICT ON UPDATE CASCADE;
