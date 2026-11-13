import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/local/database.dart';
import '../data/models.dart';
import '../data/repositories/master_repo.dart';
import '../data/repositories/trx_repo.dart';
import '../features/auth/auth_controller.dart';
import '../sync/sync_engine.dart';
import 'api_client.dart';
import 'session_store.dart';

/// Di-override di main() setelah database terbuka.
final dbProvider = Provider<AppDatabase>((ref) => throw UnimplementedError());

final sessionStoreProvider = Provider<SessionStore>((ref) => SessionStore());

final apiProvider = Provider<ApiClient>((ref) {
  final api = ApiClient(ref.watch(sessionStoreProvider));
  api.onSessionExpired = (msg) => ref.read(authProvider.notifier).sessionExpired(msg);
  return api;
});

final masterRepoProvider = Provider((ref) => MasterRepo(ref.watch(dbProvider)));
final trxRepoProvider = Provider((ref) => TrxRepo(ref.watch(dbProvider)));

final syncEngineProvider = Provider<SyncEngine>((ref) {
  final store = ref.watch(sessionStoreProvider);
  return SyncEngine(
    db: ref.watch(dbProvider),
    api: ref.watch(apiProvider),
    currentUserId: () async => (await store.user())?['id'] as int?,
  );
});

/// Status koneksi (true = ada jaringan). Server bisa tetap tak terjangkau; sync menangani itu.
final onlineProvider = StreamProvider<bool>((ref) async* {
  final c = Connectivity();
  bool isOn(List<ConnectivityResult> r) => r.any((x) => x != ConnectivityResult.none);
  yield isOn(await c.checkConnectivity());
  yield* c.onConnectivityChanged.map(isOn).distinct();
});

final currentUserProvider = Provider<AppUser?>((ref) => ref.watch(authProvider).user);

final pendingCountProvider = StreamProvider<int>((ref) => ref.watch(dbProvider).watchPendingCount());

final syncRunningProvider = StreamProvider<bool>((ref) => ref.watch(syncEngineProvider).runningStream);

final lastSyncProvider = StreamProvider<DateTime?>((ref) =>
    ref.watch(dbProvider).watchKv('last_sync_ok_at').map((v) => v == null ? null : DateTime.tryParse(v)));

final lastPullAtProvider = StreamProvider<DateTime?>((ref) =>
    ref.watch(dbProvider).watchKv('last_pull_at').map((v) => v == null ? null : DateTime.tryParse(v)));

final settingsProvider = StreamProvider<Map<String, String>>((ref) => ref
    .watch(dbProvider)
    .watchKv('settings')
    .asyncMap((_) => ref.read(masterRepoProvider).settings()));

/// Lokasi terpilih di dashboard (null = semua lokasi). Disimpan di KV.
class SelectedLocation extends Notifier<int?> {
  @override
  int? build() {
    final user = ref.watch(currentUserProvider);
    // Operator otomatis memakai lokasinya; lainnya default ke "Semua".
    if (user != null && user.role == 'operator' && user.locations.isNotEmpty) {
      return user.locations.first.id;
    }
    unawaited(ref.read(dbProvider).getKv('selected_location').then((v) {
      if (v != null && v.isNotEmpty && ref.mounted) state = int.tryParse(v);
    }));
    return null;
  }

  void select(int? id) {
    state = id;
    ref.read(dbProvider).setKv('selected_location', id?.toString() ?? '');
  }
}

final selectedLocationProvider = NotifierProvider<SelectedLocation, int?>(SelectedLocation.new);
