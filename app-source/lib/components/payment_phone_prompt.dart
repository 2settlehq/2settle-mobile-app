import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '/services/auth_service.dart';
import '/services/payment_phone_service.dart';
import '/components/status_action_button.dart';

Future<String?> ensurePaymentPhone(BuildContext context) async {
  final service = PaymentPhoneService(
    getToken: AuthService.getAccessToken,
    refreshToken: AuthService.refreshAccessToken,
  );
  try {
    final phone = await service.verifiedPhone();
    if (!context.mounted) return null;
    if (phone != null) return phone;
    return await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      isDismissible: false,
      enableDrag: false,
      builder: (_) => PaymentPhonePrompt(service: service),
    );
  } finally {
    service.close();
  }
}

class PaymentPhonePrompt extends StatefulWidget {
  const PaymentPhonePrompt({super.key, required this.service});
  final PaymentPhoneService service;
  @override
  State<PaymentPhonePrompt> createState() => _PaymentPhonePromptState();
}

class _PaymentPhonePromptState extends State<PaymentPhonePrompt> {
  final _phone = TextEditingController();
  final _code = TextEditingController();
  final _codeFocus = FocusNode();
  String? _sentTo;
  String? _error;
  bool _busy = false;
  bool _linked = false;
  int _resendSeconds = 0;
  Timer? _timer;

  @override
  void dispose() {
    _timer?.cancel();
    _phone.dispose();
    _code.dispose();
    _codeFocus.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    if (_busy || _resendSeconds > 0) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final phone = PaymentPhoneService.normalizePhone(_phone.text);
      await widget.service.requestCode(phone);
      if (!mounted) return;
      setState(() {
        _sentTo = phone;
        _resendSeconds = 60;
      });
      _timer?.cancel();
      _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (!mounted) {
          timer.cancel();
          return;
        }
        setState(() => _resendSeconds--);
        if (_resendSeconds == 0) timer.cancel();
      });
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _codeFocus.requestFocus();
      });
    } catch (error) {
      if (mounted) setState(() => _error = error.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _verify() async {
    if (_busy) return;
    if (!_linked && !RegExp(r'^\d{4,10}$').hasMatch(_code.text.trim())) {
      setState(() => _error = 'Enter the code sent to your phone.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      // Once verification succeeds, retry only /me if that refresh fails.
      // The OTP is single-use and must not be submitted again.
      if (!_linked) {
        await widget.service.linkPhone(_sentTo!, _code.text);
        _linked = true;
      }
      final phone = await widget.service.requireVerifiedPhone();
      if (mounted) Navigator.pop(context, phone);
    } catch (error) {
      if (mounted) setState(() => _error = error.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasCode = _sentTo != null;
    return PopScope(
      canPop: !_busy,
      child: Padding(
        padding:
            EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
        child: SafeArea(
          top: false,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('Add your phone number',
                      style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 8),
                  const Text(
                      'Verify a phone number to continue with your payment.'),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _phone,
                    enabled: !_busy && !hasCode,
                    keyboardType: TextInputType.phone,
                    textInputAction: TextInputAction.done,
                    decoration: const InputDecoration(
                        labelText: 'Phone number',
                        hintText: '+2348012345678',
                        helperText: 'Include your country code'),
                    onSubmitted: (_) => _send(),
                  ),
                  if (hasCode) ...[
                    const SizedBox(height: 12),
                    TextField(
                      controller: _code,
                      focusNode: _codeFocus,
                      enabled: !_busy && !_linked,
                      keyboardType: TextInputType.number,
                      textInputAction: TextInputAction.done,
                      autofillHints: const [AutofillHints.oneTimeCode],
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(10)
                      ],
                      decoration:
                          const InputDecoration(labelText: 'Verification code'),
                      onSubmitted: (_) => _verify(),
                    ),
                  ],
                  if (_error != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: Semantics(
                          liveRegion: true,
                          child: Text(_error!,
                              style: TextStyle(
                                  color: Theme.of(context).colorScheme.error))),
                    ),
                  const SizedBox(height: 20),
                  StatusActionButton(
                      text: _linked
                          ? 'Retry account check'
                          : hasCode
                              ? 'Verify and continue'
                              : 'Send code',
                      isLoading: _busy,
                      isDone: false,
                      onPressed: hasCode ? _verify : _send),
                  if (hasCode && !_linked) ...[
                    TextButton(
                        onPressed: _busy || _resendSeconds > 0 ? null : _send,
                        child: Text(_resendSeconds > 0
                            ? 'Resend code in ${_resendSeconds}s'
                            : 'Resend code')),
                    TextButton(
                        onPressed: _busy
                            ? null
                            : () => setState(() {
                                  _sentTo = null;
                                  _error = null;
                                  _code.clear();
                                  _timer?.cancel();
                                  _resendSeconds = 0;
                                }),
                        child: const Text('Change number')),
                  ],
                  TextButton(
                      onPressed: _busy ? null : () => Navigator.pop(context),
                      child: const Text('Cancel')),
                ]),
          ),
        ),
      ),
    );
  }
}
