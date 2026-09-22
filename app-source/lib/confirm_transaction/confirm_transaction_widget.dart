import '/components/status_action_button.dart';
import '/components/top_notice.dart';
import '/config/api_config.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/index.dart';
import '/services/auth_service.dart';
import '/services/debug_error_logger.dart';
import '/components/payment_phone_prompt.dart';
import '/services/transfer_flow_cache.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'confirm_transaction_model.dart';
export 'confirm_transaction_model.dart';

class ConfirmTransactionWidget extends StatefulWidget {
  const ConfirmTransactionWidget({
    super.key,
    this.settlementAmount = '0.00',
    this.rate = '...',
    this.beneficiaryName = 'Beneficiary',
    this.bankName = 'Bank',
    this.bankCode = '',
    this.accountNumber = '',
    this.cryptoAmount = '0.00000 USDT',
    this.crypto = 'USDT',
    this.network = 'TRC20',
    this.networkCode = 'trc20',
  });

  static String routeName = 'confirm_transaction';
  static String routePath = 'confirmTransaction';

  final String settlementAmount;
  final String rate;
  final String beneficiaryName;
  final String bankName;
  final String bankCode;
  final String accountNumber;
  final String cryptoAmount;
  final String crypto;
  final String network;
  final String networkCode;

  @override
  State<ConfirmTransactionWidget> createState() =>
      _ConfirmTransactionWidgetState();
}

class _ConfirmTransactionWidgetState extends State<ConfirmTransactionWidget> {
  late ConfirmTransactionModel _model;

  final scaffoldKey = GlobalKey<ScaffoldState>();
  static const _blue = Color(0xFF4472C4);
  static const _transactionStorageKey = '2settle_initiated_transactions';
  static const _paymentsUrl = ApiConfig.paymentsUrl;
  bool _isConfirming = false;

  String? _userId;
  String get _draftKey => jsonEncode([
        _userId,
        widget.settlementAmount,
        widget.bankCode,
        widget.accountNumber,
        widget.crypto,
        widget.networkCode,
      ]);

  Future<void> _openFunding(Map<String, String> params) async {
    final completed = await context.pushNamed<bool>(
        ReceiveFundingWidget.routeName,
        queryParameters: params);
    if (!mounted || completed != true) return;
    TransferFlowCache.complete(_draftKey);
    context.pop(params);
  }

  String get _settlementText => '₦${widget.settlementAmount}';
  String get _cryptoOnlyAmount {
    final number =
        _roundDownCrypto(widget.cryptoAmount.split(' ').first.trim());
    return '$number ${widget.crypto}';
  }

  String _roundDownCrypto(String value) {
    final parsed = double.tryParse(value.replaceAll(',', '').trim());
    if (parsed == null) return value;
    return ((parsed * 100000).floor() / 100000).toStringAsFixed(5);
  }

  static const _networkFee = 0.0004;
  static const _conversionFeePercent = 3;
  static const _processingFee = 1000.0;

  void _goBack() {
    if (context.canPop()) context.pop();
  }

