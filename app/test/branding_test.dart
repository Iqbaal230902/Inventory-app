import 'package:esc_pos_utils_plus/esc_pos_utils_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pasir_silika/features/delivery_note/company_branding.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('nama PT default bila profil perusahaan kosong', () {
    expect(companyNameOf({}), 'PT Berkah Azzura Mandiri');
    expect(companyNameOf({'company_name': '  '}), 'PT Berkah Azzura Mandiri');
    expect(companyNameOf({'company_name': 'PT Lain'}), 'PT Lain');
  });

  test('logo bawaan dipakai bila logo belum diunggah / tidak valid', () async {
    final a = await companyLogoBytes({});
    final b = await companyLogoBytes({'company_logo_base64': '%%%bukan-base64'});
    // Signature PNG
    expect(a.sublist(0, 4), [0x89, 0x50, 0x4E, 0x47]);
    expect(b, a);
  });

  for (final (paper, width) in [(PaperSize.mm58, 384), (PaperSize.mm80, 576)]) {
    testWidgets('kop thermal ${width}px: logo + nama PT jadi gambar ESC/POS', (tester) async {
      await tester.runAsync(() async {
        final header = await thermalHeaderImage(
          logo: await companyLogoBytes({}),
          name: 'PT Berkah Azzura Mandiri',
          widthPx: width,
        );
        expect(header.width, width);
        expect(header.height, greaterThanOrEqualTo(96));
        // Area logo (kiri) dan area teks (kanan) sama-sama berisi piksel gelap.
        bool hasInk(int x0, int x1) {
          for (var y = 0; y < header.height; y++) {
            for (var x = x0; x < x1; x++) {
              if (header.getPixel(x, y).luminance < 100) return true;
            }
          }
          return false;
        }
        expect(hasInk(0, 96), isTrue, reason: 'logo');
        expect(hasInk(110, width), isTrue, reason: 'nama PT');

        final g = Generator(paper, await CapabilityProfile.load());
        expect(g.image(header), isNotEmpty);
      });
    });
  }
}
