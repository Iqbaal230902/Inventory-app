import 'package:decimal/decimal.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pasir_silika/core/format.dart';
import 'package:pasir_silika/data/models.dart';

void main() {
  final d = Decimal.parse;

  test('fmtQty: ton 3 desimal, rit bilangan bulat', () {
    expect(fmtQty(d('12.5'), 'ton'), '12,500 Ton');
    expect(fmtQty(d('3'), 'rit'), '3 Rit');
    expect(fmtQty(d('3.000'), 'rit'), '3 Rit');
    expect(fmtQty(d('1250'), 'rit'), '1.250 Rit');
    expect(fmtQtyNum(d('4'), 'rit'), '4');
  });

  test('TrxView.qtyLabel memisahkan ton dan rit', () {
    TrxView v(String ton, String rit) =>
        TrxView({'client_uuid': 'x', 'trx_type': 'IN_RAW', 'total_ton': ton, 'total_rit': rit});
    expect(v('0.000', '3').qtyLabel, '3 Rit');
    expect(v('15.900', '0').qtyLabel, '15,900 Ton');
    expect(v('2.000', '1').qtyLabel, '2,000 Ton + 1 Rit');
    // Data lama tanpa total_rit tetap tampil dalam ton.
    expect(TrxView({'client_uuid': 'x', 'trx_type': 'OUT_SALE', 'total_ton': '5.000'}).qtyLabel, '5,000 Ton');
  });

  test('item tanpa unit dianggap ton (kompatibel data lama)', () {
    expect(TrxItemView({'qty_ton': '1.000'}).unit, 'ton');
    expect(TrxItemView({'qty_ton': '2.000', 'unit': 'rit'}).isRit, isTrue);
  });
}
