import 'dart:convert';
import 'dart:io';

import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

import '../../core/api_client.dart';
import '../../core/format.dart';
import '../../core/providers.dart';
import '../../core/theme.dart';
import '../../core/widgets.dart';
import '../../data/local/database.dart';
import '../../data/models.dart';
import '../dashboard/dashboard_provider.dart';

final _productsProvider = StreamProvider((ref) => ref.watch(masterRepoProvider).watchProducts());
final _packagingProvider = StreamProvider((ref) => ref.watch(masterRepoProvider).watchPackaging());
final _vehiclesProvider = StreamProvider((ref) => ref.watch(masterRepoProvider).watchVehicles());
final _partnersProvider =
    StreamProvider.family<List<Partner>, String>((ref, type) => ref.watch(masterRepoProvider).watchPartners(type));

/// Layar 4/5 — Form Barang Masuk, Keluar, Bahan Baku Masuk (per rit) & Penyesuaian (FR-03).
/// Online: dikirim langsung ke server (validasi stok interaktif).
/// Offline / jaringan putus: disimpan ke antrian lokal dan disinkronkan otomatis.
class TrxFormScreen extends ConsumerStatefulWidget {
  const TrxFormScreen({super.key, required this.type, this.editLocalUuid, this.editServerId});
  final String type;
  final String? editLocalUuid;
  final int? editServerId;
  @override
  ConsumerState<TrxFormScreen> createState() => _TrxFormScreenState();
}

class _TrxFormScreenState extends ConsumerState<TrxFormScreen> {
  final _form = GlobalKey<FormState>();
  late String _type = widget.type;
  late String _clientUuid = const Uuid().v4();

  DateTime _trxAt = DateTime.now();
  int? _locationId;
  int? _productId;
  int? _packagingId;
  int? _partnerId;
  /// Satuan produk terpilih: 'ton' (pasir mesh) atau 'rit' (bahan baku mentah).
  String _unit = 'ton';
  String _direction = 'in'; // penyesuaian
  bool _useScale = false;
  bool _manualDoc = false;
  String? _photoPath;
  bool _busy = false;
  bool _loaded = false;

  final _partnerName = TextEditingController();
  final _plate = TextEditingController();
  final _driver = TextEditingController();
  final _gross = TextEditingController();
  final _tare = TextEditingController();
  final _qty = TextEditingController();
  final _pkgQty = TextEditingController();
  final _manualDocNo = TextEditingController();
  final _notes = TextEditingController();

  bool get _isOut => _type == 'OUT_SALE';
  bool get _isAdj => _type == 'ADJUSTMENT';
  bool get _isRaw => _type == 'IN_RAW';
  bool get _isRitProduct => _unit == 'rit';
  bool get _hasPartner => _type == 'OUT_SALE' || _type == 'IN_SUPPLIER' || _type == 'IN_RAW';
  /// No. Polisi & sopir: tidak untuk penyesuaian dan produksi internal (tanpa truk).
  bool get _hasVehicle => !_isAdj && _type != 'IN_PRODUCTION';
  bool get _isServerEdit => widget.editServerId != null;

  /// Bahan Baku Masuk hanya produk rit; transaksi pasir hanya produk ton; penyesuaian semua.
  List<Product> _productChoices(List<Product> all) => switch (_type) {
        'IN_RAW' => all.where((p) => p.unit == 'rit').toList(),
        'ADJUSTMENT' => all,
        _ => all.where((p) => p.unit != 'rit').toList(),
      };

  @override
  void initState() {
    super.initState();
    _useScale = _type == 'OUT_SALE' || _type == 'IN_SUPPLIER';
    if (_isRaw) _qty.text = '1';
    for (final c in [_gross, _tare, _qty, _pkgQty]) {
      c.addListener(() => setState(() {}));
    }
    WidgetsBinding.instance.addPostFrameCallback((_) => _init());
  }

