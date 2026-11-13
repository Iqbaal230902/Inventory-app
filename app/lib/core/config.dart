class AppConfig {
  /// Atur saat build: flutter run --dart-define=API_BASE_URL=https://api.contoh.co.id/api/v1
  /// Default 10.0.2.2 = localhost komputer dari emulator Android.
  static const defaultApiBaseUrl =
      String.fromEnvironment('API_BASE_URL', defaultValue: 'http://10.0.2.2:3000/api/v1');

  /// Interval sinkron foreground (PRD: tiap 5 menit) & auto-refresh dashboard (30 detik).
  static const syncInterval = Duration(minutes: 5);
  static const dashboardRefresh = Duration(seconds: 30);
  static const pushBatchSize = 50;
}
