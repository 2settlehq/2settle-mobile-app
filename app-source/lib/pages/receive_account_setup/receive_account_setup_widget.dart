import 'dart:async';

import '/components/settle_numeric_keypad.dart';
import '/components/status_action_button.dart';
import '/components/keyboard_submit_bar.dart';
import '/components/top_notice.dart';
import '/config/api_config.dart';
import '/data/ng_bank_codes.dart';
import '/flutter_flow/flutter_flow_drop_down.dart';
import '/flutter_flow/flutter_flow_icon_button.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/form_field_controller.dart';
import '/index.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ReceiveAccountSetupScaffold extends StatefulWidget {
  const ReceiveAccountSetupScaffold({
    super.key,
    required this.title,
    required this.arrayKey,
    required this.network,
    required this.liveValidate,
  });

  final String title;
  final String arrayKey;
  final String network;
  final bool liveValidate;

  @override
  State<ReceiveAccountSetupScaffold> createState() =>
      _ReceiveAccountSetupScaffoldState();
}

class _ReceiveAccountSetupScaffoldState
    extends State<ReceiveAccountSetupScaffold> {
  static const _blue = Color(0xFF4472C4);
  static const _green = Color(0xFF25A55F);
  static const _red = Color(0xFFC30000);
  static const _storageKey = ReceivePaymentDetailsWidget.storageKey;
  static const _banksUrl = ApiConfig.banksListUrl;
  static const _validateBankUrl = ApiConfig.banksResolveUrl;

  final _labelController = TextEditingController();
  final _bankController = TextEditingController();
  final _accountController = TextEditingController();
  final _accountFocusNode = FocusNode();
  FormFieldController<String>? _bankFieldController;
  Timer? _validationDebounce;
  Timer? _typingTimer;

  Map<String, String> _bankCodes = Map<String, String>.from(ngBankCodes);
  List<_ReceiveDestination> _items = [];
  String? _selectedBank;
  String? _validatedAccountName;
  String _typedAccountName = '';
  String? _validationMessage;
  bool _isLoadingBanks = false;
  bool _isValidating = false;
  bool _isSaving = false;
  bool _isSaved = false;

  List<String> get _banks => _bankCodes.keys.toList();

  @override
  void initState() {
    super.initState();
    _loadItems();
    if (widget.liveValidate) _loadBanks();
    _accountController.addListener(_queueValidation);
  }

  @override
  void dispose() {
    _validationDebounce?.cancel();
    _typingTimer?.cancel();
    _labelController.dispose();
    _bankController.dispose();
    _accountController.dispose();
    _accountFocusNode.dispose();
    super.dispose();
  }

  Future<void> _openKeypad() async {
    _accountFocusNode.requestFocus();
    final fieldContext = _accountFocusNode.context;
    if (fieldContext != null) {
      await Scrollable.ensureVisible(
        fieldContext,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        alignment: 0.18,
      );
    }
    await Future.delayed(const Duration(milliseconds: 70));
    if (!mounted) return;
    SettleNumericKeypad.show(
      context,
      title: 'Account number',
      submitLabel: 'Save',
      initialValue: _accountController.text,
      maxLength: 20,
      onChanged: (value) {
        _accountController.text = value;
        safeSetState(() {});
      },
      onDone: (value) async {
        _accountController.text = value;
        _validationDebounce?.cancel();
        await _validateAccount();
        if (mounted) _save();
      },
    );
  }

  Future<void> _loadItems() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString(_storageKey);
    if (stored == null || stored.isEmpty) return;
    try {
      final decoded = jsonDecode(stored);
      if (decoded is! Map) return;
      final raw = decoded[widget.arrayKey];
      if (raw is! List) return;
      final items = raw
          .whereType<Map>()
          .map((item) => _ReceiveDestination.fromJson(
                Map<String, dynamic>.from(item),
              ))
          .toList();
      if (!mounted) return;
      safeSetState(() {
        _items = items;
        if (_items.isNotEmpty && !_items.any((item) => item.isDefault)) {
          _items.first.isDefault = true;
        }
      });
    } catch (_) {}
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    Map<String, dynamic> payload = {
      'nairaAccounts': [],
      'dollarAccounts': [],
      'wallets': [],
    };
    final stored = prefs.getString(_storageKey);
    if (stored != null && stored.isNotEmpty) {
      try {
        final decoded = jsonDecode(stored);
        if (decoded is Map) payload = Map<String, dynamic>.from(decoded);
      } catch (_) {}
    }
    payload[widget.arrayKey] = _items.map((item) => item.toJson()).toList();
    payload['updatedAt'] = DateTime.now().toIso8601String();
    await prefs.setString(_storageKey, jsonEncode(payload));
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
      // Fallback bank list stays available.
    } finally {
      if (mounted) safeSetState(() => _isLoadingBanks = false);
    }
  }

  void _queueValidation() {
    _validationDebounce?.cancel();
    _validationDebounce =
        Timer(const Duration(milliseconds: 520), _validateAccount);
  }

  String? _payloadString(Map<String, dynamic> payload, List<String> keys) {
    for (final key in keys) {
      final value = payload[key];
      if (value is String && value.trim().isNotEmpty) return value.trim();
    }
    return null;
  }

  void _animateName(String value) {
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

  Future<void> _validateAccount() async {
    final accountNumber = _accountController.text.trim();
    final bankName =
        widget.liveValidate ? _selectedBank : _bankController.text.trim();
    final bankCode =
        widget.liveValidate && bankName != null ? _bankCodes[bankName] : null;

    if (accountNumber.isEmpty) {
      safeSetState(() {
        _validatedAccountName = null;
        _typedAccountName = '';
        _validationMessage = null;
      });
      return;
    }

    if (!widget.liveValidate) {
      safeSetState(() {
        _validatedAccountName = null;
        _typedAccountName = '';
        _validationMessage = (bankName ?? '').isEmpty
            ? 'Enter the dollar bank name.'
            : 'Dollar account will be saved without live validation.';
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
      _isValidating = true;
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
        _isValidating = false;
      });
      if (accountName != null && accountName.isNotEmpty) {
        _animateName(accountName);
      }
    } catch (_) {
      if (!mounted) return;
      safeSetState(() {
        _validatedAccountName = null;
        _typedAccountName = '';
        _validationMessage = 'Unable to validate account.';
      });
    } finally {
      if (mounted && _isValidating) safeSetState(() => _isValidating = false);
    }
  }

  Future<void> _save() async {
    if (_isSaving) return;
    final bankName =
        widget.liveValidate ? _selectedBank : _bankController.text.trim();
    final accountNumber = _accountController.text.trim();
    final accountName = _validatedAccountName?.trim() ?? '';
    final label = _labelController.text.trim().isEmpty
        ? widget.title
        : _labelController.text.trim();

    if (bankName == null || bankName.isEmpty || accountNumber.isEmpty) {
      showTopNotice(
        context,
        message: 'Enter bank and account number.',
        type: TopNoticeType.caution,
      );
      return;
    }
    if (widget.liveValidate && accountName.isEmpty) {
      showTopNotice(
        context,
        message: 'Validate the naira account before saving.',
        type: TopNoticeType.caution,
      );
      return;
    }

    safeSetState(() {
      _isSaving = true;
      _isSaved = false;
    });
    await Future.delayed(const Duration(milliseconds: 360));
    if (!mounted) return;
    safeSetState(() {
      _items.add(
        _ReceiveDestination(
          id: '${widget.network}-${DateTime.now().millisecondsSinceEpoch}',
          title: label,
          primary: accountNumber,
          secondary: bankName,
          name: widget.liveValidate
              ? accountName
              : (_labelController.text.trim().isEmpty ? bankName : label),
          network: widget.network,
          isDefault: _items.isEmpty,
        ),
      );
      _labelController.clear();
      _bankController.clear();
      _accountController.clear();
      _selectedBank = null;
      _bankFieldController?.value = null;
      _validatedAccountName = null;
      _typedAccountName = '';
      _validationMessage = null;
      _isSaving = false;
      _isSaved = true;
    });
    await _persist();
    Future.delayed(const Duration(milliseconds: 650), () {
      if (mounted) safeSetState(() => _isSaved = false);
    });
  }

  void _makeDefault(_ReceiveDestination item) {
    safeSetState(() {
      for (final entry in _items) {
        entry.isDefault = entry == item;
      }
    });
    _persist();
  }

  void _delete(_ReceiveDestination item) {
    safeSetState(() {
      _items.remove(item);
      if (_items.isNotEmpty && !_items.any((entry) => entry.isDefault)) {
        _items.first.isDefault = true;
      }
    });
    _persist();
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      isDense: true,
      filled: true,
      fillColor: Colors.white,
      contentPadding:
          const EdgeInsetsDirectional.fromSTEB(14.0, 13.0, 14.0, 13.0),
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

  Widget _accountNameStatus() {
    final theme = FlutterFlowTheme.of(context);
    if (_isValidating) {
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
            style: theme.bodySmall.override(
              color: theme.secondaryText,
              fontSize: 11.0,
              letterSpacing: 0.0,
            ),
          ),
        ],
      );
    }
    final validated = _validatedAccountName ?? '';
    final isTyping =
        validated.isNotEmpty && _typedAccountName.length < validated.length;
    if (_typedAccountName.isNotEmpty || validated.isNotEmpty) {
      return Row(
        children: [
          Flexible(
            child: Text(
              '${_typedAccountName.isEmpty ? '' : _typedAccountName}${isTyping ? '|' : ''}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.bodyMedium.override(
                color: theme.primaryText,
                fontSize: 11.8,
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
      _validationMessage ??
          (widget.liveValidate
              ? 'Account name will appear here after validation.'
              : 'Enter bank details. Live USD validation will be added when provider support is connected.'),
      style: GoogleFonts.inter(
        color: _validationMessage == null ? theme.secondaryText : _red,
        fontSize: 10.8,
        fontWeight: FontWeight.w500,
      ),
    );
  }

  Widget _savedTile(_ReceiveDestination item) {
    final theme = FlutterFlowTheme.of(context);
    return Container(
      margin: const EdgeInsetsDirectional.only(bottom: 8.0),
      padding: const EdgeInsetsDirectional.fromSTEB(11.0, 8.0, 8.0, 8.0),
      decoration: BoxDecoration(
        color: _blue.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: _blue.withValues(alpha: 0.12)),
      ),
      child: Row(
        children: [
          Icon(
            item.isDefault ? Icons.check_circle_rounded : Icons.circle_outlined,
            color: item.isDefault ? _green : theme.secondaryText,
            size: 20.0,
          ),
          const SizedBox(width: 9.0),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.bodySmall.override(
                    color: theme.primaryText,
                    fontSize: 11.8,
                    letterSpacing: 0.0,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2.0),
                Text(
                  '${item.secondary} • ${item.primary}${item.name.isEmpty ? '' : ' • ${item.name}'}',
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
              if (value == 'default') _makeDefault(item);
              if (value == 'delete') _delete(item);
            },
            itemBuilder: (context) => const [
              PopupMenuItem(value: 'default', child: Text('Make default')),
              PopupMenuItem(value: 'delete', child: Text('Delete')),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    return Scaffold(
      bottomNavigationBar: KeyboardSubmitBar(
        text: 'Save',
        isLoading: _isSaving,
        onPressed: _save,
      ),
      backgroundColor: const Color(0xFFF4F6FA),
      appBar: AppBar(
        backgroundColor: _blue,
        automaticallyImplyLeading: false,
        leading: FlutterFlowIconButton(
          borderColor: Colors.transparent,
          borderRadius: 30.0,
          buttonSize: 48.0,
          icon: const Icon(Icons.arrow_back_rounded,
              color: Colors.white, size: 24.0),
          onPressed: () =>
              context.goNamed(ReceivePaymentDetailsWidget.routeName),
        ),
        title: Text(
          widget.title,
          style: theme.headlineMedium.override(
            color: Colors.white,
            fontSize: 20.0,
            letterSpacing: 0.0,
            fontWeight: FontWeight.w700,
          ),
        ),
        elevation: 0.0,
      ),
      body: SafeArea(
        top: true,
        child: ListView(
          padding: const EdgeInsetsDirectional.fromSTEB(18.0, 18.0, 18.0, 26.0),
          children: [
            Text(
              'Save ${widget.title.toLowerCase()}s',
              style: theme.bodyMedium.override(
                color: _blue,
                fontSize: 15.0,
                letterSpacing: 0.0,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12.0),
            if (widget.liveValidate)
              FlutterFlowDropDown<String>(
                controller: _bankFieldController ??=
                    FormFieldController<String>(_selectedBank),
                options: _banks,
                onChanged: (value) {
                  safeSetState(() => _selectedBank = value);
                  _queueValidation();
                },
                width: double.infinity,
                height: 48.0,
                textStyle: theme.bodyMedium.override(
                  color: theme.primaryText,
                  fontSize: 13.0,
                  letterSpacing: 0.0,
                  fontWeight: FontWeight.normal,
                ),
                hintText: _isLoadingBanks ? 'Loading banks...' : 'Select bank',
                searchHintText: 'Type bank name',
                searchCursorColor: _blue,
                icon: Icon(Icons.keyboard_arrow_down_rounded,
                    color: theme.secondaryText, size: 18.0),
                fillColor: Colors.white,
                elevation: 2.0,
                borderColor: _blue.withValues(alpha: 0.18),
                borderWidth: 1.0,
                borderRadius: 10.0,
                margin:
                    const EdgeInsetsDirectional.fromSTEB(14.0, 8.0, 12.0, 8.0),
                hidesUnderline: true,
                isSearchable: true,
                isMultiSelect: false,
              )
            else
              TextFormField(
                controller: _bankController,
                decoration: _inputDecoration('Bank name'),
                style: theme.bodyMedium,
              ),
            const SizedBox(height: 10.0),
            TextFormField(
              controller: _accountController,
              focusNode: _accountFocusNode,
              readOnly: true,
              showCursor: true,
              cursorColor: _blue,
              cursorWidth: 2.0,
              onTap: _openKeypad,
              decoration: _inputDecoration('Account number'),
              style: GoogleFonts.inter(
                color: theme.primaryText,
                fontSize: 13.0,
                fontWeight: FontWeight.w400,
              ),
            ),
            const SizedBox(height: 6.0),
            Padding(
              padding: const EdgeInsetsDirectional.only(start: 4.0),
              child: _accountNameStatus(),
            ),
            const SizedBox(height: 10.0),
            TextFormField(
              controller: _labelController,
              textInputAction: TextInputAction.done,
              onFieldSubmitted: (_) => _save(),
              decoration: _inputDecoration('Save as'),
              style: theme.bodyMedium,
            ),
            const SizedBox(height: 12.0),
            Align(
              alignment: AlignmentDirectional.centerEnd,
              child: StatusActionButton(
                text: 'Save it',
                isLoading: _isSaving,
                isDone: _isSaved,
                idleIcon: Icons.save_rounded,
                height: 46.0,
                horizontalPadding: 18.0,
                trailingPadding: 5.0,
                iconBoxSize: 36.0,
                iconSize: 19.0,
                fontSize: 13.5,
                gap: 9.0,
                backgroundColor: _blue,
                textColor: Colors.white,
                iconBackgroundColor: Colors.white,
                iconColor: _blue,
                onPressed: _save,
              ),
            ),
            const SizedBox(height: 18.0),
            Text(
              'Saved ${widget.title.toLowerCase()}s',
              style: theme.bodyMedium.override(
                color: _blue,
                fontSize: 15.0,
                letterSpacing: 0.0,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8.0),
            if (_items.isEmpty)
              Text(
                'Saved ${widget.title.toLowerCase()}s will appear here.',
                style: theme.bodySmall.override(
                  color: theme.secondaryText,
                  letterSpacing: 0.0,
                  fontWeight: FontWeight.w500,
                ),
              )
            else
              ..._items.map(_savedTile),
          ],
        ),
      ),
    );
  }
}

class _ReceiveDestination {
  _ReceiveDestination({
    required this.id,
    required this.title,
    required this.primary,
    required this.secondary,
    required this.name,
    required this.network,
    required this.isDefault,
  });

  final String id;
  final String title;
  final String primary;
  final String secondary;
  final String name;
  final String network;
  bool isDefault;

  factory _ReceiveDestination.fromJson(Map<String, dynamic> json) {
    return _ReceiveDestination(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? 'Receive account',
      primary: json['primary']?.toString() ?? '',
      secondary: json['secondary']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      network: json['network']?.toString() ?? '',
      isDefault: json['isDefault'] == true,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'primary': primary,
        'secondary': secondary,
        'name': name,
        'network': network,
        'isDefault': isDefault,
      };
}
