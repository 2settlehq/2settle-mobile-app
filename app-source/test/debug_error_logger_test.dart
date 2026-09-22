import 'package:flutter_test/flutter_test.dart';
import '../lib/services/debug_error_logger.dart';

void main() {
  test('debug error text redacts account and credential values', () {
    final result = redactDebugError(
        'pin=1234 Bearer abc.def.ghi account 0123456789 a@b.com');
    for (final secret in ['1234', 'abc.def.ghi', '0123456789', 'a@b.com']) {
      expect(result, isNot(contains(secret)));
    }
    expect(redactDebugError('Validation failed'), 'Validation failed');
  });
}
