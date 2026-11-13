import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/api_client.dart';
import '../../core/format.dart';
import '../../core/providers.dart';
import '../../core/widgets.dart';
import '../../data/local/database.dart';
import '../../data/models.dart';
import 'history_screen.dart';

/// Muat transaksi berdasarkan key: "s123" = id server, selain itu = UUID transaksi lokal.
/// Bila online & sudah tersinkron, detail lengkap (audit trail, izin) diambil dari server.
final trxDetailProvider = FutureProvider.autoDispose.family<TrxView, String>((ref, key) async {
  final repo = ref.watch(trxRepoProvider);
  final api = ref.watch(apiProvider);
  LocalTransaction? local;
  int? serverId;
  if (key.startsWith('s')) {
    serverId = int.parse(key.substring(1));
  } else {
    local = await repo.get(key);
    serverId = local?.serverId;
  }
  if (serverId != null) {
    try {
      final j = await api.get<Map<String, dynamic>>('/transactions/$serverId');
      await repo.cacheServerTrx(j, 0);
      return TrxView(j, local: local == null ? null : await repo.get(local.clientUuid));
    } on ApiException catch (e) {
      if (!e.isNetwork || local == null) rethrow;
    }
  }
  if (local == null) throw ApiException('NOT_FOUND', 'Transaksi tidak ditemukan.');
  return repo.view(local);
});

final _localRowProvider = StreamProvider.autoDispose
    .family<LocalTransaction?, String>((ref, uuid) => ref.watch(trxRepoProvider).watch(uuid));

/// Layar 8 — Detail transaksi: data lengkap, jejak audit, aksi sesuai role.
class TrxDetailScreen extends ConsumerWidget {
  const TrxDetailScreen({super.key, required this.trxKey});
  final String trxKey;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(trxDetailProvider(trxKey));
    // Muat ulang saat status sinkron baris lokal berubah.
    if (!trxKey.startsWith('s')) {
      ref.listen(_localRowProvider(trxKey), (p, n) {
        if (p?.value?.syncState != n.value?.syncState) ref.invalidate(trxDetailProvider(trxKey));
      });
    }
    return Scaffold(
      appBar: AppBar(title: const Text('Detail Transaksi')),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => ErrorView(e, onRetry: () => ref.invalidate(trxDetailProvider(trxKey))),
        data: (t) => RefreshIndicator(
          onRefresh: () async => ref.invalidate(trxDetailProvider(trxKey)),
          child: _DetailBody(t: t, trxKey: trxKey),
        ),
      ),
    );
  }
}

class _DetailBody extends ConsumerWidget {
  const _DetailBody({required this.t, required this.trxKey});
  final TrxView t;
  final String trxKey;

