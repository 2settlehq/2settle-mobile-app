import 'dart:convert';

class PaymentEstimateResult {
  const PaymentEstimateResult._({this.estimate, this.error});

  final Map<String, String>? estimate;
  final String? error;

  static const unavailable =
      'Unable to estimate this payment. Please try again.';

  factory PaymentEstimateResult.fromResponse(int statusCode, String body) {
    dynamic payload;
    try {
      payload = jsonDecode(body);
    } catch (_) {
      return const PaymentEstimateResult._(error: unavailable);
    }
    if (payload is! Map) {
      return const PaymentEstimateResult._(error: unavailable);
    }
    if (statusCode < 200 ||
        statusCode >= 300 ||
        payload['ok'] == false ||
        payload['success'] == false) {
      final error = payload['error'];
      final candidates = [
        if (error is String) error,
        if (error is Map) error['message'],
        payload['message'],
      ];
      for (final message in candidates) {
        if (message is String && message.trim().isNotEmpty) {
          return PaymentEstimateResult._(error: message.trim());
        }
      }
      return const PaymentEstimateResult._(error: unavailable);
    }
    final estimate = payload['estimate'];
    if (estimate is! Map) {
      return const PaymentEstimateResult._(error: unavailable);
    }
    final cryptoAmount = double.tryParse('${estimate['cryptoAmount']}');
    if (cryptoAmount == null || !cryptoAmount.isFinite || cryptoAmount <= 0) {
      return const PaymentEstimateResult._(error: unavailable);
    }
    return PaymentEstimateResult._(
      estimate: estimate.map((key, value) => MapEntry('$key', '$value')),
    );
  }
}
