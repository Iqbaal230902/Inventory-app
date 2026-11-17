import 'package:decimal/decimal.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

/// Utilitas angka & teks. Tonase SELALU diproses sebagai [Decimal] (bukan double)
/// agar tidak ada error pembulatan floating point (PRD 6).

final Decimal dZero = Decimal.zero;

/// Parse input user: "15,9" / "15.900" / "1.234,5" → Decimal. null jika tidak valid.
Decimal? parseTon(String? input) {
  if (input == null) return null;
  var s = input.trim().replaceAll(' ', '');
  if (s.isEmpty) return null;
  final hasComma = s.contains(',');
  final dots = '.'.allMatches(s).length;
  if (hasComma) {
    // format Indonesia: titik = ribuan, koma = desimal
    s = s.replaceAll('.', '').replaceAll(',', '.');
  } else if (dots > 1) {
    s = s.replaceAll('.', '');
  }
  return Decimal.tryParse(s);
}

Decimal dec(String? s) => (s == null || s.isEmpty) ? Decimal.zero : Decimal.parse(s);

/// String API: 3 desimal dengan titik ("15.900").
String tonApi(Decimal d) => d.toStringAsFixed(3);

final _thousands = NumberFormat('#,##0', 'en_US');

/// Tampilan Indonesia: 1.234,500
String fmtTon(Decimal? d, {int decimals = 3}) {
  if (d == null) return '-';
  final neg = d < Decimal.zero;
  final fixed = (neg ? -d : d).toStringAsFixed(decimals);
  final parts = fixed.split('.');
  final intPart = _thousands.format(int.parse(parts[0])).replaceAll(',', '.');
  final out = decimals > 0 ? '$intPart,${parts[1]}' : intPart;
  return neg ? '-$out' : out;
}

String fmtTonStr(String? s, {int decimals = 3}) => s == null ? '-' : fmtTon(dec(s), decimals: decimals);

/// Jumlah sesuai satuan produk: ton → "12,500 Ton", rit (bahan baku mentah) → "3 Rit".
String fmtQty(Decimal? d, String unit) {
  if (d == null) return '-';
  if (unit == 'rit') {
    final whole = d == d.truncate();
    return '${fmtTon(d, decimals: whole ? 0 : 3)} Rit';
  }
  return '${fmtTon(d)} Ton';
}

/// Angka saja (tanpa satuan) sesuai satuan produk.
String fmtQtyNum(Decimal d, String unit) =>
    unit == 'rit' ? fmtTon(d, decimals: d == d.truncate() ? 0 : 3) : fmtTon(d);

/// Normalisasi No. Polisi: "bg 1234 xy" → "BG1234XY"
String normalizePlate(String s) => s.toUpperCase().replaceAll(RegExp(r'[^A-Z0-9]'), '');

/// Tampilan No. Polisi: "BG1234XY" → "BG 1234 XY"
String formatPlate(String? s) {
  if (s == null || s.isEmpty) return '-';
  final m = RegExp(r'^([A-Z]{1,2})(\d{1,4})([A-Z]{0,3})$').firstMatch(normalizePlate(s));
  if (m == null) return s;
  return [m[1], m[2], m[3]].where((e) => e != null && e.isNotEmpty).join(' ');
}

/// Formatter input No. Polisi otomatis "BG 1234 XY".
class PlateInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    final raw = normalizePlate(newValue.text);
    final m = RegExp(r'^([A-Z]{0,2})(\d{0,4})([A-Z]{0,3})').firstMatch(raw);
    var out = raw;
    if (m != null) {
      out = [m[1]!, m[2]!, m[3]!].where((e) => e.isNotEmpty).join(' ');
      if (raw.length > (m[0]?.length ?? 0)) out = '$out${raw.substring(m[0]!.length)}';
    }
    if (out.length > 12) out = out.substring(0, 12);
    return TextEditingValue(text: out, selection: TextSelection.collapsed(offset: out.length));
  }
}

/// Input tonase: hanya angka + satu pemisah desimal (titik/koma), maks 3 desimal.
class TonInputFormatter extends TextInputFormatter {
  TonInputFormatter({this.decimals = 3});
  final int decimals;
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    final t = newValue.text.replaceAll('.', ',');
    final ok = RegExp('^\\d{0,7}(,\\d{0,$decimals})?\$').hasMatch(t);
    if (!ok) return oldValue;
    return newValue.copyWith(text: t);
  }
}

String tzLabel(String tz) =>
    const {'Asia/Jakarta': 'WIB', 'Asia/Makassar': 'WITA', 'Asia/Jayapura': 'WIT'}[tz] ?? 'WIB';

int tzOffsetHours(String tz) =>
    const {'Asia/Jakarta': 7, 'Asia/Makassar': 8, 'Asia/Jayapura': 9}[tz] ?? 7;

/// Tampilkan waktu sesuai zona waktu lokasi (WIB/WITA/WIT), bukan zona HP.
String fmtDateTime(DateTime? d, {String tz = 'Asia/Jakarta', bool withTz = true}) {
  if (d == null) return '-';
  final local = d.toUtc().add(Duration(hours: tzOffsetHours(tz)));
  final s = DateFormat('dd/MM/yyyy HH:mm').format(local);
  return withTz ? '$s ${tzLabel(tz)}' : s;
}

String fmtDate(DateTime d, {String tz = 'Asia/Jakarta'}) =>
    DateFormat('dd MMM yyyy', 'id').format(d.toUtc().add(Duration(hours: tzOffsetHours(tz))));

String fmtRelative(DateTime? d) {
  if (d == null) return 'belum pernah';
  final diff = DateTime.now().difference(d);
  if (diff.inSeconds < 60) return 'baru saja';
  if (diff.inMinutes < 60) return '${diff.inMinutes} menit lalu';
  if (diff.inHours < 24) return '${diff.inHours} jam lalu';
  return '${diff.inDays} hari lalu';
}

const trxTypeLabels = {
  'IN_RAW': 'Bahan Baku Masuk',
  'IN_PRODUCTION': 'Masuk – Produksi',
  'IN_SUPPLIER': 'Masuk – Supplier',
  'OUT_SALE': 'Keluar – Penjualan',
  'ADJUSTMENT': 'Penyesuaian',
  'PRODUCTION': 'Produksi/Ayakan',
  'TRANSFER_OUT': 'Transfer Keluar',
  'TRANSFER_IN': 'Transfer Masuk',
  'SHRINKAGE': 'Penyusutan',
  'VOID': 'Pembatalan (Void)',
};

const roleLabels = {
  'owner': 'Owner',
  'admin': 'Admin',
  'operator': 'Operator',
  'viewer': 'Viewer/Akuntan',
};
