import 'package:esc_pos_utils_plus/esc_pos_utils_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:print_bluetooth_thermal/print_bluetooth_thermal.dart';

import '../../core/format.dart';
import '../../data/models.dart';
import 'delivery_note_pdf.dart';

class ThermalPrinterException implements Exception {
  ThermalPrinterException(this.message);
  final String message;
  @override
  String toString() => message;
}

/// Cetak surat jalan ke printer thermal Bluetooth 58/80 mm (ESC/POS).
class ThermalPrinter {
  static Future<void> ensurePermission() async {
    final statuses = await [Permission.bluetoothConnect, Permission.bluetoothScan].request();
    if (statuses.values.any((s) => s.isPermanentlyDenied)) {
      throw ThermalPrinterException('Izin Bluetooth ditolak. Aktifkan di Pengaturan HP.');
    }
  }

  static Future<List<BluetoothInfo>> pairedPrinters() async {
    await ensurePermission();
    if (!await PrintBluetoothThermal.bluetoothEnabled) {
      throw ThermalPrinterException('Bluetooth belum aktif.');
    }
    return PrintBluetoothThermal.pairedBluetooths;
  }

  static Future<void> printBytes(String mac, List<int> bytes) async {
    await ensurePermission();
    if (!await PrintBluetoothThermal.bluetoothEnabled) {
      throw ThermalPrinterException('Bluetooth belum aktif.');
    }
    if (!await PrintBluetoothThermal.connectionStatus) {
      final ok = await PrintBluetoothThermal.connect(macPrinterAddress: mac);
      if (!ok) throw ThermalPrinterException('Gagal terhubung ke printer. Pastikan printer menyala dan sudah dipasangkan.');
    }
    final ok = await PrintBluetoothThermal.writeBytes(bytes);
    if (!ok) throw ThermalPrinterException('Gagal mengirim data ke printer.');
  }

  static Future<List<int>> testPage({required bool mm80}) async {
    final g = Generator(mm80 ? PaperSize.mm80 : PaperSize.mm58, await CapabilityProfile.load());
    return [
      ...g.reset(),
      ...g.text('TES PRINTER', styles: const PosStyles(align: PosAlign.center, bold: true, height: PosTextSize.size2)),
      ...g.text('Pasir Silika · ${mm80 ? '80' : '58'} mm', styles: const PosStyles(align: PosAlign.center)),
      ...g.feed(3),
      ...g.cut(),
    ];
  }

  static String _ascii(String s) => s.replaceAll(RegExp(r'[^\x20-\x7E]'), '');

  static Future<List<int>> deliveryNote({
    required TrxView t,
    required Map<String, String> company,
    required String apiBase,
    required bool copy,
    required bool mm80,
  }) async {
    final g = Generator(mm80 ? PaperSize.mm80 : PaperSize.mm58, await CapabilityProfile.load());
    const center = PosStyles(align: PosAlign.center);
    final b = <int>[...g.reset()];
    b.addAll(g.text(_ascii(company['company_name'] ?? ''),
        styles: const PosStyles(align: PosAlign.center, bold: true, height: PosTextSize.size2)));
    for (final l in [company['company_address'], company['company_phone']]) {
      if ((l ?? '').isNotEmpty) b.addAll(g.text(_ascii(l!), styles: center));
    }
    b.addAll(g.hr());
    b.addAll(g.text(copy ? 'SURAT JALAN (COPY)' : 'SURAT JALAN', styles: const PosStyles(align: PosAlign.center, bold: true)));
    b.addAll(g.text(_ascii(t.docNo), styles: center));
    if (t.isTemporaryNo) b.addAll(g.text('(nomor sementara - belum sinkron)', styles: center));
    if (t.manualDocNo != null) b.addAll(g.text(_ascii('SJ manual: ${t.manualDocNo}'), styles: center));
    b.addAll(g.hr());
    void kv(String k, String v) => b.addAll(g.row([
          PosColumn(text: k, width: 4),
          PosColumn(text: _ascii(': $v'), width: 8),
        ]));
    kv('Tanggal', fmtDateTime(t.trxAt, tz: t.timezone));
    kv('Dari', t.locationName);
    kv('Kepada', t.partnerName ?? '-');
    kv('No.Polisi', formatPlate(t.plateNumber));
    kv('Sopir', t.driverName ?? '-');
    b.addAll(g.hr());
    for (final i in t.items) {
      b.addAll(g.text(_ascii(i.productName), styles: const PosStyles(bold: true)));
      b.addAll(g.row([
        PosColumn(
            text: _ascii('${i.packagingName ?? 'Curah'}${i.packageQty != null ? ' x${fmtTonStr(i.packageQty, decimals: 0)}' : ''}'),
            width: 6),
        PosColumn(text: '${fmtTon(i.qtyTon)} Ton', width: 6, styles: const PosStyles(align: PosAlign.right, bold: true)),
      ]));
    }
    if (t.grossTon != null && t.tareTon != null) {
      b.addAll(g.hr(ch: '.'));
      kv('Bruto', '${fmtTon(t.grossTon)} Ton');
      kv('Tara', '${fmtTon(t.tareTon)} Ton');
      b.addAll(g.row([
        PosColumn(text: 'Netto', width: 4, styles: const PosStyles(bold: true)),
        PosColumn(text: ': ${fmtTon(t.netTon)} Ton', width: 8, styles: const PosStyles(bold: true)),
      ]));
    }
    b.addAll(g.hr());
    b.addAll(g.qrcode(verifyUrl(apiBase, t), size: QRSize.size4));
    b.addAll(g.text('Scan untuk verifikasi', styles: center));
    b.addAll(g.feed(1));
    b.addAll(g.row([
      PosColumn(text: 'Pengirim', width: 4, styles: center),
      PosColumn(text: 'Sopir', width: 4, styles: center),
      PosColumn(text: 'Penerima', width: 4, styles: center),
    ]));
    b.addAll(g.feed(3));
    b.addAll(g.row([
      PosColumn(text: '(.......)', width: 4, styles: center),
      PosColumn(text: '(.......)', width: 4, styles: center),
      PosColumn(text: '(.......)', width: 4, styles: center),
    ]));
    b.addAll(g.feed(3));
    b.addAll(g.cut());
    return b;
  }
}
