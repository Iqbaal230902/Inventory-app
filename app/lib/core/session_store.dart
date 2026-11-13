import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:uuid/uuid.dart';

import 'config.dart';

/// Token & identitas perangkat disimpan di flutter_secure_storage (Keystore).
class SessionStore {
  SessionStore([FlutterSecureStorage? storage]) : _s = storage ?? const FlutterSecureStorage();
  final FlutterSecureStorage _s;

  String? _accessCache;
  String? _deviceCache;
  String? _baseCache;

  Future<String?> accessToken() async => _accessCache ??= await _s.read(key: 'access_token');
  Future<String?> refreshToken() => _s.read(key: 'refresh_token');

  Future<DateTime?> refreshExpiresAt() async {
    final v = await _s.read(key: 'refresh_expires_at');
    return v == null ? null : DateTime.tryParse(v);
  }

  Future<void> saveTokens(Map<String, dynamic> res) async {
    _accessCache = res['access_token'] as String;
    await _s.write(key: 'access_token', value: _accessCache);
    await _s.write(key: 'refresh_token', value: res['refresh_token'] as String);
    await _s.write(key: 'refresh_expires_at', value: res['refresh_expires_at'] as String);
    if (res['user'] != null) await _s.write(key: 'user', value: jsonEncode(res['user']));
  }

  Future<Map<String, dynamic>?> user() async {
    final v = await _s.read(key: 'user');
    return v == null ? null : (jsonDecode(v) as Map).cast<String, dynamic>();
  }

  Future<void> saveUser(Map<String, dynamic> user) => _s.write(key: 'user', value: jsonEncode(user));

  Future<void> clearSession() async {
    _accessCache = null;
    for (final k in ['access_token', 'refresh_token', 'refresh_expires_at', 'user']) {
      await _s.delete(key: k);
    }
  }

  /// UUID instalasi aplikasi (dipakai sebagai device_id & kode nomor sementara).
  Future<String> deviceId() async {
    if (_deviceCache != null) return _deviceCache!;
    var id = await _s.read(key: 'device_id');
    if (id == null) {
      id = const Uuid().v4();
      await _s.write(key: 'device_id', value: id);
    }
    return _deviceCache = id;
  }

  Future<String> baseUrl() async => _baseCache ??= (await _s.read(key: 'base_url')) ?? AppConfig.defaultApiBaseUrl;

  Future<void> setBaseUrl(String url) async {
    var u = url.trim();
    while (u.endsWith('/')) {
      u = u.substring(0, u.length - 1);
    }
    if (!u.endsWith('/api/v1')) u = '$u/api/v1';
    _baseCache = u;
    await _s.write(key: 'base_url', value: u);
  }
}
