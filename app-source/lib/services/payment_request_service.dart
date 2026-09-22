import 'dart:convert';
import 'package:http/http.dart' as http;
import '/config/api_config.dart';

String paymentRequestLink(String reference) =>
    RegExp(r'^2S-[A-Z0-9]{6}$').hasMatch(reference)
        ? 'https://spend.2settle.io/p/$reference'
        : '';

class PaymentRequestService {
  static Future<Map<String, dynamic>> create({
    required String token,
    required double amount,
    required String currency,
    required String bankCode,
    required String accountNumber,
    required String description,
    http.Client? client,
  }) async {
    final httpClient = client ?? http.Client();
    try {
      final response = await httpClient
          .post(
            Uri.parse(ApiConfig.paymentsUrl),
            headers: {
              'accept': 'application/json',
              'content-type': 'application/json',
              'authorization': 'Bearer $token'
            },
            body: jsonEncode({
              'type': 'request',
              'fiatAmount': amount,
              'fiatCurrency': currency,
              'receiver': {
                'bankCode': bankCode,
                'accountNumber': accountNumber
              },
              'metadata': {'description': description}
            }),
          )
          .timeout(const Duration(seconds: 35));
      final payload = jsonDecode(response.body);
      if (payload is! Map)
        throw const FormatException('Invalid payment response.');
      if (response.statusCode < 200 ||
          response.statusCode >= 300 ||
          payload['ok'] == false ||
          payload['success'] == false) {
        throw Exception(payload['error'] ??
            payload['message'] ??
            'Could not create payment request.');
      }
      final payment = payload['payment'];
      if (payment is! Map ||
          paymentRequestLink('${payment['reference'] ?? ''}').isEmpty) {
        throw const FormatException(
            'The backend did not return a valid payment reference.');
      }
      return Map<String, dynamic>.from(payment);
    } finally {
      if (client == null) httpClient.close();
    }
  }
}
