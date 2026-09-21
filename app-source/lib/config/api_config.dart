/// Central place for the mobile API base URL.
///
/// Defaults to the deployed Vercel instance. Override at build/run time to
/// point at a local `mobile-api` instance instead, e.g.:
///   flutter run --dart-define=API_BASE_URL=http://10.0.2.2:3000   (Android emulator)
///   flutter run --dart-define=API_BASE_URL=http://localhost:3000  (iOS simulator, web, desktop)
class ApiConfig {
  ApiConfig._();

  /// The mobile-api gateway (Vercel). Holds the HMAC signing secret for
  /// payment-engine, so banks/gifts/payments must go through it rather than
  /// calling payment-engine directly.
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://2settlemobile.vercel.app',
  );

  /// payment-engine's real domain. Only its public routes (end-user
  /// email/phone/wallet/Google auth) are safe to call directly from the
  /// app — they don't require the HMAC secret that only mobile-api holds.
  static const String authBaseUrl = String.fromEnvironment(
    'AUTH_API_BASE_URL',
    defaultValue: 'https://api.2settle.io',
  );

  static const String rateUrl = '$baseUrl/api/rate';
  // Public bank-code list. Not yet proxied through the mobile-api gateway
  // (unlike rateUrl/banksResolveUrl) — this is a different upstream host
  // (bare 2settle.io, not api.2settle.io) that hasn't been confirmed as a
  // payment-engine route, so this only centralizes the literal URL rather
  // than routing it through mobile-api. Proxying it is a reasonable
  // follow-up once someone who owns that endpoint confirms its contract.
  static const String banksListUrl =
      'https://2settle.io/api/banks?country=NG&limit=50';
  static const String banksResolveUrl = '$baseUrl/api/banks/resolve';
  static const String giftsBaseUrl = '$baseUrl/api/gifts';
  static const String paymentsUrl = '$baseUrl/api/payments';
  static const String paymentsEstimateUrl = '$baseUrl/api/payments/estimate';

  static const String authOtpRequestUrl = '$authBaseUrl/v1/users/auth/otp/request';
  static const String authOtpVerifyUrl = '$authBaseUrl/v1/users/auth/otp/verify';
  static const String authRefreshUrl = '$authBaseUrl/v1/users/auth/refresh';
  static const String authLogoutUrl = '$authBaseUrl/v1/users/auth/logout';
  static const String userMeUrl = '$authBaseUrl/v1/users/me';
}
