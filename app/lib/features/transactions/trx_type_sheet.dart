import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/providers.dart';
import '../../core/theme.dart';

/// Layar 3 — pilih jenis transaksi dengan tombol besar.
void showTrxTypeSheet(BuildContext context, WidgetRef ref) {
  final user = ref.read(currentUserProvider);
  showModalBottomSheet(
    context: context,
    showDragHandle: true,
    builder: (c) {
      Widget big(String type, String title, String sub, IconData icon, Color color) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Material(
              color: Theme.of(c).colorScheme.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(18),
              child: InkWell(
                borderRadius: BorderRadius.circular(18),
                onTap: () {
                  Navigator.pop(c);
                  context.push('/trx/new/$type');
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  child: Row(children: [
                    IconCircle(icon, color: color, size: 48),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
                        Text(sub, style: TextStyle(color: Theme.of(c).colorScheme.onSurfaceVariant)),
                      ]),
                    ),
                    const Icon(Icons.chevron_right),
                  ]),
                ),
              ),
            ),
          );
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: Text('Transaksi baru', style: Theme.of(c).textTheme.titleLarge),
            ),
            big('OUT_SALE', 'Barang Keluar', 'Penjualan + surat jalan', Icons.local_shipping_rounded, AppColors.primary),
            big('IN_PRODUCTION', 'Masuk – Produksi', 'Hasil produksi internal', Icons.factory_rounded, AppColors.tertiary),
            big('IN_SUPPLIER', 'Masuk – Supplier', 'Pembelian dari supplier', Icons.inventory_rounded, AppColors.tertiary),
            if (user?.canAdjust ?? false)
              big('ADJUSTMENT', 'Penyesuaian', 'Koreksi stok (wajib alasan)', Icons.tune_rounded, AppColors.secondary),
          ]),
        ),
      );
    },
  );
}
