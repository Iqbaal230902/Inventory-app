-- Ledger bersifat append-only dan transaksi tidak boleh dihapus permanen (PRD 8).
CREATE TRIGGER trg_ledger_no_update BEFORE UPDATE ON stock_ledger
FOR EACH ROW SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'stock_ledger bersifat append-only';

CREATE TRIGGER trg_ledger_no_delete BEFORE DELETE ON stock_ledger
FOR EACH ROW SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'stock_ledger bersifat append-only';

CREATE TRIGGER trg_trx_no_delete BEFORE DELETE ON transactions
FOR EACH ROW SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Transaksi tidak boleh dihapus, gunakan void';
