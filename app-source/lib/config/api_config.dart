/// Central place for the mobile API base URL.
///
/// Defaults to the deployed Vercel instance. Override at build/run time to
/// point at a local `mobile-api` instance instead, e.g.:
///   flutter run --dart-define=API_BASE_URL=http://10.0.2.2:3000   (Android emulator)
///   flutter run --dart-define=API_BASE_URL=http://localhost:3000  (iOS simulator, web, desktop)
class ApiConfig {
  ApiConfig._();

  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://2settlemobile.vercel.app',
  );

  static const String banksResolveUrl = '$baseUrl/api/banks/resolve';
  static const String giftsBaseUrl = '$baseUrl/api/gifts';
  static const String paymentsUrl = '$baseUrl/api/payments';
}
