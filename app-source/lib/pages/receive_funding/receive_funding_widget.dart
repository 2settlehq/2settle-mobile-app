import '/config/api_config.dart';
import '/services/auth_service.dart';
import 'package:http/http.dart' as http;
import '/components/status_action_button.dart';
import '/components/top_notice.dart';
import '/flutter_flow/flutter_flow_icon_button.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/index.dart';
import 'package:barcode_widget/barcode_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'receive_funding_model.dart';
export 'receive_funding_model.dart';

class ReceiveFundingWidget extends StatefulWidget {
  const ReceiveFundingWidget({
    super.key,
    this.settlementAmount = '0.00',
    this.cryptoAmount = '0.00000 USDT',
    this.crypto = 'USDT',
    this.network = 'TRC20',
    this.beneficiaryName = 'Beneficiary',
    this.bankName = 'Bank',
    this.accountNumber = '',
    this.rate = '...',
    this.purpose = '',
    this.paymentId = '',
    this.reference = '',
    this.depositAddress = '',
    this.paymentStatus = '',
    this.expiresAt = '',
    this.chargeFiat = '',
    this.chargeCrypto = '',
    this.transactionUsd = '',
  });

  static String routeName = 'Receive_funding';
  static String routePath = 'receiveFunding';

  final String settlementAmount;
  final String cryptoAmount;
  final String crypto;
  final String network;
  final String beneficiaryName;
  final String bankName;
  final String accountNumber;
  final String rate;
  final String purpose;
  final String paymentId;
  final String reference;
  final String depositAddress;
  final String paymentStatus;
  final String expiresAt;
  final String chargeFiat;
  final String chargeCrypto;
  final String transactionUsd;

  @override
  State<ReceiveFundingWidget> createState() => _ReceiveFundingWidgetState();
}

class _ReceiveFundingWidgetState extends State<ReceiveFundingWidget> {
  late ReceiveFundingModel _model;

  final scaffoldKey = GlobalKey<ScaffoldState>();
  static const _blue = Color(0xFF4472C4);

  late String _crypto;
  late String _network;
  int _fundingStage = -1;
  bool _isConfirmingFunding = false;
  String _backendStatus = '';
  String? _fundingError;

  static const _addresses = {
    'USDT_TRC20': 'TR2SettleDemoX9aQp4rN7u8mK2sV6yW',
    'USDT_ERC20': '0x2SettleDemo9A8b7C6d5E4f3210aBCdEf',
    'USDT_BEP20': '0x2SettleBnbDemo5E4f3210aBCdEf9A8b7',
    'USDC_ERC20': '0x2SettleUsdcDemo7C6d5E4f3210aBC',
    'USDC_BEP20': '0x2SettleUsdcBnbDemo4f3210aBCdEf',
    'BTC_Bitcoin': 'bc1q2settledemo9a8b7c6d5e4f3210',
    'ETH_ERC20': '0x2SettleEthDemo3210aBCdEf9A8b7C6d',
    'ETH_Ethereum': '0x2SettleEthDemo3210aBCdEf9A8b7C6d',
    'BNB_Binance': 'bnb1q2settledemo9a8b7c6d5e4f3210',
    'TRX_Tron': 'TRX2SettleDemoX9aQp4rN7u8mK2sV6yW',
  };

