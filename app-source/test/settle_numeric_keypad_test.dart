import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:settleio/components/settle_numeric_keypad.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    GoogleFonts.config.allowRuntimeFetching = false;
    // Use the test renderer's font rather than fetching fonts over the network.
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMessageHandler('flutter/assets', (message) async {
      final asset = const StringCodec().decodeMessage(message);
      if (asset == 'AssetManifest.bin') {
        return const StandardMessageCodec().encodeMessage({
          'Inter-ExtraBold.ttf': [
            {'asset': 'Inter-ExtraBold.ttf'}
          ],
          'Inter-Black.ttf': [
            {'asset': 'Inter-Black.ttf'}
          ],
        });
      }
      return ByteData(0);
    });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMessageHandler('flutter/assets', null);
    GoogleFonts.config.allowRuntimeFetching = true;
  });

  Future<void> openKeypad(
    WidgetTester tester,
    ValueChanged<String> onDone, {
    String initialValue = '',
    bool pin = true,
    bool amount = false,
    ValueNotifier<bool>? submitEnabled,
  }) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: Builder(builder: (context) {
          return TextButton(
            onPressed: () => SettleNumericKeypad.show(
              context,
              title: 'Code',
              initialValue: initialValue,
              onDone: onDone,
              maxLength: pin ? 4 : null,
              requiredLength: pin ? 4 : null,
              submitLabel: pin
                  ? 'Confirm'
                  : amount
                      ? 'Send'
                      : null,
              allowDecimal: amount,
              submitEnabled: submitEnabled,
            ),
            child: const Text('Open'),
          );
        }),
      ),
    ));
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
  }

  testWidgets('Send and Enter stay disabled until bank validation succeeds',
      (tester) async {
    final enabled = ValueNotifier(false);
    addTearDown(enabled.dispose);
    final submitted = <String>[];
    await openKeypad(tester, submitted.add,
        initialValue: '100', pin: false, amount: true, submitEnabled: enabled);
    await tester.tap(find.text('Send'));
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    expect(submitted, isEmpty);
    enabled.value = true;
    await tester.pump();
    enabled.value = false;
    await tester.pump();
    await tester.tap(find.text('Send'));
    expect(submitted, isEmpty);
    enabled.value = true;
    await tester.pump();
    await tester.tap(find.text('Send'));
    await tester.pumpAndSettle();
    expect(submitted, ['100']);
  });

  testWidgets('Confirm is above the digits and submits only a complete PIN',
      (tester) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final submitted = <String>[];
    await openKeypad(tester, submitted.add, initialValue: '123');
    expect(tester.getCenter(find.text('Confirm')).dy,
        lessThan(tester.getCenter(find.text('1')).dy));
    await tester.tap(find.text('Confirm'));
    await tester.tap(find.text('Enter'));
    expect(submitted, isEmpty);
    await tester.tap(find.text('4'));
    await tester.pump();
    await tester.tap(find.text('Confirm'));
    await tester.pumpAndSettle();
    expect(submitted, ['1234']);
    expect(find.byType(SettleNumericKeypad), findsNothing);
    expect(tester.takeException(), isNull);
  });

  for (final enter in [
    LogicalKeyboardKey.enter,
    LogicalKeyboardKey.numpadEnter
  ]) {
    testWidgets('${enter.keyLabel} submits once using the keypad value',
        (tester) async {
      final submitted = <String>[];
      await openKeypad(tester, submitted.add, initialValue: '123');
      await tester.sendKeyEvent(enter);
      expect(submitted, isEmpty);
      await tester.sendKeyEvent(LogicalKeyboardKey.digit4, character: '4');
      await tester.pump();
      await tester.sendKeyEvent(enter);
      await tester.sendKeyEvent(enter);
      await tester.pumpAndSettle();
      expect(submitted, ['1234']);
    });
  }

  testWidgets('on-screen Enter submits; dismissing does not', (tester) async {
    final submitted = <String>[];
    await openKeypad(tester, submitted.add, initialValue: '1234');
    await tester.tap(find.text('Enter'));
    await tester.pumpAndSettle();
    expect(submitted, ['1234']);
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    Navigator.of(tester.element(find.byType(SettleNumericKeypad))).pop();
    await tester.pumpAndSettle();
    expect(submitted, ['1234']);
  });

  testWidgets('ordinary numeric keypads keep Done behavior', (tester) async {
    final submitted = <String>[];
    await openKeypad(tester, submitted.add, initialValue: '5000', pin: false);
    expect(find.text('Confirm'), findsNothing);
    await tester.tap(find.text('Done'));
    await tester.pumpAndSettle();
    expect(submitted, ['5000']);
  });

  testWidgets('amount keypad supports decimal input and Enter submission',
      (tester) async {
    final submitted = <String>[];
    await openKeypad(tester, submitted.add,
        initialValue: '50', pin: false, amount: true);
    expect(find.text('Send'), findsOneWidget);
    await tester.sendKeyEvent(LogicalKeyboardKey.period, character: '.');
    await tester.sendKeyEvent(LogicalKeyboardKey.digit5, character: '5');
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(submitted, ['50.5']);
  });
}