  Future<void> _init() async {
    final user = ref.read(currentUserProvider)!;
    _locationId = ref.read(selectedLocationProvider) ?? (user.locations.isNotEmpty ? user.locations.first.id : null);
    if (widget.editLocalUuid != null) {
      final row = await ref.read(trxRepoProvider).get(widget.editLocalUuid!);
      if (row != null) _prefill((jsonDecode(row.payload) as Map).cast<String, dynamic>(), photo: row.photoPath);
    } else if (_isServerEdit) {
      try {
        final j = await ref.read(apiProvider).get<Map<String, dynamic>>('/transactions/${widget.editServerId}');
        final t = TrxView(j);
        _prefill({
          'client_uuid': t.clientUuid,
          'trx_type': t.trxType,
          'location_id': t.locationId,
          'trx_at': t.trxAt.toIso8601String(),
          'partner_id': j['partner_id'],
          'partner_name': t.partnerName,
          'plate_number': t.plateNumber,
          'driver_name': t.driverName,
          'gross_ton': j['gross_ton'],
          'tare_ton': j['tare_ton'],
          'manual_doc_no': t.manualDocNo,
          'notes': t.notes,
          'items': t.items.map((i) => i.j).toList(),
        });
      } catch (e) {
        if (mounted) {
          showSnack(context, errorText(e), error: true);
          context.pop();
        }
        return;
      }
    }
    // Default kemasan: Curah
    final repo = ref.read(masterRepoProvider);
    final packs = await repo.watchPackaging().first;
    _packagingId ??= packs.where((p) => p.isBulk).firstOrNull?.id ?? packs.firstOrNull?.id;
    // Bahan baku masuk: produk rit pertama sebagai default.
    final products = await repo.watchProducts().first;
    if (_isRaw) _productId ??= products.where((p) => p.unit == 'rit').firstOrNull?.id;
    _unit = products.where((p) => p.id == _productId).firstOrNull?.unit ?? 'ton';
    if (_isRitProduct) {
      final q = parseTon(_qty.text);
      if (q != null) _qty.text = fmtQtyNum(q, 'rit').replaceAll('.', '');
    }
    if (!mounted) return;
    setState(() => _loaded = true);
  }

  void _prefill(Map<String, dynamic> j, {String? photo}) {
    _type = j['trx_type'] as String;
    _clientUuid = j['client_uuid'] as String;
    _trxAt = DateTime.parse(j['trx_at'] as String).toLocal();
    _locationId = j['location_id'] as int?;
    _partnerId = j['partner_id'] as int?;
    _partnerName.text = (j['partner_name'] as String?) ?? '';
    _plate.text = formatPlate(j['plate_number'] as String?).replaceAll('-', '');
    _driver.text = (j['driver_name'] as String?) ?? '';
    _gross.text = j['gross_ton'] == null ? '' : fmtTonStr(j['gross_ton'] as String).replaceAll('.', '');
    _tare.text = j['tare_ton'] == null ? '' : fmtTonStr(j['tare_ton'] as String).replaceAll('.', '');
    _useScale = j['gross_ton'] != null;
    _manualDocNo.text = (j['manual_doc_no'] as String?) ?? '';
    _manualDoc = _manualDocNo.text.isNotEmpty;
    _notes.text = (j['notes'] as String?) ?? '';
    final items = (j['items'] as List).cast<Map>();
    if (items.isNotEmpty) {
      final it = items.first;
      _productId = it['product_id'] as int?;
      _packagingId = it['packaging_unit_id'] as int?;
      _direction = (it['direction'] as String?) ?? 'in';
      if (it['package_qty'] != null) _pkgQty.text = '${it['package_qty']}'.replaceAll(RegExp(r'\.00$'), '');
      if (!_useScale && it['qty_ton'] != null) _qty.text = fmtTonStr('${it['qty_ton']}').replaceAll('.', '');
    }
    _photoPath = photo;
  }

  PackagingUnit? _packaging(List<PackagingUnit> packs) => packs.where((p) => p.id == _packagingId).firstOrNull;

  Decimal? get _net {
    final g = parseTon(_gross.text), t = parseTon(_tare.text);
    if (g == null || t == null) return null;
    return g - t;
  }

  /// Tonase final transaksi: netto timbangan > jumlah kemasan × ton/kemasan > input ton langsung.
  /// Untuk produk rit (bahan baku mentah) = jumlah rit.
  Decimal? _computedQty(List<PackagingUnit> packs) {
    if (_isRitProduct) return parseTon(_qty.text);
    if (_useScale) return _net;
    final pu = _packaging(packs);
    if (pu != null && !pu.isBulk) {
      final n = parseTon(_pkgQty.text);
      if (n == null) return null;
      return (n * Decimal.parse(pu.tonPerUnit)).round(scale: 3);
    }
    return parseTon(_qty.text);
  }

  Future<void> _pickPhoto() async {
    final x = await ImagePicker().pickImage(source: ImageSource.camera, maxWidth: 1600, imageQuality: 85);
    if (x == null) return;
    final dir = Directory(p.join((await getApplicationDocumentsDirectory()).path, 'photos'));
    await dir.create(recursive: true);
    final out = p.join(dir.path, '$_clientUuid.jpg');
    // Kompres hingga ≤ 500 KB (FR-03).
    var quality = 80;
    List<int>? bytes;
    while (quality >= 30) {
      bytes = await FlutterImageCompress.compressWithFile(x.path, minWidth: 1280, minHeight: 1280, quality: quality);
      if (bytes != null && bytes.length <= 500 * 1024) break;
      quality -= 10;
    }
    if (bytes == null) return;
    await File(out).writeAsBytes(bytes);
    setState(() => _photoPath = out);
  }

