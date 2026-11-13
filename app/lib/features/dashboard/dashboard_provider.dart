import 'package:decimal/decimal.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/format.dart';
import '../../core/providers.dart';
import '../../data/local/database.dart';
import '../../data/repositories/trx_repo.dart';

class StockRow {
  StockRow({
    required this.product,
    required this.qty,
    required this.official,
    required this.min,
    required this.status,
    required this.perLocation,
  });
  final Product product;
  final Decimal qty; // termasuk efek transaksi lokal yang belum tersinkron
  final Decimal official; // saldo resmi server terakhir
  final Decimal min;
  final String status;
  final Map<int, Decimal> perLocation;
  Decimal get localDelta => qty - official;
}

class DashboardData {
  DashboardData({required this.rows, required this.total, required this.alerts});
  final List<StockRow> rows;
  final Decimal total;
  final List<({String level, String location, String product, Decimal qty, Decimal min})> alerts;
}

/// Hijau aman, kuning ≤ 120% batas minimum, merah di bawah minimum (FR-02).
String stockStatus(Decimal qty, Decimal min) {
  if (qty < Decimal.zero) return 'critical';
  if (min <= Decimal.zero) return 'ok';
  if (qty < min) return 'critical';
  if (qty <= min * Decimal.parse('1.2')) return 'warning';
  return 'ok';
}

final _productsStream = StreamProvider((ref) => ref.watch(masterRepoProvider).watchProducts());
final _balancesStream = StreamProvider((ref) => ref.watch(masterRepoProvider).watchBalances());
final _minStream = StreamProvider((ref) => ref.watch(masterRepoProvider).watchMinLevels());
final locationsProvider = StreamProvider((ref) => ref.watch(masterRepoProvider).watchLocations());
final _localTrxStream = StreamProvider((ref) => ref.watch(trxRepoProvider).watchAll());

/// Dashboard dihitung dari cache lokal sehingga tetap berfungsi offline:
/// saldo resmi server + efek transaksi lokal yang belum tercermin di saldo server.
final dashboardProvider = Provider<AsyncValue<DashboardData>>((ref) {
  final products = ref.watch(_productsStream);
  final balances = ref.watch(_balancesStream);
  final mins = ref.watch(_minStream);
  final locs = ref.watch(locationsProvider);
  final local = ref.watch(_localTrxStream);
  final lastPull = ref.watch(lastPullAtProvider).value;
  final selected = ref.watch(selectedLocationProvider);

  for (final a in [products, balances, mins, locs, local]) {
    if (a.hasError) return AsyncValue.error(a.error!, a.stackTrace ?? StackTrace.current);
    if (!a.hasValue) return const AsyncValue.loading();
  }
  final locIds = locs.value!.map((l) => l.id).where((id) => selected == null || id == selected).toSet();
  final locName = {for (final l in locs.value!) l.id: l.name};
  final effects = TrxRepo.effects(local.value!, lastPull);

  final rows = <StockRow>[];
  final alerts = <({String level, String location, String product, Decimal qty, Decimal min})>[];
  var total = Decimal.zero;
  const rank = {'ok': 0, 'warning': 1, 'critical': 2};
  for (final p in products.value!) {
    var qty = Decimal.zero, official = Decimal.zero, min = Decimal.zero;
    var worst = 'ok';
    final per = <int, Decimal>{};
    for (final lid in locIds) {
      final b = balances.value!.where((x) => x.locationId == lid && x.productId == p.id).firstOrNull;
      final m = mins.value!.where((x) => x.locationId == lid && x.productId == p.id).firstOrNull;
      final o = dec(b?.qtyTon);
      final q = o + (effects[(lid, p.id)] ?? Decimal.zero);
      final mn = dec(m?.minTon);
      final st = stockStatus(q, mn);
      if (rank[st]! > rank[worst]!) worst = st;
      if (st != 'ok') {
        alerts.add((level: st, location: locName[lid] ?? '-', product: p.name, qty: q, min: mn));
      }
      per[lid] = q;
      qty += q;
      official += o;
      min += mn;
    }
    total += qty;
    rows.add(StockRow(product: p, qty: qty, official: official, min: min, status: worst, perLocation: per));
  }
  alerts.sort((a, b) => rank[b.level]!.compareTo(rank[a.level]!));
  return AsyncValue.data(DashboardData(rows: rows, total: total, alerts: alerts));
});

/// Ringkasan hari ini & jumlah yang perlu ditinjau — dari server (auto-refresh 30 detik saat online).
final todaySummaryProvider = FutureProvider.autoDispose<Map<String, dynamic>>((ref) {
  final loc = ref.watch(selectedLocationProvider);
  return ref.watch(apiProvider).get<Map<String, dynamic>>('/dashboard', query: {'location_id': loc?.toString()});
});

/// Ringkasan hari ini dari transaksi perangkat ini (fallback saat offline).
({Decimal inTon, Decimal outTon, int trucks}) localToday(List<LocalTransaction> rows, int? locationId) {
  final now = DateTime.now().toUtc().add(const Duration(hours: 7));
  final start = DateTime.utc(now.year, now.month, now.day).subtract(const Duration(hours: 7));
  var inT = Decimal.zero, outT = Decimal.zero;
  var trucks = 0;
  for (final r in rows) {
    if (r.trxAt.isBefore(start) || (locationId != null && r.locationId != locationId)) continue;
    if (!['IN_PRODUCTION', 'IN_SUPPLIER', 'OUT_SALE'].contains(r.trxType)) continue;
    final e = TrxRepo.effects([r.copyWith(syncState: SyncState.pending)], null);
    for (final v in e.values) {
      if (v < Decimal.zero) {
        outT -= v;
      } else {
        inT += v;
      }
    }
    trucks++;
  }
  return (inTon: inT, outTon: outT, trucks: trucks);
}

final localTrxProvider = _localTrxStream;
