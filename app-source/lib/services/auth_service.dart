import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '/config/api_config.dart';

class AuthResult {
  const AuthResult.success() : success = true, error = null;
  const AuthResult.failure(this.error) : success = false;

  final bool success;
  final String? error;
}

class AuthService {
  AuthService._();

  static const _accessTokenKey = '2settle_access_token';
  static const _refreshTokenKey = '2settle_refresh_token';

  /// [channel] is `'email'` or `'phone'`; [identifier] is the email address
  /// or normalized phone number to send the login code to.
  static Future<AuthResult> requestOtp(String channel, String identifier) async {
    try {
      final response = await http
          .post(
            Uri.parse(ApiConfig.authOtpRequestUrl),
            headers: const {
              'accept': 'application/json',
              'content-type': 'application/json',
            },
            body: jsonEncode({'channel': channel, 'identifier': identifier}),
          )
          .timeout(const Duration(seconds: 12));
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return const AuthResult.success();
      }
      return AuthResult.failure(
        _errorMessage(_decode(response.body), 'Could not send code. Try again.'),
      );
    } catch (_) {
      return const AuthResult.failure(
        'Could not reach the server. Check your connection.',
      );
    }
  }

  static Future<AuthResult> verifyOtp(
    String channel,
    String identifier,
    String code,
  ) async {
    try {
      final response = await http
          .post(
            Uri.parse(ApiConfig.authOtpVerifyUrl),
            headers: const {
              'accept': 'application/json',
              'content-type': 'application/json',
            },
            body: jsonEncode({
              'channel': channel,
              'identifier': identifier,
              'code': code,
            }),
          )
          .timeout(const Duration(seconds: 12));
      final payload = _decode(response.body);
      if (response.statusCode >= 200 && response.statusCode < 300) {
        final data = payload['data'];
        if (data is Map) {
          await _saveSession(
            accessToken: data['accessToken']?.toString(),
            refreshToken: data['refreshToken']?.toString(),
          );
        }
        return const AuthResult.success();
      }
      return AuthResult.failure(
        _errorMessage(payload, 'Incorrect code. Try again.'),
      );
    } catch (_) {
      return const AuthResult.failure(
        'Could not reach the server. Check your connection.',
      );
    }
  }

  static Future<void> logout() async {
    final refreshToken = await getRefreshToken();
    if (refreshToken != null && refreshToken.isNotEmpty) {
      try {
        await http
            .post(
              Uri.parse(ApiConfig.authLogoutUrl),
              headers: const {
                'accept': 'application/json',
                'content-type': 'application/json',
              },
              body: jsonEncode({'refreshToken': refreshToken}),
            )
            .timeout(const Duration(seconds: 8));
      } catch (_) {}
    }
    await clearSession();
  }

  static Future<void> _saveSession({
    String? accessToken,
    String? refreshToken,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    if (accessToken != null && accessToken.isNotEmpty) {
      await prefs.setString(_accessTokenKey, accessToken);
    }
    if (refreshToken != null && refreshToken.isNotEmpty) {
      await prefs.setString(_refreshTokenKey, refreshToken);
    }
  }

  static Future<void> clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_accessTokenKey);
    await prefs.remove(_refreshTokenKey);
  }

  static Future<String?> getAccessToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_accessTokenKey);
  }

  static Future<String?> getRefreshToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_refreshTokenKey);
  }

  static Future<bool> isLoggedIn() async {
    final token = await getAccessToken();
    return token != null && token.isNotEmpty;
  }

  static Map<String, dynamic> _decode(String body) {
    if (body.isEmpty) return const {};
    try {
      final decoded = jsonDecode(body);
      return decoded is Map<String, dynamic> ? decoded : const {};
    } catch (_) {
      return const {};
    }
  }

  static String _errorMessage(Map<String, dynamic> payload, String fallback) {
    final error = payload['error'];
    if (error is String && error.isNotEmpty) return error;
    final message = payload['message'];
    if (message is String && message.isNotEmpty) return message;
    return fallback;
  }
}