  Future<void> _pickDateTime() async {
    final d = await showDatePicker(
      context: context,
      initialDate: _trxAt,
      firstDate: DateTime.now().subtract(const Duration(days: 60)),
      lastDate: DateTime.now(),
    );
    if (d == null || !mounted) return;
    final t = await showTimePicker(context: context, initialTime: TimeOfDay.fromDateTime(_trxAt));
    if (t == null) return;
    setState(() => _trxAt = DateTime(d.year, d.month, d.day, t.hour, t.minute));
  }

  void _onPlateChosen(Vehicle v) {
    _plate.text = formatPlate(v.plateNumber);
    if (_driver.text.isEmpty && v.defaultDriver != null) _driver.text = v.defaultDriver!;
    if (_useScale && _tare.text.isEmpty && v.standardTareTon != null) {
      _tare.text = fmtTonStr(v.standardTareTon).replaceAll('.', '');
    }
    setState(() {});
  }

  // ---------------------------------------------------------------------------

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    final user = ref.read(currentUserProvider)!;
    final packs = ref.read(_packagingProvider).value ?? const [];
    final products = ref.read(_productsProvider).value ?? const [];
    final locs = ref.read(locationsProvider).value ?? const [];
    final qty = _computedQty(packs);
    if (qty == null || qty <= Decimal.zero) {
      showSnack(context, _isRitProduct ? 'Jumlah rit harus lebih dari 0.' : 'Netto/jumlah harus lebih dari 0.', error: true);
      return;
    }
    if (_isRitProduct && qty != qty.truncate()) {
      showSnack(context, 'Jumlah rit harus bilangan bulat (1 rit = 1 truk).', error: true);
      return;
    }
    final settings = ref.read(settingsProvider).value ?? const {};
    final online = ref.read(onlineProvider).value ?? false;
    final plate = normalizePlate(_plate.text);
    var confirmLarge = false;
    var allowNegative = false;
    String? negativeReason;

    // 1. Batas wajar per truk (mis. salah ketik 159 vs 15,9)
    final maxTon = Decimal.tryParse(settings['max_net_ton_per_trx'] ?? '60') ?? Decimal.fromInt(60);
    if (!_isAdj && !_isRitProduct && maxTon > Decimal.zero && qty > maxTon) {
      final ok = await confirmDialog(context,
          title: 'Tonase tidak wajar?',
          message: 'Netto ${fmtTon(qty)} Ton melebihi batas wajar ${fmtTon(maxTon, decimals: 0)} Ton per transaksi. '
              'Pastikan tidak salah ketik. Lanjutkan?',
          ok: 'Ya, sudah benar');
      if (!ok) return;
      confirmLarge = true;
    }

    // 2. Peringatan input ganda: No. Polisi sama keluar 2× dalam 15 menit
    if (_isOut && plate.isNotEmpty && !_isServerEdit && mounted) {
      final dup = await _duplicatePlate(plate, online);
      if (dup != null && mounted) {
        final ok = await confirmDialog(context,
            title: 'Kemungkinan input ganda',
            message: 'No. Polisi ${formatPlate(plate)} sudah tercatat keluar ($dup) dalam 15 menit terakhir. Tetap simpan?',
            ok: 'Tetap simpan');
        if (!ok) return;
      }
    }

    // 3. Stok tidak boleh negatif (cek lokal; server tetap memvalidasi ulang)
    final goingOut = _isOut || (_isAdj && _direction == 'out');
    if (goingOut && !_isServerEdit && mounted) {
      final row = ref.read(dashboardProvider).value?.rows.where((r) => r.product.id == _productId).firstOrNull;
      final avail = row?.perLocation[_locationId] ?? Decimal.zero;
      if (qty > avail) {
        if (online && user.isOwner) {
          negativeReason = await promptText(context,
              title: 'Stok tidak cukup',
              label: 'Stok tercatat ${fmtQty(avail, _unit)}. Alasan mengizinkan stok negatif',
              ok: 'Izinkan');
          if (negativeReason == null) return;
          allowNegative = true;
        } else if (!online) {
          final ok = await confirmDialog(context,
              title: 'Stok tercatat tidak cukup',
              message: 'Stok tercatat di HP ${fmtQty(avail, _unit)}. Transaksi tetap disimpan dan akan ditandai '
                  'untuk ditinjau Admin/Owner setelah sinkron. Lanjutkan?',
              ok: 'Simpan');
          if (!ok) return;
        }
        // online non-owner: biarkan server menolak dengan pesan jelas
      }
    }

