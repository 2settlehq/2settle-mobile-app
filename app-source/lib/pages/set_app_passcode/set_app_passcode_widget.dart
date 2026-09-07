import '/components/status_action_button.dart';
import '/components/settle_numeric_keypad.dart';
import '/components/top_notice.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/index.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pin_code_fields/pin_code_fields.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'set_app_passcode_model.dart';
export 'set_app_passcode_model.dart';

class SetAppPasscodeWidget extends StatefulWidget {
  const SetAppPasscodeWidget({
    super.key,
    this.mode = 'set',
  });

  static String routeName = 'Set_app_passcode';
  static String routePath = 'setAppPasscode';

  final String mode;

  @override
  State<SetAppPasscodeWidget> createState() => _SetAppPasscodeWidgetState();
}

class _SetAppPasscodeWidgetState extends State<SetAppPasscodeWidget> {
  late SetAppPasscodeModel _model;

  final scaffoldKey = GlobalKey<ScaffoldState>();
  final _oldPinController = TextEditingController();
  final _newPinController = TextEditingController();
  final _confirmPinController = TextEditingController();
  final _oldPinFocusNode = FocusNode();
  final _newPinFocusNode = FocusNode();
  final _confirmPinFocusNode = FocusNode();
  static const _passcodeStorageKey = '2settle_app_passcode';
  static const _passcodeLengthStorageKey = '2settle_app_passcode_length';
  bool _isSettingPin = false;
  bool _isPinSet = false;
  int _pinLength = 6;

