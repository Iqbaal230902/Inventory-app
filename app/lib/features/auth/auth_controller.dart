import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../core/api_client.dart';
import '../../core/providers.dart';
import '../../data/models.dart';

enum AuthStatus { loading, loggedOut, loggedIn }

class AuthState {
  const AuthState(this.status, {this.user, this.message});
  final AuthStatus status;
  final AppUser? user;
  final String? message;
}

class AuthController extends Notifier<AuthState> {
  @override
  AuthState build() {
    unawaited(_restore());
    return const AuthState(AuthStatus.loading);
  }

  /// Sesi tetap aktif saat offline selama refresh token belum kedaluwarsa (FR-01).
  Future<void> _restore() async {
    final store = ref.read(sessionStoreProvider);
    final rt = await store.refreshToken();
    final exp = await store.refreshExpiresAt();
    final user = await store.user();
    if (rt != null && user != null && (exp == null || exp.isAfter(DateTime.now()))) {
      state = AuthState(AuthStatus.loggedIn, user: AppUser.fromJson(user));
      unawaited(_refreshProfile());
    } else {
      state = const AuthState(AuthStatus.loggedOut);
    }
  }

  Future<void> _refreshProfile() async {
    try {
      final me = await ref.read(apiProvider).get<Map<String, dynamic>>('/auth/me');
      await ref.read(sessionStoreProvider).saveUser(me);
      if (state.status == AuthStatus.loggedIn) {
        state = AuthState(AuthStatus.loggedIn, user: AppUser.fromJson(me));
      }
    } catch (_) {
      // offline — pakai profil tersimpan
    }
  }

  Future<void> login({required String serverUrl, required String username, required String password}) async {
    final store = ref.read(sessionStoreProvider);
    await store.setBaseUrl(serverUrl);
    final info = await PackageInfo.fromPlatform();
    final previous = await store.user();
    final res = await ref.read(apiProvider).post<Map<String, dynamic>>(
      '/auth/login',
      {
        'username': username.trim(),
        'password': password,
        'device_id': await store.deviceId(),
        'app_version': info.version,
      },
      Options(extra: {'noAuth': true}),
    );
    await store.saveTokens(res);
    final user = AppUser.fromJson((res['user'] as Map).cast<String, dynamic>());
    final db = ref.read(dbProvider);
    if (previous != null && previous['id'] != user.id) {
      await db.clearMasterCache();
      await db.setKv('last_pull_server_time', '');
    }
    state = AuthState(AuthStatus.loggedIn, user: user);
    // Unduh master data penuh setelah login.
    unawaited(ref.read(syncEngineProvider).sync(fullPull: true));
  }

  /// Logout diblokir bila masih ada transaksi belum tersinkron (PRD 10).
  Future<void> logout({bool force = false}) async {
    final pending = await ref.read(dbProvider).watchPendingCount().first;
    if (pending > 0 && !force) {
      throw ApiException('PENDING_DATA',
          'Masih ada $pending transaksi belum tersinkron. Sinkronkan dulu sebelum logout.');
    }
    final store = ref.read(sessionStoreProvider);
    final rt = await store.refreshToken();
    if (rt != null) {
      try {
        await ref.read(apiProvider).post('/auth/logout', {'refresh_token': rt}, Options(extra: {'noAuth': true}));
      } catch (_) {}
    }
    await store.clearSession();
    state = const AuthState(AuthStatus.loggedOut);
  }

  Future<void> sessionExpired(String message) async {
    if (state.status != AuthStatus.loggedIn) return;
    await ref.read(sessionStoreProvider).clearSession();
    state = AuthState(AuthStatus.loggedOut, message: message);
  }
}

final authProvider = NotifierProvider<AuthController, AuthState>(AuthController.new);