    final product = products.firstWhere((p) => p.id == _productId);
    final pu = _isRitProduct ? null : _packaging(packs); // rit tanpa kemasan
    final location = locs.firstWhere((l) => l.id == _locationId, orElse: () => locs.first);
    final nowUtc = DateTime.now().toUtc();
    final item = <String, dynamic>{
      'product_id': product.id,
      if (pu != null) 'packaging_unit_id': pu.id,
      if (pu != null && !pu.isBulk && parseTon(_pkgQty.text) != null) 'package_qty': parseTon(_pkgQty.text)!.toStringAsFixed(2),
      'qty_ton': tonApi(qty),
      if (_isAdj) 'direction': _direction,
    };
    final payload = <String, dynamic>{
      'client_uuid': _clientUuid,
      'trx_type': _type,
      'location_id': location.id,
      if (_partnerId != null) 'partner_id': _partnerId,
      if (_hasPartner && _partnerName.text.trim().isNotEmpty) 'partner_name': _partnerName.text.trim(),
      if (_hasVehicle && plate.isNotEmpty) 'plate_number': plate,
      if (_hasVehicle && _driver.text.trim().isNotEmpty) 'driver_name': _driver.text.trim(),
      if (_useScale && !_isRitProduct) 'gross_ton': tonApi(parseTon(_gross.text)!),
      if (_useScale && !_isRitProduct) 'tare_ton': tonApi(parseTon(_tare.text)!),
      'trx_at': _trxAt.toUtc().toIso8601String(),
      'client_created_at': nowUtc.toIso8601String(),
      if (_manualDoc && _manualDocNo.text.trim().isNotEmpty) 'manual_doc_no': _manualDocNo.text.trim(),
      if (_notes.text.trim().isNotEmpty) 'notes': _notes.text.trim(),
      'items': [item],
      if (confirmLarge) 'confirm_large': true,
      if (allowNegative) 'allow_negative': true,
      'negative_reason': ?negativeReason,
    };

