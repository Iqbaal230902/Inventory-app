import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'core/providers.dart';
import 'core/router.dart';
import 'core/theme.dart';
import 'data/local/database.dart';
import 'sync/background.dart';
import 'sync/sync_lifecycle.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('id');
  final db = await openAppDatabase();
  try {
    await registerBackgroundSync();
  } catch (_) {
    // WorkManager tidak tersedia (mis. test) — sinkron foreground tetap jalan.
  }
  runApp(ProviderScope(
    // Jangan retry otomatis provider yang error (mis. offline) — UI menampilkan tombol coba lagi.
    retry: (_, _) => null,
    overrides: [dbProvider.overrideWithValue(db)],
    child: const SilikaApp(),
  ));
}

class SilikaApp extends ConsumerWidget {
  const SilikaApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final mode = ref.watch(themeModeProvider);
    return SyncLifecycle(
      child: MaterialApp.router(
        title: 'Pasir Silika',
        debugShowCheckedModeBanner: false,
        theme: buildTheme(Brightness.light),
        darkTheme: buildTheme(Brightness.dark),
        themeMode: mode,
        routerConfig: router,
        locale: const Locale('id'),
        supportedLocales: const [Locale('id'), Locale('en')],
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
      ),
    );
  }
}

class ThemeModeNotifier extends Notifier<ThemeMode> {
  @override
  ThemeMode build() {
    ref.read(dbProvider).getKv('theme_mode').then((v) {
      if (v != null && ref.mounted) state = ThemeMode.values.byName(v);
    });
    return ThemeMode.system;
  }

  void set(ThemeMode m) {
    state = m;
    ref.read(dbProvider).setKv('theme_mode', m.name);
  }
}

final themeModeProvider = NotifierProvider<ThemeModeNotifier, ThemeMode>(ThemeModeNotifier.new);
