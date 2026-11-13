import 'dart:convert';

import 'package:decimal/decimal.dart';
import 'package:drift/drift.dart';

import '../../core/format.dart';
import '../local/database.dart';
import '../models.dart';

/// Antrian transaksi lokal (offline-first). Semua input transaksi masuk ke sini
/// terlebih dahulu, lalu dikirim oleh SyncEngine.
class TrxRepo {
  TrxRepo(this.db);
  final AppDatabase db;

  Future<LocalTransaction> enqueue({
    required Map<String, dynamic> payload,
    required Map<String, dynamic> view,
    required String tmpDocNo,
    required int userId,
    String? photoPath,
  }) async {
    final row = LocalTransactionsCompanion.insert(
      clientUuid: payload['client_uuid'] as String,
      payload: jsonEncode(payload),
      trxType: payload['trx_type'] as String,
      locationId: payload['location_id'] as int,
      tmpDocNo: tmpDocNo,
      serverJson: Value(jsonEncode(view)),
      clientCreatedAt: DateTime.parse(payload['client_created_at'] as String),
      trxAt: DateTime.parse(payload['trx_at'] as String),
      photoPath: Value(photoPath),
      createdBy: userId,
    );
    await db.into(db.localTransactions).insert(row);
    return (await get(payload['client_uuid'] as String))!;
  }

  /// Perbaiki transaksi yang ditolak/pending lalu antrikan ulang (UUID tetap sama).
  Future<void> replacePending({
    required String clientUuid,
    required Map<String, dynamic> payload,
    required Map<String, dynamic> view,
    String? photoPath,
  }) =>
      (db.update(db.localTransactions)..where((t) => t.clientUuid.equals(clientUuid))).write(
        LocalTransactionsCompanion(
          payload: Value(jsonEncode(payload)),
          serverJson: Value(jsonEncode(view)),
          trxAt: Value(DateTime.parse(payload['trx_at'] as String)),
          syncState: const Value(SyncState.pending),
          errorCode: const Value(null),
          errorMessage: const Value(null),
          photoPath: Value(photoPath),
          photoUploaded: const Value(false),
        ),
      );

  Future<LocalTransaction?> get(String uuid) =>
      (db.select(db.localTransactions)..where((t) => t.clientUuid.equals(uuid))).getSingleOrNull();

  Stream<LocalTransaction?> watch(String uuid) =>
      (db.select(db.localTransactions)..where((t) => t.clientUuid.equals(uuid))).watchSingleOrNull();

  /// Hanya transaksi milik user yang sedang login yang dikirim (atribusi penginput tetap benar).
  Future<List<LocalTransaction>> pendingBatch(int limit, {required int userId}) => (db.select(db.localTransactions)
        ..where((t) => t.syncState.equals(SyncState.pending) & t.createdBy.equals(userId))
        ..orderBy([(t) => OrderingTerm(expression: t.clientCreatedAt)])
        ..limit(limit))
      .get();

  Stream<List<LocalTransaction>> watchUnsynced() => (db.select(db.localTransactions)
        ..where((t) => t.syncState.isIn([SyncState.pending, SyncState.rejected]))
        ..orderBy([(t) => OrderingTerm(expression: t.clientCreatedAt, mode: OrderingMode.desc)]))
      .watch();

  /// Transaksi yang dibuat perangkat ini (untuk riwayat saat offline).
  Stream<List<LocalTransaction>> watchRecent({int limit = 200}) => (db.select(db.localTransactions)
        ..orderBy([(t) => OrderingTerm(expression: t.trxAt, mode: OrderingMode.desc)])
        ..limit(limit))
      .watch();

  Stream<List<LocalTransaction>> watchAll() => db.select(db.localTransactions).watch();

  Future<void> markSynced(String uuid, Map<String, dynamic> serverTrx) async {
    final row = await get(uuid);
    // Pertahankan view lokal tapi gunakan data resmi server.
    await (db.update(db.localTransactions)..where((t) => t.clientUuid.equals(uuid))).write(
      LocalTransactionsCompanion(
        syncState: const Value(SyncState.synced),
        docNo: Value(serverTrx['doc_no'] as String?),
        serverId: Value(serverTrx['id'] as int?),
        serverStatus: Value(serverTrx['status'] as String?),
        serverJson: Value(jsonEncode(serverTrx)),
        syncedAt: Value(DateTime.now().toUtc()),
        errorCode: const Value(null),
        errorMessage: const Value(null),
        attempts: Value((row?.attempts ?? 0) + 1),
      ),
    );
  }

  Future<void> markRejected(String uuid, String code, String message) async {
    final row = await get(uuid);
    await (db.update(db.localTransactions)..where((t) => t.clientUuid.equals(uuid))).write(
      LocalTransactionsCompanion(
        syncState: const Value(SyncState.rejected),
        errorCode: Value(code),
        errorMessage: Value(message),
        attempts: Value((row?.attempts ?? 0) + 1),
      ),
    );
  }

  Future<void> retry(String uuid) =>
      (db.update(db.localTransactions)..where((t) => t.clientUuid.equals(uuid)))
          .write(const LocalTransactionsCompanion(syncState: Value(SyncState.pending)));

  Future<void> recordPrint(String uuid, {required bool reported}) async {
    final row = await get(uuid);
    if (row == null) return;
    await (db.update(db.localTransactions)..where((t) => t.clientUuid.equals(uuid))).write(
      LocalTransactionsCompanion(
        printCount: Value(row.printCount + 1),
        unreportedPrints: Value(row.unreportedPrints + (reported ? 0 : 1)),
      ),
    );
  }

  /// Simpan/cache transaksi server agar cetak ulang tetap bisa offline.
  Future<void> cacheServerTrx(Map<String, dynamic> j, int userId) async {
    final uuid = j['client_uuid'] as String;
    final existing = await get(uuid);
    if (existing != null) {
      await (db.update(db.localTransactions)..where((t) => t.clientUuid.equals(uuid))).write(
        LocalTransactionsCompanion(
          serverJson: Value(jsonEncode(j)),
          serverStatus: Value(j['status'] as String?),
          docNo: Value(j['doc_no'] as String?),
          printCount: Value((j['print_count'] as int?) ?? existing.printCount),
        ),
      );
    }
  }

  TrxView view(LocalTransaction row) =>
      TrxView((jsonDecode(row.serverJson!) as Map).cast<String, dynamic>(), local: row);

  /// Efek stok dari transaksi lokal yang belum tercermin pada saldo server
  /// (pending, atau tersinkron setelah pull terakhir). Hasil: (lokasi, produk) → delta ton.
  static Map<(int, int), Decimal> effects(List<LocalTransaction> rows, DateTime? lastPullAt) {
    final out = <(int, int), Decimal>{};
    for (final r in rows) {
      final counts = r.syncState == SyncState.pending ||
          (r.syncState == SyncState.synced &&
              r.syncedAt != null &&
              (lastPullAt == null || r.syncedAt!.isAfter(lastPullAt)));
      if (!counts) continue;
      final p = (jsonDecode(r.payload) as Map).cast<String, dynamic>();
      final type = p['trx_type'] as String;
      for (final it in (p['items'] as List).cast<Map>()) {
        final qty = dec(it['qty_ton'] as String?);
        final dir = type == 'ADJUSTMENT' ? it['direction'] : (type == 'OUT_SALE' ? 'out' : 'in');
        final key = (r.locationId, it['product_id'] as int);
        out[key] = (out[key] ?? Decimal.zero) + (dir == 'out' ? -qty : qty);
      }
    }
    return out;
  }
}
