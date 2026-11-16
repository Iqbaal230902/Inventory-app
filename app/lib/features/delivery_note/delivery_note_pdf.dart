import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../core/format.dart';
import '../../data/models.dart';
import 'company_branding.dart';

/// URL verifikasi QR — memakai client_uuid sehingga SJ yang dicetak offline
/// tetap dapat diverifikasi setelah tersinkron.
String verifyUrl(String apiBase, TrxView t) => '$apiBase/delivery-notes/verify/${t.clientUuid}';

/// PDF surat jalan A5 (FR-10). Dibuat di HP agar bisa dicetak/dibagikan saat offline.
Future<Uint8List> buildDeliveryNotePdf({
  required TrxView t,
  required Map<String, String> company,
  required String apiBase,
  required bool copy,
}) async {
  final name = companyNameOf(company);
  final doc = pw.Document(title: 'Surat Jalan ${t.docNo}', author: name);
  final logo = pw.MemoryImage(await companyLogoBytes(company));
  final contact = [company['company_address'], company['company_phone']].where((e) => (e ?? '').isNotEmpty).join(' · ');
  final small = const pw.TextStyle(fontSize: 8);
  final label = const pw.TextStyle(fontSize: 9);
  final bold = pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold);

  pw.Widget kv(String k, String v) => pw.Padding(
        padding: const pw.EdgeInsets.symmetric(vertical: 1.5),
        child: pw.Row(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
          pw.SizedBox(width: 70, child: pw.Text(k, style: label)),
          pw.Expanded(child: pw.Text(': $v', style: label)),
        ]),
      );

  doc.addPage(pw.Page(
    pageFormat: PdfPageFormat.a5,
    margin: const pw.EdgeInsets.all(24),
    build: (_) => pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.stretch, children: [
      // Kop: logo PT + nama PT di sampingnya
      pw.Row(crossAxisAlignment: pw.CrossAxisAlignment.center, children: [
        pw.Container(width: 50, height: 50, margin: const pw.EdgeInsets.only(right: 10), child: pw.Image(logo)),
        pw.Expanded(
          child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
            pw.Text(name, style: pw.TextStyle(fontSize: 15, fontWeight: pw.FontWeight.bold)),
            if (contact.isNotEmpty) pw.Text(contact, style: small),
          ]),
        ),
        pw.BarcodeWidget(barcode: pw.Barcode.qrCode(), data: verifyUrl(apiBase, t), width: 56, height: 56),
      ]),
      pw.Divider(),
      pw.Center(
        child: pw.Text(copy ? 'SURAT JALAN (COPY)' : 'SURAT JALAN',
            style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
      ),
      pw.Center(
        child: pw.Text('No. ${t.docNo}${t.manualDocNo != null ? '  ·  Manual: ${t.manualDocNo}' : ''}', style: label),
      ),
      if (t.isTemporaryNo)
        pw.Center(child: pw.Text('Nomor sementara - belum tersinkron', style: small.copyWith(color: PdfColors.red800))),
      pw.SizedBox(height: 10),
      kv('Tanggal', fmtDateTime(t.trxAt, tz: t.timezone)),
      kv('Dari', t.locationName),
      kv('Kepada', [t.partnerName, t.partnerAddress].whereType<String>().join(' - ')),
      kv('No. Polisi', formatPlate(t.plateNumber)),
      kv('Sopir', t.driverName ?? '-'),
      pw.SizedBox(height: 10),
      pw.TableHelper.fromTextArray(
        headerStyle: bold,
        cellStyle: label,
        headerDecoration: const pw.BoxDecoration(color: PdfColors.grey200),
        cellAlignments: {2: pw.Alignment.centerRight},
        headers: ['Produk', 'Kemasan', 'Jumlah'],
        data: t.items
            .map((i) => [
                  i.productName,
                  '${i.packagingName ?? 'Curah'}${i.packageQty != null ? ' × ${fmtTonStr(i.packageQty, decimals: 0)}' : ''}',
                  '${fmtTon(i.qtyTon)} Ton',
                ])
            .toList(),
      ),
      if (t.grossTon != null && t.tareTon != null) ...[
        pw.SizedBox(height: 6),
        pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
          pw.Text('Bruto: ${fmtTon(t.grossTon)} Ton', style: label),
          pw.Text('Tara: ${fmtTon(t.tareTon)} Ton', style: label),
          pw.Text('Netto: ${fmtTon(t.netTon)} Ton', style: bold),
        ]),
      ],
      if (t.notes != null) ...[pw.SizedBox(height: 6), pw.Text('Catatan: ${t.notes}', style: small)],
      pw.Spacer(),
      pw.Row(
        children: ['Pengirim', 'Sopir', 'Penerima']
            .map((s) => pw.Expanded(
                  child: pw.Column(children: [
                    pw.Text(s, style: label),
                    pw.SizedBox(height: 40),
                    pw.Text('(....................)', style: label),
                  ]),
                ))
            .toList(),
      ),
      pw.SizedBox(height: 8),
      pw.Center(
        child: pw.Text('Diinput oleh ${t.createdByName} · Scan QR untuk verifikasi keaslian',
            style: small.copyWith(color: PdfColors.grey700)),
      ),
    ]),
  ));
  return doc.save();
}
