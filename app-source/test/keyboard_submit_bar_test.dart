import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:settleio/components/keyboard_submit_bar.dart';
import 'package:settleio/components/status_action_button.dart';

void main() {
  for (final keyboardHeight in [0.0, 250.0, 320.0]) {
    testWidgets('form action follows keyboard height $keyboardHeight',
        (tester) async {
      tester.view.physicalSize = const Size(320, 568);
      tester.view.devicePixelRatio = 1;
      tester.view.viewInsets = FakeViewPadding(bottom: keyboardHeight);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetViewInsets);
      var submissions = 0;
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: ListView(children: const [TextField()]),
          bottomNavigationBar: KeyboardSubmitBar(
            text: 'Continue',
            onPressed: () => submissions++,
          ),
        ),
      ));
      if (keyboardHeight == 0) {
        expect(find.text('Continue'), findsNothing);
      } else {
        final button = find.byType(StatusActionButton);
        expect(tester.getBottomLeft(button).dy,
            lessThanOrEqualTo(568 - keyboardHeight));
        await tester.tap(find.text('Continue'));
        expect(submissions, 1);
      }
      expect(tester.takeException(), isNull);
    });
  }
}