  bool get _isResetMode => widget.mode == 'reset';
  bool get _isChangeMode => widget.mode == 'change';

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => SetAppPasscodeModel());
    _model.pinCodeFocusNode ??= FocusNode();
    _loadPinLength();
  }

  @override
  void dispose() {
    _oldPinController.dispose();
    _newPinController.dispose();
    _confirmPinController.dispose();
    _oldPinFocusNode.dispose();
    _newPinFocusNode.dispose();
    _confirmPinFocusNode.dispose();
    _model.dispose();
    super.dispose();
  }

  Future<void> _loadPinLength() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    safeSetState(() {
      _pinLength = prefs.getInt(_passcodeLengthStorageKey) ?? 6;
    });
  }

  void _selectPinLength(int length) {
    safeSetState(() {
      _pinLength = length;
      _model.pinCodeController?.clear();
      _oldPinController.clear();
      _newPinController.clear();
      _confirmPinController.clear();
    });
  }

  Future<void> _setPin() async {
    if (_isSettingPin) {
      return;
    }

    safeSetState(() {
      _isSettingPin = true;
      _isPinSet = false;
    });
    await Future.delayed(const Duration(milliseconds: 750));
    if (!mounted) {
      return;
    }
    final pin = _model.pinCodeController?.text ?? '';
    if (pin.length != _pinLength) {
      safeSetState(() {
        _isSettingPin = false;
        _isPinSet = false;
      });
      showTopNotice(
        context,
        message: 'Enter a $_pinLength digit passcode',
        type: TopNoticeType.caution,
      );
      return;
    }
    final prefs = await SharedPreferences.getInstance();
    if (_isChangeMode) {
      final storedPin = prefs.getString(_passcodeStorageKey) ?? '';
      final oldPin = _oldPinController.text;
      final newPin = _newPinController.text;
      final confirmPin = _confirmPinController.text;

      if (storedPin.isNotEmpty && oldPin != storedPin) {
        safeSetState(() {
          _isSettingPin = false;
          _isPinSet = false;
        });
        showTopNotice(
          context,
          message: 'Old passcode is not correct.',
          type: TopNoticeType.caution,
        );
        return;
      }
      if (newPin.length != _pinLength || confirmPin.length != _pinLength) {
        safeSetState(() {
          _isSettingPin = false;
          _isPinSet = false;
        });
        showTopNotice(
          context,
          message: 'Enter and confirm a $_pinLength digit passcode.',
          type: TopNoticeType.caution,
        );
        return;
      }
      if (newPin != confirmPin) {
        safeSetState(() {
          _isSettingPin = false;
          _isPinSet = false;
        });
        showTopNotice(
          context,
          message: 'New passcodes do not match.',
          type: TopNoticeType.caution,
        );
        return;
      }
      await prefs.setString(_passcodeStorageKey, newPin);
      await prefs.setInt(_passcodeLengthStorageKey, _pinLength);
      safeSetState(() => _isPinSet = true);
      await Future.delayed(const Duration(milliseconds: 420));
      if (!mounted) return;
      showTopNotice(
        context,
        message: 'Pin saved successfully.',
        type: TopNoticeType.info,
      );
      await Future.delayed(const Duration(milliseconds: 650));
      if (!mounted) return;
      context.pushNamed(SecurityWidget.routeName);
      return;
    }
    await prefs.setString(_passcodeStorageKey, pin);
    await prefs.setInt(_passcodeLengthStorageKey, _pinLength);
    safeSetState(() => _isPinSet = true);
    await Future.delayed(const Duration(milliseconds: 420));
    if (!mounted) {
      return;
    }
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: FlutterFlowTheme.of(context).secondaryBackground,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.0),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.check_circle_rounded,
              color: FlutterFlowTheme.of(context).primary,
              size: 46.0,
            ),
            const SizedBox(height: 12.0),
            Text(
              'Pin set successfully',
              textAlign: TextAlign.center,
              style: FlutterFlowTheme.of(context).titleSmall.override(fontFamily: 'Hornbill', 
                    font: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontStyle:
                          FlutterFlowTheme.of(context).titleSmall.fontStyle,
                    ),
                    color: FlutterFlowTheme.of(context).primaryText,
                    letterSpacing: 0.0,
                    fontWeight: FontWeight.w600,
                    fontStyle:
                        FlutterFlowTheme.of(context).titleSmall.fontStyle,
                  ),
            ),
          ],
        ),
      ),
    ).timeout(
      const Duration(milliseconds: 900),
      onTimeout: () {
        if (Navigator.of(context).canPop()) {
          Navigator.of(context).pop();
        }
      },
    );
    if (!mounted) {
      return;
    }
    await context.pushNamed(
      _isResetMode ? ConfirmCodeWidget.routeName : DashboardWidget.routeName,
      queryParameters: _isResetMode ? {'mode': 'unlock'} : {},
    );
    if (!mounted) return;
    safeSetState(() {
      _isSettingPin = false;
      _isPinSet = false;
    });
  }

  void _openPasscodeKeypad() {
    SettleNumericKeypad.show(
      context,
      title: _isResetMode ? 'Reset app passcode' : 'Set app passcode',
      initialValue: _model.pinCodeController?.text ?? '',
      maxLength: _pinLength,
      obscurePreview: true,
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

  void _openChangePinKeypad({
    required String title,
    required TextEditingController controller,
  }) {
    SettleNumericKeypad.show(
      context,
      title: title,
      initialValue: controller.text,
      maxLength: _pinLength,
      obscurePreview: true,
      onChanged: (value) {
        controller.text = value;
        safeSetState(() {});
      },
      onDone: (value) {
        controller.text = value;
        safeSetState(() {});
      },
    );
  }

  Widget _pinInput({
    required String label,
    required TextEditingController controller,
    required FocusNode focusNode,
  }) {
    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(0.0, 18.0, 0.0, 0.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsetsDirectional.only(start: 18.0, bottom: 8.0),
            child: Text(
              label,
              style: FlutterFlowTheme.of(context).bodySmall.override(fontFamily: 'Hornbill', 
                    font: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontStyle:
                          FlutterFlowTheme.of(context).bodySmall.fontStyle,
                    ),
                    color: FlutterFlowTheme.of(context).primaryText,
                    fontSize: 12.0,
                    letterSpacing: 0.0,
                    fontWeight: FontWeight.w600,
                    fontStyle: FlutterFlowTheme.of(context).bodySmall.fontStyle,
                  ),
            ),
          ),
          PinCodeTextField(
            autoDisposeControllers: false,
            appContext: context,
            length: _pinLength,
            textStyle: GoogleFonts.inter(
              color: FlutterFlowTheme.of(context).primary,
              fontSize: 16.0,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.0,
            ),
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            enableActiveFill: false,
            focusNode: focusNode,
            enablePinAutofill: false,
            errorTextSpace: 0.0,
            showCursor: true,
            keyboardType: TextInputType.none,
            onTap: () => _openChangePinKeypad(
              title: label,
              controller: controller,
            ),
            cursorColor: FlutterFlowTheme.of(context).primary,
            obscureText: true,
            obscuringCharacter: '*',
            hintCharacter: '-',
            pinTheme: PinTheme(
              fieldHeight: 42.0,
              fieldWidth: _pinLength == 6 ? 38.0 : 44.0,
              borderWidth: 2.0,
              borderRadius: BorderRadius.circular(12.0),
              shape: PinCodeFieldShape.box,
              activeColor: FlutterFlowTheme.of(context).primary,
              inactiveColor: FlutterFlowTheme.of(context).primaryBackground,
              selectedColor: FlutterFlowTheme.of(context).secondaryText,
            ),
            controller: controller,
            onChanged: (_) {},
          ),
        ],
      ),
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
          leading: IconButton(
            icon: Icon(
              Icons.arrow_back_rounded,
              color: FlutterFlowTheme.of(context).primary,
            ),
            onPressed: () => context.pushNamed(SecurityWidget.routeName),
          ),
          title: Text(
            _isChangeMode
                ? 'Change App Passcode'
                : (_isResetMode ? 'Reset App Passcode' : 'Set App Passcode'),
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
          centerTitle: true,
          elevation: 0.0,
        ),
        body: Column(
          mainAxisSize: MainAxisSize.max,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Padding(
              padding:
                  const EdgeInsetsDirectional.fromSTEB(0.0, 24.0, 0.0, 0.0),
              child: Column(
                children: [
                  Text(
                    _isChangeMode
                        ? 'Change your App Passcode'
                        : (_isResetMode
                            ? 'Create a New Pin'
                            : 'Create your App Passcode'),
                    style: FlutterFlowTheme.of(context).headlineSmall.override(fontFamily: 'Hornbill', 
                          font: TextStyle(
                            fontWeight: FlutterFlowTheme.of(context)
                                .headlineSmall
                                .fontWeight,
                            fontStyle: FlutterFlowTheme.of(context)
                                .headlineSmall
                                .fontStyle,
                          ),
                          color: const Color(0xFF4472C4),
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
                    padding: const EdgeInsetsDirectional.fromSTEB(
                        44.0, 8.0, 44.0, 0.0),
                    child: Text(
                      'Set a $_pinLength digit passcode for quick access.',
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
                    padding: const EdgeInsetsDirectional.fromSTEB(
                        44.0, 16.0, 44.0, 0.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _PinLengthChip(
                          label: '4 pin',
                          selected: _pinLength == 4,
                          onTap: () => _selectPinLength(4),
                        ),
                        const SizedBox(width: 10.0),
                        _PinLengthChip(
                          label: '6 pin',
                          selected: _pinLength == 6,
                          onTap: () => _selectPinLength(6),
                        ),
                      ],
                    ),
                  ),
                  if (_isChangeMode)
                    Padding(
                      padding: const EdgeInsetsDirectional.fromSTEB(
                          24.0, 10.0, 24.0, 0.0),
                      child: Column(
                        children: [
                          _pinInput(
                            label: 'Old passcode',
                            controller: _oldPinController,
                            focusNode: _oldPinFocusNode,
                          ),
                          _pinInput(
                            label: 'New passcode',
                            controller: _newPinController,
                            focusNode: _newPinFocusNode,
                          ),
                          _pinInput(
                            label: 'Confirm passcode',
                            controller: _confirmPinController,
                            focusNode: _confirmPinFocusNode,
                          ),
                        ],
                      ),
                    )
                  else
                    Padding(
                      padding: const EdgeInsetsDirectional.fromSTEB(
                          0.0, 32.0, 0.0, 0.0),
                      child: PinCodeTextField(
                        autoDisposeControllers: false,
                        appContext: context,
                        length: _pinLength,
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
                        enablePinAutofill: false,
                        errorTextSpace: 16.0,
                        showCursor: true,
                        keyboardType: TextInputType.none,
                        onTap: _openPasscodeKeypad,
                        cursorColor: FlutterFlowTheme.of(context).primary,
                        obscureText: true,
                        obscuringCharacter: '*',
                        hintCharacter: '-',
                        pinTheme: PinTheme(
                          fieldHeight: 48.0,
                          fieldWidth: 44.0,
                          borderWidth: 2.0,
                          borderRadius: BorderRadius.circular(12.0),
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
                ],
              ),
            ),
            Padding(
              padding:
                  const EdgeInsetsDirectional.fromSTEB(0.0, 24.0, 0.0, 44.0),
              child: StatusActionButton(
                text: _isChangeMode ? 'Save Pin' : 'Set Pin',
                isLoading: _isSettingPin && !_isPinSet,
                isDone: _isPinSet,
                onPressed: _setPin,
                idleIcon: Icons.lock_rounded,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PinLengthChip extends StatelessWidget {
  const _PinLengthChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final blue = FlutterFlowTheme.of(context).primary;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999.0),
      child: Container(
        padding: const EdgeInsetsDirectional.fromSTEB(16.0, 8.0, 16.0, 8.0),
        decoration: BoxDecoration(
          color: selected ? blue : blue.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(999.0),
          border: Border.all(color: blue.withValues(alpha: 0.25)),
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(
            color: selected ? Colors.white : blue,
            fontSize: 12.0,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.0,
          ),
        ),
      ),
    );
  }
}
