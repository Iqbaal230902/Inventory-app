import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/config.dart';
import '../core/providers.dart';
import '../features/auth/auth_controller.dart';

/// Memicu sinkron: saat login, saat koneksi kembali, saat app kembali ke depan,
/// dan tiap 5 menit selama app terbuka (FR-11).
class SyncLifecycle extends ConsumerStatefulWidget {
  const SyncLifecycle({super.key, required this.child});
  final Widget child;
  @override
  ConsumerState<SyncLifecycle> createState() => _SyncLifecycleState();
}

class _SyncLifecycleState extends ConsumerState<SyncLifecycle> with WidgetsBindingObserver {
  Timer? _timer;
  bool _firstSync = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _timer = Timer.periodic(AppConfig.syncInterval, (_) => _trigger());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _trigger();
  }

  void _trigger() {
    if (ref.read(authProvider).status != AuthStatus.loggedIn) return;
    final full = _firstSync;
    _firstSync = false;
    unawaited(ref.read(syncEngineProvider).sync(fullPull: full));
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(onlineProvider, (prev, next) {
      if (next.value == true && prev?.value != true) _trigger();
    });
    ref.listen(authProvider, (prev, next) {
      if (next.status == AuthStatus.loggedIn && prev?.status == AuthStatus.loading) _trigger();
    });
    return widget.child;
  }
}
