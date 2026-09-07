import '/flutter_flow/flutter_flow_icon_button.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'transaction_details_model.dart';
export 'transaction_details_model.dart';

class TransactionDetailsWidget extends StatefulWidget {
  const TransactionDetailsWidget({
    super.key,
    this.id = '',
    this.createdAt = '',
    this.settlementAmount = '0.00',
    this.cryptoAmount = '0.00000 USDT',
    this.crypto = 'USDT',
    this.network = 'TRC20',
    this.beneficiaryName = 'Beneficiary',
    this.bankName = 'Bank',
    this.accountNumber = '',
    this.rate = '...',
    this.status = 'funding',
  });

  static String routeName = 'Transaction_details';
  static String routePath = 'transactionDetails';

  final String id;
  final String createdAt;
  final String settlementAmount;
  final String cryptoAmount;
  final String crypto;
  final String network;
  final String beneficiaryName;
  final String bankName;
  final String accountNumber;
  final String rate;
  final String status;

  @override
  State<TransactionDetailsWidget> createState() =>
      _TransactionDetailsWidgetState();
}

class _TransactionDetailsWidgetState extends State<TransactionDetailsWidget> {
  late TransactionDetailsModel _model;

  final scaffoldKey = GlobalKey<ScaffoldState>();
  static const _blue = Color(0xFF4472C4);

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => TransactionDetailsModel());
  }

  @override
  void dispose() {
    _model.dispose();
    super.dispose();
  }

  String get _dateLabel {
    final parsed = DateTime.tryParse(widget.createdAt);
    if (parsed == null) {
      return 'Today';
    }
    return DateFormat('MMM. d, yyyy; HH:mm:ss').format(parsed);
  }

  String get _lastAccountDigits {
    if (widget.accountNumber.length <= 4) {
      return widget.accountNumber;
    }
    return widget.accountNumber.substring(widget.accountNumber.length - 4);
  }

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

  Widget _detailRow(
    String label,
    String value, {
    bool numeric = false,
    Color? valueColor,
  }) {
    final theme = FlutterFlowTheme.of(context);
    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(0.0, 8.0, 0.0, 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              label,
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
          const SizedBox(width: 14.0),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              overflow: TextOverflow.ellipsis,
              maxLines: 2,
              style: numeric
                  ? GoogleFonts.inter(
                      color: valueColor ?? theme.primaryText,
                      fontSize: 11.8,
                      fontWeight: FontWeight.w600,
                    )
                  : theme.bodySmall.override(
                      font: TextStyle(
                        fontWeight: FontWeight.normal,
                        fontStyle: theme.bodySmall.fontStyle,
                      ),
                      color: valueColor ?? theme.primaryText,
                      fontSize: 11.8,
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

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    return Scaffold(
      key: scaffoldKey,
      backgroundColor: const Color(0xFFF4F6FA),
      appBar: AppBar(
        backgroundColor: _blue,
        automaticallyImplyLeading: false,
        leading: FlutterFlowIconButton(
          borderColor: Colors.transparent,
          borderRadius: 30.0,
          buttonSize: 54.0,
          icon: const Icon(
            Icons.arrow_back_rounded,
            color: Colors.white,
            size: 26.0,
          ),
          onPressed: context.safePop,
        ),
        title: Text(
          'Details',
          style: theme.headlineSmall.override(
            font: TextStyle(
              fontWeight: FontWeight.w600,
              fontStyle: theme.headlineSmall.fontStyle,
            ),
            color: Colors.white,
            fontSize: 20.0,
            letterSpacing: 0.0,
            fontWeight: FontWeight.w600,
            fontStyle: theme.headlineSmall.fontStyle,
          ),
        ),
        elevation: 0.0,
      ),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsetsDirectional.fromSTEB(18.0, 18.0, 18.0, 24.0),
          children: [
            Container(
              padding:
                  const EdgeInsetsDirectional.fromSTEB(18.0, 18.0, 18.0, 18.0),
              decoration: BoxDecoration(
                color: _blue,
                borderRadius: BorderRadius.circular(18.0),
                boxShadow: const [
                  BoxShadow(
                    blurRadius: 16.0,
                    color: Color(0x22000000),
                    offset: Offset(0.0, 8.0),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Image.asset(
                    'assets/images/white_short_logo.png',
                    width: 64.0,
                    height: 42.0,
                    fit: BoxFit.contain,
                  ),
                  const SizedBox(height: 16.0),
                  Text(
                    '₦${widget.settlementAmount}',
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontSize: 30.0,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 5.0),
                  Text(
                    '$_cryptoOnlyAmount via ${widget.crypto}',
                    style: GoogleFonts.inter(
                      color: Colors.white.withValues(alpha: 0.74),
                      fontSize: 12.4,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 18.0),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        widget.bankName,
                        style: theme.bodyMedium.override(
                          font: TextStyle(
                            fontWeight: FontWeight.normal,
                            fontStyle: theme.bodyMedium.fontStyle,
                          ),
                          color: Colors.white,
                          fontSize: 13.0,
                          letterSpacing: 0.0,
                          fontWeight: FontWeight.normal,
                          fontStyle: theme.bodyMedium.fontStyle,
                        ),
                      ),
                      Text(
                        '**** $_lastAccountDigits',
                        style: GoogleFonts.inter(
                          color: Colors.white.withValues(alpha: 0.82),
                          fontSize: 12.0,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16.0),
            Container(
              padding:
                  const EdgeInsetsDirectional.fromSTEB(16.0, 14.0, 16.0, 14.0),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16.0),
              ),
              child: Column(
                children: [
                  _detailRow('Reference', widget.id, numeric: true),
                  const Divider(height: 1.0),
                  _detailRow('Date', _dateLabel, numeric: true),
                  const Divider(height: 1.0),
                  _detailRow('Receiver', widget.beneficiaryName),
                  const Divider(height: 1.0),
                  _detailRow('Bank', widget.bankName),
                  const Divider(height: 1.0),
                  _detailRow('Account', widget.accountNumber, numeric: true),
                  const Divider(height: 1.0),
                  _detailRow('Crypto', widget.crypto),
                  const Divider(height: 1.0),
                  _detailRow('Network', widget.network, numeric: true),
                  const Divider(height: 1.0),
                  _detailRow('Rate', '${widget.rate}/\$', numeric: true),
                  const Divider(height: 1.0),
                  _detailRow('Status', widget.status, valueColor: _blue),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
