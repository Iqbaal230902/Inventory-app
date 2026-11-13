import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:printing/printing.dart';

import '../../core/api_client.dart';
import '../../core/providers.dart';
import '../../core/widgets.dart';
import '../../data/models.dart';
import '../transactions/detail_screen.dart';
import 'delivery_note_pdf.dart';
import 'thermal_printer.dart';

/// Layar 6 — Preview & cetak surat jalan: printer thermal Bluetooth, PDF, bagikan WhatsApp.
class PrintScreen extends ConsumerStatefulWidget {
  const PrintScreen({super.key, required this.trxKey});
  final String trxKey;
  @override
  ConsumerState<PrintScreen> createState() => _PrintScreenState();
}

class _PrintScreenState extends ConsumerState<PrintScreen> {
  bool _busy = false;

  /// Catat setiap cetak (audit log server). Cetak ke-2 dst diberi label COPY.
  Future<void> _recordPrint(TrxView t, String channel) async {
    final repo = ref.read(trxRepoProvider);
    if (t.id != null) {
      try {
        await ref.read(apiProvider).post('/transactions/${t.id}/print', {'channel': channel});
        if (t.local != null) await repo.recordPrint(t.clientUuid, reported: true);
        return;
      } on ApiException catch (e) {
        if (!e.isNetwork) rethrow;
      }
    }
    // Offline: dicatat lokal, dilaporkan ke server saat sinkron.
    await repo.recordPrint(t.clientUuid, reported: false);
  }

  Future<Map<String, String>> _company() async => ref.read(masterRepoProvider).settings();

  Future<void> _run(TrxView t, Future<void> Function(bool copy) fn, String channel) async {
    setState(() => _busy = true);
    try {
      // COPY ditentukan dari jumlah cetak sebelumnya; dicatat SETELAH cetak berhasil.
      await fn(t.printCount > 0);
      await _recordPrint(t, channel);
      ref.invalidate(trxDetailProvider(widget.trxKey));
    } catch (e) {
      if (mounted) showSnack(context, e is ThermalPrinterException ? e.message : errorText(e), error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _thermal(TrxView t) async {
    final db = ref.read(dbProvider);
    final mac = await db.getKv('printer_mac');
    if (mac == null || mac.isEmpty) {
      if (mounted) {
        showSnack(context, 'Pilih printer Bluetooth terlebih dahulu.');
        context.push('/settings/printer');
      }
      return;
    }
    final mm80 = (await db.getKv('printer_paper')) == '80';
    final base = await ref.read(sessionStoreProvider).baseUrl();
    final company = await _company();
    await _run(t, (copy) async {
      final bytes = await ThermalPrinter.deliveryNote(t: t, company: company, apiBase: base, copy: copy, mm80: mm80);
      await ThermalPrinter.printBytes(mac, bytes);
      if (mounted) showSnack(context, 'Surat jalan dikirim ke printer.');
    }, 'thermal');
  }

  Future<void> _pdf(TrxView t, {required bool share}) async {
    final base = await ref.read(sessionStoreProvider).baseUrl();
    final company = await _company();
    await _run(t, (copy) async {
      final bytes = await buildDeliveryNotePdf(t: t, company: company, apiBase: base, copy: copy);
      final name = 'SJ-${t.docNo.replaceAll('/', '-')}.pdf';
      if (share) {
        await Printing.sharePdf(bytes: bytes, filename: name);
      } else {
        await Printing.layoutPdf(onLayout: (_) async => bytes, name: name);
      }
    }, share ? 'share_pdf' : 'pdf');
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(trxDetailProvider(widget.trxKey));
    return Scaffold(
      appBar: AppBar(
        title: const Text('Surat Jalan'),
        actions: [
          IconButton(
            tooltip: 'Detail transaksi',
            icon: const Icon(Icons.receipt_long),
            onPressed: () => context.pushReplacement('/trx/${widget.trxKey}'),
          ),
        ],
      ),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => ErrorView(e),
        data: (t) => FutureBuilder(
          future: Future.wait([_company(), ref.read(sessionStoreProvider).baseUrl()]),
          builder: (context, snap) {
            if (!snap.hasData) return const Center(child: CircularProgressIndicator());
            final company = snap.data![0] as Map<String, String>;
            final base = snap.data![1] as String;
            return Column(children: [
              if (t.printCount > 0)
                const Padding(
                  padding: EdgeInsets.all(8),
                  child: Pill('Sudah pernah dicetak — cetakan berikutnya ditandai COPY', icon: Icons.content_copy),
                ),
              Expanded(
                child: PdfPreview(
                  build: (_) => buildDeliveryNotePdf(t: t, company: company, apiBase: base, copy: t.printCount > 0),
                  allowPrinting: false,
                  allowSharing: false,
                  canChangePageFormat: false,
                  canChangeOrientation: false,
                  canDebug: false,
                  pdfFileName: 'SJ.pdf',
                ),
              ),
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                  child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                    FilledButton.icon(
                      onPressed: _busy ? null : () => _thermal(t),
                      icon: const Icon(Icons.print),
                      label: const Text('Cetak ke printer thermal'),
                    ),
                    const SizedBox(height: 8),
                    Row(children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _busy ? null : () => _pdf(t, share: true),
                          icon: const Icon(Icons.share),
                          label: const Text('Bagikan PDF'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _busy ? null : () => _pdf(t, share: false),
                          icon: const Icon(Icons.picture_as_pdf),
                          label: const Text('Cetak A5'),
                        ),
                      ),
                    ]),
                  ]),
                ),
              ),
            ]);
          },
        ),
      ),
    );
  }
}