  void _closeToHome() {
    context.pushNamed(DashboardWidget.routeName);
  }

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => ConfirmTransactionModel());
  }

  @override
  void dispose() {
    _model.dispose();
    super.dispose();
  }

  Widget _reviewLine({
    required IconData icon,
    required String label,
    required String value,
    Color? iconColor,
    bool numeric = false,
    bool interValue = false,
  }) {
    final theme = FlutterFlowTheme.of(context);
    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(0.0, 5.0, 0.0, 5.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: iconColor ?? _blue, size: 17.0),
          const SizedBox(width: 9.0),
          Expanded(
            child: Text(
              label,
              textAlign: TextAlign.left,
              style: theme.bodySmall.override(
                font: TextStyle(
                  fontWeight: FontWeight.normal,
                  fontStyle: theme.bodySmall.fontStyle,
                ),
                color: theme.secondaryText,
                fontSize: 11.2,
                letterSpacing: 0.0,
                fontWeight: FontWeight.normal,
                fontStyle: theme.bodySmall.fontStyle,
              ),
            ),
          ),
          const SizedBox(width: 8.0),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: numeric || interValue
                  ? GoogleFonts.inter(
                      color: theme.primaryText,
                      fontSize: 11.5,
                      fontWeight: FontWeight.w500,
                    )
                  : theme.bodySmall.override(
                      font: TextStyle(
                        fontWeight: FontWeight.normal,
                        fontStyle: theme.bodySmall.fontStyle,
                      ),
                      color: theme.primaryText,
                      fontSize: 11.5,
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

  Widget _routeReview() {
    final theme = FlutterFlowTheme.of(context);
    final crypto = widget.crypto.toUpperCase();
    final route =
        crypto == 'USDT' ? 'USDT > stables > NGN' : '$crypto > USDT > NGN';
    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(0.0, 5.0, 0.0, 5.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Crypto route',
                  textAlign: TextAlign.center,
                  style: theme.bodySmall.override(
                    font: TextStyle(
                      fontWeight: FontWeight.normal,
                      fontStyle: theme.bodySmall.fontStyle,
                    ),
                    color: theme.secondaryText,
                    fontSize: 11.2,
                    letterSpacing: 0.0,
                    fontWeight: FontWeight.normal,
                    fontStyle: theme.bodySmall.fontStyle,
                  ),
                ),
                const SizedBox(height: 2.0),
                Text(
                  route,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    color: theme.primaryText,
                    fontSize: 11.4,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _receiverReview() {
    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(0.0, 5.0, 0.0, 5.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.person_pin_circle_rounded, color: _blue, size: 17.0),
          const SizedBox(width: 9.0),
          Expanded(
            child: Column(
              children: [
                _receiverLine('Receiver name', widget.beneficiaryName),
                _receiverLine('Receiver bank', widget.bankName),
                _receiverLine('Receiver account', widget.accountNumber,
                    numeric: true),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _receiverLine(String label, String value, {bool numeric = false}) {
    final theme = FlutterFlowTheme.of(context);
    return Padding(
      padding: const EdgeInsetsDirectional.only(bottom: 3.0),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              textAlign: TextAlign.left,
              style: theme.bodySmall.override(
                font: TextStyle(
                  fontWeight: FontWeight.normal,
                  fontStyle: theme.bodySmall.fontStyle,
                ),
                color: theme.secondaryText,
                fontSize: 10.5,
                letterSpacing: 0.0,
                fontWeight: FontWeight.normal,
                fontStyle: theme.bodySmall.fontStyle,
              ),
            ),
          ),
          const SizedBox(width: 8.0),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              overflow: TextOverflow.ellipsis,
              style: numeric
                  ? GoogleFonts.inter(
                      color: theme.primaryText,
                      fontSize: 11.2,
                      fontWeight: FontWeight.w500,
                    )
                  : theme.bodySmall.override(
                      font: TextStyle(
                        fontWeight: FontWeight.normal,
                        fontStyle: theme.bodySmall.fontStyle,
                      ),
                      color: theme.primaryText,
                      fontSize: 11.2,
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

  Widget _divider() {
    return Divider(
      height: 1.0,
      thickness: 0.7,
      color: const Color(0xFFE5E8EF),
    );
  }

  Future<void> _saveInitiatedTransaction({
    required String settlementAmount,
    required String cryptoAmount,
    required String reference,
    required String status,
  }) async {
    final settlement = double.tryParse(
            settlementAmount.replaceAll(',', '').replaceAll('₦', '')) ??
        0;
    final cryptoValue =
        double.tryParse(cryptoAmount.split(' ').first.trim()) ?? 0;
    if (settlement <= 0 && cryptoValue <= 0) {
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString(_transactionStorageKey);
    List<dynamic> transactions = [];
    if (stored != null && stored.isNotEmpty) {
      try {
        final decoded = jsonDecode(stored);
        if (decoded is List) {
          transactions = decoded;
        }
      } catch (_) {
        transactions = [];
      }
    }

    final now = DateTime.now();
    transactions.insert(0, {
      'id': reference.isNotEmpty
          ? reference
          : '2ST-${now.microsecondsSinceEpoch}',
      'createdAt': now.toIso8601String(),
      'settlementAmount': settlementAmount,
      'cryptoAmount': cryptoAmount,
      'crypto': widget.crypto,
      'network': widget.network,
      'beneficiaryName': widget.beneficiaryName,
      'bankName': widget.bankName,
      'accountNumber': widget.accountNumber,
      'rate': widget.rate,
      'status': status,
    });

    await prefs.setString(
      _transactionStorageKey,
      jsonEncode(transactions.take(50).toList()),
    );
  }

  Map<String, dynamic> _paymentFromResponse(Map<String, dynamic> payload) {
    final payment = payload['payment'];
    if (payment is Map) return Map<String, dynamic>.from(payment);
    final data = payload['data'];
    if (data is Map) return Map<String, dynamic>.from(data);
    return payload;
  }

  String _formatCryptoAmount(dynamic value, String crypto) {
    final parsed = value is num
        ? value.toDouble()
        : double.tryParse('${value ?? ''}'.replaceAll(',', '').trim());
    if (parsed == null) return widget.cryptoAmount;
    final roundedDown = (parsed * 100000).floor() / 100000;
    return '${roundedDown.toStringAsFixed(5)} $crypto';
  }

  // Creates the real payment session with payment-engine (via mobile-api) so
  // the crypto amount, naira amount, and deposit wallet shown on the next
  // screen come from the session it opens, not from this screen's own
  // client-side estimate.
  Future<void> _confirmTransaction() async {
    if (_isConfirming) return;

    final fiatAmount = double.tryParse(
          widget.settlementAmount
              .replaceAll(',', '')
              .replaceAll('₦', '')
              .trim(),
        ) ??
        0;
    if (fiatAmount <= 0) {
      showTopNotice(context,
          message: 'Enter a valid amount.', type: TopNoticeType.caution);
      return;
    }
    if (widget.bankCode.isEmpty || widget.accountNumber.isEmpty) {
      logTransactionError('beneficiary_validation',
          message: 'Missing bankCode or accountNumber');
      showTopNotice(
        context,
        message: 'Select a valid beneficiary account.',
        type: TopNoticeType.caution,
      );
      return;
    }

    safeSetState(() => _isConfirming = true);
    try {
      _userId = await AuthService.getUserId();
      if (!mounted) return;
      final cached = TransferFlowCache.get(_draftKey);
      if (cached != null) {
        await _openFunding(cached);
        return;
      }

      final phone = await ensurePaymentPhone(context);
      if (!mounted || phone == null) return;
      final accessToken = await AuthService.getAccessToken();
      if (accessToken == null || accessToken.isEmpty) {
        throw Exception('Your session has expired. Please sign in again.');
      }
      final response = await http
          .post(
            Uri.parse(_paymentsUrl),
            headers: {
              'accept': 'application/json',
              'content-type': 'application/json',
              'authorization': 'Bearer $accessToken',
            },
            body: jsonEncode({
              'type': 'transfer',
              'fiatAmount': fiatAmount,
              'fiatCurrency': 'NGN',
              'crypto': widget.crypto,
              'network': widget.networkCode,
              'chargeFrom': 'crypto',
              'payer': {'phone': phone},
              'receiver': {
                'bankCode': widget.bankCode,
                'accountNumber': widget.accountNumber,
              },
            }),
          )
          .timeout(const Duration(seconds: 14));
      final decoded = response.body.isEmpty
          ? <String, dynamic>{}
          : jsonDecode(response.body) as Map<String, dynamic>;
      final ok = response.statusCode >= 200 &&
          response.statusCode < 300 &&
          decoded['ok'] != false &&
          decoded['success'] != false;
      if (!ok) {
        logTransactionError('payment_response',
            status: response.statusCode,
            code: decoded['code'],
            message: decoded['message'] ?? decoded['error']);
        final message = decoded['message'] ??
            decoded['error'] ??
            'Unable to create payment.';
        throw Exception(message);
      }

      final payment = _paymentFromResponse(decoded);
      final crypto = '${payment['crypto'] ?? widget.crypto}'.toUpperCase();
      final settlementAmount = '${payment['fiatAmount'] ?? fiatAmount}';
      final cryptoAmount = _formatCryptoAmount(payment['cryptoAmount'], crypto);
      final depositAddress = '${payment['depositAddress'] ?? ''}';
      final reference = '${payment['reference'] ?? ''}';
      final charge = payment['charge'];

      final fundingParams = <String, String>{
        'settlementAmount': settlementAmount,
        'cryptoAmount': cryptoAmount,
        'crypto': crypto,
        'network': widget.network,
        'beneficiaryName': widget.beneficiaryName,
        'bankName': widget.bankName,
        'accountNumber': widget.accountNumber,
        'rate': '${payment['rate'] ?? widget.rate}',
        'paymentId': '${payment['id'] ?? ''}',
        'reference': reference,
        'depositAddress': depositAddress,
        'paymentStatus': '${payment['status'] ?? 'pending'}',
        'expiresAt': '${payment['expiresAt'] ?? ''}',
        'chargeFiat': '${charge is Map ? charge['fiat'] ?? '' : ''}',
        'chargeCrypto': '${charge is Map ? charge['crypto'] ?? '' : ''}',
        'transactionUsd': '${payment['transactionUsd'] ?? ''}',
      };
      TransferFlowCache.save(_draftKey, fundingParams);
      await _saveInitiatedTransaction(
        settlementAmount: settlementAmount,
        cryptoAmount: cryptoAmount,
        reference: reference,
        status: 'funding',
      );
      if (!mounted) return;

      await _openFunding(fundingParams);
    } catch (error) {
      logTransactionError('payment_exception',
          code: error.runtimeType.toString(), message: error.toString());
      if (!mounted) return;
      showTopNotice(
        context,
        message: error.toString().replaceFirst('Exception: ', ''),
        type: TopNoticeType.caution,
      );
    } finally {
      if (mounted) safeSetState(() => _isConfirming = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    return Scaffold(
      key: scaffoldKey,
      backgroundColor: const Color(0xFFF4F6FA),
      body: SafeArea(
        child: Stack(
          children: [
            Positioned.fill(
              child: Opacity(
                opacity: 0.18,
                child: Image.asset(
                  'assets/images/g2t7j_2.jpg',
                  fit: BoxFit.cover,
                ),
              ),
            ),
            Align(
              alignment: Alignment.bottomCenter,
              child: Container(
                width: double.infinity,
                margin:
                    const EdgeInsetsDirectional.fromSTEB(14.0, 0.0, 14.0, 18.0),
                padding: const EdgeInsetsDirectional.fromSTEB(
                    20.0, 12.0, 20.0, 20.0),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(28.0),
                  boxShadow: const [
                    BoxShadow(
                      blurRadius: 28.0,
                      color: Color(0x26000000),
                      offset: Offset(0.0, 12.0),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 42.0,
                      height: 4.0,
                      decoration: BoxDecoration(
                        color: const Color(0xFFD7DCE5),
                        borderRadius: BorderRadius.circular(999.0),
                      ),
                    ),
                    const SizedBox(height: 14.0),
                    Text(
                      'Confirm Transaction',
                      textAlign: TextAlign.center,
                      style: theme.titleMedium.override(
                        font: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontStyle: theme.titleMedium.fontStyle,
                        ),
                        color: theme.primaryText,
                        fontSize: 18.0,
                        letterSpacing: 0.0,
                        fontWeight: FontWeight.w700,
                        fontStyle: theme.titleMedium.fontStyle,
                      ),
                    ),
                    const SizedBox(height: 8.0),
                    Text(
                      'Please review all details carefully.',
                      textAlign: TextAlign.center,
                      style: theme.bodySmall.override(
                        font: TextStyle(
                          fontWeight: FontWeight.w500,
                          fontStyle: theme.bodySmall.fontStyle,
                        ),
                        color: theme.secondaryText,
                        fontSize: 11.6,
                        letterSpacing: 0.0,
                        fontWeight: FontWeight.w500,
                        fontStyle: theme.bodySmall.fontStyle,
                      ),
                    ),
                    const SizedBox(height: 7.0),
                    Container(
                      padding: const EdgeInsetsDirectional.fromSTEB(
                          10.0, 7.0, 10.0, 7.0),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF0F0),
                        borderRadius: BorderRadius.circular(12.0),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.warning_amber_rounded,
                            color: Color(0xFFE53935),
                            size: 16.0,
                          ),
                          const SizedBox(width: 6.0),
                          Text(
                            'Completed transactions are irreversible.',
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
                        ],
                      ),
                    ),
                    const SizedBox(height: 12.0),
                    Text(
                      _settlementText,
                      style: GoogleFonts.inter(
                        color: _blue,
                        fontSize: 40.0,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.0,
                      ),
                    ),
                    Text(
                      _cryptoOnlyAmount,
                      style: GoogleFonts.inter(
                        color: theme.secondaryText,
                        fontSize: 13.0,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.0,
                      ),
                    ),
                    const SizedBox(height: 12.0),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsetsDirectional.fromSTEB(
                          12.0, 10.0, 12.0, 10.0),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFD),
                        borderRadius: BorderRadius.circular(16.0),
                        border: Border.all(color: const Color(0xFFE8ECF3)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Funding review',
                            style: theme.bodySmall.override(
                              font: TextStyle(
                                fontWeight: FontWeight.w700,
                                fontStyle: theme.bodySmall.fontStyle,
                              ),
                              color: _blue,
                              fontSize: 12.0,
                              letterSpacing: 0.0,
                              fontWeight: FontWeight.w700,
                              fontStyle: theme.bodySmall.fontStyle,
                            ),
                          ),
                          const SizedBox(height: 4.0),
                          _receiverReview(),
                          _divider(),
                          _routeReview(),
                          _divider(),
                          _reviewLine(
                            icon: Icons.account_balance_wallet_rounded,
                            label: 'You send',
                            value: _cryptoOnlyAmount,
                            numeric: true,
                          ),
                          _divider(),
                          _reviewLine(
                            icon: Icons.token_rounded,
                            label: 'Crypto',
                            value: widget.crypto,
                          ),
                          _divider(),
                          _reviewLine(
                            icon: Icons.hub_rounded,
                            label: 'Network',
                            value: widget.network,
                            interValue: true,
                          ),
                          _divider(),
                          _reviewLine(
                            icon: Icons.south_west_rounded,
                            label: 'Expected settlement',
                            value: _settlementText,
                            numeric: true,
                          ),
                          _divider(),
                          _reviewLine(
                            icon: Icons.local_gas_station_rounded,
                            label: 'Network fee',
                            value:
                                '${_roundDownCrypto(_networkFee.toString())} ${widget.crypto}',
                            iconColor: const Color(0xFFE53935),
                            numeric: true,
                          ),
                          _divider(),
                          _reviewLine(
                            icon: Icons.currency_exchange_rounded,
                            label: 'Conversion fee',
                            value: '$_conversionFeePercent%',
                            numeric: true,
                          ),
                          _divider(),
                          _reviewLine(
                            icon: Icons.payments_rounded,
                            label: 'Processing fee',
                            value:
                                '₦${NumberFormat('#,##0', 'en_US').format(_processingFee)}',
                            numeric: true,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14.0),
                    StatusActionButton(
                      text: 'Confirm',
                      isLoading: _isConfirming,
                      isDone: false,
                      onPressed: _confirmTransaction,
                      idleIcon: Icons.check_rounded,
                      height: 48.0,
                      horizontalPadding: 18.0,
                      trailingPadding: 5.0,
                      iconBoxSize: 38.0,
                      iconSize: 20.0,
                      fontSize: 14.0,
                      gap: 10.0,
                      backgroundColor: _blue,
                      textColor: Colors.white,
                      iconBackgroundColor: Colors.white,
                      iconColor: _blue,
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
              top: 10.0,
              left: 12.0,
              child: Material(
                color: Colors.white,
                shape: const CircleBorder(),
                child: IconButton(
                  icon: const Icon(
                    Icons.arrow_back_rounded,
                    color: _blue,
                    size: 22.0,
                  ),
                  onPressed: _goBack,
                ),
              ),
            ),
            Positioned(
              top: 10.0,
              right: 12.0,
              child: Material(
                color: Colors.white,
                shape: const CircleBorder(),
                child: IconButton(
                  icon: const Icon(
                    Icons.close_rounded,
                    color: Color(0xFFE53935),
                    size: 22.0,
                  ),
                  onPressed: _closeToHome,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
