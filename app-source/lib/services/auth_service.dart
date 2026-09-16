import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '/config/api_config.dart';
import '/flutter_flow/nav/nav.dart';
import 'mobile_identity_service.dart';

class AuthResult {
  const AuthResult.success() : success = true, error = null;
  const AuthResult.failure(this.error) : success = false;

  final bool success;
  final String? error;
}

class AuthService {
  AuthService._();

  static const _secureStorage = FlutterSecureStorage();
  static const _accessTokenKey = '2settle_access_token';
  static const _refreshTokenKey = '2settle_refresh_token';

  // Profile display fields aren't secrets, so they stay in SharedPreferences.
  static const _userIdKey = '2settle_auth_user_id';
  // Same key profile_details_widget.dart / set_app_passcode_widget.dart
  // read and write, so a name synced here shows up there too.
  static const _usernameKey = '2settle_profile_username';
  static const _avatarUrlKey = '2settle_profile_avatar_url';

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
          final user = data['user'];
          await _saveSession(
            accessToken: data['accessToken']?.toString(),
            refreshToken: data['refreshToken']?.toString(),
            userId: user is Map ? user['id']?.toString() : null,
            displayName: user is Map ? user['displayName']?.toString() : null,
            avatarUrl: user is Map ? user['avatarUrl']?.toString() : null,
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

  /// Calls the backend refresh endpoint and rotates the stored tokens.
  /// Returns `true` on success. On a definitive rejection (refresh token
  /// itself invalid/expired) this clears the session and returns `false`,
  /// forcing a full re-login rather than leaving stale tokens in place. A
  /// transient network failure also returns `false` but does NOT clear the
  /// session, so a flaky connection can't strand a user mid-session.
  static Future<bool> refreshAccessToken() async {
    final refreshToken = await getRefreshToken();
    if (refreshToken == null || refreshToken.isEmpty) {
      return false;
    }
    try {
      final response = await http
          .post(
            Uri.parse(ApiConfig.authRefreshUrl),
            headers: const {
              'accept': 'application/json',
              'content-type': 'application/json',
            },
            body: jsonEncode({'refreshToken': refreshToken}),
          )
          .timeout(const Duration(seconds: 12));
      final payload = _decode(response.body);
      if (response.statusCode >= 200 && response.statusCode < 300) {
        final data = payload['data'] is Map ? payload['data'] as Map : payload;
        final newAccessToken = data['accessToken']?.toString();
        final newRefreshToken = data['refreshToken']?.toString();
        if (newAccessToken == null || newAccessToken.isEmpty) {
          return false;
        }
        await _saveSession(
          accessToken: newAccessToken,
          refreshToken: newRefreshToken,
        );
        return true;
      }
      if (response.statusCode == 401 || response.statusCode == 403) {
        // Refresh token is dead — there's no recovering this session.
        await clearSession();
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  /// Checks whether the current access token is still accepted by the
  /// server, transparently refreshing once if it's expired. Returns:
  /// - `true`  — session confirmed valid (possibly after a refresh).
  /// - `false` — session is definitively invalid; the session has already
  ///   been cleared, and the caller should force a full re-login.
  /// - `null`  — couldn't reach the server; treat as inconclusive rather
  ///   than punishing the user for a flaky connection.
  static Future<bool?> validateSession() async {
    var accessToken = await getAccessToken();
    if (accessToken == null || accessToken.isEmpty) {
      return false;
    }
    try {
      var response = await _getMe(accessToken);
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return true;
      }
      if (response.statusCode == 401) {
        final refreshed = await refreshAccessToken();
        if (!refreshed) {
          return false;
        }
        accessToken = await getAccessToken();
        if (accessToken == null || accessToken.isEmpty) {
          return false;
        }
        response = await _getMe(accessToken);
        if (response.statusCode >= 200 && response.statusCode < 300) {
          return true;
        }
        if (response.statusCode == 401) {
          await clearSession();
          return false;
        }
        return null;
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  static Future<http.Response> _getMe(String accessToken) {
    return http.get(
      Uri.parse(ApiConfig.userMeUrl),
      headers: {
        'accept': 'application/json',
        'authorization': 'Bearer $accessToken',
      },
    ).timeout(const Duration(seconds: 12));
  }

  static Future<void> _saveSession({
    String? accessToken,
    String? refreshToken,
    String? userId,
    String? displayName,
    String? avatarUrl,
  }) async {
    if (accessToken != null && accessToken.isNotEmpty) {
      await _secureStorage.write(key: _accessTokenKey, value: accessToken);
    }
    if (refreshToken != null && refreshToken.isNotEmpty) {
      await _secureStorage.write(key: _refreshTokenKey, value: refreshToken);
    }
    final prefs = await SharedPreferences.getInstance();
    if (userId != null && userId.isNotEmpty) {
      await prefs.setString(_userIdKey, userId);
    }
    // The server has no displayName/avatarUrl yet for a brand new
    // phone/email signup, so don't clobber locally-set values with null.
    if (displayName != null && displayName.isNotEmpty) {
      await prefs.setString(_usernameKey, displayName);
    }
    if (avatarUrl != null && avatarUrl.isNotEmpty) {
      await prefs.setString(_avatarUrlKey, avatarUrl);
    }
    // A valid token was just issued — the router's auth gate should open.
    AppStateNotifier.instance.setAppSessionActive(true);
  }

  /// Clears everything tied to the signed-in account: tokens, cached
  /// profile, and the last-used login identifier. Deliberately leaves the
  /// device PIN in place — it's set once on first login and gates the app
  /// locally per-device, not per-account, so a plain sign-out shouldn't
  /// force the user to re-create it on their next login.
  static Future<void> clearSession() async {
    await _secureStorage.delete(key: _accessTokenKey);
    await _secureStorage.delete(key: _refreshTokenKey);
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_userIdKey);
    await prefs.remove(_usernameKey);
    await prefs.remove(_avatarUrlKey);
    await MobileIdentityService.clearIdentity();
    AppStateNotifier.instance.setAppSessionActive(false);
  }

  static Future<String?> getAccessToken() {
    return _secureStorage.read(key: _accessTokenKey);
  }

  static Future<String?> getRefreshToken() {
    return _secureStorage.read(key: _refreshTokenKey);
  }

  /// The account's raw UUID from the server, as returned in the login
  /// payload. Display it as a short 2S-... code (see
  /// profile_details_widget.dart) rather than showing this raw form.
  static Future<String?> getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_userIdKey);
  }

  static Future<String?> getAvatarUrl() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_avatarUrlKey);
  }

  /// Push a profile change to the server and, on success, mirror it into
  /// local storage so the UI reflects it immediately.
  static Future<AuthResult> updateProfile({String? displayName, String? avatarUrl}) async {
    final accessToken = await getAccessToken();
    if (accessToken == null || accessToken.isEmpty) {
      return const AuthResult.failure('Not logged in.');
    }
    try {
      final body = <String, String>{
        if (displayName != null) 'displayName': displayName,
        if (avatarUrl != null) 'avatarUrl': avatarUrl,
      };
      final response = await http
          .patch(
            Uri.parse(ApiConfig.userMeUrl),
            headers: {
              'accept': 'application/json',
              'content-type': 'application/json',
              'authorization': 'Bearer $accessToken',
            },
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 12));
      if (response.statusCode >= 200 && response.statusCode < 300) {
        final prefs = await SharedPreferences.getInstance();
        if (displayName != null && displayName.isNotEmpty) {
          await prefs.setString(_usernameKey, displayName);
        }
        if (avatarUrl != null && avatarUrl.isNotEmpty) {
          await prefs.setString(_avatarUrlKey, avatarUrl);
        }
        return const AuthResult.success();
      }
      return AuthResult.failure(
        _errorMessage(_decode(response.body), 'Could not update profile.'),
      );
    } catch (_) {
      return const AuthResult.failure(
        'Could not reach the server. Check your connection.',
      );
    }
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
