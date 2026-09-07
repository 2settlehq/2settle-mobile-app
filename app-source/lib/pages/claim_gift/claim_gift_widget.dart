import 'dart:async';

import '/components/top_notice.dart';
import '/data/ng_bank_codes.dart';
import '/flutter_flow/flutter_flow_drop_down.dart';
import '/flutter_flow/flutter_flow_icon_button.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/form_field_controller.dart';
import '/index.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ClaimGiftWidget extends StatefulWidget {
  const ClaimGiftWidget({super.key});

  static String routeName = 'ClaimGift';
  static String routePath = 'claimGift';

  @override
  State<ClaimGiftWidget> createState() => _ClaimGiftWidgetState();
}

class _ClaimGiftWidgetState extends State<ClaimGiftWidget> {
  static const _blue = Color(0xFF4472C4);
  static const _green = Color(0xFF17A34A);
  static const _red = Color(0xFFC30000);
  static const _beneficiaryStorageKey = '2settle_saved_beneficiaries';
  static const _banksUrl = 'https://2settle.io/api/banks?country=NG&limit=50';
  static const _validateBankUrl =
      'https://2settlemobile.vercel.app/api/banks/resolve';
  static const _giftClaimBaseUrl = 'https://2settlemobile.vercel.app/api/gifts';

  final _giftIdController = TextEditingController();
  final _accountController = TextEditingController();
  FormFieldController<String>? _bankFieldController;
  Timer? _validationDebounce;
  Timer? _typingTimer;
  Timer? _giftCheckDebounce;
  Timer? _giftAmountTypingTimer;

  Map<String, String> _bankCodes = Map<String, String>.from(ngBankCodes);
  String _receiveMode = 'Add account number';
  String? _selectedBank;
  String? _validatedAccountName;
  String _typedAccountName = '';
  String? _validationMessage;
  _Beneficiary? _selectedBeneficiary;
  List<_Beneficiary> _beneficiaries = [];
  String _giftCheckMessage = 'Enter the 6 character gift ID.';
  String _giftAmount = '';
  String _typedGiftAmount = '';
  String _giftStatusCode = '';
  String _claimedBankName = '';
  bool _giftValid = false;
  bool _isLoadingBanks = false;
  bool _isValidatingAccount = false;
  bool _isCheckingGift = false;
  bool _isClaiming = false;

  List<String> get _banks => _bankCodes.keys.toList();

  @override
  void initState() {
    super.initState();
    _loadBeneficiaries();
    _loadBanks();
    _accountController.addListener(_queueAccountValidation);
    _giftIdController.addListener(_queueGiftCheck);
  }

  @override
  void dispose() {
    _validationDebounce?.cancel();
    _typingTimer?.cancel();
    _giftCheckDebounce?.cancel();
    _giftAmountTypingTimer?.cancel();
    _giftIdController.dispose();
    _accountController.dispose();
    super.dispose();
  }

