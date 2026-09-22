import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:settleio/services/payment_estimate_result.dart';

void main() {
  for (final message in [
    'Amount is below the supported minimum.',
    'Amount exceeds the supported maximum.',
  ]) {
    test('retains the server limit error: $message', () {
      final result = PaymentEstimateResult.fromResponse(
          400, jsonEncode({'ok': false, 'error': message}));
      expect(result.error, message);
      expect(result.estimate, isNull);
    });
  }

  test('rejects an application error even when HTTP status is 200', () {
    final result = PaymentEstimateResult.fromResponse(200,
        jsonEncode({'ok': false, 'error': 'Amount outside supported range.'}));
    expect(result.error, 'Amount outside supported range.');
    expect(result.estimate, isNull);
  });

  test('reads nested error messages without displaying an object', () {
    final result = PaymentEstimateResult.fromResponse(
        422,
        jsonEncode({
          'error': {'message': 'Unsupported amount.'}
        }));
    expect(result.error, 'Unsupported amount.');
  });

  test('accepts a valid estimate without inventing local limits', () {
    final result = PaymentEstimateResult.fromResponse(
        200,
        jsonEncode({
          'ok': true,
          'estimate': {
            'cryptoAmount': 3.21,
            'rate': '1500',
            'conversionFee': 10
          }
        }));
    expect(result.error, isNull);
    expect(result.estimate?['cryptoAmount'], '3.21');
    expect(result.estimate?['conversionFee'], '10');
  });

  for (final amount in [null, '', 'NaN', 'Infinity', 0, -1]) {
    test('rejects an unusable quote amount: $amount', () {
      final result = PaymentEstimateResult.fromResponse(
          200,
          jsonEncode({
            'ok': true,
            'estimate': {'cryptoAmount': amount}
          }));
      expect(result.estimate, isNull);
      expect(result.error, PaymentEstimateResult.unavailable);
    });
  }

  for (final body in ['', '<html>Service unavailable</html>', '[]', '{}']) {
    test('malformed or empty response is an error: $body', () {
      final result = PaymentEstimateResult.fromResponse(200, body);
      expect(result.estimate, isNull);
      expect(result.error, PaymentEstimateResult.unavailable);
    });
  }
}
