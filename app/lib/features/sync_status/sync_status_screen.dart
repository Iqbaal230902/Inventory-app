import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/format.dart';
import '../../core/providers.dart';
import '../../core/theme.dart';
import '../../core/widgets.dart';
import '../../data/local/database.dart';

final _unsyncedProvider = StreamProvider((ref) => ref.watch(trxRepoProvider).watchUnsynced());
final _lastErrorProvider = StreamProvider((ref) => ref.watch(dbProvider).watchKv('last_sync_error'));

/// Layar 9 — Status sinkronisasi: daftar pending/gagal, alasan, kirim ulang.
class SyncStatusScreen extends ConsumerWidget {
  const SyncStatusScreen({super.key});

  Future<void> _syncNow(BuildContext context, WidgetRef ref) async {
    final r = await ref.read(syncEngineProvider).sync();
    if (context.mounted) showSnack(context, r.summary, error: !r.ok && !(r.error?.isNetwork ?? false));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rows = ref.watch(_unsyncedProvider).value ?? const <LocalTransaction>[];
    final online = ref.watch(onlineProvider).value ?? false;
    final running = ref.watch(syncRunningProvider).value ?? false;
    final lastSync = ref.watch(lastSyncProvider).value;
    final lastError = ref.watch(_lastErrorProvider).value;
    final repo = ref.watch(trxRepoProvider);
    final pending = rows.where((r) => r.syncState == SyncState.pending).length;
    final rejected = rows.where((r) => r.syncState == SyncState.rejected).length;
    final oldest = rows.isEmpty ? null : rows.map((r) => r.clientCreatedAt).reduce((a, b) => a.isBefore(b) ? a : b);
    final stale = oldest != null && DateTime.now().difference(oldest).inHours >= 24;

    return Scaffold(
      appBar: AppBar(title: const Text('Sinkronisasi')),
      body: RefreshIndicator(
        onRefresh: () => _syncNow(context, ref),
        child: ListView(padding: const EdgeInsets.all(16), children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Icon(online ? Icons.cloud_done : Icons.cloud_off, color: online ? AppColors.ok : AppColors.warning, size: 32),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(online ? 'Online' : 'Offline', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                      Text('Sinkron terakhir: ${fmtRelative(lastSync)}'),
                    ]),
                  ),
                ]),
                const SizedBox(height: 12),
                Row(children: [
                  Expanded(child: _Stat('$pending', 'Menunggu kirim', AppColors.warning)),
                  Expanded(child: _Stat('$rejected', 'Ditolak server', AppColors.critical)),
                ]),
                if (stale) ...[
                  const SizedBox(height: 12),
                  const Pill('Ada data belum tersinkron lebih dari 24 jam!', icon: Icons.warning, color: AppColors.critical),
                ],
                if ((lastError ?? '').isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text('Error terakhir: $lastError', style: TextStyle(color: Theme.of(context).colorScheme.error)),
                ],
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: running ? null : () => _syncNow(context, ref),
                    icon: running
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2.5))
                        : const Icon(Icons.sync),
                    label: Text(running ? 'Menyinkronkan…' : 'Sinkron Sekarang'),
                  ),
                ),
              ]),
            ),
          ),
          if (rows.isEmpty)
            const Padding(
              padding: EdgeInsets.only(top: 32),
              child: EmptyState(icon: Icons.check_circle_outline, message: 'Semua transaksi sudah tersinkron.'),
            )
          else ...[
            SectionTitle('Belum tersinkron'),
            ...rows.map((r) {
              final t = repo.view(r);
              final rejected = r.syncState == SyncState.rejected;
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  onTap: () => context.push('/trx/${r.clientUuid}'),
                  leading: Icon(rejected ? Icons.error : Icons.schedule,
                      color: rejected ? AppColors.critical : AppColors.warning),
                  title: Text('${r.tmpDocNo} · ${fmtTon(t.totalTon)} Ton'),
                  subtitle: Text([
                    '${t.typeLabel} · ${fmtDateTime(r.clientCreatedAt, tz: t.timezone)}',
                    if (rejected) 'Alasan: ${r.errorMessage}',
                    if (r.attempts > 0 && !rejected) 'Percobaan: ${r.attempts}',
                  ].join('\n')),
                  isThreeLine: rejected,
                  trailing: rejected
                      ? IconButton(
                          tooltip: 'Kirim ulang',
                          icon: const Icon(Icons.refresh),
                          onPressed: () async {
                            await ref.read(trxRepoProvider).retry(r.clientUuid);
                            if (context.mounted) await _syncNow(context, ref);
                          },
                        )
                      : null,
                ),
              );
            }),
          ],
        ]),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat(this.value, this.label, this.color);
  final String value;
  final String label;
  final Color color;
  @override
  Widget build(BuildContext context) => Column(children: [
        Text(value, style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: color)),
        Text(label),
      ]);
}
