import 'dart:async';

import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/index.dart';
import '/services/pin_service.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'splash_screen_model.dart';
export 'splash_screen_model.dart';

class SplashScreenWidget extends StatefulWidget {
  const SplashScreenWidget({super.key});

  static String routeName = 'Splash_screen';
  static String routePath = 'splashScreen';

  @override
  State<SplashScreenWidget> createState() => _SplashScreenWidgetState();
}

class _SplashScreenWidgetState extends State<SplashScreenWidget>
    with TickerProviderStateMixin {
  late SplashScreenModel _model;

  final scaffoldKey = GlobalKey<ScaffoldState>();
  static const _typedMessage = 'Spend and send money easily\nwith 2Settle';
  static const _appVersionLabel = '2Settle V2.36.38';
  Timer? _typingTimer;
  String _visibleTypedMessage = '';

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => SplashScreenModel());

    _typingTimer = Timer.periodic(const Duration(milliseconds: 54), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_visibleTypedMessage.length >= _typedMessage.length) {
        timer.cancel();
        return;
      }
      safeSetState(() {
        _visibleTypedMessage =
            _typedMessage.substring(0, _visibleTypedMessage.length + 1);
      });
    });

    Future.delayed(const Duration(seconds: 3), () {
      _openNextScreen();
    });
  }

  Future<void> _openNextScreen() async {
    final hasPasscode = await PinService.hasPin();
    if (!mounted) return;

    if (hasPasscode) {
      context.pushNamed(
        ConfirmCodeWidget.routeName,
        queryParameters: {'mode': 'unlock'},
      );
      return;
    }

    context.pushNamed(OnboardingWidget.routeName);
  }

  @override
  void dispose() {
    _typingTimer?.cancel();
    _model.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: scaffoldKey,
      backgroundColor: Color(0xFF1E2429),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          image: DecorationImage(
            fit: BoxFit.fitHeight,
            image: Image.asset(
              'assets/images/potrait.jpg',
            ).image,
          ),
          gradient: LinearGradient(
            colors: [Color(0xFF45B4A2), Color(0xFF067AEF)],
            stops: [0.0, 1.0],
            begin: AlignmentDirectional(1.0, -1.0),
            end: AlignmentDirectional(-1.0, 1.0),
          ),
        ),
        child: Stack(
          children: [
            Align(
              alignment: AlignmentDirectional(0.0, 0.0),
              child: Column(
                mainAxisSize: MainAxisSize.max,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Flexible(
                    child: Container(
                      width: 300.0,
                      height: 300.0,
                      clipBehavior: Clip.antiAlias,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                      ),
                      child: Image.asset(
                        'assets/images/a_avatar.png',
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  Padding(
                    padding:
                        EdgeInsetsDirectional.fromSTEB(0.0, 10.0, 0.0, 0.0),
                    child: Text(
                      'How far 👋',
                      textAlign: TextAlign.center,
                      style:
                          FlutterFlowTheme.of(context).headlineSmall.override(
                                fontFamily: 'Hornbill',
                                font: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontStyle: FlutterFlowTheme.of(context)
                                      .headlineSmall
                                      .fontStyle,
                                ),
                                color: FlutterFlowTheme.of(context).primary,
                                fontSize: 20.0,
                                letterSpacing: 0.0,
                                fontWeight: FontWeight.w700,
                                fontStyle: FlutterFlowTheme.of(context)
                                    .headlineSmall
                                    .fontStyle,
                              ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsetsDirectional.fromSTEB(
                        30.0, 8.0, 30.0, 0.0),
                    child: Text(
                      _visibleTypedMessage,
                      textAlign: TextAlign.center,
                      style: FlutterFlowTheme.of(context).bodyLarge.override(
                            fontFamily: 'Hornbill',
                            font: GoogleFonts.inter(
                              fontWeight: FontWeight.w400,
                              fontStyle: FlutterFlowTheme.of(context)
                                  .bodyLarge
                                  .fontStyle,
                            ),
                            color: FlutterFlowTheme.of(context).primary,
                            fontSize: 16.0,
                            letterSpacing: 0.0,
                            fontWeight: FontWeight.w400,
                            fontStyle: FlutterFlowTheme.of(context)
                                .bodyLarge
                                .fontStyle,
                          ),
                    ),
                  ),
                ],
              ),
            ),
            Align(
              alignment: AlignmentDirectional(0.0, 0.94),
              child: Text(
                _appVersionLabel,
                style: GoogleFonts.inter(
                  color: FlutterFlowTheme.of(context)
                      .primary
                      .withValues(alpha: 0.7),
                  fontSize: 9.5,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.0,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
