import 'dart:convert';
import 'dart:ui' as ui;

import 'package:flutter/painting.dart';
import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;

import '../../core/widgets.dart';

/// Nama PT di kop surat jalan (dari Profil Perusahaan; default nama PT bawaan).
String companyNameOf(Map<String, String> company) {
  final n = (company['company_name'] ?? '').trim();
  return n.isEmpty ? companyName : n;
}

/// Logo kop surat jalan: logo yang diunggah di Profil Perusahaan, atau logo PT bawaan aplikasi.
Future<Uint8List> companyLogoBytes(Map<String, String> company) async {
  final b64 = company['company_logo_base64'] ?? '';
  if (b64.isNotEmpty) {
    try {
      return base64Decode(b64.replaceFirst(RegExp(r'^data:.*?;base64,'), ''));
    } catch (_) {
      // logo tidak valid — pakai logo bawaan
    }
  }
  final data = await rootBundle.load('assets/branding/logo.png');
  return data.buffer.asUint8List();
}

/// Kop untuk printer thermal: logo di kiri + nama PT di sampingnya, digambar sebagai satu
/// gambar selebar kertas (58 mm = 384 titik, 80 mm = 576 titik) agar bisa dicetak ESC/POS.
Future<img.Image> thermalHeaderImage({
  required Uint8List logo,
  required String name,
  required int widthPx,
}) async {
  const logoPx = 96.0;
  const gap = 12.0;
  final textWidth = widthPx - logoPx - gap;

  final para = (ui.ParagraphBuilder(ui.ParagraphStyle(fontSize: widthPx >= 576 ? 30 : 24, fontWeight: FontWeight.w800))
        ..pushStyle(ui.TextStyle(color: const Color(0xFF000000)))
        ..addText(name))
      .build()
    ..layout(ui.ParagraphConstraints(width: textWidth));
  final height = (para.height > logoPx ? para.height : logoPx).ceil();

  final codec = await ui.instantiateImageCodec(logo, targetWidth: logoPx.toInt(), targetHeight: logoPx.toInt());
  final logoImg = (await codec.getNextFrame()).image;

  final recorder = ui.PictureRecorder();
  Canvas(recorder)
    ..drawRect(Rect.fromLTWH(0, 0, widthPx.toDouble(), height.toDouble()), Paint()..color = const Color(0xFFFFFFFF))
    ..drawImage(logoImg, Offset(0, (height - logoPx) / 2), Paint())
    ..drawParagraph(para, Offset(logoPx + gap, (height - para.height) / 2));
  final pic = recorder.endRecording();
  final rendered = await pic.toImage(widthPx, height);
  final bytes = await rendered.toByteData(format: ui.ImageByteFormat.rawRgba);
  logoImg.dispose();
  rendered.dispose();
  return img.Image.fromBytes(
    width: widthPx,
    height: height,
    bytes: bytes!.buffer,
    numChannels: 4,
    order: img.ChannelOrder.rgba,
  );
}
