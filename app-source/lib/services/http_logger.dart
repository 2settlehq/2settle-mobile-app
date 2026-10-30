import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import 'debug_error_logger.dart';

/// Debug-only HTTP client that logs every backend call the app makes.
/// Installed app-wide in main() via http.runWithClient, so the top-level
/// http.get/post helpers and http.Client() all route through it.
///
/// Query strings are dropped from the logged URL and response bodies are
/// only logged (redacted) for failures, since success bodies can carry
/// session tokens and account details.
class LoggingHttpClient extends http.BaseClient {
  LoggingHttpClient(this._inner);

  final http.Client _inner;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    final url = '${request.url.origin}${request.url.path}';
    final stopwatch = Stopwatch()..start();
    try {
      final response = await _inner.send(request);
      if (response.statusCode >= 200 && response.statusCode < 300) {
        debugPrint('[HTTP] ${request.method} $url '
            '-> ${response.statusCode} (${stopwatch.elapsedMilliseconds}ms)');
        return response;
      }
      // Buffer the error body so it can be logged and still returned intact.
      final bytes = await response.stream.toBytes();
      final body = utf8.decode(bytes, allowMalformed: true);
      debugPrint('[HTTP] ${request.method} $url '
          '-> ${response.statusCode} (${stopwatch.elapsedMilliseconds}ms) '
          'body=${redactDebugError(body)}');
      return http.StreamedResponse(
        http.ByteStream.fromBytes(bytes),
        response.statusCode,
        contentLength: bytes.length,
        request: response.request,
        headers: response.headers,
        isRedirect: response.isRedirect,
        persistentConnection: response.persistentConnection,
        reasonPhrase: response.reasonPhrase,
      );
    } catch (e) {
      debugPrint('[HTTP] ${request.method} $url '
          '-> failed (${stopwatch.elapsedMilliseconds}ms) '
          '${e.runtimeType}: ${redactDebugError(e.toString())}');
      rethrow;
    }
  }

  @override
  void close() => _inner.close();
}

/// Runs [body] with every http call logged in debug builds; a no-op wrapper
/// in release builds.
void runWithHttpLogging(void Function() body) {
  if (!kDebugMode) {
    body();
    return;
  }
  http.runWithClient(body, () => LoggingHttpClient(http.Client()));
}
