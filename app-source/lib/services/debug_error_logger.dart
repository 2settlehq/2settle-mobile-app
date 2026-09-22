import 'package:flutter/foundation.dart';

String redactDebugError(Object? value) {
  if (value is! String) return '';
  return value
      .replaceAll(
          RegExp(
              r'''(?:token|secret|password|pin|api[_-]?key|authorization|signature)\s*[=:]\s*["']?[^\s,"';}]+''',
              caseSensitive: false),
          '[CREDENTIAL REDACTED]')
      .replaceAll(RegExp(r'https?://\S+'), '[URL REDACTED]')
      .replaceAll(
          RegExp(r'Bearer\s+\S+', caseSensitive: false), 'Bearer [REDACTED]')
      .replaceAll(RegExp(r'\b[A-Za-z0-9_\-]{24,}(?:\.[A-Za-z0-9_\-]+)*\b'),
          '[REDACTED]')
      .replaceAll(RegExp(r'\b\d{4,}\b'), '[REDACTED]')
      .replaceAll(
          RegExp(r'\b[\w.+-]+@[\w.-]+\.[A-Za-z]+\b'), '[EMAIL REDACTED]')
      .replaceAll(RegExp(r'[\r\n]'), ' ');
}

void logTransactionError(String stage,
    {int? status, Object? code, Object? message}) {
  if (!kDebugMode) return;
  debugPrint('[Transfer] $stage POST /api/payments '
      'status=${status ?? "unavailable"} '
      'code=${redactDebugError(code)} message=${redactDebugError(message)}');
}
