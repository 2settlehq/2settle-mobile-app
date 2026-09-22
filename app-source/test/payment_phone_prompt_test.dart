import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:settleio/components/payment_phone_prompt.dart';
import 'package:settleio/services/payment_phone_service.dart';

class FakePhoneService extends PaymentPhoneService {
  FakePhoneService()
      : super(getToken: () async => 'token', refreshToken: () async => false);
  int sends = 0;
  int links = 0;
  int checks = 0;
  bool failFirstCheck = false;
  @override
  Future<void> requestCode(String phone) async {
    sends++;
  }

  @override
  Future<void> linkPhone(String phone, String code) async {
    links++;
  }

  @override
  Future<String> requireVerifiedPhone() async {
    checks++;
    if (failFirstCheck && checks == 1)
      throw const PaymentPhoneException('Retry account check');
    return '+2348012345678';
  }
}

void main() {
  Future<void> open(WidgetTester tester, FakePhoneService service,
      void Function(String?) onResult) async {
    await tester.pumpWidget(MaterialApp(
        home: Builder(
            builder: (context) => Scaffold(
                  body: TextButton(
                      onPressed: () async {
                        final result = await showModalBottomSheet<String>(
                            context: context,
                            isScrollControlled: true,
                            builder: (_) =>
                                PaymentPhonePrompt(service: service));
                        onResult(result);
                      },
                      child: const Text('Open')),
                ))));
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
  }

  testWidgets('cancel stops the flow without linking', (tester) async {
    final service = FakePhoneService();
    addTearDown(service.close);
    var returned = false;
    await open(tester, service, (result) {
      expect(result, isNull);
      returned = true;
    });
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(returned, true);
    expect(service.links, 0);
  });

  testWidgets('Enter submits code; failed profile refresh does not reuse OTP',
      (tester) async {
    final service = FakePhoneService()..failFirstCheck = true;
    addTearDown(service.close);
    String? result;
    await open(tester, service, (phone) => result = phone);
    await tester.enterText(find.byType(TextField).first, '+2348012345678');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();
    expect(service.sends, 1);
    await tester.enterText(find.byType(TextField).last, '123456');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();
    expect(service.links, 1);
    expect(result, isNull);
    await tester.tap(find.text('Retry account check').last);
    await tester.pumpAndSettle();
    expect(service.links, 1);
    expect(result, '+2348012345678');
  });
}
