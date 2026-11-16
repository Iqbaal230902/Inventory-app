import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/auth/auth_controller.dart';
import '../features/auth/login_screen.dart';
import '../features/dashboard/dashboard_screen.dart';
import '../features/delivery_note/print_screen.dart';
import '../features/master_data/master_screens.dart';
import '../features/settings/printer_settings_screen.dart';
import '../features/settings/settings_screen.dart';
import '../features/sync_status/sync_status_screen.dart';
import '../features/transactions/detail_screen.dart';
import '../features/transactions/history_screen.dart';
import '../features/transactions/trx_form_screen.dart';
import '../features/users/users_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final refresh = ValueNotifier(0);
  ref.listen(authProvider, (_, _) => refresh.value++);
  ref.onDispose(refresh.dispose);

  return GoRouter(
    initialLocation: '/',
    refreshListenable: refresh,
    redirect: (context, state) {
      final auth = ref.read(authProvider);
      final atLogin = state.matchedLocation == '/login';
      if (auth.status == AuthStatus.loading) return state.matchedLocation == '/splash' ? null : '/splash';
      if (auth.status == AuthStatus.loggedOut) return atLogin ? null : '/login';
      if (atLogin || state.matchedLocation == '/splash') return '/';
      // Guard berbasis role
      final user = auth.user!;
      final loc = state.matchedLocation;
      if (loc.startsWith('/users') && !user.isOwner) return '/';
      if (loc.startsWith('/master') && !user.isManager && loc != '/master') return '/master';
      if (loc.startsWith('/trx/new') && !user.canInput) return '/';
      return null;
    },
    routes: [
      GoRoute(path: '/splash', builder: (_, _) => const SplashScreen()),
      GoRoute(path: '/login', builder: (_, _) => const LoginScreen()),
      StatefulShellRoute.indexedStack(
        builder: (context, state, shell) => HomeShell(shell: shell),
        branches: [
          StatefulShellBranch(routes: [GoRoute(path: '/', builder: (_, _) => const DashboardScreen())]),
          StatefulShellBranch(routes: [GoRoute(path: '/history', builder: (_, s) => HistoryScreen(initialQuery: s.uri.queryParameters))]),
          StatefulShellBranch(routes: [GoRoute(path: '/sync', builder: (_, _) => const SyncStatusScreen())]),
          StatefulShellBranch(routes: [GoRoute(path: '/more', builder: (_, _) => const SettingsScreen())]),
        ],
      ),
      GoRoute(
        path: '/trx/new/:type',
        builder: (_, s) => TrxFormScreen(type: s.pathParameters['type']!, editLocalUuid: s.uri.queryParameters['local']),
      ),
      GoRoute(
        path: '/trx/edit/:id',
        builder: (_, s) => TrxFormScreen(type: '', editServerId: int.parse(s.pathParameters['id']!)),
      ),
      // key = "s123" (id server) atau UUID lokal
      GoRoute(path: '/trx/:key', builder: (_, s) => TrxDetailScreen(trxKey: s.pathParameters['key']!)),
      GoRoute(path: '/trx/:key/print', builder: (_, s) => PrintScreen(trxKey: s.pathParameters['key']!)),
      GoRoute(path: '/master', builder: (_, _) => const MasterMenuScreen()),
      GoRoute(path: '/master/:entity', builder: (_, s) => MasterListScreen(entity: s.pathParameters['entity']!)),
      GoRoute(path: '/users', builder: (_, _) => const UsersScreen()),
      GoRoute(path: '/settings/printer', builder: (_, _) => const PrinterSettingsScreen()),
      GoRoute(path: '/settings/company', builder: (_, _) => const CompanySettingsScreen()),
    ],
  );
});

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});
  @override
  Widget build(BuildContext context) => const Scaffold(body: Center(child: CircularProgressIndicator()));
}

class HomeShell extends StatelessWidget {
  const HomeShell({super.key, required this.shell});
  final StatefulNavigationShell shell;

  static const _items = [
    (Icons.home_outlined, Icons.home_rounded, 'Stok'),
    (Icons.receipt_long_outlined, Icons.receipt_long_rounded, 'Riwayat'),
    (Icons.sync_rounded, Icons.sync_rounded, 'Sinkron'),
    (Icons.person_outline_rounded, Icons.person_rounded, 'Pengaturan'),
  ];

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    // Tombol back di tab Riwayat / Sinkron / Pengaturan kembali ke tab Stok;
    // di tab Stok, back menutup aplikasi seperti biasa.
    return PopScope(
      canPop: shell.currentIndex == 0,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) shell.goBranch(0);
      },
      child: Scaffold(
        body: shell,
        extendBody: false,
        // Navigasi "pill" dengan indikator lingkaran (design system).
        bottomNavigationBar: SafeArea(
          minimum: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          child: Container(
            height: 70,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(
              color: cs.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(35),
              boxShadow: [BoxShadow(color: cs.shadow, blurRadius: 16, offset: const Offset(0, 4))],
            ),
            child: Row(children: [
              for (var i = 0; i < _items.length; i++)
                Expanded(
                  child: _NavItem(
                    icon: shell.currentIndex == i ? _items[i].$2 : _items[i].$1,
                    label: _items[i].$3,
                    selected: shell.currentIndex == i,
                    onTap: () => shell.goBranch(i, initialLocation: i == shell.currentIndex),
                  ),
                ),
            ]),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({required this.icon, required this.label, required this.selected, required this.onTap});
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Semantics(
      selected: selected,
      button: true,
      label: label,
      child: InkResponse(
        onTap: onTap,
        radius: 36,
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOut,
            width: 40,
            height: 40,
            decoration: BoxDecoration(color: selected ? cs.primary : Colors.transparent, shape: BoxShape.circle),
            child: Icon(icon, size: 22, color: selected ? cs.onPrimary : cs.onSurfaceVariant),
          ),
          const SizedBox(height: 2),
          Text(label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                color: selected ? cs.primary : cs.onSurfaceVariant,
              )),
        ]),
      ),
    );
  }
}
