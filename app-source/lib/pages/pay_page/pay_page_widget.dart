import '/components/settle_numeric_keypad.dart';
import '/components/status_action_button.dart';
import '/components/top_notice.dart';
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
import 'pay_page_model.dart';
export 'pay_page_model.dart';

class PayPageWidget extends StatefulWidget {
  const PayPageWidget({super.key});

  static String routeName = 'Pay_Page';
  static String routePath = 'payPage';

  @override
  State<PayPageWidget> createState() => _PayPageWidgetState();
}

class _PayPageWidgetState extends State<PayPageWidget> {
  late PayPageModel _model;
  static const _blue = Color(0xFF4472C4);
  static const _storageKey = '2settle_receive_requests';
  static const _transactionStorageKey = '2settle_initiated_transactions';
  static const _beneficiaryStorageKey = '2settle_saved_beneficiaries';
  static const _validateBankUrl =
      'https://2settlemobile.vercel.app/api/banks/resolve';
  static const _bankCodes = ngBankCodes;

  final scaffoldKey = GlobalKey<ScaffoldState>();
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _accountController = TextEditingController();
  final _amountFocusNode = FocusNode();

  String _currency = 'NGN';
  String _expiry = '24 hours';
  DateTime? _customExpiryDate;
  String _usage = 'Use once';
  String _settlementMode = 'Default account';
  String _network = 'TRC20';
  String? _inputBankName;
  String? _inputAccountName;
  _SavedBeneficiary? _selectedBeneficiary;
  bool _payerCanEdit = false;
  bool _isCreating = false;
  bool _isCreated = false;
  String _receiveStatusFilter = 'Unpaid';
  List<_ReceiveRequest> _requests = [];
  List<_SavedBeneficiary> _beneficiaries = [];

