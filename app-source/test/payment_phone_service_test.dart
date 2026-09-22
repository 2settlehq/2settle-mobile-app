import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:settleio/services/payment_phone_service.dart';

http.Response profile(List<Object> identities) => http.Response(
    jsonEncode({
      'success': true,
      'data': {
        'user': {'id': 'current-user'},
        'identities': identities
      },
    }),
    200);

void main() {
  test('uses a verified backend phone regardless of login identity', () async {
    final service = PaymentPhoneService(
        getToken: () async => 'current-token',
        refreshToken: () async => false,
        client: MockClient((request) async {
          expect(request.headers['authorization'], 'Bearer current-token');
          expect(request.url.path, '/v1/users/me');
          return profile([
            {'type': 'email', 'identifier': 'a@b.com', 'verifiedAt': 'today'},
            {
              'type': 'phone',
              'identifier': '+2348012345678',
              'verifiedAt': 'today'
            },
          ]);
        }));
    addTearDown(service.close);
    expect(await service.verifiedPhone(), '+2348012345678');
  });

  test('unverified phone requires linking; malformed profile is an error',
      () async {
    var malformed = false;
    final service = PaymentPhoneService(
        getToken: () async => 'token',
        refreshToken: () async => false,
        client: MockClient((_) async => malformed
            ? http.Response('{}', 200)
            : profile([
                {
                  'type': 'phone',
                  'identifier': '+2348012345678',
                  'verifiedAt': null
                }
              ])));
    addTearDown(service.close);
    expect(await service.verifiedPhone(), isNull);
    malformed = true;
    await expectLater(
        service.verifiedPhone(), throwsA(isA<PaymentPhoneException>()));
  });

  test('requests public OTP and links to current account without logging in',
      () async {
    final requests = <http.Request>[];
    final service = PaymentPhoneService(
        getToken: () async => 'current-token',
        refreshToken: () async => false,
        client: MockClient((request) async {
          requests.add(request);
          return http.Response('{"success":true}', 200);
        }));
    addTearDown(service.close);
    await service.requestCode('+234 801 234 5678');
    await service.linkPhone('+234 801 234 5678', '123456');
    expect(requests[0].url.path, '/v1/users/auth/otp/request');
    expect(requests[0].headers.containsKey('authorization'), false);
    expect(requests[1].url.path, '/v1/users/me/identities/otp/verify');
    expect(requests[1].headers['authorization'], 'Bearer current-token');
    expect(jsonDecode(requests[1].body), {
      'channel': 'phone',
      'identifier': '+2348012345678',
      'code': '123456',
    });
  });

  test('preserves backend conflict message', () async {
    final service = PaymentPhoneService(
        getToken: () async => 'token',
        refreshToken: () async => false,
        client: MockClient((_) async => http.Response(
            '{"error":"Phone is linked to another account"}', 409)));
    addTearDown(service.close);
    await expectLater(
        service.linkPhone('+2348012345678', '123456'),
        throwsA(isA<PaymentPhoneException>().having((e) => e.message, 'message',
            'Phone is linked to another account')));
  });

  test('refreshes expired token and retries profile lookup once', () async {
    var token = 'expired';
    var refreshes = 0;
    final service = PaymentPhoneService(
        getToken: () async => token,
        refreshToken: () async {
          refreshes++;
          token = 'fresh';
          return true;
        },
        client: MockClient((request) async =>
            request.headers['authorization'] == 'Bearer fresh'
                ? profile([])
                : http.Response('{"error":"Expired"}', 401)));
    addTearDown(service.close);
    expect(await service.verifiedPhone(), isNull);
    expect(refreshes, 1);
  });

  test('lookup failure does not become a missing-phone result', () async {
    final service = PaymentPhoneService(
        getToken: () async => 'token',
        refreshToken: () async => false,
        client: MockClient(
            (_) async => http.Response('{"error":"Server unavailable"}', 503)));
    addTearDown(service.close);
    await expectLater(
        service.verifiedPhone(), throwsA(isA<PaymentPhoneException>()));
  });

  test('requires explicit country code rather than guessing for local numbers',
      () {
    expect(PaymentPhoneService.normalizePhone('+234 (801) 234-5678'),
        '+2348012345678');
    expect(() => PaymentPhoneService.normalizePhone('08012345678'),
        throwsA(isA<PaymentPhoneException>()));
  });
}