    setState(() => _busy = true);
    try {
      if (_isServerEdit) {
        await _saveServerEdit(payload);
        return;
      }
      final partnerAddr = _partnerId == null
          ? null
          : (await ref.read(masterRepoProvider).watchPartners(_isOut ? 'customer' : 'supplier').first)
              .where((x) => x.id == _partnerId)
              .firstOrNull
              ?.address;
      final view = _buildView(payload, user, location, product, pu, partnerAddr, qty);
      await _saveNew(payload, view, user, online);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<String?> _duplicatePlate(String plate, bool online) async {
    if (online) {
      try {
        final r = await ref
            .read(apiProvider)
            .get<Map<String, dynamic>>('/transactions/plate-check', query: {'plate': plate, 'location_id': '$_locationId'});
        if (r['duplicate'] == true) return r['doc_no'] as String?;
      } catch (_) {}
    }
    final since = DateTime.now().toUtc().subtract(const Duration(minutes: 15));
    final rows = await ref.read(trxRepoProvider).watchRecent(limit: 50).first;
    for (final r in rows) {
      if (r.trxType != 'OUT_SALE' || r.clientUuid == _clientUuid || r.trxAt.isBefore(since)) continue;
      final p = (jsonDecode(r.payload) as Map)['plate_number'];
      if (p == plate) return r.docNo ?? r.tmpDocNo;
    }
    return null;
  }

  Map<String, dynamic> _buildView(Map<String, dynamic> payload, AppUser user, Location loc, Product product,
      PackagingUnit? pu, String? partnerAddr, Decimal qty) {
    final net = _useScale && !_isRitProduct ? _net : null;
    final rit = product.unit == 'rit';
    return {
      'id': null,
      'client_uuid': payload['client_uuid'],
      'doc_no': null,
      'manual_doc_no': payload['manual_doc_no'],
      'trx_type': _type,
      'status': 'posted',
      'location': {'id': loc.id, 'code': loc.code, 'name': loc.name, 'timezone': loc.timezone},
      'partner_id': payload['partner_id'],
      'partner_name': payload['partner_name'],
      'partner_address': partnerAddr,
      'plate_number': payload['plate_number'],
      'driver_name': payload['driver_name'],
      'gross_ton': payload['gross_ton'],
      'tare_ton': payload['tare_ton'],
      'net_ton': net == null ? null : tonApi(net),
      'total_ton': tonApi(rit ? Decimal.zero : qty),
      'total_rit': rit ? qty.toString() : '0',
      'trx_at': payload['trx_at'],
      'notes': payload['notes'],
      'print_count': 0,
      'created_by': {'id': user.id, 'name': user.name},
      'client_created_at': payload['client_created_at'],
      'items': [
        {
          'product_id': product.id,
          'product_code': product.code,
          'product_name': product.name,
          'direction': _isAdj ? _direction : (_isOut ? 'out' : 'in'),
          'packaging_unit_id': pu?.id,
          'packaging_name': pu?.name,
          'package_qty': (payload['items'] as List).first['package_qty'],
          'qty_ton': tonApi(qty),
          'unit': product.unit,
        }
      ],
    };
  }

  Future<void> _saveNew(Map<String, dynamic> payload, Map<String, dynamic> view, AppUser user, bool online) async {
    final repo = ref.read(trxRepoProvider);
    final db = ref.read(dbProvider);
    final isFix = widget.editLocalUuid != null;
    final store = ref.read(sessionStoreProvider);

    Future<void> enqueue() async {
      if (isFix) {
        await repo.replacePending(clientUuid: _clientUuid, payload: payload, view: view, photoPath: _photoPath);
      } else {
        final dev = (await store.deviceId()).substring(0, 4).toUpperCase();
        final seq = await db.nextLocalSeq();
        await repo.enqueue(
          payload: payload,
          view: view,
          tmpDocNo: 'TMP-$dev-${seq.toString().padLeft(4, '0')}',
          userId: user.id,
          photoPath: _photoPath,
        );
      }
    }

    List<dynamic> warnings = const [];
    if (online) {
      try {
        final res = await ref.read(apiProvider).post<Map<String, dynamic>>('/transactions', payload);
        warnings = (res['warnings'] as List?) ?? const [];
        await enqueue();
        final t = (res['transaction'] as Map).cast<String, dynamic>();
        await repo.markSynced(_clientUuid, t);
        // Foto & saldo diperbarui di latar belakang
        ref.read(syncEngineProvider).sync();
      } on ApiException catch (e) {
        if (!e.isNetwork) {
          if (mounted) await _showServerError(e);
          return;
        }
        await enqueue(); // jaringan putus → antrian offline
      }
    } else {
      await enqueue();
    }
    final row = await repo.get(_clientUuid);
    final synced = row?.syncState == SyncState.synced;
    if (!mounted) return;
    showSnack(
      context,
      synced
          ? 'Tersimpan: ${row?.docNo}${warnings.isNotEmpty ? ' — ${warnings.first['message']}' : ''}'
          : 'Tersimpan di HP (${row?.tmpDocNo}). Akan dikirim otomatis saat online.',
    );
    if (!mounted) return;
    if (_isOut) {
      context.pushReplacement('/trx/$_clientUuid/print');
    } else {
      context.pushReplacement('/trx/$_clientUuid');
    }
  }

  Future<void> _saveServerEdit(Map<String, dynamic> payload) async {
    final reason = await promptText(context, title: 'Alasan perubahan', label: 'Mengapa transaksi ini diubah?');
    if (reason == null) return;
    final body = Map.of(payload)
      ..remove('client_uuid')
      ..remove('trx_type')
      ..remove('location_id')
      ..remove('client_created_at')
      ..['edit_reason'] = reason;
    if (!_useScale) {
      body['gross_ton'] = '';
      body['tare_ton'] = '';
    }
    try {
      final t = await ref.read(apiProvider).patch<Map<String, dynamic>>('/transactions/${widget.editServerId}', body);
      await ref.read(trxRepoProvider).cacheServerTrx(t, ref.read(currentUserProvider)!.id);
      ref.read(syncEngineProvider).sync();
      if (mounted) {
        showSnack(context, 'Perubahan disimpan.');
        context.pop(true);
      }
    } on ApiException catch (e) {
      if (mounted) await _showServerError(e);
    }
  }

  Future<void> _showServerError(ApiException e) => showDialog(
        context: context,
        builder: (c) => AlertDialog(
          icon: Icon(Icons.error_outline, color: Theme.of(c).colorScheme.error),
          title: Text(switch (e.code) {
            'INSUFFICIENT_STOCK' => 'Stok tidak cukup',
            'LOCKED' => 'Transaksi terkunci',
            'FORBIDDEN' => 'Tidak diizinkan',
            _ => 'Gagal menyimpan',
          }),
          content: Text(e.message),
          actions: [FilledButton(onPressed: () => Navigator.pop(c), child: const Text('OK'))],
        ),
      );

  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider)!;
    final products = ref.watch(_productsProvider).value ?? const <Product>[];
    final packs = ref.watch(_packagingProvider).value ?? const <PackagingUnit>[];
    final vehicles = ref.watch(_vehiclesProvider).value ?? const <Vehicle>[];
    final choices = _productChoices(products);
    final partners = _hasPartner
        ? (ref.watch(_partnersProvider(_isOut ? 'customer' : 'supplier')).value ?? const <Partner>[])
        : const <Partner>[];
    final locs = ref.watch(locationsProvider).value ?? const <Location>[];
    final online = ref.watch(onlineProvider).value ?? false;
    final pu = _packaging(packs);
    final qty = _computedQty(packs);
    final locTz = locs.where((l) => l.id == _locationId).firstOrNull?.timezone ?? 'Asia/Jakarta';
    final title = _isServerEdit
        ? 'Edit ${trxTypeLabels[_type] ?? ''}'
        : (widget.editLocalUuid != null ? 'Perbaiki Transaksi' : (trxTypeLabels[_type] ?? 'Transaksi'));

