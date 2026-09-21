import 'dart:async';

import '/components/settle_numeric_keypad.dart';
import '/components/status_action_button.dart';
import '/components/top_notice.dart';
import '/config/api_config.dart';
import '/data/ng_bank_codes.dart';
import '/flutter_flow/flutter_flow_drop_down.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/form_field_controller.dart';
import '/index.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'account_details_model.dart';
export 'account_details_model.dart';

class AccountDetailsWidget extends StatefulWidget {
  const AccountDetailsWidget({
    super.key,
    this.origin = 'home',
  });

  static String routeName = 'Account_Details';
  static String routePath = 'accountDetails';

  final String origin;

  @override
  State<AccountDetailsWidget> createState() => _AccountDetailsWidgetState();
}

class _AccountDetailsWidgetState extends State<AccountDetailsWidget> {
  late AccountDetailsModel _model;

  final scaffoldKey = GlobalKey<ScaffoldState>();
  final _beneficiaryNameController = TextEditingController();
  final _accountNumberController = TextEditingController();
  final _accountNumberFocusNode = FocusNode();
  Timer? _validationDebounce;
  Timer? _accountNameTypingTimer;
  final List<_Beneficiary> _beneficiaries = [
    _Beneficiary(
      name: 'Kayode main',
      bank: 'GTBank',
      accountNumber: '0123456789',
      accountName: 'Kayode Adewale',
      isDefault: true,
    ),
  ];
  String? _selectedBank;
  String? _validatedBankName;
  String? _validatedAccountName;
  String _typedAccountName = '';
  String? _validationMessage;
  bool _isLoadingBanks = false;
  bool _isValidatingAccount = false;
  bool _isSaving = false;
  bool _isSaved = false;
  late Map<String, String> _bankCodes;

