import 'dart:async';

import 'package:dio/dio.dart';

import 'session_store.dart';

/// Error API dalam format standar { error: { code, message, details } }.
class ApiException implements Exception {
  ApiException(this.code, this.message, {this.status, this.details});
  final String code;
  final String message;
  final int? status;
  final dynamic details;

  /// Tidak ada koneksi / timeout — transaksi harus tetap di antrian.
  bool get isNetwork => code == 'NETWORK';

  @override
  String toString() => message;

  static ApiException from(Object e) {
    if (e is ApiException) return e;
    if (e is DioException) {
      final data = e.response?.data;
      if (data is Map && data['error'] is Map) {
        final err = data['error'] as Map;
        return ApiException(
          '${err['code']}',
          '${err['message']}',
          status: e.response?.statusCode,
          details: err['details'],
        );
      }
      if (e.response == null) {
        return ApiException('NETWORK', 'Tidak dapat terhubung ke server. Periksa koneksi internet.');
      }
      return ApiException('HTTP_${e.response?.statusCode}', 'Server mengembalikan kesalahan (${e.response?.statusCode}).',
          status: e.response?.statusCode);
    }
    return ApiException('UNKNOWN', e.toString());
  }
}

/// Dio dengan token JWT, header perangkat, dan refresh token otomatis (single-flight).
class ApiClient {
  ApiClient(this.store, {this.onSessionExpired}) {
    dio = Dio(BaseOptions(
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 30),
      sendTimeout: const Duration(seconds: 30),
      contentType: 'application/json',
    ));
    dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        options.baseUrl = await store.baseUrl();
        final token = await store.accessToken();
        if (token != null && options.extra['noAuth'] != true) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        options.headers['X-Device-Id'] = await store.deviceId();
        handler.next(options);
      },
      onError: (e, handler) async {
        final status = e.response?.statusCode;
        final code = (e.response?.data is Map) ? (e.response?.data['error']?['code']) : null;
        final retried = e.requestOptions.extra['retried'] == true;
        if (status == 401 && code == 'UNAUTHENTICATED' && !retried && e.requestOptions.extra['noAuth'] != true) {
          try {
            await _refresh();
          } catch (err) {
            // Refresh gagal karena jaringan → jangan logout; biarkan request gagal sebagai NETWORK.
            final refreshRejected =
                (err is DioException && err.response?.statusCode == 401) || err is ApiException;
            if (refreshRejected) {
              final data = err is DioException ? err.response?.data : null;
              final rc = (data is Map && data['error'] is Map) ? (data['error'] as Map)['code'] : null;
              onSessionExpired?.call(rc == 'USER_INACTIVE'
                  ? 'Akun Anda telah dinonaktifkan. Hubungi Owner.'
                  : 'Sesi berakhir, silakan login kembali.');
            }
            return handler.next(e);
          }
          try {
            final opts = e.requestOptions..extra['retried'] = true;
            opts.headers['Authorization'] = 'Bearer ${await store.accessToken()}';
            return handler.resolve(await dio.fetch(opts));
          } on DioException catch (retryErr) {
            return handler.next(retryErr);
          }
        }
        if (status == 401 && code == 'USER_INACTIVE') {
          onSessionExpired?.call(code == 'USER_INACTIVE'
              ? 'Akun Anda telah dinonaktifkan. Hubungi Owner.'
              : 'Sesi berakhir, silakan login kembali.');
        }
        handler.next(e);
      },
    ));
  }

  final SessionStore store;
  void Function(String message)? onSessionExpired;
  late final Dio dio;
  Completer<void>? _refreshing;

  Future<void> _refresh() async {
    if (_refreshing != null) return _refreshing!.future;
    final c = _refreshing = Completer<void>();
    try {
      final rt = await store.refreshToken();
      if (rt == null) throw ApiException('UNAUTHENTICATED', 'Sesi berakhir.');
      final res = await dio.post('/auth/refresh',
          data: {'refresh_token': rt}, options: Options(extra: {'noAuth': true}));
      await store.saveTokens(res.data as Map<String, dynamic>);
      c.complete();
    } catch (e) {
      c.completeError(e);
      rethrow;
    } finally {
      _refreshing = null;
    }
  }

  Future<T> _wrap<T>(Future<Response> Function() fn) async {
    try {
      final r = await fn();
      return r.data as T;
    } catch (e) {
      throw ApiException.from(e);
    }
  }

  Future<T> get<T>(String path, {Map<String, dynamic>? query}) =>
      _wrap(() => dio.get(path,
          queryParameters: query == null ? null : (Map.of(query)..removeWhere((k, v) => v == null || v == ''))));
  Future<T> post<T>(String path, [Object? data, Options? options]) =>
      _wrap(() => dio.post(path, data: data, options: options));
  Future<T> put<T>(String path, [Object? data]) => _wrap(() => dio.put(path, data: data));
  Future<T> patch<T>(String path, [Object? data]) => _wrap(() => dio.patch(path, data: data));
  Future<T> delete<T>(String path) => _wrap(() => dio.delete(path));

  Future<List<int>> getBytes(String path) => _wrap(() => dio.get<List<int>>(path,
      options: Options(responseType: ResponseType.bytes)));
}
