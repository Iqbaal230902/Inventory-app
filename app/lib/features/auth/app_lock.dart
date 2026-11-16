import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:local_auth/local_auth.dart';

import '../../core/providers.dart';
import '../../core/widgets.dart';
import 'auth_controller.dart';

/// App dikunci bila ditinggal (di background / ditutup) minimal selama ini (default 5 menit).
/// Untuk pengujian bisa dipersingkat: --dart-define=APP_LOCK_SECONDS=10
const appLockAfter = Duration(seconds: int.fromEnvironment('APP_LOCK_SECONDS', defaultValue: 300));

const _kLastBackground = 'last_background_at';
const _kLockEnabled = 'biometric_lock_enabled';

/// Preferensi "Kunci dengan biometrik" (default aktif), disimpan di DB lokal terenkripsi.
class BiometricLockPref extends Notifier<bool> {
  @override
  bool build() {
    ref.read(dbProvider).getKv(_kLockEnabled).then((v) {
      if (v != null && ref.mounted) state = v != '0';
    });
    return true;
  }

  Future<void> set(bool v) async {
    state = v;
    await ref.read(dbProvider).setKv(_kLockEnabled, v ? '1' : '0');
  }
}

final biometricLockPrefProvider = NotifierProvider<BiometricLockPref, bool>(BiometricLockPref.new);

/// Apakah HP punya sidik jari / Face ID / PIN layar yang bisa dipakai.
final deviceAuthSupportedProvider = FutureProvider<bool>((ref) async {
  try {
    return await LocalAuthentication().isDeviceSupported();
  } catch (_) {
    return false;
  }
});

/// Membungkus seluruh app. Saat user sudah login lalu meninggalkan app ≥ 5 menit
/// (pindah app, layar mati, atau app ditutup), app dikunci dan harus dibuka dengan
/// sidik jari / Face ID (atau PIN layar HP sebagai cadangan). Sesi login tidak berakhir.
class AppLockGate extends ConsumerStatefulWidget {
  const AppLockGate({super.key, required this.child});
  final Widget child;
  @override
  ConsumerState<AppLockGate> createState() => _AppLockGateState();
}

class _AppLockGateState extends ConsumerState<AppLockGate> with WidgetsBindingObserver {
  final _auth = LocalAuthentication();
  bool _locked = false;
  bool _authenticating = false;
  DateTime? _backgroundAt;
  String? _error;
  bool _confirmLogout = false;

  /// App sempat benar-benar ke background saat terkunci → tampilkan prompt lagi saat kembali.
  /// (Prompt biometrik hanya membuat app `inactive`, jadi membatalkannya tidak memicu prompt ulang.)
  bool _hiddenWhileLocked = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Cold start: cek kapan terakhir app ditinggalkan.
    unawaited(_checkColdStart());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  bool get _loggedIn => ref.read(authProvider).status == AuthStatus.loggedIn;

