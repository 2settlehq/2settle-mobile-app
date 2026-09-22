import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:pin_code_fields/pin_code_fields.dart';
import 'package:settleio/pages/confirm_code/confirm_code_widget.dart';
import 'package:settleio/services/pin_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  testWidgets(
      'PIN resume blocks Back and restores the existing form after verification',
      (tester) async {
    tester.view.physicalSize = const Size(430, 950);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    FlutterSecureStorage.setMockInitialValues(
        {'2settle_access_token': 'test-token'});
    await PinService.setPin('123456');
    GoogleFonts.config.allowRuntimeFetching = false;
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMessageHandler('flutter/assets', (message) async {
      if (const StringCodec().decodeMessage(message) == 'AssetManifest.bin') {
        return const StandardMessageCodec().encodeMessage({
          'Inter-SemiBold.ttf': [
            {'asset': 'Inter-SemiBold.ttf'}
          ],
        });
      }
      return ByteData(0);
    });
    addTearDown(() {
      GoogleFonts.config.allowRuntimeFetching = true;
      messenger.setMockMessageHandler('flutter/assets', null);
    });
    final controller = TextEditingController(text: 'Draft payment');
    addTearDown(controller.dispose);
    final router = GoRouter(initialLocation: '/form', routes: [
      GoRoute(
          path: '/form',
          builder: (_, __) =>
              Scaffold(body: TextField(controller: controller))),
      GoRoute(
          path: '/lock',
          builder: (_, __) => const ConfirmCodeWidget(mode: 'resume')),
    ]);
    addTearDown(router.dispose);
    await http.runWithClient(() async {
      await tester.pumpWidget(MaterialApp.router(routerConfig: router));
      router.push('/lock');
      await tester.pump(const Duration(milliseconds: 700));
      await tester.binding.handlePopRoute();
      await tester.pump(const Duration(milliseconds: 700));
      expect(find.byType(ConfirmCodeWidget), findsOneWidget);
      tester
          .widget<PinCodeTextField>(find.byType(PinCodeTextField))
          .controller!
          .text = '123456';
      await tester.tap(find.text('Confirm'));
      await tester.pump(const Duration(seconds: 1));
      await tester.pump(const Duration(seconds: 1));
      await tester.pump(const Duration(milliseconds: 700));
      expect(find.byType(ConfirmCodeWidget), findsNothing);
      expect(find.text('Draft payment'), findsOneWidget);
      await tester.pumpWidget(const SizedBox.shrink());
    }, () => MockClient((_) async => http.Response('{"success":true}', 200)));
  });
}