  static const _blue = Color(0xFF4472C4);
  static const _storageKey = '2settle_saved_beneficiaries';
  static const _banksUrl = ApiConfig.banksListUrl;
  static const _validateBankUrl = ApiConfig.banksResolveUrl;
  static const _fallbackBankCodes = ngBankCodes;

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => AccountDetailsModel());
    _bankCodes = Map<String, String>.from(_fallbackBankCodes);
    _loadBeneficiaries();
    _loadBanks();
    _accountNumberController.addListener(_queueAccountValidation);
  }

  @override
  void dispose() {
    _validationDebounce?.cancel();
    _accountNameTypingTimer?.cancel();
    _beneficiaryNameController.dispose();
    _accountNumberController.dispose();
    _accountNumberFocusNode.dispose();
    _model.dispose();
    super.dispose();
  }

  Future<void> _openAccountNumberKeypad() async {
    _accountNumberFocusNode.requestFocus();
    final fieldContext = _accountNumberFocusNode.context;
    if (fieldContext != null) {
      await Scrollable.ensureVisible(
        fieldContext,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        alignment: 0.0,
      );
    }
    await Future.delayed(const Duration(milliseconds: 80));
    if (!mounted) return;
    SettleNumericKeypad.show(
      context,
      title: 'Account number',
      initialValue: _accountNumberController.text,
      maxLength: 10,
      onChanged: (value) {
        _accountNumberController.text = value;
        safeSetState(() {});
      },
      onDone: (value) {
        _accountNumberController.text = value;
        _queueAccountValidation();
      },
    );
  }

  List<String> get _banks => _bankCodes.keys.toList();

  Future<void> _saveBeneficiary() async {
    final accountName = _validatedAccountName?.trim() ?? '';
    final fallbackName = accountName.isNotEmpty ? accountName : 'Beneficiary';
    final name = _beneficiaryNameController.text.trim().isEmpty
        ? fallbackName
        : _beneficiaryNameController.text.trim();
    final accountNumber = _accountNumberController.text.trim();
    final bank = _selectedBank;

    if (accountNumber.length != 10 || accountName.isEmpty || bank == null) {
      showTopNotice(
        context,
        message: 'Validate the account number before saving.',
        type: TopNoticeType.caution,
      );
      return;
    }

    safeSetState(() {
      _isSaving = true;
      _isSaved = false;
    });
    await Future.delayed(const Duration(milliseconds: 420));
    if (!mounted) return;

    safeSetState(() {
      _beneficiaries.add(
        _Beneficiary(
          name: name,
          bank: bank,
          accountNumber: accountNumber,
          accountName: accountName,
          isDefault: _beneficiaries.isEmpty,
        ),
      );
      _beneficiaryNameController.clear();
      _accountNumberController.clear();
      _selectedBank = null;
      _validatedBankName = null;
      _validatedAccountName = null;
      _typedAccountName = '';
      _validationMessage = null;
      _isSaving = false;
      _isSaved = true;
    });
    await _persistBeneficiaries();
    Future.delayed(const Duration(milliseconds: 650), () {
      if (mounted) safeSetState(() => _isSaved = false);
    });
  }

  void _editBeneficiary(_Beneficiary beneficiary) {
    safeSetState(() {
      _beneficiaryNameController.text = beneficiary.name;
      _accountNumberController.text = beneficiary.accountNumber;
      _selectedBank = beneficiary.bank;
      _validatedBankName = beneficiary.bank;
      _validatedAccountName = beneficiary.accountName;
      _typedAccountName = beneficiary.accountName;
      _beneficiaries.remove(beneficiary);
    });
    _persistBeneficiaries();
  }

  void _makeDefault(_Beneficiary beneficiary) {
    safeSetState(() {
      for (final item in _beneficiaries) {
        item.isDefault = item == beneficiary;
      }
    });
    _persistBeneficiaries();
  }

  void _deleteBeneficiary(_Beneficiary beneficiary) {
    safeSetState(() {
      _beneficiaries.remove(beneficiary);
      if (_beneficiaries.isNotEmpty &&
          !_beneficiaries.any((item) => item.isDefault)) {
        _beneficiaries.first.isDefault = true;
      }
    });
    _persistBeneficiaries();
  }

  Future<void> _loadBeneficiaries() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_storageKey);
      if (raw == null || raw.isEmpty) {
        return;
      }

      final decoded = jsonDecode(raw);
      if (decoded is! List) {
        return;
      }

      final loaded = decoded
          .whereType<Map>()
          .map((item) => _Beneficiary.fromJson(
                Map<String, dynamic>.from(item),
              ))
          .toList();

      if (!mounted || loaded.isEmpty) {
        return;
      }

      safeSetState(() {
        _beneficiaries
          ..clear()
          ..addAll(loaded);
        if (!_beneficiaries.any((item) => item.isDefault)) {
          _beneficiaries.first.isDefault = true;
        }
      });
    } catch (_) {
      // Keep the default demo beneficiary if stored data cannot be read.
    }
  }

  Future<void> _persistBeneficiaries() async {
    final prefs = await SharedPreferences.getInstance();
    final payload = jsonEncode(
      _beneficiaries.map((beneficiary) => beneficiary.toJson()).toList(),
    );
    await prefs.setString(_storageKey, payload);
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
      safeSetState(() {
        _bankCodes = {
          ..._fallbackBankCodes,
          ...next,
        };
      });
    } catch (_) {
      // Keep fallback bank list available.
    } finally {
      if (mounted) safeSetState(() => _isLoadingBanks = false);
    }
  }

  void _queueAccountValidation() {
    _validationDebounce?.cancel();
    _validationDebounce = Timer(
      const Duration(milliseconds: 550),
      _validateAccount,
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

  Future<void> _validateAccount() async {
    final accountNumber = _accountNumberController.text.trim();
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
      final responseOk = response.statusCode >= 200 &&
          response.statusCode < 300 &&
          payload['ok'] != false;

      if (!mounted) return;

      safeSetState(() {
        _validatedBankName = _payloadString(
              payload,
              const ['bankName', 'bank_name'],
            ) ??
            bankName ??
            _validatedBankName;
        _validatedAccountName = accountName;
        _validationMessage = responseOk && accountName != null
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

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      isDense: true,
      filled: true,
      fillColor: FlutterFlowTheme.of(context).secondaryBackground,
      contentPadding:
          const EdgeInsetsDirectional.fromSTEB(14.0, 14.0, 14.0, 14.0),
      enabledBorder: OutlineInputBorder(
        borderSide: BorderSide(color: _blue.withValues(alpha: 0.18)),
        borderRadius: BorderRadius.circular(10.0),
      ),
      focusedBorder: OutlineInputBorder(
        borderSide: const BorderSide(color: _blue),
        borderRadius: BorderRadius.circular(10.0),
      ),
    );
  }

  Widget _sectionTitle(String title) {
    final theme = FlutterFlowTheme.of(context);
    return Align(
      alignment: AlignmentDirectional.centerStart,
      child: Text(
        title,
        style: theme.bodyMedium.override(
          font: TextStyle(
            fontWeight: FontWeight.w700,
            fontStyle: theme.bodyMedium.fontStyle,
          ),
          color: _blue,
          fontSize: 15.0,
          letterSpacing: 0.0,
          fontWeight: FontWeight.w700,
          fontStyle: theme.bodyMedium.fontStyle,
        ),
      ),
    );
  }

  Widget _beneficiaryTile(_Beneficiary beneficiary) {
    final theme = FlutterFlowTheme.of(context);

    return Container(
      padding: const EdgeInsetsDirectional.fromSTEB(12.0, 8.0, 8.0, 8.0),
      decoration: BoxDecoration(
        color: _blue.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(10.0),
        border: Border.all(color: _blue.withValues(alpha: 0.14)),
      ),
      child: Row(
        children: [
          Container(
            width: 34.0,
            height: 34.0,
            decoration:
                const BoxDecoration(color: _blue, shape: BoxShape.circle),
            child: const Icon(Icons.account_balance_rounded,
                color: Colors.white, size: 17.0),
          ),
          const SizedBox(width: 10.0),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        beneficiary.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.bodyMedium.override(
                          font: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontStyle: theme.bodyMedium.fontStyle,
                          ),
                          color: theme.primaryText,
                          fontSize: 12.5,
                          letterSpacing: 0.0,
                          fontWeight: FontWeight.w700,
                          fontStyle: theme.bodyMedium.fontStyle,
                        ),
                      ),
                    ),
                    if (beneficiary.isDefault) ...[
                      const SizedBox(width: 6.0),
                      Container(
                        padding: const EdgeInsetsDirectional.fromSTEB(
                            6.0, 2.0, 6.0, 2.0),
                        decoration: BoxDecoration(
                          color: _blue,
                          borderRadius: BorderRadius.circular(10.0),
                        ),
                        child: Text(
                          'Default',
                          style: GoogleFonts.inter(
                            color: Colors.white,
                            fontSize: 9.0,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 2.0),
                Text(
                  '${beneficiary.bank} • ${beneficiary.accountNumber} • ${beneficiary.accountName}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    color: theme.secondaryText,
                    fontSize: 10.0,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert_rounded, color: _blue, size: 20.0),
            onSelected: (value) {
              if (value == 'default') _makeDefault(beneficiary);
              if (value == 'edit') _editBeneficiary(beneficiary);
              if (value == 'delete') _deleteBeneficiary(beneficiary);
            },
            itemBuilder: (context) => const [
              PopupMenuItem(value: 'default', child: Text('Make default')),
              PopupMenuItem(value: 'edit', child: Text('Edit')),
              PopupMenuItem(value: 'delete', child: Text('Delete')),
            ],
          ),
        ],
      ),
    );
  }

  Widget _accountNameStatus() {
    final theme = FlutterFlowTheme.of(context);

    if (_isValidatingAccount) {
      return Row(
        children: [
          const SizedBox(
            width: 16.0,
            height: 16.0,
            child: CircularProgressIndicator(
              strokeWidth: 2.0,
              valueColor: AlwaysStoppedAnimation<Color>(_blue),
            ),
          ),
          const SizedBox(width: 8.0),
          Text(
            'Validating bank account...',
            style: theme.bodySmall.override(
              font: TextStyle(
                fontWeight: FontWeight.w500,
                fontStyle: theme.bodySmall.fontStyle,
              ),
              color: theme.secondaryText,
              letterSpacing: 0.0,
              fontWeight: FontWeight.w500,
              fontStyle: theme.bodySmall.fontStyle,
            ),
          ),
        ],
      );
    }

    final validatedName = _validatedAccountName ?? '';
    final isTyping = validatedName.isNotEmpty &&
        _typedAccountName.length < validatedName.length;

    if (_typedAccountName.isNotEmpty || validatedName.isNotEmpty) {
      return Row(
        children: [
          Flexible(
            child: Text(
              '${_typedAccountName.isEmpty ? '' : _typedAccountName}${isTyping ? '|' : ''}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.bodyMedium.override(
                font: TextStyle(
                  fontWeight: FontWeight.w500,
                  fontStyle: theme.bodyMedium.fontStyle,
                ),
                color: theme.primaryText,
                fontSize: 12.0,
                letterSpacing: 0.0,
                fontWeight: FontWeight.w500,
                fontStyle: theme.bodyMedium.fontStyle,
              ),
            ),
          ),
          const SizedBox(width: 6.0),
          const Icon(Icons.verified_rounded, color: _blue, size: 18.0),
        ],
      );
    }

    if (_validationMessage != null) {
      return Text(
        _validationMessage!,
        style: theme.bodySmall.override(
          font: TextStyle(
            fontWeight: FontWeight.w500,
            fontStyle: theme.bodySmall.fontStyle,
          ),
          color: const Color(0xFFE04F5F),
          letterSpacing: 0.0,
          fontWeight: FontWeight.w500,
          fontStyle: theme.bodySmall.fontStyle,
        ),
      );
    }

    return Text(
      'Account name will appear here after validation.',
      style: theme.bodySmall.override(
        font: TextStyle(
          fontWeight: FontWeight.w500,
          fontStyle: theme.bodySmall.fontStyle,
        ),
        color: theme.secondaryText,
        letterSpacing: 0.0,
        fontWeight: FontWeight.w500,
        fontStyle: theme.bodySmall.fontStyle,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);

    return Scaffold(
      key: scaffoldKey,
      backgroundColor: theme.secondaryBackground,
      appBar: AppBar(
        backgroundColor: _blue,
        automaticallyImplyLeading: false,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          onPressed: () {
            context.goNamed(
              widget.origin == 'account'
                  ? AccountWidget.routeName
                  : widget.origin == 'settings'
                      ? SettingsWidget.routeName
                      : DashboardWidget.routeName,
            );
          },
        ),
        title: Text(
          'Bank Details',
          style: theme.headlineMedium.override(
            font: TextStyle(
              fontWeight: FontWeight.w700,
              fontStyle: theme.headlineMedium.fontStyle,
            ),
            color: Colors.white,
            fontSize: 20.0,
            letterSpacing: 0.0,
            fontWeight: FontWeight.w700,
            fontStyle: theme.headlineMedium.fontStyle,
          ),
        ),
        elevation: 0.0,
      ),
      body: SafeArea(
        top: true,
        child: ListView(
          padding: const EdgeInsetsDirectional.fromSTEB(18.0, 18.0, 18.0, 24.0),
          children: [
            _sectionTitle('Save bank details'),
            const SizedBox(height: 12.0),
            FlutterFlowDropDown<String>(
              controller: _model.bankNameValueController ??=
                  FormFieldController<String>(_selectedBank),
              options: _banks,
              onChanged: (value) {
                safeSetState(() => _selectedBank = value);
                _queueAccountValidation();
              },
              width: double.infinity,
              height: 48.0,
              textStyle: theme.bodyMedium.override(
                font: TextStyle(
                  fontWeight: FontWeight.normal,
                  fontStyle: theme.bodyMedium.fontStyle,
                ),
                fontSize: 13.0,
                letterSpacing: 0.0,
                fontWeight: FontWeight.normal,
                fontStyle: theme.bodyMedium.fontStyle,
              ),
              hintText: _isLoadingBanks ? 'Loading banks...' : 'Select bank',
              searchHintText: 'Type bank name',
              searchHintTextStyle: theme.bodySmall.override(
                font: TextStyle(
                  fontWeight: FontWeight.normal,
                  fontStyle: theme.bodySmall.fontStyle,
                ),
                color: theme.secondaryText,
                letterSpacing: 0.0,
                fontWeight: FontWeight.normal,
                fontStyle: theme.bodySmall.fontStyle,
              ),
              searchTextStyle: theme.bodyMedium.override(
                font: TextStyle(
                  fontWeight: FontWeight.w500,
                  fontStyle: theme.bodyMedium.fontStyle,
                ),
                color: theme.primaryText,
                letterSpacing: 0.0,
                fontWeight: FontWeight.w500,
                fontStyle: theme.bodyMedium.fontStyle,
              ),
              searchCursorColor: _blue,
              icon: Icon(Icons.keyboard_arrow_down_rounded,
                  color: theme.secondaryText, size: 18.0),
              fillColor: theme.secondaryBackground,
              elevation: 2.0,
              borderColor: _blue.withValues(alpha: 0.18),
              borderWidth: 1.0,
              borderRadius: 10.0,
              margin:
                  const EdgeInsetsDirectional.fromSTEB(14.0, 8.0, 12.0, 8.0),
              hidesUnderline: true,
              isSearchable: true,
              isMultiSelect: false,
            ),
            const SizedBox(height: 10.0),
            TextFormField(
              controller: _accountNumberController,
              focusNode: _accountNumberFocusNode,
              readOnly: true,
              showCursor: true,
              cursorColor: FlutterFlowTheme.of(context).primary,
              cursorWidth: 2.0,
              onTap: _openAccountNumberKeypad,
              maxLength: 10,
              decoration: _inputDecoration('Account number').copyWith(
                counterText: '',
              ),
              style: GoogleFonts.inter(
                color: theme.primaryText,
                fontSize: 13.0,
                fontWeight: FontWeight.w400,
              ),
            ),
            const SizedBox(height: 5.0),
            Padding(
              padding: const EdgeInsetsDirectional.only(start: 4.0),
              child: _accountNameStatus(),
            ),
            const SizedBox(height: 8.0),
            TextFormField(
              controller: _beneficiaryNameController,
              decoration: _inputDecoration('Save as'),
              style: theme.bodyMedium,
            ),
            const SizedBox(height: 10.0),
            Align(
              alignment: AlignmentDirectional.centerEnd,
              child: StatusActionButton(
                text: 'Save it',
                isLoading: _isSaving,
                isDone: _isSaved,
                idleIcon: Icons.save_rounded,
                height: 48.0,
                horizontalPadding: 18.0,
                trailingPadding: 5.0,
                iconBoxSize: 38.0,
                iconSize: 20.0,
                fontSize: 14.0,
                gap: 10.0,
                shadowBlur: 12.0,
                shadowOffset: const Offset(2.0, 2.0),
                backgroundColor: _blue,
                textColor: Colors.white,
                iconBackgroundColor: Colors.white,
                iconColor: _blue,
                onPressed: () {
                  _saveBeneficiary();
                },
              ),
            ),
            const SizedBox(height: 18.0),
            _sectionTitle('Beneficiaries'),
            const SizedBox(height: 8.0),
            if (_beneficiaries.isEmpty)
              Text(
                'Saved bank details will appear here.',
                style: theme.bodySmall.override(
                  font: TextStyle(
                    fontWeight: FontWeight.w500,
                    fontStyle: theme.bodySmall.fontStyle,
                  ),
                  color: theme.secondaryText,
                  letterSpacing: 0.0,
                  fontWeight: FontWeight.w500,
                  fontStyle: theme.bodySmall.fontStyle,
                ),
              )
            else
              ..._beneficiaries
                  .map(
                    (beneficiary) => Padding(
                      padding: const EdgeInsetsDirectional.only(bottom: 7.0),
                      child: _beneficiaryTile(beneficiary),
                    ),
                  )
                  .toList(),
          ],
        ),
      ),
    );
  }
}

class _Beneficiary {
  _Beneficiary({
    required this.name,
    required this.bank,
    required this.accountNumber,
    required this.accountName,
    required this.isDefault,
  });

  final String name;
  final String bank;
  final String accountNumber;
  final String accountName;
  bool isDefault;

  factory _Beneficiary.fromJson(Map<String, dynamic> json) {
    return _Beneficiary(
      name: json['name']?.toString() ?? '',
      bank: json['bank']?.toString() ?? 'GTBank',
      accountNumber: json['accountNumber']?.toString() ?? '',
      accountName: json['accountName']?.toString() ?? '',
      isDefault: json['isDefault'] == true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'bank': bank,
      'accountNumber': accountNumber,
      'accountName': accountName,
      'isDefault': isDefault,
    };
  }
}
