import '/components/status_action_button.dart';
import '/components/settle_numeric_keypad.dart';
import '/components/top_notice.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/index.dart';
import '/services/auth_service.dart';
import '/services/mobile_identity_service.dart';
import '/services/pin_service.dart';
import 'package:pin_code_fields/pin_code_fields.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'confirm_code_model.dart';
export 'confirm_code_model.dart';

class ConfirmCodeWidget extends StatefulWidget {
  const ConfirmCodeWidget({
    super.key,
    this.mode = 'confirm',
  });

  static String routeName = 'Confirm_code';
  static String routePath = 'confirmCode';

  final String mode;

  @override
  State<ConfirmCodeWidget> createState() => _ConfirmCodeWidgetState();
}

class _ConfirmCodeWidgetState extends State<ConfirmCodeWidget> {
  late ConfirmCodeModel _model;

  final scaffoldKey = GlobalKey<ScaffoldState>();
  bool _isConfirming = false;
  bool _isConfirmed = false;
  int _passcodeLength = 6;

  bool get _isUnlockMode => widget.mode == 'unlock';
  bool get _isRecoveryMode => widget.mode == 'recover';

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => ConfirmCodeModel());

    _model.pinCodeFocusNode ??= FocusNode();
    _loadPasscodeLength();
  }

  @override
  void dispose() {
    _model.dispose();

    super.dispose();
  }

  Future<void> _loadPasscodeLength() async {
    final length = await PinService.getPinLength();
    if (!mounted) return;
    safeSetState(() {
      _passcodeLength = length;
    });
  }

  Future<void> _confirmCode() async {
    if (_isConfirming) {
      return;
    }

    final code = _model.pinCodeController?.text ?? '';

    safeSetState(() {
      _isConfirming = true;
      _isConfirmed = false;
    });

    if (_isUnlockMode) {
      await Future.delayed(const Duration(milliseconds: 750));
      if (!mounted) {
        return;
      }
      final verify = await PinService.verifyPin(code);
      if (!verify.isSuccess) {
        safeSetState(() {
          _isConfirming = false;
          _isConfirmed = false;
        });
        showTopNotice(
          context,
          message: verify.status == PinVerifyStatus.lockedOut
              ? 'Too many attempts. Try again in ${verify.lockoutSeconds}s.'
              : verify.remainingAttempts != null
                  ? 'Incorrect passcode (${verify.remainingAttempts} attempts left).'
                  : 'Incorrect passcode',
          type: TopNoticeType.caution,
        );
        return;
      }

      // The PIN only unlocks the device — it doesn't re-prove the backend
      // session is still valid, so check that too before granting access.
      final sessionValid = await AuthService.validateSession();
      if (!mounted) return;
      if (sessionValid == false) {
        safeSetState(() {
          _isConfirming = false;
          _isConfirmed = false;
        });
        showTopNotice(
          context,
          message: 'Your session has expired. Please sign in again.',
          type: TopNoticeType.caution,
        );
        context.goNamed(LoginWidget.routeName);
        return;
      }
      AppStateNotifier.instance.setAppSessionActive(true);
    } else {
      final login = await MobileIdentityService.getLoginIdentifier();
      final result = await AuthService.verifyOtp(
        login.channel,
        login.identifier,
        code,
      );
      if (!mounted) {
        return;
      }
      if (!result.success) {
        safeSetState(() {
          _isConfirming = false;
          _isConfirmed = false;
        });
        showTopNotice(
          context,
          message: result.error ?? 'Incorrect code. Try again.',
          type: TopNoticeType.caution,
        );
        return;
      }
    }

    safeSetState(() => _isConfirmed = true);
    await Future.delayed(const Duration(milliseconds: 520));
    if (!mounted) {
      return;
    }

    // A plain login only needs a new app passcode if this device doesn't
    // already have one (e.g. it was wiped, or the refresh token just
    // expired and forced a re-login on an already-set-up device).
    var hasPasscode = false;
    if (!_isUnlockMode && !_isRecoveryMode) {
      hasPasscode = await PinService.hasPin();
    }

    await context.pushNamed(
      _isUnlockMode
          ? DashboardWidget.routeName
          : _isRecoveryMode
              ? SetAppPasscodeWidget.routeName
              : hasPasscode
                  ? DashboardWidget.routeName
                  : SetAppPasscodeWidget.routeName,
      queryParameters: _isRecoveryMode ? {'mode': 'reset'} : {},
    );
    if (!mounted) return;
    safeSetState(() {
      _isConfirming = false;
      _isConfirmed = false;
    });
  }

  void _openCodeKeypad() {
    final length = _isUnlockMode ? _passcodeLength : 6;
    SettleNumericKeypad.show(
      context,
      title: _isUnlockMode ? 'App passcode' : 'Confirm code',
      initialValue: _model.pinCodeController?.text ?? '',
      maxLength: length,
      obscurePreview: _isUnlockMode,
      onChanged: (value) {
        _model.pinCodeController?.text = value;
        safeSetState(() {});
      },
      onDone: (value) {
        _model.pinCodeController?.text = value;
        safeSetState(() {});
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
        FocusManager.instance.primaryFocus?.unfocus();
      },
      child: Scaffold(
        key: scaffoldKey,
        backgroundColor: FlutterFlowTheme.of(context).secondaryBackground,
        appBar: AppBar(
          backgroundColor: FlutterFlowTheme.of(context).secondaryBackground,
          automaticallyImplyLeading: false,
          title: Text(
            'Enter Pin Code Below',
            style: FlutterFlowTheme.of(context).bodyMedium.override(fontFamily: 'Hornbill', 
                  font: TextStyle(
                    fontWeight:
                        FlutterFlowTheme.of(context).bodyMedium.fontWeight,
                    fontStyle:
                        FlutterFlowTheme.of(context).bodyMedium.fontStyle,
                  ),
                  letterSpacing: 0.0,
                  fontWeight:
                      FlutterFlowTheme.of(context).bodyMedium.fontWeight,
                  fontStyle: FlutterFlowTheme.of(context).bodyMedium.fontStyle,
                ),
          ),
          actions: [],
          centerTitle: true,
          elevation: 0.0,
        ),
        body: Column(
          mainAxisSize: MainAxisSize.max,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Padding(
              padding: EdgeInsetsDirectional.fromSTEB(0.0, 24.0, 0.0, 0.0),
              child: Column(
                mainAxisSize: MainAxisSize.max,
                children: [
                  Text(
                    _isUnlockMode
                        ? 'Enter App Passcode'
                        : _isRecoveryMode
                            ? 'Confirm recovery code'
                            : 'Confirm your Code',
                    style: FlutterFlowTheme.of(context).headlineSmall.override(fontFamily: 'Hornbill', 
                          font: TextStyle(
                            fontWeight: FlutterFlowTheme.of(context)
                                .headlineSmall
                                .fontWeight,
                            fontStyle: FlutterFlowTheme.of(context)
                                .headlineSmall
                                .fontStyle,
                          ),
                          color: Color(0xFF4472C4),
                          letterSpacing: 0.0,
                          fontWeight: FlutterFlowTheme.of(context)
                              .headlineSmall
                              .fontWeight,
                          fontStyle: FlutterFlowTheme.of(context)
                              .headlineSmall
                              .fontStyle,
                        ),
                  ),
                  Padding(
                    padding:
                        EdgeInsetsDirectional.fromSTEB(44.0, 8.0, 44.0, 0.0),
                    child: Text(
                      _isUnlockMode
                          ? 'Enter your $_passcodeLength digit app passcode.'
                          : _isRecoveryMode
                              ? 'Enter the code sent to reset your pin.'
                              : 'Enter the code sent to your phone or email.',
                      textAlign: TextAlign.center,
                      style: FlutterFlowTheme.of(context).bodySmall.override(fontFamily: 'Hornbill', 
                            font: TextStyle(
                              fontWeight: FontWeight.normal,
                              fontStyle: FlutterFlowTheme.of(context)
                                  .bodySmall
                                  .fontStyle,
                            ),
                            letterSpacing: 0.0,
                            fontWeight: FontWeight.normal,
                            fontStyle: FlutterFlowTheme.of(context)
                                .bodySmall
                                .fontStyle,
                          ),
                    ),
                  ),
                  Padding(
                    padding:
                        EdgeInsetsDirectional.fromSTEB(0.0, 32.0, 0.0, 0.0),
                    child: PinCodeTextField(
                      autoDisposeControllers: false,
                      appContext: context,
                      length: _isUnlockMode ? _passcodeLength : 6,
                      textStyle: GoogleFonts.inter(
                        color: FlutterFlowTheme.of(context).primary,
                        fontSize: 18.0,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.0,
                      ),
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      enableActiveFill: false,
                      autoFocus: true,
                      focusNode: _model.pinCodeFocusNode,
                      enablePinAutofill: true,
                      errorTextSpace: 16.0,
                      showCursor: true,
                      keyboardType: TextInputType.none,
                      onTap: _openCodeKeypad,
                      cursorColor: FlutterFlowTheme.of(context).primary,
                      obscureText: _isUnlockMode,
                      obscuringCharacter: '*',
                      hintCharacter: '-',
                      pinTheme: PinTheme(
                        fieldHeight: 48.0,
                        fieldWidth: 44.0,
                        borderWidth: 2.0,
                        borderRadius: BorderRadius.only(
                          bottomLeft: Radius.circular(12.0),
                          bottomRight: Radius.circular(12.0),
                          topLeft: Radius.circular(12.0),
                          topRight: Radius.circular(12.0),
                        ),
                        shape: PinCodeFieldShape.box,
                        activeColor: FlutterFlowTheme.of(context).primary,
                        inactiveColor:
                            FlutterFlowTheme.of(context).primaryBackground,
                        selectedColor:
                            FlutterFlowTheme.of(context).secondaryText,
                      ),
                      controller: _model.pinCodeController,
                      onChanged: (_) {},
                      autovalidateMode: AutovalidateMode.onUserInteraction,
                      validator: _model.pinCodeControllerValidator
                          .asValidator(context),
                    ),
                  ),
                  if (_isUnlockMode)
                    Padding(
                      padding: const EdgeInsetsDirectional.fromSTEB(
                          0.0, 12.0, 0.0, 0.0),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          InkWell(
                            onTap: () {
                              context.pushNamed(
                                LoginWidget.routeName,
                                queryParameters: {'mode': 'recover_pin'},
                              );
                            },
                            borderRadius: BorderRadius.circular(8.0),
                            child: Padding(
                              padding: const EdgeInsetsDirectional.fromSTEB(
                                  10.0, 6.0, 10.0, 6.0),
                              child: Text(
                                'Forgot pin?',
                                style: FlutterFlowTheme.of(context)
                                    .bodySmall
                                    .override(fontFamily: 'Hornbill', 
                                      font: TextStyle(
                                        fontWeight: FontWeight.normal,
                                        fontStyle: FlutterFlowTheme.of(context)
                                            .bodySmall
                                            .fontStyle,
                                      ),
                                      color:
                                          FlutterFlowTheme.of(context).primary,
                                      letterSpacing: 0.0,
                                      fontWeight: FontWeight.normal,
                                      fontStyle: FlutterFlowTheme.of(context)
                                          .bodySmall
                                          .fontStyle,
                                    ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 4.0),
                          InkWell(
                            onTap: () {
                              context.pushNamed(OnboardingWidget.routeName);
                            },
                            borderRadius: BorderRadius.circular(18.0),
                            child: Container(
                              width: 32.0,
                              height: 32.0,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: const Color(0xFF4472C4)
                                    .withValues(alpha: 0.1),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.air_rounded,
                                color: Color(0xFF4472C4),
                                size: 18.0,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            Padding(
              padding: EdgeInsetsDirectional.fromSTEB(0.0, 24.0, 0.0, 44.0),
              child: StatusActionButton(
                text: 'Confirm',
                isLoading: _isConfirming && !_isConfirmed,
                isDone: _isConfirmed,
                onPressed: _confirmCode,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