  List<String> get _expiryOptions {
    if (_expiry.startsWith('Expires ')) {
      return [
        '24 hours',
        '3 days',
        '7 days',
        _expiry,
        'Custom date',
        'No expiry'
      ];
    }
    return ['24 hours', '3 days', '7 days', 'Custom date', 'No expiry'];
  }

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => PayPageModel());
    _loadRequests();
    _loadBeneficiaries();
  }

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    _accountController.dispose();
    _amountFocusNode.dispose();
    _model.dispose();
    super.dispose();
  }

  Future<void> _loadRequests() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString(_storageKey);
    if (stored == null || stored.isEmpty) return;
    try {
      final decoded = jsonDecode(stored);
      if (decoded is! List) return;
      final requests = decoded
          .whereType<Map>()
          .map((item) => _ReceiveRequest.fromJson(
                Map<String, dynamic>.from(item),
              ))
          .toList();
      if (!mounted) return;
      safeSetState(() => _requests = requests);
    } catch (_) {}
  }

  Future<void> _loadBeneficiaries() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString(_beneficiaryStorageKey);
    if (stored == null || stored.isEmpty) return;
    try {
      final decoded = jsonDecode(stored);
      if (decoded is! List) return;
      final beneficiaries = decoded
          .whereType<Map>()
          .map((item) => _SavedBeneficiary.fromJson(
                Map<String, dynamic>.from(item),
              ))
          .where((item) => item.accountNumber.isNotEmpty)
          .toList();
      final defaults = beneficiaries.where((item) => item.isDefault).toList();
      final defaultBeneficiary = defaults.isNotEmpty ? defaults.first : null;
      if (!mounted) return;
      safeSetState(() {
        _beneficiaries = beneficiaries;
        _selectedBeneficiary = defaultBeneficiary ??
            (beneficiaries.isNotEmpty ? beneficiaries.first : null);
      });
    } catch (_) {}
  }

  Future<void> _saveRequests() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _storageKey,
      jsonEncode(_requests.map((item) => item.toJson()).toList()),
    );
  }

  String _formatMoney(String currency, String amount) {
    final symbol = currency.toUpperCase() == 'NGN'
        ? '₦'
        : currency.toUpperCase() == 'USD'
            ? r'$'
            : currency;
    final parsed = double.tryParse(amount.replaceAll(',', '').trim());
    if (parsed == null) return '$symbol$amount';
    final fixed = parsed == parsed.truncateToDouble()
        ? parsed.toStringAsFixed(0)
        : parsed.toStringAsFixed(2);
    final parts = fixed.split('.');
    final whole = parts.first;
    final buffer = StringBuffer();
    for (var index = 0; index < whole.length; index++) {
      final remaining = whole.length - index;
      buffer.write(whole[index]);
      if (remaining > 1 && remaining % 3 == 1) buffer.write(',');
    }
    final value = parts.length > 1
        ? '${buffer.toString()}.${parts.last}'
        : buffer.toString();
    return '$symbol$value';
  }

  List<_ReceiveRequest> get _filteredRequests {
    final paid = _receiveStatusFilter == 'Received';
    return _requests
        .where((request) => paid ? request.isPaid : !request.isPaid)
        .toList();
  }

  String _receiveLink(String id) => 'https://receive.2settle.io/pay/$id';

  Future<void> _syncReceiveActivity(_ReceiveRequest request) async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString(_transactionStorageKey);
    final list = stored == null || stored.isEmpty
        ? <dynamic>[]
        : (jsonDecode(stored) as List? ?? <dynamic>[]);
    final amount = request.amount.replaceAll(',', '').trim();
    list.removeWhere(
        (item) => item is Map && '${item['id'] ?? ''}' == request.id);
    list.insert(0, {
      'id': request.id,
      'type': 'receive_payment',
      'reference': request.id,
      'createdAt': request.createdAt.toIso8601String(),
      'settlementAmount': amount,
      'cryptoAmount': '0.00000 RECEIVE',
      'crypto': 'RECEIVE',
      'network': request.currency,
      'beneficiaryName': request.description,
      'bankName': request.settlementMode,
      'accountNumber': request.accountNumber,
      'accountName': request.settlementLabel,
      'bankCode': '',
      'rate': _receiveLink(request.id),
      'status': request.status,
    });
    await prefs.setString(
      _transactionStorageKey,
      jsonEncode(list.take(50).toList()),
    );
  }

  Future<void> _openAmountKeypad() async {
    _amountFocusNode.requestFocus();
    final fieldContext = _amountFocusNode.context;
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
      title: 'Receive amount',
      initialValue: _amountController.text,
      allowDecimal: true,
      onChanged: (value) {
        _amountController.text = value;
        safeSetState(() {});
      },
      onDone: (value) {
        _amountController.text = value;
        safeSetState(() {});
      },
    );
  }

  Future<void> _pickCustomExpiryDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate:
          _customExpiryDate ?? DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
                  primary: _blue,
                ),
          ),
          child: child!,
        );
      },
    );
    if (picked == null || !mounted) return;
    safeSetState(() {
      _customExpiryDate = picked;
      _expiry = 'Expires ${dateTimeFormat('MMMEd', picked)}';
    });
  }

  String get _expiryLabel {
    return _expiry;
  }

  bool get _isCryptoCurrency =>
      const ['USDT', 'BTC', 'ETH', 'BNB', 'TRX'].contains(_currency);

  String get _fixedCurrencyNetwork => switch (_currency) {
        'BTC' => 'Bitcoin',
        'ETH' => 'Ethereum',
        'BNB' => 'Binance',
        'TRX' => 'Tron',
        _ => 'Native',
      };

  String get _destinationLabel {
    if (_settlementMode == '2Settle custom account') {
      return '0987654321 • 2Settle MFB • 2S-receive payment';
    }
    if (_settlementMode == 'Saved beneficiary') {
      final beneficiary = _selectedBeneficiary;
      if (beneficiary == null) return 'Choose saved beneficiary';
      return '${beneficiary.accountNumber} • ${beneficiary.bank} • ${beneficiary.accountName}';
    }
    if (_settlementMode == 'Input account number') {
      final account = _accountController.text.trim();
      if (account.isEmpty) return 'Enter destination account';
      return [
        account,
        if ((_inputBankName ?? '').isNotEmpty) _inputBankName,
        if ((_inputAccountName ?? '').isNotEmpty) _inputAccountName,
      ].join(' • ');
    }
    final defaults = _beneficiaries.where((item) => item.isDefault).toList();
    final beneficiary = defaults.isNotEmpty
        ? defaults.first
        : (_beneficiaries.isNotEmpty ? _beneficiaries.first : null);
    if (beneficiary == null) return 'No default account saved yet';
    return '${beneficiary.accountNumber} • ${beneficiary.bank} • ${beneficiary.accountName}';
  }

  Future<void> _createRequest() async {
    if (_amountController.text.trim().isEmpty) {
      _showNoticeSnackBar('Enter amount to receive.');
      return;
    }
    safeSetState(() {
      _isCreating = true;
      _isCreated = false;
    });
    await Future.delayed(const Duration(milliseconds: 650));
    final request = _ReceiveRequest(
      id: 'RCV-${DateTime.now().millisecondsSinceEpoch}',
      amount: _amountController.text.trim(),
      currency: _currency,
      description: _descriptionController.text.trim().isEmpty
          ? '2Settle payment request'
          : _descriptionController.text.trim(),
      expiry: _expiry,
      expiryLabel: _expiryLabel,
      usage: _usage,
      payerCanEdit: _payerCanEdit,
      settlementMode: _settlementMode,
      settlementLabel: _destinationLabel,
      network: _isCryptoCurrency ? _network : '',
      accountNumber: _accountController.text.trim(),
      status: 'created',
      createdAt: DateTime.now(),
    );
    safeSetState(() {
      _requests = [request, ..._requests];
      _isCreating = false;
      _isCreated = true;
      _amountController.clear();
      _descriptionController.clear();
      _accountController.clear();
      _inputAccountName = null;
      _inputBankName = null;
    });
    await _saveRequests();
    await _syncReceiveActivity(request);
    await Future.delayed(const Duration(milliseconds: 900));
    if (!mounted) return;
    safeSetState(() => _isCreated = false);
  }

  TextStyle _labelStyle(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    return theme.bodySmall.override(
      font: TextStyle(
        fontWeight: FontWeight.normal,
        fontStyle: theme.bodySmall.fontStyle,
      ),
      color: theme.secondaryText,
      fontSize: 11.2,
      letterSpacing: 0.0,
      fontWeight: FontWeight.normal,
      fontStyle: theme.bodySmall.fontStyle,
    );
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: _labelStyle(context),
      filled: true,
      fillColor: Colors.white,
      contentPadding:
          const EdgeInsetsDirectional.fromSTEB(14.0, 11.0, 14.0, 11.0),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.0),
        borderSide: BorderSide(color: _blue.withValues(alpha: 0.16)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.0),
        borderSide: const BorderSide(color: _blue),
      ),
    );
  }

  Widget _selectField({
    required String label,
    required String value,
    required List<String> options,
    required ValueChanged<String> onChanged,
  }) {
    final theme = FlutterFlowTheme.of(context);
    return DropdownButtonFormField<String>(
      initialValue: value,
      isExpanded: true,
      icon: const Icon(Icons.keyboard_arrow_down_rounded, color: _blue),
      decoration: _inputDecoration(label),
      style: theme.bodyMedium.override(
        font: TextStyle(
          fontWeight: FontWeight.normal,
          fontStyle: theme.bodyMedium.fontStyle,
        ),
        color: theme.primaryText,
        fontSize: 12.4,
        letterSpacing: 0.0,
        fontWeight: FontWeight.normal,
        fontStyle: theme.bodyMedium.fontStyle,
      ),
      items: options
          .map(
            (option) => DropdownMenuItem<String>(
              value: option,
              child: Text(
                option == 'NGN'
                    ? '🇳🇬 ₦'
                    : option == 'USD'
                        ? '🇺🇸 \$'
                        : option,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          )
          .toList(),
      onChanged: (value) {
        if (value != null) onChanged(value);
      },
    );
  }

  Widget _inlineCautionNotice(String text) {
    final theme = FlutterFlowTheme.of(context);
    return Container(
      padding: const EdgeInsetsDirectional.fromSTEB(10.0, 8.0, 10.0, 8.0),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF0F0),
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.warning_amber_rounded,
            color: Color(0xFFE53935),
            size: 17.0,
          ),
          const SizedBox(width: 7.0),
          Expanded(
            child: Text(
              text,
              style: theme.bodySmall.override(
                font: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontStyle: theme.bodySmall.fontStyle,
                ),
                color: const Color(0xFFE53935),
                fontSize: 10.8,
                letterSpacing: 0.0,
                fontWeight: FontWeight.w600,
                fontStyle: theme.bodySmall.fontStyle,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showNoticeSnackBar(String text) {
    showTopNotice(
      context,
      message: text,
      type: TopNoticeType.caution,
    );
  }

  Future<String?> _resolveInputAccount({
    required String bankName,
    required String accountNumber,
  }) async {
    final bankCode = _bankCodes[bankName];
    if (bankCode == null || accountNumber.length != 10) {
      return null;
    }
    try {
      final response = await http.post(
        Uri.parse(_validateBankUrl),
        headers: const {'Content-Type': 'application/json'},
        body: jsonEncode({
          'bankCode': bankCode,
          'accountNumber': accountNumber,
        }),
      );
      final payload = jsonDecode(response.body);
      if (payload is Map) {
        final candidates = [
          payload['accountName'],
          payload['account_name'],
          payload['account_name_enquiry'],
          if (payload['data'] is Map) (payload['data'] as Map)['accountName'],
          if (payload['data'] is Map) (payload['data'] as Map)['account_name'],
          if (payload['data'] is Map)
            (payload['data'] as Map)['account_name_enquiry'],
        ];
        for (final candidate in candidates) {
          final value = candidate?.toString().trim();
          if (value != null && value.isNotEmpty) {
            return value;
          }
        }
      }
    } catch (_) {}
    return null;
  }

  Future<void> _openInputAccountPopup() async {
    var popupBank = _inputBankName ?? _bankCodes.keys.first;
    var popupAccount = _accountController.text.trim();
    var popupAccountName = _inputAccountName;
    var validating = false;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final theme = FlutterFlowTheme.of(context);
        return StatefulBuilder(
          builder: (context, setModalState) {
            Future<void> validate() async {
              if (popupAccount.length != 10) {
                setModalState(() => popupAccountName = null);
                return;
              }
              setModalState(() => validating = true);
              final name = await _resolveInputAccount(
                bankName: popupBank,
                accountNumber: popupAccount,
              );
              if (!context.mounted) return;
              setModalState(() {
                popupAccountName = name;
                validating = false;
              });
            }

            return Padding(
              padding: EdgeInsetsDirectional.only(
                bottom: MediaQuery.viewInsetsOf(context).bottom + 12.0,
                start: 12.0,
                end: 12.0,
              ),
              child: Container(
                padding: const EdgeInsetsDirectional.fromSTEB(
                    16.0, 12.0, 16.0, 16.0),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(
                    top: Radius.circular(24.0),
                  ),
                  boxShadow: [
                    BoxShadow(
                      blurRadius: 26.0,
                      color: Color(0x33000000),
                      offset: Offset(0.0, -8.0),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 42.0,
                        height: 4.0,
                        decoration: BoxDecoration(
                          color: const Color(0xFFE1E6F0),
                          borderRadius: BorderRadius.circular(100.0),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14.0),
                    Text(
                      'Receive to bank account',
                      style: theme.titleSmall.override(
                        font: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontStyle: theme.titleSmall.fontStyle,
                        ),
                        color: theme.primaryText,
                        letterSpacing: 0.0,
                        fontWeight: FontWeight.w700,
                        fontStyle: theme.titleSmall.fontStyle,
                      ),
                    ),
                    const SizedBox(height: 12.0),
                    FlutterFlowDropDown<String>(
                      controller: FormFieldController<String>(popupBank),
                      options: _bankCodes.keys.toList(),
                      onChanged: (value) async {
                        if (value == null) return;
                        setModalState(() {
                          popupBank = value;
                          popupAccountName = null;
                        });
                        await validate();
                      },
                      width: double.infinity,
                      height: 46.0,
                      textStyle: theme.bodyMedium,
                      hintText: 'Select bank',
                      searchHintText: 'Type bank name',
                      icon: Icon(Icons.keyboard_arrow_down_rounded,
                          color: theme.secondaryText, size: 18.0),
                      fillColor: theme.secondaryBackground,
                      elevation: 2.0,
                      borderColor: _blue.withValues(alpha: 0.18),
                      borderWidth: 1.0,
                      borderRadius: 10.0,
                      margin: const EdgeInsetsDirectional.fromSTEB(
                          14.0, 8.0, 12.0, 8.0),
                      hidesUnderline: true,
                      isSearchable: true,
                      isMultiSelect: false,
                    ),
                    const SizedBox(height: 10.0),
                    TextFormField(
                      initialValue: popupAccount,
                      keyboardType: TextInputType.number,
                      maxLength: 10,
                      cursorColor: _blue,
                      decoration: _inputDecoration('Account number').copyWith(
                        counterText: '',
                      ),
                      style: GoogleFonts.inter(
                        color: theme.primaryText,
                        fontSize: 13.4,
                        fontWeight: FontWeight.w700,
                      ),
                      onChanged: (value) async {
                        popupAccount = value.replaceAll(RegExp(r'\D'), '');
                        await validate();
                      },
                    ),
                    const SizedBox(height: 8.0),
                    if (validating)
                      Text(
                        'Validating account...',
                        style: theme.bodySmall.override(
                          font: TextStyle(
                            fontWeight: FontWeight.normal,
                            fontStyle: theme.bodySmall.fontStyle,
                          ),
                          color: theme.secondaryText,
                          letterSpacing: 0.0,
                          fontWeight: FontWeight.normal,
                          fontStyle: theme.bodySmall.fontStyle,
                        ),
                      )
                    else if ((popupAccountName ?? '').isNotEmpty)
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              popupAccountName!,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.bodySmall.override(
                                font: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontStyle: theme.bodySmall.fontStyle,
                                ),
                                color: _blue,
                                fontSize: 11.4,
                                letterSpacing: 0.0,
                                fontWeight: FontWeight.w600,
                                fontStyle: theme.bodySmall.fontStyle,
                              ),
                            ),
                          ),
                          const SizedBox(width: 5.0),
                          const Icon(Icons.verified_rounded,
                              color: Color(0xFF18A058), size: 15.0),
                        ],
                      ),
                    const SizedBox(height: 14.0),
                    Align(
                      alignment: AlignmentDirectional.centerEnd,
                      child: StatusActionButton(
                        text: 'Use account',
                        isLoading: false,
                        isDone: false,
                        idleIcon: Icons.check_rounded,
                        height: 46.0,
                        horizontalPadding: 16.0,
                        trailingPadding: 5.0,
                        iconBoxSize: 36.0,
                        iconSize: 19.0,
                        fontSize: 13.0,
                        onPressed: () {
                          if (popupAccount.length != 10 ||
                              (popupAccountName ?? '').isEmpty) {
                            _showNoticeSnackBar(
                              'Validate the bank account before using it.',
                            );
                            return;
                          }
                          safeSetState(() {
                            _inputBankName = popupBank;
                            _inputAccountName = popupAccountName;
                            _accountController.text = popupAccount;
                          });
                          Navigator.of(context).pop();
                        },
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _destinationSummary() {
    final theme = FlutterFlowTheme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsetsDirectional.fromSTEB(12.0, 10.0, 12.0, 10.0),
      decoration: BoxDecoration(
        color: _blue.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(13.0),
        border: Border.all(color: _blue.withValues(alpha: 0.12)),
      ),
      child: Row(
        children: [
          Container(
            width: 30.0,
            height: 30.0,
            decoration: BoxDecoration(
              color: _blue.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.account_balance_rounded,
                color: _blue, size: 17.0),
          ),
          const SizedBox(width: 9.0),
          Expanded(
            child: Text(
              _destinationLabel,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: theme.bodySmall.override(
                font: TextStyle(
                  fontWeight: FontWeight.normal,
                  fontStyle: theme.bodySmall.fontStyle,
                ),
                color: theme.primaryText,
                fontSize: 11.0,
                letterSpacing: 0.0,
                fontWeight: FontWeight.normal,
                fontStyle: theme.bodySmall.fontStyle,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _networkSummary() {
    final theme = FlutterFlowTheme.of(context);
    return Container(
      height: 48.0,
      alignment: Alignment.centerLeft,
      padding: const EdgeInsetsDirectional.fromSTEB(12.0, 0.0, 12.0, 0.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: _blue.withValues(alpha: 0.16)),
      ),
      child: Row(
        children: [
          Icon(
            Icons.hub_rounded,
            color: _blue.withValues(alpha: 0.82),
            size: 18.0,
          ),
          const SizedBox(width: 8.0),
          Text(
            'Network: $_fixedCurrencyNetwork',
            style: theme.bodyMedium.override(
              font: TextStyle(
                fontWeight: FontWeight.normal,
                fontStyle: theme.bodyMedium.fontStyle,
              ),
              color: theme.primaryText,
              fontSize: 12.4,
              letterSpacing: 0.0,
              fontWeight: FontWeight.normal,
              fontStyle: theme.bodyMedium.fontStyle,
            ),
          ),
        ],
      ),
    );
  }

  Widget _receiveList() {
    final theme = FlutterFlowTheme.of(context);
    final requests = _filteredRequests;
    if (requests.isEmpty) {
      return Container(
        padding: const EdgeInsetsDirectional.fromSTEB(18.0, 18.0, 18.0, 18.0),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16.0),
          border: Border.all(color: _blue.withValues(alpha: 0.08)),
        ),
        child: Column(
          children: [
            Icon(Icons.receipt_long_rounded,
                color: _blue.withValues(alpha: 0.45), size: 34.0),
            const SizedBox(height: 8.0),
            Text(
              'No receive request yet.',
              style: theme.bodyMedium.override(
                font: TextStyle(
                  fontWeight: FontWeight.normal,
                  fontStyle: theme.bodyMedium.fontStyle,
                ),
                color: theme.secondaryText,
                fontSize: 12.2,
                letterSpacing: 0.0,
                fontWeight: FontWeight.normal,
                fontStyle: theme.bodyMedium.fontStyle,
              ),
            ),
          ],
        ),
      );
    }
    return Column(
      children: requests.take(5).map((request) {
        final timeLabel = _historyTimeLabel(request.createdAt);
        final statusColor =
            request.isPaid ? const Color(0xFF1E9D5A) : const Color(0xFFE08A1E);
        return InkWell(
          onTap: () => context.pushNamed(
            ReceiveRequestDetailsWidget.routeName,
            queryParameters: {
              'requestId': serializeParam(request.id, ParamType.String),
            }.withoutNulls,
          ),
          borderRadius: BorderRadius.circular(14.0),
          child: Container(
            margin: const EdgeInsetsDirectional.only(bottom: 8.0),
            padding:
                const EdgeInsetsDirectional.fromSTEB(14.0, 11.0, 14.0, 11.0),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14.0),
              border: Border.all(color: const Color(0xFFE8ECF3)),
            ),
            child: Row(
              children: [
                Container(
                  width: 34.0,
                  height: 34.0,
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    request.isPaid
                        ? Icons.check_rounded
                        : Icons.hourglass_empty_rounded,
                    color: statusColor,
                    size: 18.0,
                  ),
                ),
                const SizedBox(width: 10.0),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        request.description,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.bodyMedium.override(
                          font: TextStyle(
                            fontWeight: FontWeight.normal,
                            fontStyle: theme.bodyMedium.fontStyle,
                          ),
                          fontSize: 12.2,
                          letterSpacing: 0.0,
                          fontWeight: FontWeight.normal,
                          fontStyle: theme.bodyMedium.fontStyle,
                        ),
                      ),
                      const SizedBox(height: 2.0),
                      Text(
                        '${request.usage} • ${request.expiryLabel} • ${request.settlementMode}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.bodySmall.override(
                          font: TextStyle(
                            fontWeight: FontWeight.normal,
                            fontStyle: theme.bodySmall.fontStyle,
                          ),
                          color: theme.secondaryText,
                          fontSize: 10.2,
                          letterSpacing: 0.0,
                          fontWeight: FontWeight.normal,
                          fontStyle: theme.bodySmall.fontStyle,
                        ),
                      ),
                      const SizedBox(height: 2.0),
                      Text(
                        request.isPaid ? 'Received payment' : 'Yet to be paid',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(
                          color: statusColor,
                          fontSize: 9.8,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.0,
                        ),
                      ),
                      const SizedBox(height: 2.0),
                      Text(
                        timeLabel,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(
                          color: theme.secondaryText,
                          fontSize: 9.8,
                          fontWeight: FontWeight.w500,
                          letterSpacing: 0.0,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  _formatMoney(request.currency, request.amount),
                  style: GoogleFonts.inter(
                    color: _blue,
                    fontSize: 12.4,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(width: 4.0),
                Icon(Icons.chevron_right_rounded,
                    color: theme.secondaryText, size: 18.0),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _receiveStatusChip(String value, String label) {
    final selected = _receiveStatusFilter == value;
    return Expanded(
      child: InkWell(
        onTap: () => safeSetState(() => _receiveStatusFilter = value),
        borderRadius: BorderRadius.circular(16.0),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsetsDirectional.fromSTEB(10.0, 8.0, 10.0, 8.0),
          decoration: BoxDecoration(
            color: selected ? _blue : Colors.white,
            borderRadius: BorderRadius.circular(16.0),
            border: Border.all(
              color: selected ? _blue : const Color(0xFFE2E7EF),
              width: 0.8,
            ),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.inter(
              color: selected ? Colors.white : _blue,
              fontSize: 10.8,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.0,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    return Scaffold(
      key: scaffoldKey,
      backgroundColor: const Color(0xFFF4F6FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF4F6FA),
        elevation: 0.0,
        leading: FlutterFlowIconButton(
          borderColor: Colors.transparent,
          borderRadius: 30.0,
          buttonSize: 52.0,
          icon: const Icon(Icons.arrow_back_rounded, color: _blue, size: 24.0),
          onPressed: () => context.goNamed(DashboardWidget.routeName),
        ),
        title: Text(
          'Receive payment',
          style: theme.titleSmall.override(
            font: TextStyle(
              fontWeight: FontWeight.w800,
              fontStyle: theme.titleSmall.fontStyle,
            ),
            color: theme.primaryText,
            letterSpacing: 0.0,
            fontWeight: FontWeight.w800,
            fontStyle: theme.titleSmall.fontStyle,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsetsDirectional.fromSTEB(18.0, 10.0, 18.0, 26.0),
          children: [
            Container(
              padding:
                  const EdgeInsetsDirectional.fromSTEB(16.0, 16.0, 16.0, 16.0),
              decoration: BoxDecoration(
                color: _blue,
                borderRadius: BorderRadius.circular(18.0),
                boxShadow: [
                  BoxShadow(
                    blurRadius: 18.0,
                    color: _blue.withValues(alpha: 0.22),
                    offset: const Offset(0.0, 8.0),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    'Smart payment request',
                    textAlign: TextAlign.center,
                    style: theme.titleMedium.override(
                      font: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontStyle: theme.titleMedium.fontStyle,
                      ),
                      color: Colors.white,
                      fontSize: 17.0,
                      letterSpacing: 0.0,
                      fontWeight: FontWeight.w800,
                      fontStyle: theme.titleMedium.fontStyle,
                    ),
                  ),
                  const SizedBox(height: 4.0),
                  Text(
                    'Create a receive link, settle to bank, beneficiary, or 2Settle account.',
                    textAlign: TextAlign.center,
                    style: theme.bodySmall.override(
                      font: TextStyle(
                        fontWeight: FontWeight.normal,
                        fontStyle: theme.bodySmall.fontStyle,
                      ),
                      color: Colors.white.withValues(alpha: 0.82),
                      fontSize: 11.4,
                      letterSpacing: 0.0,
                      fontWeight: FontWeight.normal,
                      fontStyle: theme.bodySmall.fontStyle,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14.0),
            Row(
              children: [
                Expanded(
                  flex: 3,
                  child: TextFormField(
                    controller: _amountController,
                    focusNode: _amountFocusNode,
                    readOnly: true,
                    showCursor: true,
                    cursorColor: _blue,
                    cursorWidth: 2.0,
                    onTap: _openAmountKeypad,
                    decoration: _inputDecoration('Amount'),
                    style: GoogleFonts.inter(
                      color: theme.primaryText,
                      fontSize: 16.0,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(width: 8.0),
                Expanded(
                  flex: 2,
                  child: _selectField(
                    label: 'Currency',
                    value: _currency,
                    options: const [
                      'NGN',
                      'USD',
                    ],
                    onChanged: (value) => safeSetState(() {
                      _currency = value;
                      if (value != 'USDT') _network = 'Native';
                      if (value == 'USDT') _network = 'TRC20';
                    }),
                  ),
                ),
              ],
            ),
            if (_isCryptoCurrency) ...[
              const SizedBox(height: 10.0),
              _currency == 'USDT'
                  ? _selectField(
                      label: 'Network',
                      value: _network,
                      options: const ['TRC20', 'ERC20', 'BEP20'],
                      onChanged: (value) =>
                          safeSetState(() => _network = value),
                    )
                  : _networkSummary(),
            ],
            const SizedBox(height: 10.0),
            SwitchListTile.adaptive(
              value: _payerCanEdit,
              dense: true,
              contentPadding: EdgeInsets.zero,
              activeThumbColor: _blue,
              activeTrackColor: _blue.withValues(alpha: 0.24),
              title: Text(
                'Allow payer to edit amount',
                style: theme.bodyMedium.override(
                  font: TextStyle(
                    fontWeight: FontWeight.normal,
                    fontStyle: theme.bodyMedium.fontStyle,
                  ),
                  fontSize: 12.4,
                  letterSpacing: 0.0,
                  fontWeight: FontWeight.normal,
                  fontStyle: theme.bodyMedium.fontStyle,
                ),
              ),
              onChanged: (value) => safeSetState(() => _payerCanEdit = value),
            ),
            TextFormField(
              controller: _descriptionController,
              decoration: _inputDecoration('Payment description'),
              style: theme.bodyMedium.override(
                font: TextStyle(
                  fontWeight: FontWeight.normal,
                  fontStyle: theme.bodyMedium.fontStyle,
                ),
                fontSize: 12.6,
                letterSpacing: 0.0,
                fontWeight: FontWeight.normal,
                fontStyle: theme.bodyMedium.fontStyle,
              ),
            ),
            const SizedBox(height: 10.0),
            Row(
              children: [
                Expanded(
                  child: _selectField(
                    label: 'Expiry',
                    value: _expiry,
                    options: _expiryOptions,
                    onChanged: (value) async {
                      if (value == 'Custom date') {
                        await _pickCustomExpiryDate();
                      } else {
                        safeSetState(() => _expiry = value);
                      }
                    },
                  ),
                ),
                const SizedBox(width: 8.0),
                Expanded(
                  child: _selectField(
                    label: 'Usage',
                    value: _usage,
                    options: const ['Use once', 'Use multiple'],
                    onChanged: (value) => safeSetState(() => _usage = value),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10.0),
            _selectField(
              label: 'Settlement destination',
              value: _settlementMode,
              options: const [
                'Default account',
                'Saved beneficiary',
                'Input account number',
                '2Settle custom account',
              ],
              onChanged: (value) async {
                safeSetState(() => _settlementMode = value);
                if (value == 'Input account number') {
                  await _openInputAccountPopup();
                }
              },
            ),
            if (_settlementMode == 'Saved beneficiary') ...[
              const SizedBox(height: 10.0),
              if (_beneficiaries.isEmpty)
                _inlineCautionNotice(
                  'No saved beneficiary yet. Add bank details first or use input account number.',
                )
              else
                DropdownButtonFormField<_SavedBeneficiary>(
                  initialValue: _selectedBeneficiary,
                  isExpanded: true,
                  icon: const Icon(Icons.keyboard_arrow_down_rounded,
                      color: _blue),
                  decoration: _inputDecoration('Saved beneficiary'),
                  items: _beneficiaries
                      .map(
                        (beneficiary) => DropdownMenuItem<_SavedBeneficiary>(
                          value: beneficiary,
                          child: Text(
                            '${beneficiary.name} • ${beneficiary.bank}',
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: (value) =>
                      safeSetState(() => _selectedBeneficiary = value),
                ),
            ],
            if (_settlementMode == 'Input account number') ...[
              const SizedBox(height: 10.0),
              InkWell(
                onTap: _openInputAccountPopup,
                borderRadius: BorderRadius.circular(13.0),
                child: _destinationSummary(),
              ),
            ],
            if (_settlementMode != 'Input account number' &&
                _settlementMode != 'Saved beneficiary') ...[
              const SizedBox(height: 10.0),
              _destinationSummary(),
            ],
            const SizedBox(height: 14.0),
            Align(
              alignment: AlignmentDirectional.centerEnd,
              child: StatusActionButton(
                text: 'Create',
                isLoading: _isCreating,
                isDone: _isCreated,
                idleIcon: Icons.add_link_rounded,
                height: 48.0,
                horizontalPadding: 17.0,
                trailingPadding: 5.0,
                iconBoxSize: 38.0,
                iconSize: 20.0,
                fontSize: 14.0,
                onPressed: _createRequest,
              ),
            ),
            const SizedBox(height: 22.0),
            Text(
              'History',
              style: theme.bodyMedium.override(
                font: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontStyle: theme.bodyMedium.fontStyle,
                ),
                color: _blue,
                letterSpacing: 0.0,
                fontWeight: FontWeight.w700,
                fontStyle: theme.bodyMedium.fontStyle,
              ),
            ),
            const SizedBox(height: 10.0),
            Row(
              children: [
                _receiveStatusChip('Unpaid', 'Yet to be paid'),
                const SizedBox(width: 8.0),
                _receiveStatusChip('Received', 'Received payment'),
              ],
            ),
            const SizedBox(height: 10.0),
            _receiveList(),
          ],
        ),
      ),
    );
  }

  String _historyTimeLabel(DateTime value) {
    final difference = DateTime.now().difference(value);
    if (difference.inHours < 48) {
      return '${dateTimeFormat('relative', value)} • ${DateFormat('h:mm a').format(value)}';
    }
    return DateFormat('MMM d, yyyy • h:mm a').format(value);
  }
}

class _ReceiveRequest {
  const _ReceiveRequest({
    required this.id,
    required this.amount,
    required this.currency,
    required this.description,
    required this.expiry,
    required this.expiryLabel,
    required this.usage,
    required this.payerCanEdit,
    required this.settlementMode,
    required this.settlementLabel,
    required this.network,
    required this.accountNumber,
    required this.status,
    required this.createdAt,
  });

  final String id;
  final String amount;
  final String currency;
  final String description;
  final String expiry;
  final String expiryLabel;
  final String usage;
  final bool payerCanEdit;
  final String settlementMode;
  final String settlementLabel;
  final String network;
  final String accountNumber;
  final String status;
  final DateTime createdAt;

  factory _ReceiveRequest.fromJson(Map<String, dynamic> json) {
    return _ReceiveRequest(
      id: json['id']?.toString() ?? '',
      amount: json['amount']?.toString() ?? '0',
      currency: json['currency']?.toString() ?? 'NGN',
      description: json['description']?.toString() ?? 'Payment request',
      expiry: json['expiry']?.toString() ?? '24 hours',
      expiryLabel: json['expiryLabel']?.toString() ??
          json['expiry']?.toString() ??
          '24 hours',
      usage: json['usage']?.toString() ?? 'Use once',
      payerCanEdit: json['payerCanEdit'] == true,
      settlementMode: json['settlementMode']?.toString() ?? 'Default account',
      settlementLabel: json['settlementLabel']?.toString() ?? '',
      network: json['network']?.toString() ?? '',
      accountNumber: json['accountNumber']?.toString() ?? '',
      status: json['status']?.toString() ?? 'created',
      createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? '') ??
          DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'amount': amount,
        'currency': currency,
        'description': description,
        'expiry': expiry,
        'expiryLabel': expiryLabel,
        'usage': usage,
        'payerCanEdit': payerCanEdit,
        'settlementMode': settlementMode,
        'settlementLabel': settlementLabel,
        'network': network,
        'accountNumber': accountNumber,
        'status': status,
        'createdAt': createdAt.toIso8601String(),
      };

  bool get isPaid => status.toLowerCase() == 'paid';
}

class _SavedBeneficiary {
  const _SavedBeneficiary({
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
  final bool isDefault;

  factory _SavedBeneficiary.fromJson(Map<String, dynamic> json) {
    return _SavedBeneficiary(
      name: json['name']?.toString() ?? 'Beneficiary',
      bank: json['bank']?.toString() ?? 'Bank',
      accountNumber: json['accountNumber']?.toString() ?? '',
      accountName: json['accountName']?.toString() ?? '',
      isDefault: json['isDefault'] == true,
    );
  }
}
