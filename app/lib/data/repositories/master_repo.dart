import 'dart:convert';

import 'package:drift/drift.dart';

import '../local/database.dart';

/// Cache master data lokal, diperbarui dari GET /sync/pull (delta).
class MasterRepo {
  MasterRepo(this.db);
  final AppDatabase db;

  Future<void> applyPull(Map<String, dynamic> j) async {
    final full = j['full'] == true;
    List<Map<String, dynamic>> list(String k) =>
        ((j[k] as List?) ?? []).map((e) => (e as Map).cast<String, dynamic>()).toList();

    await db.transaction(() async {
      if (full) {
        for (final t in <TableInfo>[db.products, db.locations, db.packagingUnits, db.partners, db.vehicles, db.minLevels]) {
          await db.delete(t).go();
        }
      }
      await db.batch((b) {
        b.insertAllOnConflictUpdate(
          db.products,
          list('products').map((p) => ProductsCompanion.insert(
                id: Value(p['id'] as int),
                code: p['code'] as String,
                name: p['name'] as String,
                meshSize: Value(p['mesh_size'] as String?),
                category: p['category'] as String,
                unit: Value((p['unit'] as String?) ?? 'ton'),
                sortOrder: Value((p['sort_order'] as int?) ?? 0),
                isActive: Value(p['is_active'] != false),
              )),
        );
        b.insertAllOnConflictUpdate(
          db.locations,
          list('locations').map((l) => LocationsCompanion.insert(
                id: Value(l['id'] as int),
                code: l['code'] as String,
                name: l['name'] as String,
                type: l['type'] as String,
                address: Value(l['address'] as String?),
                timezone: Value((l['timezone'] as String?) ?? 'Asia/Jakarta'),
                isActive: Value(l['is_active'] != false),
              )),
        );
        b.insertAllOnConflictUpdate(
          db.packagingUnits,
          list('packaging_units').map((p) => PackagingUnitsCompanion.insert(
                id: Value(p['id'] as int),
                name: p['name'] as String,
                tonPerUnit: p['ton_per_unit'] as String,
                isBulk: Value(p['is_bulk'] == true),
                isActive: Value(p['is_active'] != false),
              )),
        );
        b.insertAllOnConflictUpdate(
          db.partners,
          list('partners').map((p) => PartnersCompanion.insert(
                id: Value(p['id'] as int),
                type: p['type'] as String,
                name: p['name'] as String,
                phone: Value(p['phone'] as String?),
                address: Value(p['address'] as String?),
                isActive: Value(p['is_active'] != false),
              )),
        );
        b.insertAllOnConflictUpdate(
          db.vehicles,
          list('vehicles').map((v) => VehiclesCompanion.insert(
                id: Value(v['id'] as int),
                plateNumber: v['plate_number'] as String,
                defaultDriver: Value(v['default_driver'] as String?),
                standardTareTon: Value(v['standard_tare_ton'] as String?),
                isActive: Value(v['is_active'] != false),
              )),
        );
        b.insertAllOnConflictUpdate(
          db.minLevels,
          list('min_levels').map((m) => MinLevelsCompanion.insert(
                locationId: m['location_id'] as int,
                productId: m['product_id'] as int,
                minTon: m['min_ton'] as String,
              )),
        );
      });
      // Saldo selalu dikirim penuh → ganti seluruhnya.
      await db.delete(db.balances).go();
      await db.batch((b) => b.insertAll(
            db.balances,
            list('balances').map((x) => BalancesCompanion.insert(
                  locationId: x['location_id'] as int,
                  productId: x['product_id'] as int,
                  qtyTon: x['qty_ton'] as String,
                  inTransitTon: Value((x['in_transit_ton'] as String?) ?? '0'),
                )),
          ));
      if (j['settings'] != null) await db.setKv('settings', jsonEncode(j['settings']));
      await db.setKv('last_pull_server_time', j['server_time'] as String);
      await db.setKv('last_pull_at', DateTime.now().toUtc().toIso8601String());
    });
  }

  Stream<List<Product>> watchProducts({bool activeOnly = true}) => (db.select(db.products)
        ..where((t) => activeOnly ? t.isActive.equals(true) : const Constant(true))
        ..orderBy([(t) => OrderingTerm(expression: t.sortOrder), (t) => OrderingTerm(expression: t.id)]))
      .watch();

  Stream<List<Location>> watchLocations() => (db.select(db.locations)
        ..where((t) => t.isActive.equals(true))
        ..orderBy([(t) => OrderingTerm(expression: t.code)]))
      .watch();

  Stream<List<PackagingUnit>> watchPackaging() =>
      (db.select(db.packagingUnits)..where((t) => t.isActive.equals(true))).watch();

  Stream<List<Partner>> watchPartners(String type) => (db.select(db.partners)
        ..where((t) => t.isActive.equals(true) & t.type.isIn([type, 'both']))
        ..orderBy([(t) => OrderingTerm(expression: t.name)]))
      .watch();

  Stream<List<Vehicle>> watchVehicles() => (db.select(db.vehicles)
        ..where((t) => t.isActive.equals(true))
        ..orderBy([(t) => OrderingTerm(expression: t.plateNumber)]))
      .watch();

  Stream<List<Balance>> watchBalances() => db.select(db.balances).watch();
  Stream<List<MinLevel>> watchMinLevels() => db.select(db.minLevels).watch();

  Future<Map<String, String>> settings() async =>
      (await db.getJson('settings')).map((k, v) => MapEntry(k, '$v'));
}
