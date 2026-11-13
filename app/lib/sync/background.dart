import 'package:workmanager/workmanager.dart';

import '../core/api_client.dart';
import '../core/session_store.dart';
import '../data/local/database.dart';
import 'sync_engine.dart';

const backgroundSyncTask = 'silika-background-sync';

/// Entry point WorkManager — berjalan di isolate terpisah tanpa UI.
@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, input) async {
    AppDatabase? db;
    try {
      final store = SessionStore();
      if (await store.refreshToken() == null) return true; // belum login
      db = await openAppDatabase();
      final engine = SyncEngine(
        db: db,
        api: ApiClient(store),
        currentUserId: () async => (await store.user())?['id'] as int?,
      );
      final r = await engine.sync();
      // false → WorkManager akan mencoba lagi dengan backoff (mis. jaringan putus)
      return r.ok || (r.error?.isNetwork ?? false);
    } catch (_) {
      return false;
    } finally {
      await db?.close();
    }
  });
}

/// Android membatasi periodic work minimal 15 menit; saat app terbuka, sinkron
/// foreground berjalan tiap 5 menit (lihat SyncLifecycle).
Future<void> registerBackgroundSync() async {
  await Workmanager().initialize(callbackDispatcher);
  await Workmanager().registerPeriodicTask(
    backgroundSyncTask,
    backgroundSyncTask,
    frequency: const Duration(minutes: 15),
    constraints: Constraints(networkType: NetworkType.connected),
    existingWorkPolicy: ExistingPeriodicWorkPolicy.keep,
  );
}
