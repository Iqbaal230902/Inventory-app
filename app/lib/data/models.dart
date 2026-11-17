import 'package:decimal/decimal.dart';

import '../core/format.dart';
import 'local/database.dart';

class AppLocation {
  AppLocation({required this.id, required this.code, required this.name, this.type, this.timezone = 'Asia/Jakarta'});
  final int id;
  final String code;
  final String name;
  final String? type;
  final String timezone;

  factory AppLocation.fromJson(Map<String, dynamic> j) => AppLocation(
        id: j['id'] as int,
        code: j['code'] as String,
        name: j['name'] as String,
        type: j['type'] as String?,
        timezone: (j['timezone'] as String?) ?? 'Asia/Jakarta',
      );
}

class AppUser {
  AppUser({
    required this.id,
    required this.name,
    required this.username,
    required this.role,
    required this.allLocations,
    required this.locations,
  });
  final int id;
  final String name;
  final String username;
  final String role;
  final bool allLocations;
  final List<AppLocation> locations;

  bool get isOwner => role == 'owner';
  bool get isAdmin => role == 'admin';
  bool get isManager => isOwner || isAdmin;
  bool get canInput => role != 'viewer';
  bool get canAdjust => isManager;
  bool get canExport => role != 'operator';

  factory AppUser.fromJson(Map<String, dynamic> j) => AppUser(
        id: j['id'] as int,
        name: j['name'] as String,
        username: j['username'] as String,
        role: j['role'] as String,
        allLocations: j['all_locations'] == true,
        locations: ((j['locations'] as List?) ?? [])
            .map((e) => AppLocation.fromJson((e as Map).cast<String, dynamic>()))
            .toList(),
      );
}

class TrxItemView {
  TrxItemView(this.j);
  final Map<String, dynamic> j;
  int? get productId => j['product_id'] as int?;
  String get productName => (j['product_name'] as String?) ?? '-';
  String? get packagingName => j['packaging_name'] as String?;
  String? get packageQty => j['package_qty'] as String?;
  /// Untuk item bersatuan rit, nilai ini = jumlah rit.
  Decimal get qtyTon => dec(j['qty_ton'] as String?);
  String get unit => (j['unit'] as String?) ?? 'ton';
  bool get isRit => unit == 'rit';
  String get direction => (j['direction'] as String?) ?? 'in';
}

/// Tampilan transaksi — sama untuk data server maupun transaksi lokal yang belum tersinkron.
class TrxView {
  TrxView(this.j, {this.local});
  final Map<String, dynamic> j;

  /// Baris antrian lokal (null bila data hanya dari server).
  final LocalTransaction? local;

  int? get id => (j['id'] as int?) ?? local?.serverId;
  String get clientUuid => j['client_uuid'] as String;
  String get docNo => (j['doc_no'] as String?) ?? local?.docNo ?? local?.tmpDocNo ?? '-';
  bool get isTemporaryNo => j['doc_no'] == null && local?.docNo == null;
  String? get manualDocNo => j['manual_doc_no'] as String?;
  String get trxType => j['trx_type'] as String;
  String get typeLabel => trxTypeLabels[trxType] ?? trxType;
  String get status => (j['status'] as String?) ?? 'posted';
  Map<String, dynamic> get location => (j['location'] as Map).cast<String, dynamic>();
  int get locationId => location['id'] as int;
  String get locationName => location['name'] as String;
  String get timezone => (location['timezone'] as String?) ?? 'Asia/Jakarta';
  String? get partnerName => j['partner_name'] as String?;
  String? get partnerAddress => j['partner_address'] as String?;
  String? get plateNumber => j['plate_number'] as String?;
  String? get driverName => j['driver_name'] as String?;
  Decimal? get grossTon => j['gross_ton'] == null ? null : dec(j['gross_ton'] as String);
  Decimal? get tareTon => j['tare_ton'] == null ? null : dec(j['tare_ton'] as String);
  Decimal? get netTon => j['net_ton'] == null ? null : dec(j['net_ton'] as String);
  Decimal get totalTon => dec(j['total_ton'] as String?);
  Decimal get totalRit => dec(j['total_rit'] as String?);

  /// Ringkasan jumlah: "15,900 Ton", "3 Rit", atau keduanya (penyesuaian campuran).
  String get qtyLabel {
    final parts = <String>[];
    if (totalTon != Decimal.zero || totalRit == Decimal.zero) parts.add(fmtQty(totalTon, 'ton'));
    if (totalRit != Decimal.zero) parts.add(fmtQty(totalRit, 'rit'));
    return parts.join(' + ');
  }
  DateTime get trxAt => DateTime.parse(j['trx_at'] as String);
  String? get notes => j['notes'] as String?;
  String? get voidReason => j['void_reason'] as String?;
  bool get voidRequested => j['void_requested'] == true;
  String? get reviewNote => j['review_note'] as String?;
  /// Jumlah cetak: maksimum dari data server dan catatan lokal (cetak offline).
  int get printCount {
    final server = (j['print_count'] as int?) ?? 0;
    final loc = local?.printCount ?? 0;
    return server > loc ? server : loc;
  }
  String get createdByName => ((j['created_by'] as Map?)?['name'] as String?) ?? '-';
  String? get deviceId => j['device_id'] as String?;
  DateTime? get clientCreatedAt => DateTime.tryParse('${j['client_created_at']}');
  DateTime? get createdAt => DateTime.tryParse('${j['created_at']}');
  List<TrxItemView> get items =>
      ((j['items'] as List?) ?? []).map((e) => TrxItemView((e as Map).cast<String, dynamic>())).toList();
  List<Map<String, dynamic>> get history =>
      ((j['history'] as List?) ?? []).map((e) => (e as Map).cast<String, dynamic>()).toList();
  Map<String, dynamic> get permissions => ((j['permissions'] as Map?) ?? {}).cast<String, dynamic>();
  bool get isLocked => j['is_locked'] == true;
  bool get hasPhoto => j['has_photo'] == true;

  bool get isOut => trxType == 'OUT_SALE';
  bool get isVoid => status == 'void';

  String get syncState => local?.syncState ?? SyncState.synced;
  bool get isPending => syncState == SyncState.pending;
  bool get isRejected => syncState == SyncState.rejected;
  bool get needsSync => isPending || isRejected;

  /// Arah dominan untuk ikon/warna di daftar.
  String get direction {
    if (trxType == 'OUT_SALE' || trxType == 'TRANSFER_OUT' || trxType == 'SHRINKAGE') return 'out';
    if (trxType.startsWith('IN_') || trxType == 'TRANSFER_IN') return 'in';
    final it = items;
    if (it.isNotEmpty && it.every((i) => i.direction == 'out')) return 'out';
    if (it.isNotEmpty && it.every((i) => i.direction == 'in')) return 'in';
    return 'mixed';
  }
}