  Future<void> _loadBeneficiaries() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_beneficiaryStorageKey);
    if (raw == null || raw.isEmpty) return;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return;
      final loaded = decoded
          .whereType<Map>()
          .map((item) => _Beneficiary.fromJson(Map<String, dynamic>.from(item)))
          .where((item) => item.accountNumber.isNotEmpty)
          .toList();
      if (!mounted) return;
      safeSetState(() {
        _beneficiaries = loaded;
        _selectedBeneficiary =
            loaded.where((item) => item.isDefault).firstOrNull ??
                loaded.firstOrNull;
      });
    } catch (_) {}
  }

  Future<void> _loadBanks() async {
    safeSetState(() => _isLoadingBanks = true);
    try {
      final response = await http.get(
        Uri.parse(_banksUrl),
        headers: const {'accept': 'application/json'},
      ).timeout(const Duration(seconds: 8));
      if (response.statusCode < 200 || response.statusCode >= 300) return;
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
      safeSetState(() => _bankCodes = {...ngBankCodes, ...next});
    } catch (_) {
      // Fallback bank list remains available.
    } finally {
      if (mounted) safeSetState(() => _isLoadingBanks = false);
    }
  }

  void _queueAccountValidation() {
    _validationDebounce?.cancel();
    _validationDebounce =
        Timer(const Duration(milliseconds: 520), _validateAccount);
  }

  void _animateAccountName(String value) {
    _typingTimer?.cancel();
    safeSetState(() => _typedAccountName = '');
    _typingTimer = Timer.periodic(const Duration(milliseconds: 38), (timer) {
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

  void _animateGiftAmount(String value) {
    _giftAmountTypingTimer?.cancel();
    safeSetState(() => _typedGiftAmount = '');
    _giftAmountTypingTimer =
        Timer.periodic(const Duration(milliseconds: 38), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_typedGiftAmount.length >= value.length) {
        timer.cancel();
        return;
      }
      safeSetState(() {
        _typedGiftAmount = value.substring(0, _typedGiftAmount.length + 1);
      });
    });
  }

  String get _giftReference =>
      '2S-${_giftIdController.text.trim().toUpperCase()}';

  void _queueGiftCheck() {
    final cleaned = _giftIdController.text
        .replaceAll(RegExp('[^a-zA-Z0-9]'), '')
        .toUpperCase();
    if (_giftIdController.text != cleaned) {
      _giftIdController.value = TextEditingValue(
        text: cleaned,
        selection: TextSelection.collapsed(offset: cleaned.length),
      );
      return;
    }
    _giftCheckDebounce?.cancel();
    if (cleaned.length < 6) {
      safeSetState(() {
        _giftValid = false;
        _giftAmount = '';
        _typedGiftAmount = '';
        _giftStatusCode = '';
        _claimedBankName = '';
        _giftCheckMessage = 'Enter the 6 character gift ID.';
      });
      return;
    }
    _giftCheckDebounce =
        Timer(const Duration(milliseconds: 450), _checkGiftReference);
  }

  String _formatGiftAmount(Map<String, dynamic> payload) {
    final amount = _payloadString(
      payload,
      const [
        'amount',
        'amountNgn',
        'fiatAmount',
        'settlementAmount',
        'settlement_amount',
        'value',
      ],
    );
    final currency = _payloadString(
          payload,
          const ['currency', 'settlementCurrency', 'settlement_currency'],
        ) ??
        'NGN';
    if (amount == null) return '';
    final parsed = double.tryParse(amount.replaceAll(',', ''));
    if (parsed == null) return '$currency $amount';
    final prefix = currency.toUpperCase() == 'NGN' ? '₦' : '$currency ';
    return '$prefix${_formatNumberWithCommas(parsed)}';
  }

  String _formatNumberWithCommas(double value) {
    final fixed = value == value.truncateToDouble()
        ? value.toStringAsFixed(0)
        : value.toStringAsFixed(2);
    final parts = fixed.split('.');
    final whole = parts.first;
    final buffer = StringBuffer();
    for (var index = 0; index < whole.length; index++) {
      final remaining = whole.length - index;
      buffer.write(whole[index]);
      if (remaining > 1 && remaining % 3 == 1) {
        buffer.write(',');
      }
    }
    return parts.length > 1
        ? '${buffer.toString()}.${parts.last}'
        : buffer.toString();
  }

  Future<void> _checkGiftReference() async {
    final reference = _giftReference;
    if (_giftIdController.text.trim().length != 6) return;
    safeSetState(() {
      _isCheckingGift = true;
      _giftValid = false;
      _giftAmount = '';
      _typedGiftAmount = '';
      _giftStatusCode = '';
      _claimedBankName = '';
      _giftCheckMessage = 'Checking gift ID...';
    });
    try {
      final response = await http.get(
        Uri.parse(
          '$_giftClaimBaseUrl/${Uri.encodeComponent(reference)}?ts=${DateTime.now().millisecondsSinceEpoch}',
        ),
        headers: const {'accept': 'application/json'},
      ).timeout(const Duration(seconds: 8));
      final decoded = response.body.isEmpty ? null : jsonDecode(response.body);
      final payload = decoded is Map<String, dynamic>
          ? decoded
          : decoded is Map
              ? Map<String, dynamic>.from(decoded)
              : <String, dynamic>{};
      final ok = response.statusCode >= 200 &&
          response.statusCode < 300 &&
          payload['ok'] != false;
      final amount = _formatGiftAmount(payload);
      final status = (_payloadString(payload, const ['status', 'state']) ?? '')
          .toLowerCase();
      final claimedBank = _payloadString(payload, const [
            'claimedBankName',
            'bankName',
            'bank_name',
            'receiverBankName',
            'receiver_bank_name',
            'settlementBankName',
            'settlement_bank_name',
            'destinationBankName',
            'destination_bank_name',
            'institutionName',
          ]) ??
          '';
      final isConfirmed = ok && (status == 'confirmed' || status == 'created');
      final isPending = ok && status == 'pending';
      final isSettled = ok && status == 'settled';
      final isCancelled = ok && (status == 'cancelled' || status == 'canceled');
      if (!mounted) return;
      safeSetState(() {
        _giftValid = isConfirmed;
        _giftAmount = amount;
        _giftStatusCode = status;
        _claimedBankName = claimedBank;
        _giftCheckMessage = isConfirmed
            ? 'Gift ID is valid.'
            : isPending
                ? 'Gift ID is valid but not funded yet.'
                : isSettled
                    ? 'This ID has been claimed${claimedBank.isEmpty ? '' : ' to $claimedBank'}.'
                    : isCancelled
                        ? 'This Gift ID has been cancelled.'
                        : ok
                            ? status.isEmpty
                                ? 'Gift ID could not be claimed.'
                                : 'Gift ID is $status.'
                            : 'Gift ID not found.';
        _isCheckingGift = false;
      });
      if ((isConfirmed || isPending) && amount.isNotEmpty) {
        _animateGiftAmount(amount);
      }
    } catch (_) {
      if (!mounted) return;
      safeSetState(() {
        _giftValid = false;
        _giftAmount = '';
        _typedGiftAmount = '';
        _giftStatusCode = '';
        _claimedBankName = '';
        _giftCheckMessage = 'Gift ID could not be verified.';
        _isCheckingGift = false;
      });
    }
  }

  String? _payloadString(Map<String, dynamic> payload, List<String> keys) {
    for (final key in keys) {
      final value = payload[key];
      final normalized = _normalizePayloadValue(value);
      if (normalized != null) return normalized;
      if (payload['data'] is Map) {
        final nested = (payload['data'] as Map)[key];
        final nestedNormalized = _normalizePayloadValue(nested);
        if (nestedNormalized != null) return nestedNormalized;
      }
      if (payload['gift'] is Map) {
        final nested = (payload['gift'] as Map)[key];
        final nestedNormalized = _normalizePayloadValue(nested);
        if (nestedNormalized != null) return nestedNormalized;
      }
    }
    return null;
  }

  String? _normalizePayloadValue(dynamic value) {
    if (value is String && value.trim().isNotEmpty) return value.trim();
    if (value is num) return value.toString();
    return null;
  }

  Future<void> _validateAccount() async {
    final accountNumber = _accountController.text.trim();
    final bankName = _selectedBank;
    final bankCode = bankName == null ? null : _bankCodes[bankName];

    if (accountNumber.isEmpty) {
      safeSetState(() {
        _validatedAccountName = null;
        _typedAccountName = '';
        _validationMessage = null;
      });
      return;
    }

    if (accountNumber.length != 10 || bankCode == null) {
      safeSetState(() {
        _validatedAccountName = null;
        _typedAccountName = '';
        _validationMessage = accountNumber.length == 10
            ? 'Select a supported bank.'
            : 'Enter a 10 digit account number.';
      });
      return;
    }

    safeSetState(() {
      _isValidatingAccount = true;
      _validatedAccountName = null;
      _typedAccountName = '';
      _validationMessage = null;
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
      final accountName = _payloadString(
        payload,
        const ['accountName', 'account_name', 'account_name_enquiry'],
      );
      final ok = response.statusCode >= 200 &&
          response.statusCode < 300 &&
          payload['ok'] != false &&
          accountName != null;
      if (!mounted) return;
      safeSetState(() {
        _validatedAccountName = accountName;
        _validationMessage = ok
            ? null
            : _payloadString(payload, const ['error', 'message']) ??
                'Unable to validate account.';
        _isValidatingAccount = false;
      });
      if (accountName != null && accountName.isNotEmpty) {
        _animateAccountName(accountName);
      }
    } catch (_) {
      if (!mounted) return;
      safeSetState(() {
        _validatedAccountName = null;
        _typedAccountName = '';
        _validationMessage = 'Unable to validate account.';
      });
    } finally {
      if (mounted && _isValidatingAccount) {
        safeSetState(() => _isValidatingAccount = false);
      }
    }
  }

  String? get _claimBankCode {
    if (_receiveMode == 'Select from beneficiary') {
      final bank = _selectedBeneficiary?.bank;
      return bank == null ? null : _bankCodes[bank];
    }
    final bank = _selectedBank;
    return bank == null ? null : _bankCodes[bank];
  }

  String get _claimAccountNumber {
    if (_receiveMode == 'Select from beneficiary') {
      return _selectedBeneficiary?.accountNumber ?? '';
    }
    return _accountController.text.trim();
  }

  void _openClaimConfirmation() {
    final bankCode = _claimBankCode;
    final accountNumber = _claimAccountNumber;
    final bankName = _receiveMode == 'Select from beneficiary'
        ? _selectedBeneficiary?.bank
        : _selectedBank;
    final accountName = _receiveMode == 'Select from beneficiary'
        ? _selectedBeneficiary?.name
        : _validatedAccountName;

    if (_receiveMode == 'Select from beneficiary' &&
        _selectedBeneficiary == null) {
      showTopNotice(
        context,
        message: 'Select a beneficiary first.',
        type: TopNoticeType.caution,
      );
      return;
    }
    if (bankCode == null || accountNumber.isEmpty || bankName == null) {
      showTopNotice(
        context,
        message: 'Select a valid receiving account first.',
        type: TopNoticeType.caution,
      );
      return;
    }
    if (_receiveMode == 'Add account number' &&
        (_validatedAccountName == null || _validatedAccountName!.isEmpty)) {
      showTopNotice(
        context,
        message: 'Validate the account number before claiming.',
        type: TopNoticeType.caution,
      );
      return;
    }
    if (_giftIdController.text.trim().length != 6) {
      showTopNotice(
        context,
        message: 'Enter the complete 2S gift ID.',
        type: TopNoticeType.caution,
      );
      return;
    }
    if (!_giftValid) {
      showTopNotice(
        context,
        message: 'Validate the gift ID before claiming.',
        type: TopNoticeType.caution,
      );
      return;
    }

    context.pushNamed(
      ConfirmGiftClaimWidget.routeName,
      queryParameters: {
        'reference': _giftReference,
        'amount': _giftAmount,
        'bankName': bankName,
        'accountNumber': accountNumber,
        'accountName': accountName ?? 'Receiver',
        'bankCode': bankCode,
      }.withoutNulls,
    );
  }

  InputDecoration _inputDecoration(String label, {String? hint}) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      isDense: true,
      filled: true,
      fillColor: Colors.white,
      contentPadding:
          const EdgeInsetsDirectional.fromSTEB(14.0, 12.0, 14.0, 12.0),
      labelStyle: GoogleFonts.inter(
        color: const Color(0xFF6D7884),
        fontSize: 10.8,
        fontWeight: FontWeight.w500,
      ),
      hintStyle: GoogleFonts.inter(
        color: const Color(0xFF9AA6B2),
        fontSize: 10.4,
        fontWeight: FontWeight.w500,
      ),
      enabledBorder: OutlineInputBorder(
        borderSide: BorderSide(color: _blue.withValues(alpha: 0.18)),
        borderRadius: BorderRadius.circular(12.0),
      ),
      focusedBorder: OutlineInputBorder(
        borderSide: const BorderSide(color: _blue),
        borderRadius: BorderRadius.circular(12.0),
      ),
    );
  }

  Widget _accountNameStatus() {
    final theme = FlutterFlowTheme.of(context);
    if (_isValidatingAccount) {
      return Row(
        children: [
          const SizedBox(
            width: 15.0,
            height: 15.0,
            child: CircularProgressIndicator(
              strokeWidth: 2.0,
              valueColor: AlwaysStoppedAnimation<Color>(_blue),
            ),
          ),
          const SizedBox(width: 8.0),
          Text(
            'Validating account...',
            style: GoogleFonts.inter(
              color: theme.secondaryText,
              fontSize: 10.7,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      );
    }
    if (_typedAccountName.isNotEmpty || _validatedAccountName != null) {
      final target = _validatedAccountName ?? '';
      final typing = _typedAccountName.length < target.length;
      return Row(
        children: [
          Flexible(
            child: Text(
              '${_typedAccountName.isEmpty ? '' : _typedAccountName}${typing ? '|' : ''}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.bodyMedium.override(
                color: theme.primaryText,
                fontSize: 11.6,
                letterSpacing: 0.0,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(width: 6.0),
          const Icon(Icons.verified_rounded, color: _blue, size: 17.0),
        ],
      );
    }
    return Text(
      _validationMessage ?? 'Account name will appear here after validation.',
      style: GoogleFonts.inter(
        color: _validationMessage == null
            ? FlutterFlowTheme.of(context).secondaryText
            : _red,
        fontSize: 10.4,
        fontWeight: FontWeight.w500,
      ),
    );
  }

  Widget _giftStatus() {
    final theme = FlutterFlowTheme.of(context);
    final isSettled = _giftStatusCode == 'settled';
    final isPending = _giftStatusCode == 'pending';
    final isCancelled =
        _giftStatusCode == 'cancelled' || _giftStatusCode == 'canceled';
    final statusColor = _giftValid ? _blue : _red;
    if (_isCheckingGift) {
      return Row(
        children: [
          const SizedBox(
            width: 15.0,
            height: 15.0,
            child: CircularProgressIndicator(
              strokeWidth: 2.0,
              valueColor: AlwaysStoppedAnimation<Color>(_blue),
            ),
          ),
          const SizedBox(width: 8.0),
          Text(
            _giftCheckMessage,
            style: GoogleFonts.inter(
              color: theme.secondaryText,
              fontSize: 10.7,
              fontWeight: FontWeight.w500,
            ),
          )
        ],
      );
    }
    if (_giftValid && _giftAmount.isNotEmpty) {
      final typing = _typedGiftAmount.length < _giftAmount.length;
      return Row(
        children: [
          const Icon(Icons.verified_rounded, color: _green, size: 17.0),
          const SizedBox(width: 7.0),
          Expanded(
            child: RichText(
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              text: TextSpan(
                style: GoogleFonts.inter(
                  color: _green,
                  fontSize: 10.8,
                  fontWeight: FontWeight.w600,
                ),
                children: [
                  const TextSpan(text: 'Gift ID is valid with '),
                  TextSpan(
                    text:
                        '${_typedGiftAmount.isEmpty ? '' : _typedGiftAmount}${typing ? '|' : ''}',
                    style: GoogleFonts.inter(
                      color: _green,
                      fontSize: 10.9,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const TextSpan(text: ' ready to be claimed'),
                ],
              ),
            ),
          ),
        ],
      );
    }

    if (isSettled) {
      return Row(
        children: [
          const Icon(Icons.info_outline_rounded, color: _red, size: 17.0),
          const SizedBox(width: 7.0),
          Expanded(
            child: Text(
              _claimedBankName.isEmpty
                  ? 'This ID has been claimed.'
                  : 'This ID has been claimed to $_claimedBankName.',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.inter(
                color: _red,
                fontSize: 10.8,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      );
    }

    if (isCancelled) {
      return Row(
        children: [
          const Icon(Icons.cancel_rounded, color: _red, size: 17.0),
          const SizedBox(width: 7.0),
          Expanded(
            child: Text(
              'This Gift ID has been cancelled.',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.inter(
                color: _red,
                fontSize: 10.8,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      );
    }

    if (isPending) {
      return Row(
        children: [
          const Icon(Icons.hourglass_empty_rounded,
              color: Color(0xFFE08A1E), size: 17.0),
          const SizedBox(width: 7.0),
          Expanded(
            child: RichText(
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              text: TextSpan(
                style: GoogleFonts.inter(
                  color: const Color(0xFFE08A1E),
                  fontSize: 10.8,
                  fontWeight: FontWeight.w600,
                ),
                children: [
                  const TextSpan(text: 'Gift ID is valid'),
                  if (_typedGiftAmount.isNotEmpty) ...[
                    const TextSpan(text: ' with '),
                    TextSpan(
                      text: _typedGiftAmount,
                      style: GoogleFonts.inter(
                        color: const Color(0xFFE08A1E),
                        fontSize: 10.9,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                  const TextSpan(text: ' but not funded yet'),
                ],
              ),
            ),
          ),
        ],
      );
    }

    return Row(
      children: [
        Icon(
          _giftValid ? Icons.verified_rounded : Icons.info_outline_rounded,
          color: _giftValid ? _blue : theme.secondaryText,
          size: 17.0,
        ),
        const SizedBox(width: 7.0),
        Expanded(
          child: Text(
            _giftCheckMessage,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.inter(
              color: _giftValid ? statusColor : theme.secondaryText,
              fontSize: 10.8,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    final canContinue = _giftValid && !_isClaiming;
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FA),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsetsDirectional.only(bottom: 28.0),
          children: [
            Padding(
              padding:
                  const EdgeInsetsDirectional.fromSTEB(6.0, 4.0, 18.0, 0.0),
              child: Row(
                children: [
                  FlutterFlowIconButton(
                    borderColor: Colors.transparent,
                    borderRadius: 30.0,
                    buttonSize: 48.0,
                    icon: Icon(
                      Icons.arrow_back_rounded,
                      color: theme.primaryText,
                      size: 24.0,
                    ),
                    onPressed: () => context.goNamed(GiftWidget.routeName),
                  ),
                  Expanded(
                    child: Text(
                      'Claim Gift',
                      style: theme.titleMedium.override(
                        color: theme.primaryText,
                        fontSize: 20.0,
                        letterSpacing: 0.0,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding:
                  const EdgeInsetsDirectional.fromSTEB(22.0, 2.0, 22.0, 0.0),
              child: Text(
                'Enter the gift ID, then choose where to receive the claim.',
                style: GoogleFonts.inter(
                  color: theme.secondaryText,
                  fontSize: 11.2,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Padding(
              padding:
                  const EdgeInsetsDirectional.fromSTEB(18.0, 18.0, 18.0, 0.0),
              child: Container(
                padding: const EdgeInsetsDirectional.fromSTEB(
                    14.0, 14.0, 14.0, 14.0),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF3F8),
                  borderRadius: BorderRadius.circular(18.0),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          height: 47.0,
                          alignment: Alignment.center,
                          padding: const EdgeInsetsDirectional.fromSTEB(
                              13.0, 0.0, 13.0, 0.0),
                          decoration: BoxDecoration(
                            color: _blue,
                            borderRadius: BorderRadius.circular(12.0),
                          ),
                          child: Text(
                            '2S-',
                            style: GoogleFonts.inter(
                              color: Colors.white,
                              fontSize: 12.6,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8.0),
                        Expanded(
                          child: TextFormField(
                            controller: _giftIdController,
                            textCapitalization: TextCapitalization.characters,
                            inputFormatters: [
                              LengthLimitingTextInputFormatter(6),
                              FilteringTextInputFormatter.allow(
                                RegExp('[a-zA-Z0-9]'),
                              ),
                            ],
                            decoration: _inputDecoration(
                              'Gift ID',
                              hint: '6 characters',
                            ),
                            style: GoogleFonts.inter(
                              color: theme.primaryText,
                              fontSize: 12.2,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1.2,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6.0),
                    Align(
                      alignment: AlignmentDirectional.centerStart,
                      child: Padding(
                        padding: const EdgeInsetsDirectional.only(start: 4.0),
                        child: _giftStatus(),
                      ),
                    ),
                    const SizedBox(height: 14.0),
                    Text(
                      'Account details',
                      style: theme.bodySmall.override(
                        color: _blue,
                        fontSize: 12.0,
                        letterSpacing: 0.0,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 9.0),
                    DropdownButtonFormField<String>(
                      initialValue: _receiveMode,
                      decoration: _inputDecoration('Mode of receiving payment'),
                      style: GoogleFonts.inter(
                        color: theme.primaryText,
                        fontSize: 11.3,
                        fontWeight: FontWeight.w500,
                      ),
                      icon: const Icon(Icons.keyboard_arrow_down_rounded,
                          color: _blue),
                      items: const [
                        'Add account number',
                        'Select from beneficiary',
                      ]
                          .map(
                            (item) => DropdownMenuItem(
                                value: item, child: Text(item)),
                          )
                          .toList(),
                      onChanged: (value) {
                        if (value != null) {
                          safeSetState(() {
                            _receiveMode = value;
                            _validationMessage = null;
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 10.0),
                    if (_receiveMode == 'Select from beneficiary')
                      DropdownButtonFormField<_Beneficiary>(
                        initialValue: _selectedBeneficiary,
                        decoration: _inputDecoration('Select beneficiary'),
                        style: GoogleFonts.inter(
                          color: theme.primaryText,
                          fontSize: 11.3,
                          fontWeight: FontWeight.w500,
                        ),
                        icon: const Icon(Icons.keyboard_arrow_down_rounded,
                            color: _blue),
                        items: _beneficiaries
                            .map(
                              (item) => DropdownMenuItem(
                                value: item,
                                child: Text(
                                  '${item.name} • ${item.bank}',
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            )
                            .toList(),
                        onChanged: (value) {
                          safeSetState(() => _selectedBeneficiary = value);
                        },
                      )
                    else ...[
                      FlutterFlowDropDown<String>(
                        controller: _bankFieldController ??=
                            FormFieldController<String>(_selectedBank),
                        options: _banks,
                        onChanged: (value) {
                          safeSetState(() => _selectedBank = value);
                          _queueAccountValidation();
                        },
                        width: double.infinity,
                        height: 47.0,
                        textStyle: GoogleFonts.inter(
                          color: theme.primaryText,
                          fontSize: 11.3,
                          fontWeight: FontWeight.w500,
                        ),
                        hintText: _isLoadingBanks
                            ? 'Loading banks...'
                            : 'Select bank',
                        searchHintText: 'Type bank name',
                        searchCursorColor: _blue,
                        icon: Icon(Icons.keyboard_arrow_down_rounded,
                            color: theme.secondaryText, size: 18.0),
                        fillColor: Colors.white,
                        elevation: 2.0,
                        borderColor: _blue.withValues(alpha: 0.18),
                        borderWidth: 1.0,
                        borderRadius: 12.0,
                        margin: const EdgeInsetsDirectional.fromSTEB(
                            14.0, 8.0, 12.0, 8.0),
                        hidesUnderline: true,
                        isSearchable: true,
                        isMultiSelect: false,
                      ),
                      const SizedBox(height: 10.0),
                      TextFormField(
                        controller: _accountController,
                        keyboardType: TextInputType.number,
                        maxLength: 10,
                        decoration: _inputDecoration('Account number').copyWith(
                          counterText: '',
                        ),
                        style: GoogleFonts.inter(
                          color: theme.primaryText,
                          fontSize: 12.2,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 6.0),
                      Align(
                        alignment: AlignmentDirectional.centerStart,
                        child: Padding(
                          padding: const EdgeInsetsDirectional.only(start: 4.0),
                          child: _accountNameStatus(),
                        ),
                      ),
                    ],
                    const SizedBox(height: 13.0),
                    Align(
                      alignment: AlignmentDirectional.centerEnd,
                      child: InkWell(
                        onTap: canContinue ? _openClaimConfirmation : null,
                        borderRadius: BorderRadius.circular(24.0),
                        child: Container(
                          padding: const EdgeInsetsDirectional.fromSTEB(
                              16.0, 11.0, 8.0, 11.0),
                          decoration: BoxDecoration(
                            color:
                                canContinue ? _blue : const Color(0xFFB8C0CC),
                            borderRadius: BorderRadius.circular(24.0),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                _isClaiming ? 'Checking...' : 'Continue',
                                style: theme.bodySmall.override(
                                  color: Colors.white,
                                  fontSize: 12.5,
                                  letterSpacing: 0.0,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(width: 9.0),
                              Container(
                                width: 30.0,
                                height: 30.0,
                                decoration: const BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                ),
                                child: _isClaiming
                                    ? const Padding(
                                        padding: EdgeInsets.all(7.0),
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2.0,
                                          valueColor:
                                              AlwaysStoppedAnimation<Color>(
                                                  _blue),
                                        ),
                                      )
                                    : const Icon(
                                        Icons.arrow_forward_rounded,
                                        color: _blue,
                                        size: 17.0,
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
            ),
          ],
        ),
      ),
    );
  }
}

class _Beneficiary {
  const _Beneficiary({
    required this.name,
    required this.bank,
    required this.accountNumber,
    required this.isDefault,
  });

  final String name;
  final String bank;
  final String accountNumber;
  final bool isDefault;

  factory _Beneficiary.fromJson(Map<String, dynamic> json) {
    return _Beneficiary(
      name: json['name']?.toString() ?? 'Beneficiary',
      bank: json['bank']?.toString() ?? 'Bank',
      accountNumber: json['accountNumber']?.toString() ?? '',
      isDefault: json['isDefault'] == true,
    );
  }
}