    if (!_loaded) return Scaffold(appBar: AppBar(title: Text(title)), body: const Center(child: CircularProgressIndicator()));
    if (choices.isEmpty || locs.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: Text(title)),
        body: EmptyState(
            icon: Icons.cloud_download_outlined,
            message: _isRaw
                ? 'Data bahan baku belum tersedia di HP ini. Sambungkan ke internet dan lakukan sinkron terlebih dahulu.'
                : 'Master data belum tersedia di HP ini. Sambungkan ke internet dan lakukan sinkron terlebih dahulu.'),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Form(
        key: _form,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
          children: [
            if (!online && !_isServerEdit)
              const Padding(
                padding: EdgeInsets.only(bottom: 8),
                child: Pill('Offline — akan disimpan di HP dan disinkronkan otomatis', icon: Icons.cloud_off, color: AppColors.warning),
              ),
            // ---- Waktu & lokasi ----
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.event),
              title: Text(fmtDateTime(_trxAt, tz: locTz)),
              subtitle: const Text('Tanggal & jam transaksi'),
              trailing: const Icon(Icons.edit_calendar),
              onTap: _pickDateTime,
            ),
            if (locs.length > 1 && !_isServerEdit && user.role != 'operator')
              DropdownButtonFormField<int>(
                initialValue: _locationId,
                decoration: const InputDecoration(labelText: 'Lokasi'),
                items: locs.map((l) => DropdownMenuItem(value: l.id, child: Text(l.name))).toList(),
                onChanged: (v) => setState(() => _locationId = v),
                validator: (v) => v == null ? 'Pilih lokasi' : null,
              )
            else
              KeyValueRow('Lokasi', locs.where((l) => l.id == _locationId).firstOrNull?.name ?? '-'),
            const SizedBox(height: 12),