  Future<void> _checkColdStart() async {
    final v = await ref.read(dbProvider).getKv(_kLastBackground);
    final last = v == null || v.isEmpty ? null : DateTime.tryParse(v);
    if (last == null) return;
    // Tunggu status login selesai dipulihkan.
    var auth = ref.read(authProvider);
    while (auth.status == AuthStatus.loading && mounted) {
      await Future<void>.delayed(const Duration(milliseconds: 100));
      auth = ref.read(authProvider);
    }
    if (mounted && auth.status == AuthStatus.loggedIn && DateTime.now().difference(last) >= appLockAfter) {
      await _lock();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Dialog biometrik sendiri bisa memicu perubahan lifecycle — abaikan.
    if (_authenticating) return;
    switch (state) {
      case AppLifecycleState.paused:
      case AppLifecycleState.hidden:
        if (_locked) _hiddenWhileLocked = true;
        if (_loggedIn && !_locked && _backgroundAt == null) {
          _backgroundAt = DateTime.now();
          unawaited(ref.read(dbProvider).setKv(_kLastBackground, _backgroundAt!.toIso8601String()));
        }
      case AppLifecycleState.resumed:
        final at = _backgroundAt;
        _backgroundAt = null;
        if (_locked) {
          if (_hiddenWhileLocked) {
            _hiddenWhileLocked = false;
            unawaited(_unlock());
          }
        } else if (at != null && _loggedIn && DateTime.now().difference(at) >= appLockAfter) {
          unawaited(_lock());
        }
      default:
        break;
    }
  }

  Future<void> _lock() async {
    if (!ref.read(biometricLockPrefProvider)) return;
    if (!await ref.read(deviceAuthSupportedProvider.future)) return;
    if (!mounted) return;
    setState(() {
      _locked = true;
      _error = null;
    });
    await _unlock();
  }

  Future<void> _unlock() async {
    if (_authenticating || !_locked) return;
    setState(() {
      _authenticating = true;
      _error = null;
    });
    try {
      final ok = await _auth.authenticate(
        localizedReason: 'Buka aplikasi dengan sidik jari / Face ID',
        persistAcrossBackgrounding: true,
      );
      if (ok) await _markUnlocked();
    } on LocalAuthException catch (e) {
      if (e.code == LocalAuthExceptionCode.noBiometricHardware ||
          e.code == LocalAuthExceptionCode.noCredentialsSet ||
          e.code == LocalAuthExceptionCode.noBiometricsEnrolled) {
        // Tidak ada metode kunci di HP — jangan kunci user keluar dari app.
        await _markUnlocked();
      } else if (e.code != LocalAuthExceptionCode.userCanceled &&
          e.code != LocalAuthExceptionCode.systemCanceled &&
          mounted) {
        setState(() => _error = switch (e.code) {
              LocalAuthExceptionCode.temporaryLockout ||
              LocalAuthExceptionCode.biometricLockout =>
                'Terlalu banyak percobaan. Tunggu sebentar lalu coba lagi.',
              _ => 'Verifikasi gagal. Coba lagi.',
            });
      }
    } catch (e) {
      if (mounted) setState(() => _error = 'Verifikasi gagal. Coba lagi.');
    } finally {
      if (mounted) setState(() => _authenticating = false);
    }
  }

  Future<void> _markUnlocked() async {
    await ref.read(dbProvider).setKv(_kLastBackground, '');
    if (mounted) setState(() => _locked = false);
  }

  /// Cadangan bila biometrik tidak bisa dipakai: keluar akun lalu login dengan password.
  /// (Konfirmasi ditampilkan langsung di layar kunci — gate ini berada di atas Navigator.)
  Future<void> _usePassword() async {
    if (!_confirmLogout) {
      setState(() => _confirmLogout = true);
      return;
    }
    setState(() => _confirmLogout = false);
    try {
      await ref.read(authProvider.notifier).logout();
      await _markUnlocked();
    } catch (e) {
      if (mounted) setState(() => _error = errorText(e));
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(authProvider, (prev, next) {
      // Login baru atau logout — app tidak perlu terkunci.
      if (next.status != AuthStatus.loggedIn && _locked) setState(() => _locked = false);
    });
    return Stack(children: [
      // Saat terkunci, isi app di bawahnya tidak boleh terbaca (mis. oleh pembaca layar).
      ExcludeSemantics(excluding: _locked, child: widget.child),
      if (_locked)
        Positioned.fill(
          child: _LockScreen(
            name: ref.watch(currentUserProvider)?.name,
            busy: _authenticating,
            error: _error,
            confirmLogout: _confirmLogout,
            onUnlock: _unlock,
            onUsePassword: _usePassword,
            onCancelLogout: () => setState(() => _confirmLogout = false),
          ),
        ),
    ]);
  }
}

class _LockScreen extends StatelessWidget {
  const _LockScreen({
    required this.name,
    required this.busy,
    required this.error,
    required this.confirmLogout,
    required this.onUnlock,
    required this.onUsePassword,
    required this.onCancelLogout,
  });
  final String? name;
  final bool busy;
  final String? error;
  final VoidCallback onUnlock;
  final VoidCallback onUsePassword;
  final VoidCallback onCancelLogout;
  final bool confirmLogout;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Material(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(children: [
            const Spacer(),
            const AppLogo(size: 112),
            const SizedBox(height: 20),
            Text(companyName,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
            const SizedBox(height: 6),
            Text(name == null ? 'Aplikasi terkunci' : 'Halo, $name',
                style: TextStyle(color: cs.onSurfaceVariant)),
            const SizedBox(height: 40),
            Icon(Icons.fingerprint_rounded, size: 72, color: cs.primary),
            const SizedBox(height: 12),
            Text('Buka dengan sidik jari / Face ID', style: TextStyle(color: cs.onSurfaceVariant)),
            if (error != null) ...[
              const SizedBox(height: 12),
              Text(error!, textAlign: TextAlign.center, style: TextStyle(color: cs.error)),
            ],
            const Spacer(),
            if (confirmLogout) ...[
              Text('Keluar dari akun ini dan login ulang dengan username & password?',
                  textAlign: TextAlign.center, style: TextStyle(color: cs.onSurfaceVariant)),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(child: OutlinedButton(onPressed: onCancelLogout, child: const Text('Batal'))),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    style: FilledButton.styleFrom(backgroundColor: cs.error),
                    onPressed: onUsePassword,
                    child: const Text('Keluar'),
                  ),
                ),
              ]),
            ] else ...[
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: busy ? null : onUnlock,
                  icon: const Icon(Icons.lock_open_rounded),
                  label: const Text('Buka Kunci'),
                ),
              ),
              const SizedBox(height: 8),
              TextButton(onPressed: busy ? null : onUsePassword, child: const Text('Masuk dengan password')),
            ],
          ]),
        ),
      ),
    );
  }
}
