-- AlterTable
ALTER TABLE `transaction_items` ADD COLUMN `superseded_at` DATETIME(0) NULL;

-- AlterTable
ALTER TABLE `transactions` ADD COLUMN `partner_name` VARCHAR(150) NULL,
    ADD COLUMN `void_request_reason` VARCHAR(255) NULL,
    ADD COLUMN `void_requested_at` DATETIME(0) NULL,
    ADD COLUMN `void_requested_by` INTEGER UNSIGNED NULL;