            // ---- Produk ----
            if (_isAdj) ...[
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment(value: 'in', icon: Icon(Icons.add), label: Text('Tambah stok')),
                  ButtonSegment(value: 'out', icon: Icon(Icons.remove), label: Text('Kurangi stok')),
                ],
                selected: {_direction},
                onSelectionChanged: (s) => setState(() => _direction = s.first),
              ),
              const SizedBox(height: 12),
            ],
            DropdownButtonFormField<int>(
              initialValue: choices.any((p) => p.id == _productId) ? _productId : null,
              decoration: InputDecoration(labelText: _isRaw ? 'Bahan baku' : 'Produk / Mesh'),
              items: choices
                  .map((p) => DropdownMenuItem(value: p.id, child: Text(p.unit == 'rit' && _isAdj ? '${p.name} (rit)' : p.name)))
                  .toList(),
              onChanged: (v) => setState(() {
                _productId = v;
                final unit = products.where((p) => p.id == v).firstOrNull?.unit ?? 'ton';
                if (unit != _unit) _qty.clear();
                _unit = unit;
              }),
              validator: (v) => v == null ? 'Pilih produk' : null,
            ),
            const SizedBox(height: 12),
            if (!_isRitProduct) ...[
              DropdownButtonFormField<int>(
                initialValue: _packagingId,
                decoration: const InputDecoration(labelText: 'Kemasan'),
                items: packs
                    .map((p) => DropdownMenuItem(
                        value: p.id, child: Text(p.isBulk ? p.name : '${p.name} (${fmtTonStr(p.tonPerUnit)} Ton)')))
                    .toList(),
                onChanged: (v) => setState(() => _packagingId = v),
              ),
              const SizedBox(height: 12),
            ],

            // ---- Jumlah rit (bahan baku mentah, dihitung per truk) ----
            if (_isRitProduct) ...[
              _ritField(),
              if (_isRaw)
                Padding(
                  padding: const EdgeInsets.only(top: 6, left: 4),
                  child: Text('Dihitung per truk yang masuk (1 rit = 1 truk), tanpa tonase.',
                      style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant)),
                ),
              const SizedBox(height: 16),
            ] else ...[
            // ---- Berat ----
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Pakai timbangan (bruto/tara)'),
              value: _useScale,
              onChanged: (v) => setState(() => _useScale = v),
            ),
            if (_useScale) ...[
              Row(children: [
                Expanded(child: _tonField(_gross, 'Bruto (Ton)', required: true)),
                const SizedBox(width: 12),
                Expanded(child: _tonField(_tare, 'Tara (Ton)', required: true)),
              ]),
              const SizedBox(height: 8),
              _NetBox(net: _net),
              if (pu != null && !pu.isBulk) ...[
                const SizedBox(height: 12),
                _tonField(_pkgQty, 'Jumlah ${pu.name} (opsional)', decimals: 0),
              ],
            ] else if (pu != null && !pu.isBulk) ...[
              _tonField(_pkgQty, 'Jumlah ${pu.name}', required: true, decimals: 0),
              const SizedBox(height: 8),
              _NetBox(net: qty, label: 'Tonase (${fmtTonStr(pu.tonPerUnit)} Ton × jumlah)'),
            ] else
              _tonField(_qty, 'Jumlah (Ton)', required: true),
            const SizedBox(height: 16),
            ],

            // ---- Pihak & kendaraan ----
            if (_hasPartner) ...[
              _PartnerField(
                controller: _partnerName,
                partners: partners,
                label: _isOut ? 'Pelanggan' : (_isRaw ? 'Asal tambang / Supplier (opsional)' : 'Supplier'),
                onSelected: (p) => setState(() => _partnerId = p?.id),
                required: _isOut,
              ),
              const SizedBox(height: 12),
            ],
            if (_hasVehicle) ...[
              Autocomplete<Vehicle>(
                initialValue: TextEditingValue(text: _plate.text),
                optionsBuilder: (v) {
                  final q = normalizePlate(v.text);
                  if (q.isEmpty) return const [];
                  return vehicles.where((x) => x.plateNumber.contains(q)).take(6);
                },
                displayStringForOption: (v) => formatPlate(v.plateNumber),
                onSelected: _onPlateChosen,
                fieldViewBuilder: (ctx, ctrl, focus, onSubmit) {
                  ctrl.addListener(() {
                    if (_plate.text != ctrl.text) _plate.text = ctrl.text;
                  });
                  return TextFormField(
                    controller: ctrl,
                    focusNode: focus,
                    textCapitalization: TextCapitalization.characters,
                    inputFormatters: [PlateInputFormatter()],
                    decoration: const InputDecoration(labelText: 'No. Polisi', hintText: 'BG 1234 XY', prefixIcon: Icon(Icons.local_shipping_outlined)),
                    validator: (v) => _isOut && normalizePlate(v ?? '').isEmpty ? 'No. Polisi wajib untuk surat jalan' : null,
                  );
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _driver,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(labelText: 'Nama Sopir', prefixIcon: Icon(Icons.badge_outlined)),
                validator: (v) => _isOut && (v ?? '').trim().isEmpty ? 'Nama sopir wajib untuk surat jalan' : null,
              ),
              const SizedBox(height: 12),
            ],
            if (_isOut && !_isServerEdit) ...[
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Pakai No. SJ dari buku manual'),
                subtitle: const Text('Nomor otomatis tetap dibuat oleh sistem'),
                value: _manualDoc,
                onChanged: (v) => setState(() => _manualDoc = v),
              ),
              if (_manualDoc)
                TextFormField(
                  controller: _manualDocNo,
                  decoration: const InputDecoration(labelText: 'No. SJ manual'),
                  validator: (v) => _manualDoc && (v ?? '').trim().isEmpty ? 'Isi nomor SJ manual' : null,
                ),
              const SizedBox(height: 12),
            ],
            TextFormField(
              controller: _notes,
              maxLines: 2,
              maxLength: 500,
              decoration: InputDecoration(labelText: _isAdj ? 'Alasan penyesuaian (wajib)' : 'Catatan'),
              validator: (v) => _isAdj && (v ?? '').trim().isEmpty ? 'Alasan penyesuaian wajib diisi' : null,
            ),
            if (!_isServerEdit) ...[
              const SizedBox(height: 4),
              _photoTile(),
            ],
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: FilledButton.icon(
            onPressed: _busy ? null : _submit,
            icon: _busy
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2.5))
                : const Icon(Icons.save),
            label: Text(qty != null && qty > Decimal.zero ? 'Simpan · ${fmtQty(qty, _unit)}' : 'Simpan'),
          ),
        ),
      ),
    );
  }

  Widget _tonField(TextEditingController c, String label, {bool required = false, int decimals = 3}) => TextFormField(
        controller: c,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        inputFormatters: [TonInputFormatter(decimals: decimals)],
        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
        decoration: InputDecoration(labelText: label),
        validator: (v) {
          if (!required) return null;
          final d = parseTon(v);
          if (d == null) return 'Wajib diisi';
          if (d <= Decimal.zero) return 'Harus > 0';
          return null;
        },
      );

  /// Jumlah rit (1 rit = 1 truk): bilangan bulat dengan tombol − / +.
  Widget _ritField() {
    void bump(int d) {
      final cur = int.tryParse(_qty.text) ?? 0;
      _qty.text = '${(cur + d).clamp(1, 999)}';
    }

    return Row(children: [
      IconButton.filledTonal(onPressed: () => bump(-1), icon: const Icon(Icons.remove), iconSize: 28),
      const SizedBox(width: 12),
      Expanded(
        child: TextFormField(
          controller: _qty,
          textAlign: TextAlign.center,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(3)],
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700),
          decoration: const InputDecoration(labelText: 'Jumlah truk (rit)', suffixText: 'Rit'),
          validator: (v) {
            final n = int.tryParse(v ?? '');
            if (n == null) return 'Wajib diisi';
            if (n <= 0) return 'Harus > 0';
            return null;
          },
        ),
      ),
      const SizedBox(width: 12),
      IconButton.filledTonal(onPressed: () => bump(1), icon: const Icon(Icons.add), iconSize: 28),
    ]);
  }

  Widget _photoTile() => Card(
        child: ListTile(
          leading: _photoPath == null
              ? const Icon(Icons.photo_camera_outlined)
              : ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: Image.file(File(_photoPath!), width: 48, height: 48, fit: BoxFit.cover)),
          title: Text(_photoPath == null ? (_isRaw ? 'Foto truk / muatan' : 'Foto tiket timbangan / bak truk') : 'Foto terlampir'),
          subtitle: const Text('Opsional · dikompres maks. 500 KB'),
          trailing: _photoPath == null
              ? null
              : IconButton(icon: const Icon(Icons.close), onPressed: () => setState(() => _photoPath = null)),
          onTap: _pickPhoto,
        ),
      );
}

