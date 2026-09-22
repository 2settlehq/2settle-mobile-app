import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:settleio/services/payment_request_service.dart';

void main() {
  Future<Map<String, dynamic>> create(http.Client client) =>
      PaymentRequestService.create(
          token: 'token',
          amount: 10000,
          currency: 'NGN',
          bankCode: '000013',
          accountNumber: '0123456789',
          description: 'Invoice',
          client: client);

  test('creates a request and builds spend link from backend reference',
      () async {
    final client = MockClient((request) async {
      expect(request.url.path, '/api/payments');
      expect(request.headers['authorization'], 'Bearer token');
      final body = jsonDecode(request.body) as Map;
      expect(body['type'], 'request');
      expect(body['receiver']['accountNumber'], '0123456789');
      expect(body.containsKey('payer'), false);
      expect(body.containsKey('crypto'), false);
      return http.Response(
          '{"ok":true,"payment":{"reference":"2S-ABC123"}}', 200);
    });
    addTearDown(client.close);
    final payment = await create(client);
    expect(paymentRequestLink(payment['reference']),
        'https://spend.2settle.io/p/2S-ABC123');
  });
  test('backend errors do not produce a request or link', () async {
    final client = MockClient(
        (_) async => http.Response('{"error":"Invalid receiver"}', 400));
    addTearDown(client.close);
    await expectLater(create(client),
        throwsA(predicate((e) => '$e'.contains('Invalid receiver'))));
  });
  test('missing backend reference cannot become a local request', () async {
    final client =
        MockClient((_) async => http.Response('{"ok":true,"payment":{}}', 200));
    addTearDown(client.close);
    await expectLater(create(client), throwsFormatException);
    expect(paymentRequestLink('RCV-12345'), isEmpty);
  });
}