  Future<void> _action(BuildContext context, WidgetRef ref, Future<void> Function() fn, String ok) async {
    try {
      await fn();
      ref.invalidate(trxDetailProvider(trxKey));
      ref.read(syncEngineProvider).sync();
      if (context.mounted) showSnack(context, ok);
    } catch (e) {
      if (context.mounted) showSnack(context, errorText(e), error: true);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final perm = t.permissions;
    final api = ref.read(apiProvider);
    final cs = Theme.of(context).colorScheme;
    final user = ref.watch(currentUserProvider);
    final local = t.local;

    return ListView(padding: const EdgeInsets.fromLTRB(16, 12, 16, 32), children: [
      Text(t.docNo, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800)),
      if (t.isTemporaryNo)
        const Text('Nomor sementara — nomor resmi diberikan server setelah sinkron.', style: TextStyle(fontSize: 12)),
      const SizedBox(height: 6),
      Wrap(spacing: 6, runSpacing: 6, children: [Pill(t.typeLabel), ...TrxStatusPills.of(t)]),
      if (local?.syncState == SyncState.rejected) ...[
        const SizedBox(height: 12),
        Card(
          color: cs.errorContainer,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Text('Ditolak server: ${local!.errorMessage}', style: TextStyle(color: cs.onErrorContainer)),
          ),
        ),
      ],
      if (t.isVoid) KeyValueRow('Alasan void', t.voidReason),
      if (t.voidRequested) KeyValueRow('Pengajuan void', t.j['void_request_reason'] as String?),
      if (t.reviewNote != null) KeyValueRow('Catatan tinjauan', t.reviewNote),
      const SizedBox(height: 8),

      // ---- Aksi ----
      Wrap(spacing: 8, runSpacing: 8, children: [
        if (t.isOut && !t.isVoid)
          FilledButton.icon(
            onPressed: () => context.push('/trx/${local?.clientUuid ?? trxKey}/print'),
            icon: const Icon(Icons.print),
            label: Text(t.printCount > 0 ? 'Cetak ulang SJ' : 'Cetak SJ'),
          ),
        if (local != null && t.needsSync && local.createdBy == user?.id)
          OutlinedButton.icon(
            onPressed: () => context.push('/trx/new/${t.trxType}?local=${local.clientUuid}'),
            icon: const Icon(Icons.edit),
            label: const Text('Perbaiki'),
          ),
        if (local?.syncState == SyncState.rejected)
          OutlinedButton.icon(
            onPressed: () => _action(context, ref, () => ref.read(trxRepoProvider).retry(local!.clientUuid), 'Dikirim ulang.'),
            icon: const Icon(Icons.refresh),
            label: const Text('Kirim ulang'),
          ),
        if (perm['can_edit'] == true)
          OutlinedButton.icon(
            onPressed: () async {
              final changed = await context.push<bool>('/trx/edit/${t.id}');
              if (changed == true) ref.invalidate(trxDetailProvider(trxKey));
            },
            icon: const Icon(Icons.edit),
            label: const Text('Edit'),
          ),
        if (perm['can_approve'] == true)
          OutlinedButton.icon(
            onPressed: () async {
              final ok = await confirmDialog(context,
                  title: 'Tandai sudah ditinjau?',
                  message: 'Transaksi diterima saat stok server tidak cukup. Pastikan sudah dicek fisik.');
              if (!ok || !context.mounted) return;
              await _action(context, ref, () => api.post('/transactions/${t.id}/approve', {}), 'Transaksi disetujui.');
            },
            icon: const Icon(Icons.verified),
            label: const Text('Setujui'),
          ),
        if (perm['can_void'] == true || perm['can_request_void'] == true)
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(foregroundColor: cs.error),
            onPressed: () async {
              final owner = perm['can_void'] == true;
              final reason = await promptText(context,
                  title: owner ? 'Void transaksi' : 'Ajukan void ke Owner',
                  label: 'Alasan (wajib)',
                  ok: owner ? 'Void' : 'Ajukan');
              if (reason == null || !context.mounted) return;
              await _action(context, ref, () => api.post('/transactions/${t.id}/void', {'reason': reason}),
                  owner ? 'Transaksi di-void. Mutasi pembalik dibuat.' : 'Pengajuan void dikirim ke Owner.');
            },
            icon: const Icon(Icons.block),
            label: Text(perm['can_void'] == true ? 'Void' : 'Ajukan void'),
          ),
      ]),
      if (t.isLocked)
        const Padding(
          padding: EdgeInsets.only(top: 8),
          child: Text('Transaksi terkunci (lewat H+1). Koreksi hanya lewat Penyesuaian.', style: TextStyle(fontSize: 12)),
        ),

      SectionTitle('Data transaksi'),
      Card(
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(children: [
            KeyValueRow('Tanggal', fmtDateTime(t.trxAt, tz: t.timezone)),
            KeyValueRow('Lokasi', t.locationName),
            if (t.partnerName != null) KeyValueRow(t.isOut ? 'Pelanggan' : 'Supplier', t.partnerName),
            if (t.plateNumber != null) KeyValueRow('No. Polisi', formatPlate(t.plateNumber)),
            if (t.driverName != null) KeyValueRow('Sopir', t.driverName),
            if (t.manualDocNo != null) KeyValueRow('No. SJ manual', t.manualDocNo),
            if (t.grossTon != null) KeyValueRow('Bruto', '${fmtTon(t.grossTon)} Ton'),
            if (t.tareTon != null) KeyValueRow('Tara', '${fmtTon(t.tareTon)} Ton'),
            if (t.netTon != null) KeyValueRow('Netto', '${fmtTon(t.netTon)} Ton', bold: true),
            if (t.notes != null) KeyValueRow('Catatan', t.notes),
            if (t.j['ref_transaction'] != null) KeyValueRow('Referensi', (t.j['ref_transaction'] as Map)['doc_no'] as String?),
            if (t.j['void_transaction'] != null) KeyValueRow('Dokumen void', (t.j['void_transaction'] as Map)['doc_no'] as String?),
          ]),
        ),
      ),
      SectionTitle('Produk'),
      ...t.items.map((i) => Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              title: Text(i.productName, style: const TextStyle(fontWeight: FontWeight.w700)),
              subtitle: Text([
                i.packagingName ?? 'Curah',
                if (i.packageQty != null) '× ${fmtTonStr(i.packageQty, decimals: 0)}',
                if (t.trxType == 'ADJUSTMENT' || t.trxType == 'VOID') (i.direction == 'in' ? 'tambah' : 'kurang'),
              ].join(' ')),
              trailing: Text('${fmtTon(i.qtyTon)} Ton', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
            ),
          )),
      if (t.hasPhoto && t.id != null) _ServerPhoto(id: t.id!),
      if (local?.photoPath != null && File(local!.photoPath!).existsSync() && !t.hasPhoto)
        Padding(
          padding: const EdgeInsets.only(top: 8),
          child: ClipRRect(borderRadius: BorderRadius.circular(12), child: Image.file(File(local.photoPath!))),
        ),

      SectionTitle('Jejak audit'),
      Card(
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(children: [
            KeyValueRow('Diinput oleh', t.createdByName),
            KeyValueRow('Dibuat di perangkat', fmtDateTime(t.clientCreatedAt, tz: t.timezone)),
            KeyValueRow('Diterima server', t.createdAt == null ? 'Belum (menunggu sinkron)' : fmtDateTime(t.createdAt, tz: t.timezone)),
            if (t.deviceId != null) KeyValueRow('ID perangkat', t.deviceId),
            KeyValueRow('Jumlah cetak', '${t.printCount}×'),
          ]),
        ),
      ),
      if (t.history.isNotEmpty) ...[
        SectionTitle('Riwayat perubahan'),
        ...t.history.map((h) => _HistoryTile(h: h, tz: t.timezone)),
      ],
    ]);
  }
}

