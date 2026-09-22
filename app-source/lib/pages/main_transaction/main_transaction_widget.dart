import 'dart:async';

import '/components/settle_numeric_keypad.dart';
import '/components/status_action_button.dart';
import '/components/top_notice.dart';
import '/config/api_config.dart';
import '/data/ng_bank_codes.dart';
import '/data/payment_networks.dart';
import '/flutter_flow/flutter_flow_animations.dart';
import '/flutter_flow/flutter_flow_drop_down.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/form_field_controller.dart';
import '/index.dart';
import '/services/payment_estimate_result.dart';
import 'package:easy_debounce/easy_debounce.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'main_transaction_model.dart';
export 'main_transaction_model.dart';

class MainTransactionWidget extends StatefulWidget {
  const MainTransactionWidget({super.key});

  static String routeName = 'Main_Transaction';
  static String routePath = 'mainTransaction';

  @override
  State<MainTransactionWidget> createState() => _MainTransactionWidgetState();
}

class _MainTransactionWidgetState extends State<MainTransactionWidget>
    with TickerProviderStateMixin {
  late MainTransactionModel _model;

  final scaffoldKey = GlobalKey<ScaffoldState>();
  static const _rateUrl = ApiConfig.rateUrl;
  static const _cryptoPriceUrl =
      'https://api.coingecko.com/api/v3/simple/price?ids=bitcoin,ethereum,binancecoin,tether,tron&vs_currencies=usd';
  static const _banksUrl = ApiConfig.banksListUrl;
  static const _validateBankUrl = ApiConfig.banksResolveUrl;
  static const _estimateUrl = ApiConfig.paymentsEstimateUrl;
  static const _fallbackBankCodes = ngBankCodes;
  static const _beneficiaryStorageKey = '2settle_saved_beneficiaries';
  Timer? _rateRefreshTimer;
  double? _liveRate;
  // Server-computed estimate (cryptoAmount, crypto, network, fiatAmount,
  // conversionFee, processingFee) for the currently entered amount/crypto/
  // network. Only a successful server estimate can be used to continue.
  Map<String, String>? _estimate;
  String? _estimateError;
  String? _estimatedInputKey;
  int _estimateRequestId = 0;
  bool _isEstimating = false;
  bool _isRefreshingRate = false;
  Map<String, double> _cryptoUsdPrices = {
    'BTC': 65000.0,
    'ETH': 3200.0,
    'BNB': 580.0,
    'USDT': 1.0,
    'TRX': 0.12,
  };
  String? _validatedBankName;
  String? _validatedAccountName;
  String _typedAccountName = '';
  String? _bankValidationMessage;
  bool _isValidatingBank = false;
  bool _isLoadingBanks = false;
  bool _isSending = false;
  bool _isSent = false;
  late Map<String, String> _bankCodes;
  final List<_SavedBeneficiary> _savedBeneficiaries = [];
  Timer? _accountNameTypingTimer;

  final animationsMap = <String, AnimationInfo>{};

  double get _enteredAmount {
    final raw = _model.amountTextController?.text ?? '';
    return double.tryParse(raw.replaceAll(',', '').trim()) ?? 0;
  }

  String get _selectedInputCurrency => _model.budgetValue ?? 'NGN';

  String get _selectedCrypto => _model.cryptoValue ?? 'TRX';

  bool get _isUsdtSelected => _selectedCrypto == 'USDT';

  String get _selectedCryptoNetwork {
    if (_isUsdtSelected) {
      return _model.cryptoNetworkValue ?? 'TRC20';
    }
    return switch (_selectedCrypto) {
      'BTC' => 'Bitcoin',
      'ETH' => 'Ethereum',
      'TRX' => 'Tron',
      'BNB' => 'Binance',
      _ => 'Network',
    };
  }

  // Machine-readable network code for the estimate/payment APIs, matching
  // the convention already used by create_gift_widget.dart.
  String get _selectedNetworkForApi {
    return paymentNetworkCode(
      crypto: _selectedCrypto,
      network: _selectedCryptoNetwork,
    );
  }

  double get _selectedCryptoUsdPrice =>
      _cryptoUsdPrices[_selectedCrypto] ?? 1.0;

  double get _enteredAmountInNaira {
    final amount = _enteredAmount;
    final rate = _liveRate;
    if (amount <= 0) return 0;
    if (_selectedInputCurrency == 'USD') {
      return rate == null || rate <= 0 ? 0 : amount * rate;
    }
    if (_selectedInputCurrency == 'CRYPTO') {
      return rate == null || rate <= 0
          ? 0
          : amount * _selectedCryptoUsdPrice * rate;
    }
    return amount;
  }

  String get _formattedEnteredAmount {
    final amount = _enteredAmountInNaira;
    if (amount <= 0) {
      return '0.00';
    }
    return NumberFormat('#,##0.00', 'en_US').format(amount);
  }

  // Prefer the rate returned alongside the payment estimate — it's the same
  // market rate, already fetched for the currently entered amount/crypto/
  // network — over the separately polled live rate, so this screen doesn't
  // show two numbers pulled from two different calls. Falls back to the
  // polled live rate until the first estimate lands (or if it fails).
  double? get _displayRate {
    final estimateRate = double.tryParse(_estimate?['rate'] ?? '');
    if (estimateRate != null && estimateRate > 0) return estimateRate;
    return _liveRate;
  }

  String get _formattedLiveRate {
    final rate = _displayRate;
    if (rate == null) {
      return '...';
    }
    final roundedDown = (rate * 100).floor() / 100;
    return NumberFormat('#,##0.00', 'en_US').format(roundedDown);
  }

  String get _quoteText {
    final rawAmount = _enteredAmount;
    if (rawAmount <= 0) {
      return 'Sending ₦0.00 at $_formattedLiveRate/\$';
    }
    if ((_selectedInputCurrency == 'USD' ||
            _selectedInputCurrency == 'CRYPTO') &&
        (_displayRate == null || _displayRate! <= 0)) {
      return 'Sending ₦**** while live rate loads';
    }
    final suffix = _selectedInputCurrency == 'CRYPTO'
        ? ' from ${_roundDownCrypto(rawAmount)} $_selectedCrypto'
        : _selectedInputCurrency == 'USD'
            ? ' from \$${_formatFiat(rawAmount)}'
            : '';
    return 'Sending ₦$_formattedEnteredAmount$suffix at $_formattedLiveRate/\$';
  }

  String _cryptoAmountText() {
    final settlementAmount = _enteredAmountInNaira;
    if (settlementAmount <= 0) {
      return '0.00000 $_selectedCrypto';
    }

    // Prefer the server-computed estimate (real fee schedule from
    // payment-engine) when we have one for the currently entered amount.
    final estimated = double.tryParse(_estimate?['cryptoAmount'] ?? '');
    if (estimated != null && estimated > 0) {
      return '${_roundDownCrypto(estimated)} $_selectedCrypto';
    }

    return 'Unavailable';
  }

  String? get _conversionFeeText {
    final fee = double.tryParse(_estimate?['conversionFee'] ?? '');
    if (fee == null) return null;
    return '₦${_formatFiat(fee)}';
  }

  String? get _processingFeeText {
    final fee = double.tryParse(_estimate?['processingFee'] ?? '');
    if (fee == null || !fee.isFinite) return null;
    return '₦${_formatFiat(fee)}';
  }

  void _queueEstimate() {
    // Invalidate both the old quote and any in-flight response immediately.
    _estimateRequestId++;
    safeSetState(() {
      _estimate = null;
      _estimatedInputKey = null;
      _estimateError = null;
      _isEstimating = true;
    });
    EasyDebounce.debounce(
      '_estimate',
      const Duration(milliseconds: 600),
      _fetchEstimate,
    );
  }

  // Manual refresh from the rate row — cancels any pending debounced
  // estimate so this runs immediately instead of waiting behind it.
  Future<void> _refreshRate() async {
    if (_isRefreshingRate) return;
    EasyDebounce.cancel('_estimate');
    safeSetState(() => _isRefreshingRate = true);
    try {
      await _loadLiveRate();
      if (mounted) await _fetchEstimate();
    } finally {
      if (mounted) safeSetState(() => _isRefreshingRate = false);
    }
  }

  String get _estimateInputKey =>
      '$_enteredAmountInNaira|$_selectedInputCurrency|$_selectedCrypto|$_selectedNetworkForApi';

  Future<bool> _fetchEstimate() async {
    final requestId = ++_estimateRequestId;
    final inputKey = _estimateInputKey;
    final amount = _enteredAmountInNaira;
    if (!amount.isFinite || amount <= 0) {
      if (!mounted) return false;
      safeSetState(() {
        _estimate = null;
        _estimatedInputKey = null;
        _estimateError =
            (_model.amountTextController?.text.trim().isEmpty ?? true)
                ? null
                : 'Enter a valid amount and wait for the live rate to load.';
        _isEstimating = false;
      });
      return false;
    }

    safeSetState(() {
      _isEstimating = true;
      _estimate = null;
      _estimatedInputKey = null;
      _estimateError = null;
    });
    try {
      final response = await http
          .post(
            Uri.parse(_estimateUrl),
            headers: const {
              'accept': 'application/json',
              'content-type': 'application/json',
            },
            body: jsonEncode({
              'fiatAmount': amount,
              'fiatCurrency': 'NGN',
              'crypto': _selectedCrypto,
              'network': _selectedNetworkForApi,
            }),
          )
          .timeout(const Duration(seconds: 8));
      final result = PaymentEstimateResult.fromResponse(
          response.statusCode, response.body);
      if (!mounted || requestId != _estimateRequestId) return false;
      final inputUnchanged = inputKey == _estimateInputKey;
      safeSetState(() {
        _estimate = inputUnchanged ? result.estimate : null;
        _estimatedInputKey = _estimate == null ? null : inputKey;
        _estimateError = inputUnchanged
            ? result.error
            : 'The amount or rate changed. Please refresh the estimate.';
        _isEstimating = false;
      });
      return _estimate != null;
    } catch (_) {
      if (!mounted || requestId != _estimateRequestId) return false;
      safeSetState(() {
        _estimate = null;
        _estimatedInputKey = null;
        _estimateError = PaymentEstimateResult.unavailable;
        _isEstimating = false;
      });
      return false;
    }
  }

  String _roundDownCrypto(double value) =>
      ((value * 100000).floor() / 100000).toStringAsFixed(5);

  String _formatFiat(double value) =>
      NumberFormat('#,##0.00', 'en_US').format(value);

  double? _parseRate(dynamic value) {
    if (value is num && value.isFinite) {
      return value.toDouble();
    }
    if (value is String) {
      final parsed = double.tryParse(value.replaceAll(',', '').trim());
      if (parsed != null && parsed.isFinite) {
        return parsed;
      }
    }
    return null;
  }

  double? _parseRatePayload(dynamic payload) {
    final direct = _parseRate(payload);
    if (direct != null) return direct;

    if (payload is List) {
      for (final item in payload) {
        final parsed = _parseRatePayload(item);
        if (parsed != null) return parsed;
      }
      return null;
    }

    if (payload is! Map) return null;

    for (final key in [
      'rate',
      'price',
      'value',
      'amount',
      'currentRate',
      'exchangeRate',
      'buyRate',
      'sellRate',
    ]) {
      final parsed = _parseRate(payload[key]);
      if (parsed != null) return parsed;
    }

    for (final key in ['data', 'result']) {
      final nested = _parseRatePayload(payload[key]);
      if (nested != null) return nested;
    }

    return null;
  }

  Future<void> _loadLiveRate() async {
    try {
      final response = await http.get(
        Uri.parse(_rateUrl),
        headers: const {'accept': 'application/json'},
      ).timeout(const Duration(seconds: 6));
      if (response.statusCode < 200 || response.statusCode >= 300) return;

      dynamic payload;
      try {
        payload = jsonDecode(response.body);
      } catch (_) {
        payload = response.body;
      }

      final rate = _parseRatePayload(payload);
      if (!mounted || rate == null) return;
      safeSetState(() => _liveRate = rate);
    } catch (_) {
      // Keep the current rate while offline or if the endpoint is unavailable.
    }
  }

  Future<void> _loadCryptoPrices() async {
    try {
      final response = await http.get(
        Uri.parse(_cryptoPriceUrl),
        headers: const {'accept': 'application/json'},
      ).timeout(const Duration(seconds: 8));
      if (response.statusCode < 200 || response.statusCode >= 300) return;

      final payload = jsonDecode(response.body);
      if (payload is! Map) return;
      final next = Map<String, double>.from(_cryptoUsdPrices);
      const idMap = {
        'BTC': 'bitcoin',
        'ETH': 'ethereum',
        'BNB': 'binancecoin',
        'USDT': 'tether',
        'TRX': 'tron',
      };
      for (final entry in idMap.entries) {
        final raw = payload[entry.value];
        if (raw is Map && raw['usd'] is num) {
          final value = raw['usd'] as num;
          if (value.isFinite) {
            next[entry.key] = value.toDouble();
          }
        }
      }
      if (!mounted) return;
      safeSetState(() => _cryptoUsdPrices = next);
    } catch (_) {
      // Keep fallback crypto prices while offline.
    }
  }

  Future<void> _loadBanks() async {
    safeSetState(() => _isLoadingBanks = true);
    try {
      final response = await http.get(
        Uri.parse(_banksUrl),
        headers: const {'accept': 'application/json'},
      ).timeout(const Duration(seconds: 8));

      if (response.statusCode < 200 || response.statusCode >= 300) {
        return;
      }

      final payload = jsonDecode(response.body);
      final data = payload is Map ? payload['data'] : null;
      if (data is! List) return;

      final next = <String, String>{};
      for (final item in data) {
        if (item is! Map) continue;
        final name = item['name']?.toString();
        final code = item['code']?.toString();
        if (name != null &&
            code != null &&
            name.isNotEmpty &&
            code.isNotEmpty) {
          next[name] = code;
        }
      }

      if (!mounted || next.isEmpty) return;
      safeSetState(() {
        _bankCodes = {
          ..._fallbackBankCodes,
          ...next,
        };
      });
    } catch (_) {
      // Keep fallback banks available offline.
    } finally {
      if (mounted) safeSetState(() => _isLoadingBanks = false);
    }
  }

  Future<void> _loadSavedBeneficiaries() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_beneficiaryStorageKey);
      if (raw == null || raw.isEmpty) return;

      final decoded = jsonDecode(raw);
      if (decoded is! List) return;

      final loaded = decoded
          .whereType<Map>()
          .map((item) => _SavedBeneficiary.fromJson(
                Map<String, dynamic>.from(item),
              ))
          .where((item) =>
              item.bank.isNotEmpty &&
              item.accountNumber.length == 10 &&
              item.accountName.isNotEmpty)
          .toList();

      if (!mounted) return;
      safeSetState(() {
        _savedBeneficiaries
          ..clear()
          ..addAll(loaded);
      });
    } catch (_) {
      // Saved beneficiaries are optional; manual entry remains available.
    }
  }

  void _selectBeneficiary(_SavedBeneficiary beneficiary) {
    safeSetState(() {
      _model.bankNameValue = beneficiary.bank;
      _model.bankNameValueController ??= FormFieldController<String>(null);
      _model.bankNameValueController!.value = beneficiary.bank;
      _model.accNoTextController?.text = beneficiary.accountNumber;
      _validatedBankName = beneficiary.bank;
      _validatedAccountName = beneficiary.accountName;
      _typedAccountName = beneficiary.accountName;
      _bankValidationMessage = null;
    });
  }

  Future<void> _openAmountKeypad() async {
    _model.amountFocusNode?.requestFocus();
    final fieldContext = _model.amountFocusNode?.context;
    if (fieldContext != null) {
      await Scrollable.ensureVisible(
        fieldContext,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        alignment: 0.02,
      );
    }
    await Future.delayed(const Duration(milliseconds: 80));
    if (!mounted) return;
    SettleNumericKeypad.show(
      context,
      title: 'Amount',
      submitLabel: 'Send',
      initialValue: _model.amountTextController?.text ?? '',
      allowDecimal: true,
      onChanged: (value) {
        _model.amountTextController?.text = value;
        safeSetState(() {});
        _queueEstimate();
      },
      onDone: (value) {
        _model.amountTextController?.text = value;
        safeSetState(() {});
        _submitTransaction();
      },
    );
  }

  Future<void> _openAccountKeypad() async {
    _model.accNoFocusNode?.requestFocus();
    final fieldContext = _model.accNoFocusNode?.context;
    var showFallbackPreview = true;
    if (fieldContext != null) {
      await Scrollable.ensureVisible(
        fieldContext,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        alignment: 0.0,
      );
      final box = fieldContext.findRenderObject() as RenderBox?;
      if (box != null && box.hasSize) {
        final fieldBottom = box.localToGlobal(Offset.zero).dy + box.size.height;
        final screenHeight = MediaQuery.sizeOf(context).height;
        const estimatedKeypadHeight = 345.0;
        showFallbackPreview =
            fieldBottom > screenHeight - estimatedKeypadHeight;
      }
    }
    await Future.delayed(const Duration(milliseconds: 80));
    if (!mounted) return;
    SettleNumericKeypad.show(
      context,
      title: 'Account number',
      submitLabel: 'Send',
      requiredLength: 10,
      initialValue: _model.accNoTextController?.text ?? '',
      maxLength: 10,
      showPreview: showFallbackPreview,
      onChanged: (value) {
        _model.accNoTextController?.text = value;
        safeSetState(() {});
      },
      onDone: (value) {
        _model.accNoTextController?.text = value;
        _submitTransaction();
      },
    );
  }

  Widget _bankDropdown() {
    return FlutterFlowDropDown<String>(
      controller: _model.bankNameValueController ??=
          FormFieldController<String>(null),
      options: _bankCodes.keys.toList(),
      onChanged: (val) {
        safeSetState(() {
          _model.bankNameValue = val;
          _validatedBankName = val;
          _validatedAccountName = null;
        });
        _validateBankAccount();
      },
      width: MediaQuery.sizeOf(context).width,
      height: 40.0,
      textStyle: FlutterFlowTheme.of(context).bodyMedium.override(
            font: TextStyle(
              fontWeight: FontWeight.normal,
              fontStyle: FlutterFlowTheme.of(context).bodyMedium.fontStyle,
            ),
            fontSize: 12.0,
            letterSpacing: 0.0,
            fontWeight: FontWeight.normal,
            fontStyle: FlutterFlowTheme.of(context).bodyMedium.fontStyle,
          ),
      hintText: 'Select bank',
      searchHintText: 'Type bank name',
      searchHintTextStyle: FlutterFlowTheme.of(context).bodySmall.override(
            font: TextStyle(
              fontWeight: FontWeight.w400,
              fontStyle: FlutterFlowTheme.of(context).bodySmall.fontStyle,
            ),
            color: FlutterFlowTheme.of(context).secondaryText,
            letterSpacing: 0.0,
            fontWeight: FontWeight.w400,
            fontStyle: FlutterFlowTheme.of(context).bodySmall.fontStyle,
          ),
      searchTextStyle: FlutterFlowTheme.of(context).bodyMedium.override(
            font: TextStyle(
              fontWeight: FontWeight.w400,
              fontStyle: FlutterFlowTheme.of(context).bodyMedium.fontStyle,
            ),
            letterSpacing: 0.0,
            fontWeight: FontWeight.w400,
            fontStyle: FlutterFlowTheme.of(context).bodyMedium.fontStyle,
          ),
      searchCursorColor: const Color(0xFF4472C4),
      icon: Icon(
        Icons.keyboard_arrow_down_rounded,
        color: FlutterFlowTheme.of(context).secondaryText,
        size: 15.0,
      ),
      fillColor: FlutterFlowTheme.of(context).secondaryBackground,
      elevation: 2.0,
      borderColor: FlutterFlowTheme.of(context).primaryBackground,
      borderWidth: 2.0,
      borderRadius: 8.0,
      margin: const EdgeInsetsDirectional.fromSTEB(12.0, 6.0, 10.0, 6.0),
      hidesUnderline: true,
      isSearchable: true,
      isMultiSelect: false,
    );
  }

  void _animateAccountName(String value) {
    _accountNameTypingTimer?.cancel();
    safeSetState(() => _typedAccountName = '');

    _accountNameTypingTimer =
        Timer.periodic(const Duration(milliseconds: 38), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_typedAccountName.length >= value.length) {
        timer.cancel();
        return;
      }
      safeSetState(() {
        _typedAccountName = value.substring(0, _typedAccountName.length + 1);
      });
    });
  }

  String? _payloadString(Map<String, dynamic> payload, List<String> keys) {
    for (final key in keys) {
      final value = payload[key];
      if (value is String && value.trim().isNotEmpty) {
        return value.trim();
      }
    }
    return null;
  }

  Future<void> _validateBankAccount() async {
    final accountNumber = (_model.accNoTextController?.text ?? '').trim();
    final bankName = _model.bankNameValue;
    final bankCode = bankName == null ? null : _bankCodes[bankName];

    if (accountNumber.length != 10 || bankCode == null) {
      safeSetState(() {
        _validatedBankName = bankName;
        _validatedAccountName = null;
        _typedAccountName = '';
        _bankValidationMessage =
            bankName == null ? 'Select beneficiary bank.' : null;
      });
      return;
    }

    safeSetState(() {
      _isValidatingBank = true;
      _bankValidationMessage = null;
      _validatedAccountName = null;
      _typedAccountName = '';
    });

    try {
      final response = await http
          .post(
            Uri.parse(_validateBankUrl),
            headers: const {
              'accept': 'application/json',
              'content-type': 'application/json',
            },
            body: jsonEncode({
              'accountNumber': accountNumber,
              'bankCode': bankCode,
            }),
          )
          .timeout(const Duration(seconds: 8));
      final payload = response.body.isEmpty
          ? <String, dynamic>{}
          : jsonDecode(response.body) as Map<String, dynamic>;

      if (!mounted) return;

      final accountName = _payloadString(
        payload,
        const ['accountName', 'account_name', 'account_name_enquiry'],
      );
      final responseOk = response.statusCode >= 200 &&
          response.statusCode < 300 &&
          payload['ok'] != false;
      safeSetState(() {
        _validatedBankName = _payloadString(
              payload,
              const ['bankName', 'bank_name'],
            ) ??
            bankName ??
            _validatedBankName;
        _validatedAccountName = accountName;
        _bankValidationMessage = responseOk && accountName != null
            ? null
            : _payloadString(payload, const ['error', 'message']) ??
                'Unable to validate account.';
        _isValidatingBank = false;
      });
      if (accountName != null && accountName.isNotEmpty) {
        _animateAccountName(accountName);
      }
    } catch (_) {
      if (!mounted) return;
      safeSetState(() {
        _validatedBankName = bankName;
        _validatedAccountName = null;
        _typedAccountName = '';
        _bankValidationMessage = 'Unable to validate account.';
      });
    } finally {
      if (mounted && _isValidatingBank) {
        safeSetState(() => _isValidatingBank = false);
      }
    }
  }

  Future<void> _submitTransaction() async {
    if (_isSending || _isSent) return;
    if (_model.formKey.currentState == null ||
        !_model.formKey.currentState!.validate()) {
      return;
    }

    final bankName = _model.bankNameValue;
    final bankCode = bankName == null ? null : _bankCodes[bankName];
    if (!_enteredAmountInNaira.isFinite ||
        _enteredAmountInNaira <= 0 ||
        bankCode == null ||
        !RegExp(r'^[0-9]{10}$')
            .hasMatch(_model.accNoTextController?.text.trim() ?? '')) {
      showTopNotice(
        context,
        message:
            'Enter an amount, select a bank and enter a 10 digit account number.',
        type: TopNoticeType.caution,
      );
      return;
    }

    safeSetState(() {
      _isSending = true;
      _isSent = false;
    });
    EasyDebounce.cancel('_estimate');
    EasyDebounce.cancel('_model.accNoTextController.validate');
    final estimated = await _fetchEstimate();
    if (!mounted) return;
    if (!estimated) {
      safeSetState(() => _isSending = false);
      showTopNotice(
        context,
        message: _estimateError ??
            'Wait for a valid payment estimate before continuing.',
        type: TopNoticeType.caution,
      );
      return;
    }
    await _validateBankAccount();
    if (!mounted) return;
    safeSetState(() {
      _isSending = false;
      _isSent = true;
    });
    await Future.delayed(const Duration(milliseconds: 300));
    if (!mounted) return;
    if (_estimate == null ||
        _estimatedInputKey != _estimateInputKey ||
        _isEstimating) {
      safeSetState(() {
        _isSending = false;
        _isSent = false;
      });
      showTopNotice(
        context,
        message: 'The amount changed. Check the new estimate and try again.',
        type: TopNoticeType.caution,
      );
      return;
    }
    await context.pushNamed(
      ConfirmTransactionWidget.routeName,
      queryParameters: {
        'settlementAmount': _formattedEnteredAmount,
        'rate': _formattedLiveRate,
        'beneficiaryName': _validatedAccountName ?? 'Beneficiary',
        'bankName': _validatedBankName ?? _model.bankNameValue ?? 'Bank',
        'bankCode': bankCode,
        'accountNumber': _model.accNoTextController?.text ?? '',
        'cryptoAmount': _cryptoAmountText(),
        'crypto': _selectedCrypto,
        'network': _selectedCryptoNetwork,
        'networkCode': _selectedNetworkForApi,
      }.withoutNulls,
    );
    if (!mounted) return;
    safeSetState(() {
      _isSending = false;
      _isSent = false;
    });
  }

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => MainTransactionModel());
    _bankCodes = Map<String, String>.from(_fallbackBankCodes);

    _model.amountTextController ??= TextEditingController();
    _model.amountFocusNode ??= FocusNode();

    _model.amountMask = MaskTextInputFormatter(mask: '##,####');
    _model.accNoTextController ??= TextEditingController();
    _model.accNoFocusNode ??= FocusNode();
    _model.accNoTextController?.addListener(() {
      EasyDebounce.debounce(
        '_model.accNoTextController.validate',
        const Duration(milliseconds: 700),
        _validateBankAccount,
      );
    });
    _loadLiveRate();
    _loadCryptoPrices();
    _loadBanks();
    _loadSavedBeneficiaries();
    _rateRefreshTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      _loadLiveRate();
      _loadCryptoPrices();
    });

    animationsMap.addAll({
      'textFieldOnPageLoadAnimation1': AnimationInfo(
        trigger: AnimationTrigger.onPageLoad,
        effectsBuilder: () => [
          MoveEffect(
            curve: Curves.easeInOut,
            delay: 0.0.ms,
            duration: 600.0.ms,
            begin: Offset(0.0, 0.0),
            end: Offset(0.0, 0.0),
          ),
        ],
      ),
    });
  }

  @override
  void dispose() {
    EasyDebounce.cancel('_estimate');
    _estimateRequestId++;
    _rateRefreshTimer?.cancel();
    _accountNameTypingTimer?.cancel();
    _model.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: scaffoldKey,
      backgroundColor: Color(0xFF4472C4),
      body: Form(
        key: _model.formKey,
        autovalidateMode: AutovalidateMode.disabled,
        child: ListView(
          padding: EdgeInsets.only(
            bottom: 24.0 + MediaQuery.viewPaddingOf(context).bottom,
          ),
          children: [
            Container(
              width: double.infinity,
              constraints: const BoxConstraints(minHeight: 220.0),
              decoration: BoxDecoration(
                color: FlutterFlowTheme.of(context).secondaryBackground,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.max,
                children: [
                  Padding(
                    padding:
                        EdgeInsetsDirectional.fromSTEB(16.0, 46.0, 16.0, 0.0),
                    child: Row(
                      mainAxisSize: MainAxisSize.max,
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        InkWell(
                          splashColor: Colors.transparent,
                          focusColor: Colors.transparent,
                          hoverColor: Colors.transparent,
                          highlightColor: Colors.transparent,
                          onTap: () async {
                            context.pushNamed(DashboardWidget.routeName);
                          },
                          borderRadius: BorderRadius.circular(18.0),
                          child: Container(
                            width: 36.0,
                            height: 36.0,
                            decoration: BoxDecoration(
                              color: const Color(0xFF4472C4)
                                  .withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.arrow_back_rounded,
                              color: Color(0xFF4472C4),
                              size: 21.0,
                            ),
                          ),
                        ),
                        Padding(
                          padding: EdgeInsetsDirectional.fromSTEB(
                              10.0, 0.0, 0.0, 0.0),
                          child: Text(
                            'Transfer Money',
                            style: FlutterFlowTheme.of(context)
                                .headlineMedium
                                .override(
                                  font: TextStyle(
                                    fontWeight: FlutterFlowTheme.of(context)
                                        .headlineMedium
                                        .fontWeight,
                                    fontStyle: FlutterFlowTheme.of(context)
                                        .headlineMedium
                                        .fontStyle,
                                  ),
                                  letterSpacing: 0.0,
                                  fontWeight: FlutterFlowTheme.of(context)
                                      .headlineMedium
                                      .fontWeight,
                                  fontStyle: FlutterFlowTheme.of(context)
                                      .headlineMedium
                                      .fontStyle,
                                ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Align(
                    child: Container(
                      width: MediaQuery.sizeOf(context).width * 0.8,
                      constraints: BoxConstraints(
                        maxWidth: MediaQuery.sizeOf(context).width * 0.8,
                      ),
                      decoration: BoxDecoration(),
                      child: Padding(
                        padding: EdgeInsetsDirectional.fromSTEB(
                            10.0, 0.0, 10.0, 0.0),
                        child: Column(
                          mainAxisSize: MainAxisSize.max,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: EdgeInsetsDirectional.fromSTEB(
                                  0.0, 16.0, 0.0, 0.0),
                              child: Text(
                                'Enter the amount',
                                style: FlutterFlowTheme.of(context)
                                    .bodyMedium
                                    .override(
                                      font: TextStyle(
                                        fontWeight: FontWeight.w700,
                                        fontStyle: FlutterFlowTheme.of(context)
                                            .bodyMedium
                                            .fontStyle,
                                      ),
                                      color: Color(0xFF4472C4),
                                      fontSize: 13.0,
                                      letterSpacing: 0.0,
                                      fontWeight: FontWeight.w700,
                                      fontStyle: FlutterFlowTheme.of(context)
                                          .bodyMedium
                                          .fontStyle,
                                    ),
                              ),
                            ),
                            Padding(
                              padding: EdgeInsetsDirectional.fromSTEB(
                                  0.0, 6.0, 0.0, 0.0),
                              child: Row(
                                mainAxisSize: MainAxisSize.max,
                                mainAxisAlignment: MainAxisAlignment.start,
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  FlutterFlowDropDown<String>(
                                    controller: _model.budgetValueController ??=
                                        FormFieldController<String>(
                                      _model.budgetValue ??= 'NGN',
                                    ),
                                    options: List<String>.from(
                                        ['USD', 'NGN', 'CRYPTO']),
                                    optionLabels: ['USD', 'NGN', 'CRYPTO'],
                                    onChanged: (val) {
                                      safeSetState(
                                          () => _model.budgetValue = val);
                                      _queueEstimate();
                                    },
                                    width: MediaQuery.sizeOf(context).width *
                                        0.262,
                                    height: 46.0,
                                    textStyle: FlutterFlowTheme.of(context)
                                        .bodyMedium
                                        .override(
                                          font: TextStyle(
                                            fontWeight: FontWeight.normal,
                                            fontStyle:
                                                FlutterFlowTheme.of(context)
                                                    .bodyMedium
                                                    .fontStyle,
                                          ),
                                          color: Colors.black,
                                          fontSize: 14.0,
                                          letterSpacing: 0.0,
                                          fontWeight: FontWeight.normal,
                                          fontStyle:
                                              FlutterFlowTheme.of(context)
                                                  .bodyMedium
                                                  .fontStyle,
                                        ),
                                    hintText: 'Symbol',
                                    icon: Icon(
                                      Icons.keyboard_arrow_down_rounded,
                                      color: FlutterFlowTheme.of(context)
                                          .secondaryText,
                                      size: 15.0,
                                    ),
                                    fillColor: FlutterFlowTheme.of(context)
                                        .secondaryBackground,
                                    elevation: 2.0,
                                    borderColor: Color(0xFF4472C4),
                                    borderWidth: 1.0,
                                    borderRadius: 8.0,
                                    margin: EdgeInsetsDirectional.fromSTEB(
                                        10.0, 8.0, 10.0, 8.0),
                                    hidesUnderline: true,
                                    isSearchable: false,
                                    isMultiSelect: false,
                                  ),
                                  Expanded(
                                    child: Padding(
                                      padding: EdgeInsetsDirectional.fromSTEB(
                                          5.0, 0.0, 5.0, 0.0),
                                      child: TextFormField(
                                        controller: _model.amountTextController,
                                        focusNode: _model.amountFocusNode,
                                        readOnly: true,
                                        showCursor: true,
                                        cursorColor:
                                            FlutterFlowTheme.of(context)
                                                .primary,
                                        cursorWidth: 2.0,
                                        onTap: _openAmountKeypad,
                                        onChanged: (_) => EasyDebounce.debounce(
                                          '_model.amountTextController',
                                          Duration(milliseconds: 2000),
                                          () => safeSetState(() {}),
                                        ),
                                        autofocus: true,
                                        obscureText: false,
                                        decoration: InputDecoration(
                                          labelStyle: FlutterFlowTheme.of(
                                                  context)
                                              .bodyMedium
                                              .override(
                                                font: TextStyle(
                                                  fontWeight:
                                                      FlutterFlowTheme.of(
                                                              context)
                                                          .bodyMedium
                                                          .fontWeight,
                                                  fontStyle:
                                                      FlutterFlowTheme.of(
                                                              context)
                                                          .bodyMedium
                                                          .fontStyle,
                                                ),
                                                letterSpacing: 0.0,
                                                fontWeight:
                                                    FlutterFlowTheme.of(context)
                                                        .bodyMedium
                                                        .fontWeight,
                                                fontStyle:
                                                    FlutterFlowTheme.of(context)
                                                        .bodyMedium
                                                        .fontStyle,
                                              ),
                                          hintText: 'Amount',
                                          isDense: true,
                                          contentPadding:
                                              EdgeInsetsDirectional.fromSTEB(
                                                  14.0, 14.0, 14.0, 14.0),
                                          enabledBorder: OutlineInputBorder(
                                            borderSide: BorderSide(
                                              color: Color(0xFF4472C4),
                                              width: 1.0,
                                            ),
                                            borderRadius:
                                                BorderRadius.circular(10.0),
                                          ),
                                          focusedBorder: OutlineInputBorder(
                                            borderSide: BorderSide(
                                              color: Color(0x00000000),
                                              width: 1.0,
                                            ),
                                            borderRadius:
                                                BorderRadius.circular(10.0),
                                          ),
                                          errorBorder: OutlineInputBorder(
                                            borderSide: BorderSide(
                                              color: Color(0xFFC30000),
                                              width: 1.0,
                                            ),
                                            borderRadius:
                                                BorderRadius.circular(10.0),
                                          ),
                                          focusedErrorBorder:
                                              OutlineInputBorder(
                                            borderSide: BorderSide(
                                              color: Color(0xFFC30000),
                                              width: 1.0,
                                            ),
                                            borderRadius:
                                                BorderRadius.circular(10.0),
                                          ),
                                        ),
                                        style: GoogleFonts.inter(
                                          color: Color(0xFF171515),
                                          fontSize: 16.0,
                                          fontWeight: FontWeight.w700,
                                          letterSpacing: 0.0,
                                        ),
                                        textAlign: TextAlign.start,
                                        maxLines: 1,
                                        validator: _model
                                            .amountTextControllerValidator
                                            .asValidator(context),
                                      ).animateOnPageLoad(animationsMap[
                                          'textFieldOnPageLoadAnimation1']!),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Padding(
                              padding: EdgeInsetsDirectional.fromSTEB(
                                  0.0, 5.0, 0.0, 20.0),
                              child: Align(
                                alignment: AlignmentDirectional.center,
                                child: InkWell(
                                  onTap: _refreshRate,
                                  borderRadius: BorderRadius.circular(6.0),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Flexible(
                                        child: Text(
                                          _quoteText,
                                          textAlign: TextAlign.center,
                                          style: FlutterFlowTheme.of(context)
                                              .bodyMedium
                                              .override(
                                                font: TextStyle(
                                                  fontWeight: FontWeight.normal,
                                                  fontStyle:
                                                      FlutterFlowTheme.of(
                                                              context)
                                                          .bodyMedium
                                                          .fontStyle,
                                                ),
                                                color: Color(0xFF4472C4),
                                                fontSize: 11.0,
                                                letterSpacing: 0.0,
                                                fontWeight: FontWeight.normal,
                                                fontStyle:
                                                    FlutterFlowTheme.of(context)
                                                        .bodyMedium
                                                        .fontStyle,
                                              ),
                                        ),
                                      ),
                                      Padding(
                                        padding: EdgeInsetsDirectional.only(
                                            start: 4.0),
                                        child: _isRefreshingRate
                                            ? SizedBox(
                                                width: 11.0,
                                                height: 11.0,
                                                child:
                                                    CircularProgressIndicator(
                                                  strokeWidth: 1.5,
                                                  valueColor:
                                                      AlwaysStoppedAnimation(
                                                          Color(0xFF4472C4)),
                                                ),
                                              )
                                            : Icon(
                                                Icons.refresh_rounded,
                                                color: Color(0xFF4472C4),
                                                size: 13.0,
                                              ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            if (_isEstimating)
                              Padding(
                                padding: const EdgeInsetsDirectional.only(
                                    bottom: 10.0),
                                child: Align(
                                  alignment: AlignmentDirectional.center,
                                  child: Text(
                                    'Getting fee estimate...',
                                    style: GoogleFonts.inter(
                                      color: const Color(0xFF6D7884),
                                      fontSize: 10.4,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              )
                            else if (_estimateError != null)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 10.0),
                                child: Semantics(
                                  liveRegion: true,
                                  child: Text(
                                    _estimateError!,
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      color: Color(0xFFC30000),
                                      fontSize: 12.0,
                                    ),
                                  ),
                                ),
                              )
                            else if (_conversionFeeText != null ||
                                _processingFeeText != null)
                              Padding(
                                padding: const EdgeInsetsDirectional.only(
                                    bottom: 10.0),
                                child: Align(
                                  alignment: AlignmentDirectional.center,
                                  child: Text(
                                    [
                                      if (_conversionFeeText != null)
                                        'Conversion fee: $_conversionFeeText',
                                      if (_processingFeeText != null)
                                        'Processing fee: $_processingFeeText',
                                    ].join('  •  '),
                                    textAlign: TextAlign.center,
                                    style: GoogleFonts.inter(
                                      color: const Color(0xFF6D7884),
                                      fontSize: 10.4,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Material(
              color: Colors.transparent,
              elevation: 1.0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(20.0),
                  bottomRight: Radius.circular(20.0),
                ),
              ),
              child: Container(
                width: double.infinity,
                constraints: BoxConstraints(
                  minHeight: MediaQuery.sizeOf(context).height * 0.42,
                ),
                decoration: BoxDecoration(
                  color: FlutterFlowTheme.of(context).primaryBtnText,
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(20.0),
                    bottomRight: Radius.circular(20.0),
                  ),
                ),
                child: Column(
                  children: [
                    Material(
                      color: Colors.transparent,
                      elevation: 0.0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(0.0),
                      ),
                      child: Container(
                        width: MediaQuery.sizeOf(context).width * 1.0,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(0.0),
                          shape: BoxShape.rectangle,
                        ),
                        child: Padding(
                          padding: EdgeInsetsDirectional.fromSTEB(
                              20.0, 14.0, 20.0, 12.0),
                          child: Column(
                            mainAxisSize: MainAxisSize.max,
                            children: [
                              Column(
                                mainAxisSize: MainAxisSize.max,
                                children: [
                                  Align(
                                    alignment: AlignmentDirectional(-1.0, 0.0),
                                    child: Padding(
                                      padding: EdgeInsetsDirectional.fromSTEB(
                                          5.0, 0.0, 0.0, 0.0),
                                      child: Text(
                                        'Pay with ',
                                        textAlign: TextAlign.justify,
                                        style: FlutterFlowTheme.of(context)
                                            .titleMedium
                                            .override(
                                              font: TextStyle(
                                                fontWeight:
                                                    FlutterFlowTheme.of(context)
                                                        .titleMedium
                                                        .fontWeight,
                                                fontStyle:
                                                    FlutterFlowTheme.of(context)
                                                        .titleMedium
                                                        .fontStyle,
                                              ),
                                              color: Color(0xFF4472C4),
                                              fontSize: 13.0,
                                              letterSpacing: 0.0,
                                              fontWeight:
                                                  FlutterFlowTheme.of(context)
                                                      .titleMedium
                                                      .fontWeight,
                                              fontStyle:
                                                  FlutterFlowTheme.of(context)
                                                      .titleMedium
                                                      .fontStyle,
                                            ),
                                      ),
                                    ),
                                  ),
                                  Row(
                                    mainAxisSize: MainAxisSize.max,
                                    children: [
                                      Flexible(
                                        flex: 1,
                                        child: Padding(
                                          padding:
                                              EdgeInsetsDirectional.fromSTEB(
                                                  0.0, 0.0, 5.0, 0.0),
                                          child: FlutterFlowDropDown<String>(
                                            controller:
                                                _model.cryptoValueController ??=
                                                    FormFieldController<String>(
                                                        _model.cryptoValue ??=
                                                            'TRX'),
                                            options: [
                                              'BTC',
                                              'BNB',
                                              'USDT',
                                              'TRX',
                                              'ETH'
                                            ],
                                            onChanged: (val) {
                                              safeSetState(() {
                                                _model.cryptoValue = val;
                                                if (val == 'USDT') {
                                                  _model.cryptoNetworkValue ??=
                                                      'TRC20';
                                                  _model.cryptoNetworkValueController ??=
                                                      FormFieldController<
                                                          String>('TRC20');
                                                  _model
                                                      .cryptoNetworkValueController!
                                                      .value = _model
                                                          .cryptoNetworkValue ??
                                                      'TRC20';
                                                } else {
                                                  _model.cryptoNetworkValue =
                                                      null;
                                                  _model
                                                      .cryptoNetworkValueController
                                                      ?.value = null;
                                                }
                                              });
                                              _queueEstimate();
                                            },
                                            width: MediaQuery.sizeOf(context)
                                                    .width *
                                                1.0,
                                            height: 40.0,
                                            textStyle:
                                                FlutterFlowTheme.of(context)
                                                    .bodyMedium
                                                    .override(
                                                      font: TextStyle(
                                                        fontWeight:
                                                            FontWeight.normal,
                                                        fontStyle:
                                                            FlutterFlowTheme.of(
                                                                    context)
                                                                .bodyMedium
                                                                .fontStyle,
                                                      ),
                                                      letterSpacing: 0.0,
                                                      fontWeight:
                                                          FontWeight.normal,
                                                      fontStyle:
                                                          FlutterFlowTheme.of(
                                                                  context)
                                                              .bodyMedium
                                                              .fontStyle,
                                                    ),
                                            hintText: 'Crypto',
                                            icon: Icon(
                                              Icons.keyboard_arrow_down_rounded,
                                              color:
                                                  FlutterFlowTheme.of(context)
                                                      .secondaryText,
                                              size: 15.0,
                                            ),
                                            fillColor:
                                                FlutterFlowTheme.of(context)
                                                    .secondaryBackground,
                                            elevation: 2.0,
                                            borderColor:
                                                FlutterFlowTheme.of(context)
                                                    .primaryBackground,
                                            borderWidth: 2.0,
                                            borderRadius: 8.0,
                                            margin:
                                                EdgeInsetsDirectional.fromSTEB(
                                                    14.0, 8.0, 10.0, 8.0),
                                            hidesUnderline: true,
                                            isSearchable: false,
                                            isMultiSelect: false,
                                          ),
                                        ),
                                      ),
                                      Flexible(
                                        flex: 1,
                                        child: _isUsdtSelected
                                            ? FlutterFlowDropDown<String>(
                                                controller: _model
                                                        .cryptoNetworkValueController ??=
                                                    FormFieldController<
                                                        String>(_model
                                                            .cryptoNetworkValue ??=
                                                        'TRC20'),
                                                options: [
                                                  'TRC20',
                                                  'ERC20',
                                                  'BEP20',
                                                ],
                                                onChanged: (val) {
                                                  safeSetState(() => _model
                                                          .cryptoNetworkValue =
                                                      val);
                                                  _queueEstimate();
                                                },
                                                width:
                                                    MediaQuery.sizeOf(context)
                                                            .width *
                                                        1.0,
                                                height: 40.0,
                                                textStyle:
                                                    FlutterFlowTheme.of(context)
                                                        .bodyMedium
                                                        .override(
                                                          font: TextStyle(
                                                            fontWeight:
                                                                FontWeight
                                                                    .normal,
                                                            fontStyle:
                                                                FlutterFlowTheme.of(
                                                                        context)
                                                                    .bodyMedium
                                                                    .fontStyle,
                                                          ),
                                                          letterSpacing: 0.0,
                                                          fontWeight:
                                                              FontWeight.normal,
                                                          fontStyle:
                                                              FlutterFlowTheme.of(
                                                                      context)
                                                                  .bodyMedium
                                                                  .fontStyle,
                                                        ),
                                                hintText: 'Network',
                                                icon: Icon(
                                                  Icons
                                                      .keyboard_arrow_down_rounded,
                                                  color: FlutterFlowTheme.of(
                                                          context)
                                                      .secondaryText,
                                                  size: 15.0,
                                                ),
                                                fillColor:
                                                    FlutterFlowTheme.of(context)
                                                        .secondaryBackground,
                                                elevation: 2.0,
                                                borderColor:
                                                    FlutterFlowTheme.of(context)
                                                        .primaryBackground,
                                                borderWidth: 2.0,
                                                borderRadius: 8.0,
                                                margin: EdgeInsetsDirectional
                                                    .fromSTEB(
                                                        14.0, 8.0, 10.0, 8.0),
                                                hidesUnderline: true,
                                                isSearchable: false,
                                                isMultiSelect: false,
                                              )
                                            : Container(
                                                height: 40.0,
                                                alignment: Alignment.centerLeft,
                                                padding: EdgeInsetsDirectional
                                                    .fromSTEB(
                                                        14.0, 0.0, 10.0, 0.0),
                                                decoration: BoxDecoration(
                                                  color: FlutterFlowTheme.of(
                                                          context)
                                                      .secondaryBackground,
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                          8.0),
                                                  border: Border.all(
                                                    color: FlutterFlowTheme.of(
                                                            context)
                                                        .primaryBackground,
                                                    width: 2.0,
                                                  ),
                                                ),
                                                child: Text(
                                                  _selectedCryptoNetwork,
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  style: FlutterFlowTheme.of(
                                                          context)
                                                      .bodyMedium
                                                      .override(
                                                        font: TextStyle(
                                                          fontWeight:
                                                              FontWeight.normal,
                                                          fontStyle:
                                                              FlutterFlowTheme.of(
                                                                      context)
                                                                  .bodyMedium
                                                                  .fontStyle,
                                                        ),
                                                        letterSpacing: 0.0,
                                                        fontWeight:
                                                            FontWeight.normal,
                                                        fontStyle:
                                                            FlutterFlowTheme.of(
                                                                    context)
                                                                .bodyMedium
                                                                .fontStyle,
                                                      ),
                                                ),
                                              ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              Column(
                                mainAxisSize: MainAxisSize.max,
                                children: [
                                  Align(
                                    alignment: AlignmentDirectional(-1.0, 0.0),
                                    child: Padding(
                                      padding: EdgeInsetsDirectional.fromSTEB(
                                          5.0, 8.0, 0.0, 4.0),
                                      child: Text(
                                        'Pay To ',
                                        textAlign: TextAlign.justify,
                                        style: FlutterFlowTheme.of(context)
                                            .titleMedium
                                            .override(
                                              font: TextStyle(
                                                fontWeight:
                                                    FlutterFlowTheme.of(context)
                                                        .titleMedium
                                                        .fontWeight,
                                                fontStyle:
                                                    FlutterFlowTheme.of(context)
                                                        .titleMedium
                                                        .fontStyle,
                                              ),
                                              color: Color(0xFF4472C4),
                                              fontSize: 13.0,
                                              letterSpacing: 0.0,
                                              fontWeight:
                                                  FlutterFlowTheme.of(context)
                                                      .titleMedium
                                                      .fontWeight,
                                              fontStyle:
                                                  FlutterFlowTheme.of(context)
                                                      .titleMedium
                                                      .fontStyle,
                                            ),
                                      ),
                                    ),
                                  ),
                                  if (_savedBeneficiaries.isNotEmpty)
                                    Container(
                                      width: double.infinity,
                                      margin: EdgeInsetsDirectional.fromSTEB(
                                          0.0, 0.0, 0.0, 5.0),
                                      padding: EdgeInsetsDirectional.fromSTEB(
                                          10.0, 0.0, 10.0, 0.0),
                                      decoration: BoxDecoration(
                                        color: Color(0xFF4472C4)
                                            .withValues(alpha: 0.08),
                                        borderRadius:
                                            BorderRadius.circular(10.0),
                                        border: Border.all(
                                          color: Color(0xFF4472C4)
                                              .withValues(alpha: 0.12),
                                        ),
                                      ),
                                      child: DropdownButtonHideUnderline(
                                        child:
                                            DropdownButton<_SavedBeneficiary>(
                                          isExpanded: true,
                                          hint: Text(
                                            'Select beneficiary',
                                            style: FlutterFlowTheme.of(context)
                                                .bodySmall
                                                .override(
                                                  font: TextStyle(
                                                    fontWeight:
                                                        FontWeight.normal,
                                                    fontStyle:
                                                        FlutterFlowTheme.of(
                                                                context)
                                                            .bodySmall
                                                            .fontStyle,
                                                  ),
                                                  color: Color(0xFF4472C4),
                                                  fontSize: 12.0,
                                                  letterSpacing: 0.0,
                                                  fontWeight: FontWeight.normal,
                                                  fontStyle:
                                                      FlutterFlowTheme.of(
                                                              context)
                                                          .bodySmall
                                                          .fontStyle,
                                                ),
                                          ),
                                          icon: Icon(
                                            Icons.keyboard_arrow_down_rounded,
                                            color: Color(0xFF4472C4),
                                            size: 18.0,
                                          ),
                                          items: _savedBeneficiaries
                                              .map(
                                                (beneficiary) =>
                                                    DropdownMenuItem<
                                                        _SavedBeneficiary>(
                                                  value: beneficiary,
                                                  child: Text(
                                                    '${beneficiary.name} • ${beneficiary.bank}',
                                                    maxLines: 1,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                    style: FlutterFlowTheme.of(
                                                            context)
                                                        .bodySmall
                                                        .override(
                                                          font: TextStyle(
                                                            fontWeight:
                                                                FontWeight
                                                                    .normal,
                                                            fontStyle:
                                                                FlutterFlowTheme.of(
                                                                        context)
                                                                    .bodySmall
                                                                    .fontStyle,
                                                          ),
                                                          fontSize: 12.0,
                                                          letterSpacing: 0.0,
                                                          fontWeight:
                                                              FontWeight.normal,
                                                          fontStyle:
                                                              FlutterFlowTheme.of(
                                                                      context)
                                                                  .bodySmall
                                                                  .fontStyle,
                                                        ),
                                                  ),
                                                ),
                                              )
                                              .toList(),
                                          onChanged: (beneficiary) {
                                            if (beneficiary != null) {
                                              _selectBeneficiary(beneficiary);
                                            }
                                          },
                                        ),
                                      ),
                                    ),
                                  _bankDropdown(),
                                  SizedBox(height: 5.0),
                                  TextFormField(
                                    controller: _model.accNoTextController,
                                    focusNode: _model.accNoFocusNode,
                                    readOnly: true,
                                    showCursor: true,
                                    cursorColor:
                                        FlutterFlowTheme.of(context).primary,
                                    cursorWidth: 2.0,
                                    onTap: _openAccountKeypad,
                                    obscureText: false,
                                    decoration: InputDecoration(
                                      labelText: 'Account Number',
                                      hintText:
                                          'Select beneficiary or enter account number',
                                      labelStyle: FlutterFlowTheme.of(context)
                                          .bodyMedium
                                          .override(
                                            font: TextStyle(
                                              fontWeight: FontWeight.normal,
                                              fontStyle:
                                                  FlutterFlowTheme.of(context)
                                                      .bodyMedium
                                                      .fontStyle,
                                            ),
                                            letterSpacing: 0.0,
                                            fontWeight: FontWeight.normal,
                                            fontStyle:
                                                FlutterFlowTheme.of(context)
                                                    .bodyMedium
                                                    .fontStyle,
                                          ),
                                      enabledBorder: OutlineInputBorder(
                                        borderSide: BorderSide(
                                          color: FlutterFlowTheme.of(context)
                                              .primaryBackground,
                                          width: 2.0,
                                        ),
                                        borderRadius:
                                            BorderRadius.circular(8.0),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderSide: BorderSide(
                                          color: Color(0x00000000),
                                          width: 2.0,
                                        ),
                                        borderRadius:
                                            BorderRadius.circular(8.0),
                                      ),
                                      errorBorder: OutlineInputBorder(
                                        borderSide: BorderSide(
                                          color: Color(0x00000000),
                                          width: 2.0,
                                        ),
                                        borderRadius:
                                            BorderRadius.circular(8.0),
                                      ),
                                      focusedErrorBorder: OutlineInputBorder(
                                        borderSide: BorderSide(
                                          color: Color(0x00000000),
                                          width: 2.0,
                                        ),
                                        borderRadius:
                                            BorderRadius.circular(8.0),
                                      ),
                                      filled: true,
                                      fillColor: FlutterFlowTheme.of(context)
                                          .secondaryBackground,
                                      contentPadding:
                                          EdgeInsetsDirectional.fromSTEB(
                                              14.0, 14.0, 18.0, 14.0),
                                    ),
                                    style: FlutterFlowTheme.of(context)
                                        .bodySmall
                                        .override(
                                          font: TextStyle(
                                            fontWeight: FontWeight.normal,
                                            fontStyle:
                                                FlutterFlowTheme.of(context)
                                                    .bodySmall
                                                    .fontStyle,
                                          ),
                                          letterSpacing: 0.0,
                                          fontWeight: FontWeight.normal,
                                          fontStyle:
                                              FlutterFlowTheme.of(context)
                                                  .bodySmall
                                                  .fontStyle,
                                        ),
                                    maxLines: 1,
                                    validator: _model
                                        .accNoTextControllerValidator
                                        .asValidator(context),
                                  ),
                                  Align(
                                    alignment: AlignmentDirectional(-0.95, 0.0),
                                    child: Padding(
                                      padding: EdgeInsetsDirectional.fromSTEB(
                                          0.0, 10.0, 0.0, 0.0),
                                      child: _validatedAccountName != null
                                          ? Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Flexible(
                                                  child: Text(
                                                    '${_typedAccountName.isEmpty ? '|' : _typedAccountName} • ${_validatedBankName ?? _model.bankNameValue ?? 'Bank'}',
                                                    maxLines: 1,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                    style: FlutterFlowTheme.of(
                                                            context)
                                                        .bodySmall
                                                        .override(
                                                          font: TextStyle(
                                                            fontWeight:
                                                                FontWeight.w600,
                                                            fontStyle:
                                                                FlutterFlowTheme.of(
                                                                        context)
                                                                    .bodySmall
                                                                    .fontStyle,
                                                          ),
                                                          color:
                                                              Color(0xFF4472C4),
                                                          fontSize: 10.5,
                                                          letterSpacing: 0.0,
                                                          fontWeight:
                                                              FontWeight.w600,
                                                          fontStyle:
                                                              FlutterFlowTheme.of(
                                                                      context)
                                                                  .bodySmall
                                                                  .fontStyle,
                                                        ),
                                                  ),
                                                ),
                                                const SizedBox(width: 5.0),
                                                Icon(
                                                  Icons.verified_rounded,
                                                  color: Color(0xFF18A058),
                                                  size: 15.0,
                                                ),
                                              ],
                                            )
                                          : Text(
                                              _isValidatingBank
                                                  ? 'Validating bank account...'
                                                  : (_bankValidationMessage ??
                                                      (_isLoadingBanks
                                                          ? 'Loading banks...'
                                                          : (_validatedBankName ??
                                                              'Bank name appears here'))),
                                              style:
                                                  FlutterFlowTheme.of(context)
                                                      .bodySmall
                                                      .override(
                                                        font: TextStyle(
                                                          fontWeight:
                                                              FontWeight.normal,
                                                          fontStyle:
                                                              FlutterFlowTheme.of(
                                                                      context)
                                                                  .bodySmall
                                                                  .fontStyle,
                                                        ),
                                                        letterSpacing: 0.0,
                                                        fontWeight:
                                                            FontWeight.normal,
                                                        fontStyle:
                                                            FlutterFlowTheme.of(
                                                                    context)
                                                                .bodySmall
                                                                .fontStyle,
                                                      ),
                                            ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: EdgeInsetsDirectional.fromSTEB(0.0, 8.0, 0.0, 0.0),
              child: Row(
                mainAxisSize: MainAxisSize.max,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.max,
                    children: [
                      Padding(
                        padding:
                            EdgeInsetsDirectional.fromSTEB(0.0, 40.0, 0.0, 0.0),
                        child: StatusActionButton(
                          text: 'Send',
                          isLoading: _isSending,
                          isDone: _isSent,
                          onPressed: _submitTransaction,
                          idleIcon: Icons.send_rounded,
                          backgroundColor: Colors.white,
                          textColor: const Color(0xFF4472C4),
                          iconBackgroundColor: const Color(0xFF4472C4),
                          iconColor: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Padding(
              padding: EdgeInsetsDirectional.fromSTEB(0.0, 20.0, 0.0, 0.0),
              child: Text(
                'Tap to complete transaction',
                style: FlutterFlowTheme.of(context).bodyMedium.override(
                      font: TextStyle(
                        fontWeight: FontWeight.normal,
                        fontStyle:
                            FlutterFlowTheme.of(context).bodyMedium.fontStyle,
                      ),
                      color: FlutterFlowTheme.of(context).primaryBtnText,
                      letterSpacing: 0.0,
                      fontWeight: FontWeight.normal,
                      fontStyle:
                          FlutterFlowTheme.of(context).bodyMedium.fontStyle,
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SavedBeneficiary {
  const _SavedBeneficiary({
    required this.name,
    required this.bank,
    required this.accountNumber,
    required this.accountName,
  });

  final String name;
  final String bank;
  final String accountNumber;
  final String accountName;

  factory _SavedBeneficiary.fromJson(Map<String, dynamic> json) {
    return _SavedBeneficiary(
      name: json['name']?.toString() ?? 'Beneficiary',
      bank: json['bank']?.toString() ?? '',
      accountNumber: json['accountNumber']?.toString() ?? '',
      accountName: json['accountName']?.toString() ?? '',
    );
  }
}