  String get _address => widget.depositAddress.trim().isNotEmpty
      ? widget.depositAddress.trim()
      : _addresses['${_crypto}_$_network'] ?? '';

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

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => ReceiveFundingModel());
    _crypto = widget.crypto;
    _network = widget.network;
  }

  @override
  void dispose() {
    _model.dispose();
    super.dispose();
  }

  Future<void> _copyAddress() async {
    await Clipboard.setData(ClipboardData(text: _address));
    if (!mounted) return;
    showTopNotice(
      context,
      message: 'Wallet address copied',
      type: TopNoticeType.info,
    );
  }

  Future<void> _confirmFunding() async {
    if (_isConfirmingFunding) return;
    safeSetState(() {
      _isConfirmingFunding = true;
      _fundingStage = 0;
    });

    try {
      if (widget.reference.isEmpty)
        throw Exception('Payment reference is missing.');
      final token = await AuthService.getAccessToken();
      if (token == null) throw Exception('Please sign in again.');
      final response = await http.get(
        Uri.parse(
            '${ApiConfig.paymentsUrl}/${Uri.encodeComponent(widget.reference)}'),
        headers: {
          'accept': 'application/json',
          'authorization': 'Bearer $token'
        },
      ).timeout(const Duration(seconds: 14));
      final payload = jsonDecode(response.body);
      if (response.statusCode < 200 ||
          response.statusCode >= 300 ||
          payload is! Map ||
          payload['ok'] == false) {
        throw Exception(payload is Map
            ? payload['error'] ?? 'Could not check payment.'
            : 'Could not check payment.');
      }
      final payment = payload['payment'];
      final status =
          payment is Map ? '${payment['status'] ?? ''}'.toLowerCase() : '';
      if (status.isEmpty) throw Exception('Payment status is unavailable.');
      if (!mounted) return;
      final complete = status == 'settled' ||
          (widget.purpose == 'create_gift' &&
              ['confirmed', 'settling'].contains(status));
      safeSetState(() {
        _backendStatus = status;
        _fundingStage = complete ? 3 : -1;
        _fundingError = complete
            ? null
            : 'Payment status: $status. You can check again shortly.';
      });
      if (_fundingError != null) {
        showTopNotice(context,
            message: _fundingError!, type: TopNoticeType.caution);
      }
    } catch (error) {
      if (!mounted) return;
      safeSetState(() {
        _fundingStage = -1;
        _fundingError = error.toString().replaceFirst('Exception: ', '');
      });
      showTopNotice(context,
          message: _fundingError!, type: TopNoticeType.caution);
    } finally {
      if (mounted) safeSetState(() => _isConfirmingFunding = false);
    }
  }

  Future<void> _continueToConfirmed() async {
    if (_isConfirmingFunding || _fundingError != null) return;
    if (widget.purpose == 'create_gift') {
      await context.pushNamed(
        GiftCreatedWidget.routeName,
        queryParameters: {
          'amount': widget.settlementAmount,
          'crypto': _crypto,
          'network': _network,
          'cryptoAmount': widget.cryptoAmount,
          'reference': widget.reference,
          'paymentId': widget.paymentId,
          'depositAddress': _address,
          'status':
              widget.paymentStatus.isEmpty ? 'pending' : widget.paymentStatus,
          'expiresAt': widget.expiresAt,
          'chargeFiat': widget.chargeFiat,
          'chargeCrypto': widget.chargeCrypto,
          'rate': widget.rate,
          'transactionUsd': widget.transactionUsd,
        }.withoutNulls,
      );
      if (!mounted) return;
      safeSetState(() {
        _fundingStage = -1;
        _isConfirmingFunding = false;
      });
      return;
    }
    if (_fundingError != null || _backendStatus != 'settled') return;
    context.pop(true);
  }

  Widget _fundingStat({
    required IconData icon,
    required String label,
    required String value,
  }) {
    final theme = FlutterFlowTheme.of(context);
    return Expanded(
      child: Container(
        padding: const EdgeInsetsDirectional.fromSTEB(8.0, 8.0, 8.0, 8.0),
        decoration: BoxDecoration(
          color: _blue.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12.0),
        ),
        child: Column(
          children: [
            Icon(icon, color: _blue, size: 18.0),
            const SizedBox(height: 4.0),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.bodySmall.override(
                font: TextStyle(
                  fontWeight: FontWeight.normal,
                  fontStyle: theme.bodySmall.fontStyle,
                ),
                color: theme.secondaryText,
                fontSize: 9.5,
                letterSpacing: 0.0,
                fontWeight: FontWeight.normal,
                fontStyle: theme.bodySmall.fontStyle,
              ),
            ),
            const SizedBox(height: 2.0),
            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.inter(
                color: theme.primaryText,
                fontSize: 10.8,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _fundingProgress() {
    final theme = FlutterFlowTheme.of(context);
    const stages = [
      _FundingStageData('Pending', Icons.hourglass_empty_rounded),
      _FundingStageData('Confirming', Icons.sync_rounded),
      _FundingStageData('Settling', Icons.account_balance_rounded),
      _FundingStageData('Paid', Icons.check_circle_rounded),
    ];
    return Container(
      width: double.infinity,
      padding: const EdgeInsetsDirectional.fromSTEB(12.0, 12.0, 12.0, 12.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14.0),
        border: Border.all(color: _blue.withValues(alpha: 0.12)),
      ),
      child: Column(
        children: [
          TweenAnimationBuilder<double>(
            tween: Tween<double>(
              begin: 0.0,
              end: _fundingStage < 0
                  ? 0.0
                  : (_fundingStage / (stages.length - 1)).clamp(0.0, 1.0),
            ),
            duration: const Duration(milliseconds: 720),
            curve: Curves.easeInOutCubic,
            builder: (context, progress, child) {
              return Stack(
                alignment: Alignment.topCenter,
                children: [
                  Positioned(
                    top: 11.0,
                    left: 34.0,
                    right: 34.0,
                    child: Container(
                      height: 2.0,
                      color: const Color(0xFFE8ECF3),
                    ),
                  ),
                  Positioned(
                    top: 11.0,
                    left: 34.0,
                    right: 34.0,
                    child: Align(
                      alignment: AlignmentDirectional.centerStart,
                      child: FractionallySizedBox(
                        widthFactor: progress,
                        child: Container(
                          height: 2.0,
                          decoration: BoxDecoration(
                            color: _blue,
                            borderRadius: BorderRadius.circular(4.0),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: List.generate(stages.length, (index) {
                      final threshold =
                          index == 0 ? 0.0 : index / (stages.length - 1);
                      final active =
                          _fundingStage >= 0 && progress + 0.001 >= threshold;
                      return Expanded(
                        child: Column(
                          children: [
                            Stack(
                              clipBehavior: Clip.none,
                              alignment: Alignment.center,
                              children: [
                                AnimatedContainer(
                                  duration: const Duration(milliseconds: 260),
                                  width: 24.0,
                                  height: 24.0,
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    color: active
                                        ? _blue
                                        : const Color(0xFFE8ECF3),
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: Colors.white,
                                      width: 2.0,
                                    ),
                                    boxShadow: active
                                        ? [
                                            BoxShadow(
                                              color: const Color(0xFFFF9F1C)
                                                  .withValues(alpha: 0.32),
                                              blurRadius: 10.0,
                                              spreadRadius: 1.0,
                                            )
                                          ]
                                        : null,
                                  ),
                                  child: Icon(
                                    active
                                        ? stages[index].icon
                                        : Icons.radio_button_unchecked_rounded,
                                    color: active
                                        ? Colors.white
                                        : theme.secondaryText,
                                    size: 14.0,
                                  ),
                                ),
                                if (active && index > 0)
                                  const Positioned(
                                    top: -9.0,
                                    child: Icon(
                                      Icons.local_fire_department_rounded,
                                      color: Color(0xFFFF9F1C),
                                      size: 12.0,
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 7.0),
                            Text(
                              stages[index].label,
                              textAlign: TextAlign.center,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.bodySmall.override(
                                font: TextStyle(
                                  fontWeight: active
                                      ? FontWeight.w700
                                      : FontWeight.normal,
                                  fontStyle: theme.bodySmall.fontStyle,
                                ),
                                color: active ? _blue : theme.secondaryText,
                                fontSize: 9.2,
                                letterSpacing: 0.0,
                                fontWeight: active
                                    ? FontWeight.w700
                                    : FontWeight.normal,
                                fontStyle: theme.bodySmall.fontStyle,
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _giftFundingNotice() {
    if (widget.purpose != 'create_gift') return const SizedBox.shrink();
    final theme = FlutterFlowTheme.of(context);
    final status = _backendStatus.isEmpty
        ? widget.paymentStatus.toLowerCase()
        : _backendStatus;
    final funded = status == 'confirmed' ||
        status == 'settling' ||
        status == 'settled' ||
        _fundingStage >= 3;
    final color = funded ? const Color(0xFF1E9D5A) : const Color(0xFFE08A1E);
    return Container(
      width: double.infinity,
      padding: const EdgeInsetsDirectional.fromSTEB(12.0, 10.0, 12.0, 10.0),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(14.0),
        border: Border.all(color: color.withValues(alpha: 0.18)),
      ),
      child: Row(
        children: [
          Icon(
            funded ? Icons.verified_rounded : Icons.hourglass_empty_rounded,
            color: color,
            size: 18.0,
          ),
          const SizedBox(width: 8.0),
          Expanded(
            child: Text(
              funded
                  ? '${widget.reference} funding detected.'
                  : '${widget.reference} is created but not funded yet.',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: theme.bodySmall.override(
                color: color,
                fontSize: 10.8,
                letterSpacing: 0.0,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _lockedFundingPill({
    required IconData icon,
    required String label,
    required String value,
  }) {
    final theme = FlutterFlowTheme.of(context);
    return Expanded(
      child: Container(
        height: 42.0,
        padding: const EdgeInsetsDirectional.fromSTEB(12.0, 0.0, 12.0, 0.0),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10.0),
          border: Border.all(color: _blue.withValues(alpha: 0.15)),
        ),
        child: Row(
          children: [
            Icon(icon, color: _blue, size: 18.0),
            const SizedBox(width: 8.0),
            Expanded(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.bodySmall.override(
                  font: TextStyle(
                    fontWeight: FontWeight.normal,
                    fontStyle: theme.bodySmall.fontStyle,
                  ),
                  color: theme.secondaryText,
                  fontSize: 10.0,
                  letterSpacing: 0.0,
                  fontWeight: FontWeight.normal,
                  fontStyle: theme.bodySmall.fontStyle,
                ),
              ),
            ),
            Text(
              value,
              style: GoogleFonts.inter(
                color: _blue,
                fontSize: 12.0,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    return Scaffold(
      key: scaffoldKey,
      backgroundColor: theme.primaryBackground,
      appBar: AppBar(
        backgroundColor: theme.primaryBackground,
        automaticallyImplyLeading: false,
        leading: FlutterFlowIconButton(
          borderColor: Colors.transparent,
          borderRadius: 30.0,
          borderWidth: 1.0,
          buttonSize: 54.0,
          icon: const Icon(
            Icons.arrow_back_rounded,
            color: _blue,
            size: 26.0,
          ),
          onPressed: context.safePop,
        ),
        title: Text(
          'Receive crypto',
          style: theme.titleSmall.override(
            font: TextStyle(
              fontWeight: FontWeight.w600,
              fontStyle: theme.titleSmall.fontStyle,
            ),
            color: _blue,
            letterSpacing: 0.0,
            fontWeight: FontWeight.w600,
            fontStyle: theme.titleSmall.fontStyle,
          ),
        ),
        elevation: 0.0,
      ),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsetsDirectional.fromSTEB(16.0, 16.0, 16.0, 24.0),
          children: [
            Container(
              width: double.infinity,
              padding:
                  const EdgeInsetsDirectional.fromSTEB(16.0, 16.0, 16.0, 16.0),
              decoration: BoxDecoration(
                color: theme.secondaryBackground,
                borderRadius: BorderRadius.circular(18.0),
                border: Border.all(color: _blue.withValues(alpha: 0.14)),
                boxShadow: const [
                  BoxShadow(
                    blurRadius: 12.0,
                    color: Color(0x12000000),
                    offset: Offset(0.0, 5.0),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Text(
                    'Fund this transaction',
                    style: theme.titleMedium.override(
                      font: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontStyle: theme.titleMedium.fontStyle,
                      ),
                      color: _blue,
                      letterSpacing: 0.0,
                      fontWeight: FontWeight.w700,
                      fontStyle: theme.titleMedium.fontStyle,
                    ),
                  ),
                  const SizedBox(height: 4.0),
                  Text(
                    'Send $_cryptoOnlyAmount to complete ₦${widget.settlementAmount}',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      color: theme.secondaryText,
                      fontSize: 12.0,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 14.0),
                  Container(
                    padding: const EdgeInsets.all(14.0),
                    decoration: BoxDecoration(
                      color: _blue.withValues(alpha: 0.07),
                      borderRadius: BorderRadius.circular(18.0),
                    ),
                    child: BarcodeWidget(
                      data: _address,
                      barcode: Barcode.qrCode(),
                      width: 190.0,
                      height: 190.0,
                      color: _blue,
                      backgroundColor: Colors.transparent,
                      drawText: false,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12.0),
            Row(
              children: [
                _lockedFundingPill(
                  icon: Icons.token_rounded,
                  label: 'Crypto',
                  value: _crypto,
                ),
                const SizedBox(width: 10.0),
                _lockedFundingPill(
                  icon: Icons.hub_rounded,
                  label: 'Network',
                  value: _network,
                ),
              ],
            ),
            const SizedBox(height: 12.0),
            Container(
              width: double.infinity,
              padding:
                  const EdgeInsetsDirectional.fromSTEB(14.0, 12.0, 10.0, 12.0),
              decoration: BoxDecoration(
                color: theme.secondaryBackground,
                borderRadius: BorderRadius.circular(14.0),
                border: Border.all(color: _blue.withValues(alpha: 0.12)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      _address,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        color: theme.primaryText,
                        fontSize: 12.0,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: _copyAddress,
                    icon: const Icon(Icons.copy_rounded),
                    color: _blue,
                    iconSize: 20.0,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10.0),
            Row(
              children: [
                _fundingStat(
                  icon: Icons.payments_rounded,
                  label: 'Amount',
                  value: '₦${widget.settlementAmount}',
                ),
                const SizedBox(width: 8.0),
                _fundingStat(
                  icon: Icons.token_rounded,
                  label: 'Crypto',
                  value: _crypto,
                ),
                const SizedBox(width: 8.0),
                _fundingStat(
                  icon: Icons.hub_rounded,
                  label: 'Network',
                  value: _network,
                ),
              ],
            ),
            if (widget.purpose == 'create_gift') ...[
              const SizedBox(height: 12.0),
              _giftFundingNotice(),
            ],
            const SizedBox(height: 16.0),
            _fundingProgress(),
            const SizedBox(height: 16.0),
            if (widget.purpose == 'create_gift')
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: TextButton.icon(
                  onPressed: _continueToConfirmed,
                  icon: const Icon(Icons.bookmark_added_rounded,
                      color: _blue, size: 17.0),
                  label: Text(
                    'Fund later',
                    style: FlutterFlowTheme.of(context).bodySmall.override(
                          color: _blue,
                          fontSize: 11.0,
                          letterSpacing: 0.0,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ),
              ),
            Align(
              alignment: AlignmentDirectional.centerEnd,
              child: StatusActionButton(
                text: _fundingStage >= 3 ? 'Continue' : 'Confirm',
                isLoading: _isConfirmingFunding && _fundingStage < 3,
                isDone: false,
                onPressed:
                    _fundingStage >= 3 ? _continueToConfirmed : _confirmFunding,
                backgroundColor: _blue,
                textColor: Colors.white,
                iconBackgroundColor: Colors.white,
                iconColor: _blue,
                height: 46.0,
                horizontalPadding: 14.0,
                trailingPadding: 4.0,
                iconBoxSize: 36.0,
                iconSize: 18.0,
                fontSize: 13.0,
                gap: 8.0,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FundingStageData {
  const _FundingStageData(this.label, this.icon);

  final String label;
  final IconData icon;
}