class _HistoryTile extends StatelessWidget {
  const _HistoryTile({required this.h, required this.tz});
  final Map<String, dynamic> h;
  final String tz;

  static const _labels = {
    'create': 'Dibuat',
    'update': 'Diubah',
    'void': 'Di-void',
    'void_request': 'Diajukan void',
    'approve': 'Disetujui',
    'print': 'Dicetak',
    'photo': 'Foto diunggah',
  };

  @override
  Widget build(BuildContext context) {
    final action = h['action'] as String;
    final nv = h['new_values'];
    String? detail;
    if (nv is Map) {
      detail = (nv['reason'] ?? nv['note'] ?? (nv['channel'] != null ? 'via ${nv['channel']}' : null))?.toString();
    }
    return ExpansionTile(
      tilePadding: EdgeInsets.zero,
      leading: const Icon(Icons.history),
      title: Text('${_labels[action] ?? action} · ${h['user_name'] ?? '-'}'),
      subtitle: Text([fmtDateTime(DateTime.tryParse('${h['created_at']}'), tz: tz), ?detail].join('\n')),
      children: [
        if (h['old_values'] != null) _json('Sebelum', h['old_values']),
        if (nv != null) _json('Sesudah', nv),
      ],
    );
  }

  Widget _json(String label, Object v) => Align(
        alignment: Alignment.centerLeft,
        child: Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Text('$label: ${const JsonEncoder.withIndent('  ').convert(v)}',
              style: const TextStyle(fontFamily: 'monospace', fontSize: 11)),
        ),
      );
}

final _photoProvider = FutureProvider.autoDispose.family<Uint8List, int>((ref, id) async {
  final bytes = await ref.watch(apiProvider).getBytes('/transactions/$id/photo');
  return Uint8List.fromList(bytes);
});

class _ServerPhoto extends ConsumerWidget {
  const _ServerPhoto({required this.id});
  final int id;
  @override
  Widget build(BuildContext context, WidgetRef ref) => ref.watch(_photoProvider(id)).when(
        data: (b) => Padding(
          padding: const EdgeInsets.only(top: 8),
          child: ClipRRect(borderRadius: BorderRadius.circular(12), child: Image.memory(b)),
        ),
        loading: () => const Padding(padding: EdgeInsets.all(16), child: LinearProgressIndicator()),
        error: (_, _) => const ListTile(leading: Icon(Icons.broken_image), title: Text('Foto tidak dapat dimuat')),
      );
}
