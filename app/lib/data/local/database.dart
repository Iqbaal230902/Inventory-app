import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

part 'database.g.dart';

// ===== Cache master data (dari /sync/pull) =====

class Products extends Table {
  IntColumn get id => integer()();
  TextColumn get code => text()();
  TextColumn get name => text()();
  TextColumn get meshSize => text().nullable()();
  TextColumn get category => text()();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
  @override
  Set<Column> get primaryKey => {id};
}

class Locations extends Table {
  IntColumn get id => integer()();
  TextColumn get code => text()();
  TextColumn get name => text()();
  TextColumn get type => text()();
  TextColumn get address => text().nullable()();
  TextColumn get timezone => text().withDefault(const Constant('Asia/Jakarta'))();
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
  @override
  Set<Column> get primaryKey => {id};
}

class PackagingUnits extends Table {
  IntColumn get id => integer()();
  TextColumn get name => text()();
  TextColumn get tonPerUnit => text()(); // desimal sebagai teks
  BoolColumn get isBulk => boolean().withDefault(const Constant(false))();
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
  @override
  Set<Column> get primaryKey => {id};
}

class Partners extends Table {
  IntColumn get id => integer()();
  TextColumn get type => text()();
  TextColumn get name => text()();
  TextColumn get phone => text().nullable()();
  TextColumn get address => text().nullable()();
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
  @override
  Set<Column> get primaryKey => {id};
}

class Vehicles extends Table {
  IntColumn get id => integer()();
  TextColumn get plateNumber => text()();
  TextColumn get defaultDriver => text().nullable()();
  TextColumn get standardTareTon => text().nullable()();
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
  @override
  Set<Column> get primaryKey => {id};
}

class MinLevels extends Table {
  IntColumn get locationId => integer()();
  IntColumn get productId => integer()();
  TextColumn get minTon => text()();
  @override
  Set<Column> get primaryKey => {locationId, productId};
}

/// Saldo resmi dari server (per waktu sinkron terakhir).
class Balances extends Table {
  IntColumn get locationId => integer()();
  IntColumn get productId => integer()();
  TextColumn get qtyTon => text()();
  TextColumn get inTransitTon => text().withDefault(const Constant('0'))();
  @override
  Set<Column> get primaryKey => {locationId, productId};
}

// ===== Antrian transaksi offline (pending_sync) =====

/// Status sinkron transaksi lokal.
abstract class SyncState {
  static const pending = 'pending';
  static const synced = 'synced';
  static const rejected = 'rejected';
}

class LocalTransactions extends Table {
  TextColumn get clientUuid => text()();
  /// Body request POST /transactions (JSON) — dikirim apa adanya saat sinkron.
  TextColumn get payload => text()();
  TextColumn get trxType => text()();
  IntColumn get locationId => integer()();
  TextColumn get tmpDocNo => text()();
  TextColumn get docNo => text().nullable()(); // nomor resmi dari server
  IntColumn get serverId => integer().nullable()();
  TextColumn get serverStatus => text().nullable()(); // posted / pending_approval / void
  /// JSON transaksi dari server setelah sinkron (untuk tampilan & cetak ulang offline).
  TextColumn get serverJson => text().nullable()();
  TextColumn get syncState => text().withDefault(const Constant(SyncState.pending))();
  TextColumn get errorCode => text().nullable()();
  TextColumn get errorMessage => text().nullable()();
  IntColumn get attempts => integer().withDefault(const Constant(0))();
  DateTimeColumn get clientCreatedAt => dateTime()();
  DateTimeColumn get trxAt => dateTime()();
  DateTimeColumn get syncedAt => dateTime().nullable()();
  TextColumn get photoPath => text().nullable()();
  BoolColumn get photoUploaded => boolean().withDefault(const Constant(false))();
  /// Jumlah cetak yang belum dilaporkan ke server (POST /print).
  IntColumn get unreportedPrints => integer().withDefault(const Constant(0))();
  IntColumn get printCount => integer().withDefault(const Constant(0))();
  IntColumn get createdBy => integer()();
  @override
  Set<Column> get primaryKey => {clientUuid};
}

class KeyValues extends Table {
  TextColumn get key => text()();
  TextColumn get value => text()();
  @override
  Set<Column> get primaryKey => {key};
}

@DriftDatabase(
  tables: [
    Products,
    Locations,
    PackagingUnits,
    Partners,
    Vehicles,
    MinLevels,
    Balances,
    LocalTransactions,
    KeyValues,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.e);

  @override
  int get schemaVersion => 1;

  // ---- key-value ----
  Future<String?> getKv(String key) async =>
      (await (select(keyValues)..where((t) => t.key.equals(key))).getSingleOrNull())?.value;

  Future<void> setKv(String key, String value) =>
      into(keyValues).insertOnConflictUpdate(KeyValuesCompanion.insert(key: key, value: value));

  Stream<String?> watchKv(String key) => (select(keyValues)..where((t) => t.key.equals(key)))
      .watchSingleOrNull()
      .map((r) => r?.value);

  Future<Map<String, dynamic>> getJson(String key) async {
    final v = await getKv(key);
    return v == null ? {} : (jsonDecode(v) as Map).cast<String, dynamic>();
  }

  /// Nomor urut lokal untuk nomor sementara TMP-{device}-{urutan}.
  Future<int> nextLocalSeq() => transaction(() async {
        final n = int.parse(await getKv('local_seq') ?? '0') + 1;
        await setKv('local_seq', '$n');
        return n;
      });

  // ---- transaksi lokal ----
  Stream<int> watchPendingCount() {
    final c = localTransactions.clientUuid.count();
    return (selectOnly(localTransactions)
          ..addColumns([c])
          ..where(localTransactions.syncState.isIn([SyncState.pending, SyncState.rejected])))
        .watchSingle()
        .map((r) => r.read(c) ?? 0);
  }

  /// Hapus seluruh cache (dipakai saat ganti user). Transaksi lokal TIDAK dihapus.
  Future<void> clearMasterCache() => transaction(() async {
        for (final t in <TableInfo>[products, locations, packagingUnits, partners, vehicles, minLevels, balances]) {
          await delete(t).go();
        }
      });
}

const _storage = FlutterSecureStorage();
const _dbKeyName = 'db_cipher_key';

/// Kunci enkripsi database dibuat acak sekali dan disimpan di Keystore.
Future<String> _dbKey() async {
  var key = await _storage.read(key: _dbKeyName);
  if (key == null) {
    final rnd = Random.secure();
    key = List.generate(32, (_) => rnd.nextInt(256).toRadixString(16).padLeft(2, '0')).join();
    await _storage.write(key: _dbKeyName, value: key);
  }
  return key;
}

Future<AppDatabase> openAppDatabase() async {
  final dir = await getApplicationDocumentsDirectory();
  final file = File(p.join(dir.path, 'silika.db.enc'));
  final key = await _dbKey();
  return AppDatabase(
    NativeDatabase.createInBackground(
      file,
      setup: (raw) {
        raw.execute("PRAGMA key = \"x'$key'\";");
        raw.execute('PRAGMA busy_timeout = 5000;');
        // Pastikan build SQLCipher aktif — gagal keras bila database tidak terenkripsi.
        final res = raw.select('PRAGMA cipher_version;');
        if (res.isEmpty) {
          throw StateError('SQLCipher tidak tersedia; database lokal tidak dapat dienkripsi.');
        }
      },
    ),
  );
}
