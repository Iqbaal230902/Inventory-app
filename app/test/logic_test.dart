import 'dart:convert';

import 'package:decimal/decimal.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pasir_silika/core/format.dart';
import 'package:pasir_silika/data/local/database.dart';
import 'package:pasir_silika/data/repositories/trx_repo.dart';
import 'package:pasir_silika/features/dashboard/dashboard_provider.dart';

Decimal d(String s) => Decimal.parse(s);

LocalTransaction row(String uuid, String type, List<Map<String, dynamic>> items,
        {String state = SyncState.pending, DateTime? syncedAt, int loc = 1}) =>
    LocalTransaction(
      clientUuid: uuid,
      payload: jsonEncode({'trx_type': type, 'items': items}),
      trxType: type,
      locationId: loc,
      tmpDocNo: 'TMP',
      syncState: state,
      attempts: 0,
      clientCreatedAt: DateTime.utc(2026, 11, 13),
      trxAt: DateTime.utc(2026, 11, 13),
      syncedAt: syncedAt,
      photoUploaded: false,
      unreportedPrints: 0,
      printCount: 0,
      createdBy: 1,
    );

void main() {
  group('parseTon', () {
    test('menerima koma & titik desimal', () {
      expect(parseTon('15,9'), d('15.9'));
      expect(parseTon('15.900'), d('15.9'));
      expect(parseTon('1.234,5'), d('1234.5'));
      expect(parseTon(' 0,05 '), d('0.05'));
      expect(parseTon(''), isNull);
      expect(parseTon('abc'), isNull);
    });

    test('netto = bruto − tara tanpa error floating point', () {
      expect(parseTon('24,350')! - parseTon('8,450')!, d('15.9'));
      // 0.1 + 0.2 yang klasik
      expect(d('0.1') + d('0.2'), d('0.3'));
    });

    test('1000 transaksi acak 3 desimal: total eksak', () {
      var sumDec = Decimal.zero;
      var sumMilli = 0;
      for (var i = 1; i <= 1000; i++) {
        final milli = (i * 7919) % 30000 + 1;
        sumMilli += milli;
        sumDec += parseTon('${milli ~/ 1000},${(milli % 1000).toString().padLeft(3, '0')}')!;
      }
      expect(tonApi(sumDec), '${sumMilli ~/ 1000}.${(sumMilli % 1000).toString().padLeft(3, '0')}');
    });
  });

  group('format', () {
    test('format tonase Indonesia', () {
      expect(fmtTon(d('15.9')), '15,900');
      expect(fmtTon(d('1234567.5')), '1.234.567,500');
      expect(fmtTon(d('-1.9')), '-1,900');
      expect(tonApi(d('15.9')), '15.900');
    });

    test('No. Polisi', () {
      expect(normalizePlate('bg 1234 xy'), 'BG1234XY');
      expect(formatPlate('BG1234XY'), 'BG 1234 XY');
      expect(formatPlate('B1XYZ'), 'B 1 XYZ');
    });

    test('zona waktu lokasi', () {
      final t = DateTime.utc(2026, 11, 13, 7, 15);
      expect(fmtDateTime(t), '13/11/2026 14:15 WIB');
      expect(fmtDateTime(t, tz: 'Asia/Makassar'), '13/11/2026 15:15 WITA');
    });
  });

  group('status stok (FR-02)', () {
    test('hijau / kuning ≤120% / merah', () {
      expect(stockStatus(d('100'), d('50')), 'ok');
      expect(stockStatus(d('60'), d('50')), 'warning');
      expect(stockStatus(d('55'), d('50')), 'warning');
      expect(stockStatus(d('49.999'), d('50')), 'critical');
      expect(stockStatus(d('10'), d('0')), 'ok');
      expect(stockStatus(d('-1'), d('0')), 'critical');
    });
  });

  group('efek transaksi lokal pada saldo offline', () {
    final pull = DateTime.utc(2026, 11, 13, 10);
    test('pending dihitung, ditolak tidak, tersinkron hanya bila setelah pull terakhir', () {
      final rows = [
        row('a', 'OUT_SALE', [{'product_id': 4, 'qty_ton': '15.900'}]),
        row('b', 'IN_PRODUCTION', [{'product_id': 4, 'qty_ton': '10.000'}]),
        row('c', 'OUT_SALE', [{'product_id': 4, 'qty_ton': '99.000'}], state: SyncState.rejected),
        row('d', 'OUT_SALE', [{'product_id': 4, 'qty_ton': '1.000'}],
            state: SyncState.synced, syncedAt: pull.subtract(const Duration(minutes: 1))),
        row('e', 'OUT_SALE', [{'product_id': 4, 'qty_ton': '2.000'}],
            state: SyncState.synced, syncedAt: pull.add(const Duration(minutes: 1))),
        row('f', 'ADJUSTMENT', [{'product_id': 5, 'qty_ton': '0.500', 'direction': 'out'}]),
      ];
      final e = TrxRepo.effects(rows, pull);
      expect(e[(1, 4)], d('-7.9')); // -15,9 + 10 - 2
      expect(e[(1, 5)], d('-0.5'));
    });
  });
}