class _NetBox extends StatelessWidget {
  const _NetBox({required this.net, this.label = 'Netto (bruto − tara)'});
  final Decimal? net;
  final String label;
  @override
  Widget build(BuildContext context) {
    final bad = net != null && net! <= Decimal.zero;
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: bad ? cs.errorContainer : cs.primaryContainer,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(children: [
        Expanded(child: Text(label, style: TextStyle(fontWeight: FontWeight.w600, color: bad ? cs.onErrorContainer : cs.onPrimaryContainer))),
        Text(net == null ? '-' : '${fmtTon(net)} Ton',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: bad ? cs.onErrorContainer : cs.primary)),
      ]),
    );
  }
}

/// Pelanggan/supplier: pilih dari master atau ketik nama baru (tetap bisa offline).
class _PartnerField extends StatelessWidget {
  const _PartnerField({
    required this.controller,
    required this.partners,
    required this.label,
    required this.onSelected,
    required this.required,
  });
  final TextEditingController controller;
  final List<Partner> partners;
  final String label;
  final ValueChanged<Partner?> onSelected;
  final bool required;

  @override
  Widget build(BuildContext context) => Autocomplete<Partner>(
        initialValue: TextEditingValue(text: controller.text),
        optionsBuilder: (v) {
          final q = v.text.toLowerCase();
          return partners.where((p) => q.isEmpty || p.name.toLowerCase().contains(q)).take(8);
        },
        displayStringForOption: (p) => p.name,
        onSelected: (p) {
          controller.text = p.name;
          onSelected(p);
        },
        fieldViewBuilder: (ctx, ctrl, focus, onSubmit) {
          ctrl.addListener(() {
            if (controller.text != ctrl.text) {
              controller.text = ctrl.text;
              final exact = partners.where((p) => p.name == ctrl.text).firstOrNull;
              onSelected(exact);
            }
          });
          return TextFormField(
            controller: ctrl,
            focusNode: focus,
            textCapitalization: TextCapitalization.words,
            decoration: InputDecoration(labelText: label, prefixIcon: const Icon(Icons.storefront_outlined)),
            validator: (v) => required && (v ?? '').trim().isEmpty ? '$label wajib diisi' : null,
          );
        },
      );
}
