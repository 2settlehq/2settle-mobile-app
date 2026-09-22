import 'dart:convert';
import 'package:http/http.dart' as http;
import '/config/api_config.dart';

class PaymentPhoneException implements Exception {
  const PaymentPhoneException(this.message);
  final String message;
  @override
  String toString() => message;
}

/// Reads account identities from the backend; never uses a device fallback.
class PaymentPhoneService {
  PaymentPhoneService({
    required this.getToken,
    required this.refreshToken,
    http.Client? client,
  }) : _client = client ?? http.Client();

  final Future<String?> Function() getToken;
  final Future<bool> Function() refreshToken;
  final http.Client _client;
  void close() => _client.close();

  Future<Map<String, dynamic>> _request(String url,
      {Map<String, String>? body, bool authenticated = true}) async {
    try {
      for (var attempt = 0; attempt < 2; attempt++) {
        final token = authenticated ? await getToken() : null;
        if (authenticated && (token == null || token.isEmpty)) {
          throw const PaymentPhoneException(
              'Please sign in again to continue.');
        }
        final headers = {
          'accept': 'application/json',
          'content-type': 'application/json',
          if (authenticated) 'authorization': 'Bearer $token',
        };
        final response = await (body == null
                ? _client.get(Uri.parse(url), headers: headers)
                : _client.post(Uri.parse(url),
                    headers: headers, body: jsonEncode(body)))
            .timeout(const Duration(seconds: 12));
        if (response.statusCode == 401 &&
            authenticated &&
            attempt == 0 &&
            await refreshToken()) continue;
        final decoded = jsonDecode(response.body);
        if (decoded is! Map<String, dynamic>) throw const FormatException();
        if (response.statusCode < 200 ||
            response.statusCode >= 300 ||
            decoded['success'] == false ||
            decoded['ok'] == false) {
          final message = decoded['error'] ?? decoded['message'];
          throw PaymentPhoneException(message is String
              ? message
              : 'Could not verify your phone. Please try again.');
        }
        return decoded;
      }
      throw const PaymentPhoneException('Please sign in again to continue.');
    } on PaymentPhoneException {
      rethrow;
    } catch (_) {
      throw const PaymentPhoneException(
          'Could not reach the server or read its response. Please try again.');
    }
  }

  Future<String?> verifiedPhone() async {
    final payload = await _request(ApiConfig.userMeUrl);
    final data = payload['data'];
    if (data is! Map || data['user'] is! Map || data['identities'] is! List) {
      throw const PaymentPhoneException(
          'Could not read your account details. Please try again.');
    }
    for (final identity in data['identities'] as List) {
      if (identity is Map &&
          identity['type'] == 'phone' &&
          identity['verifiedAt'] != null &&
          '${identity['verifiedAt']}'.isNotEmpty) {
        final phone = identity['identifier'];
        if (phone is String && phone.trim().isNotEmpty) return phone.trim();
      }
    }
    return null;
  }

  static String normalizePhone(String input) {
    final phone = input.trim().replaceAll(RegExp(r'[\s()\-]'), '');
    if (!RegExp(r'^\+?[1-9]\d{6,14}$').hasMatch(phone)) {
      throw const PaymentPhoneException(
          'Enter your phone number with its country code, e.g. +2348012345678.');
    }
    return phone.startsWith('+') ? phone : '+$phone';
  }

  Future<void> requestCode(String phone) async {
    await _request(ApiConfig.authOtpRequestUrl,
        authenticated: false,
        body: {'channel': 'phone', 'identifier': normalizePhone(phone)});
  }

  Future<void> linkPhone(String phone, String code) async {
    await _request(ApiConfig.linkPhoneUrl, body: {
      'channel': 'phone',
      'identifier': normalizePhone(phone),
      'code': code.trim(),
    });
  }

  Future<String> requireVerifiedPhone() async {
    final phone = await verifiedPhone();
    if (phone == null) {
      throw const PaymentPhoneException(
          'Your account does not yet show a verified phone. Please retry.');
    }
    return phone;
  }
}
