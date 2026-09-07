import 'dart:io';
import 'dart:ui' as ui;

import '/components/status_action_button.dart';
import '/components/top_notice.dart';
import '/flutter_flow/flutter_flow_icon_button.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/index.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:path_provider/path_provider.dart';
import 'confirmation_page_model.dart';
export 'confirmation_page_model.dart';

class ConfirmationPageWidget extends StatefulWidget {
  const ConfirmationPageWidget({
    super.key,
    this.settlementAmount = '0.00',
    this.cryptoAmount = '0.00000 USDT',
    this.crypto = 'USDT',
    this.network = 'TRC20',
    this.beneficiaryName = 'Beneficiary',
    this.bankName = 'Bank',
    this.accountNumber = '',
    this.rate = '...',
  });

  static String routeName = 'Confirmation_page';
  static String routePath = 'confirmationPage';

  final String settlementAmount;
  final String cryptoAmount;
  final String crypto;
  final String network;
  final String beneficiaryName;
  final String bankName;
  final String accountNumber;
  final String rate;

  @override
  State<ConfirmationPageWidget> createState() => _ConfirmationPageWidgetState();
}

class _ConfirmationPageWidgetState extends State<ConfirmationPageWidget> {
  late ConfirmationPageModel _model;

  final scaffoldKey = GlobalKey<ScaffoldState>();
  final _receiptImageKey = GlobalKey();
  static const _blue = Color(0xFF4472C4);
  static const _shareChannel = MethodChannel('com.sirfitech.settleio/share');
  final String _receiptReference =
      '2ST-${DateTime.now().millisecondsSinceEpoch}';

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

  String get _receiptText {
    final issuedAt = DateFormat('MMM d, yyyy h:mma').format(DateTime.now());
    return '''
2Settle Transaction Receipt

Reference: $_receiptReference
Status: Confirmed
Issued: $issuedAt

Amount settled: ₦${widget.settlementAmount}
Crypto paid: $_cryptoOnlyAmount
Crypto: ${widget.crypto}
Network: ${widget.network}
Rate: ${widget.rate}/\$

Receiver: ${widget.beneficiaryName}
Bank: ${widget.bankName}
Account: ${widget.accountNumber}

Thank you for using 2Settle.
''';
  }

  void _showReceipt() {
    showDialog(
      context: context,
      builder: (dialogContext) {
        final theme = FlutterFlowTheme.of(dialogContext);
        final issued = DateTime.now();
        return Dialog(
          insetPadding: const EdgeInsets.fromLTRB(18.0, 18.0, 18.0, 18.0),
          backgroundColor: Colors.transparent,
          child: Container(
            padding:
                const EdgeInsetsDirectional.fromSTEB(16.0, 16.0, 16.0, 16.0),
            decoration: BoxDecoration(
              color: const Color(0xFFF7F7F7),
              borderRadius: BorderRadius.circular(22.0),
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 72.0,
                    height: 72.0,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: const Color(0xFF45C52A).withValues(alpha: 0.16),
                      shape: BoxShape.circle,
                    ),
                    child: Container(
                      width: 48.0,
                      height: 48.0,
                      alignment: Alignment.center,
                      decoration: const BoxDecoration(
                        color: Color(0xFF45C52A),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.check_rounded,
                        color: Colors.white,
                        size: 31.0,
                      ),
                    ),
                  ),
                  const SizedBox(height: 9.0),
                  Text(
                    'Payment Successful',
                    style: theme.titleMedium.override(
                      font: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontStyle: theme.titleMedium.fontStyle,
                      ),
                      color: theme.primaryText,
                      fontSize: 17.0,
                      letterSpacing: 0.0,
                      fontWeight: FontWeight.w700,
                      fontStyle: theme.titleMedium.fontStyle,
                    ),
                  ),
                  const SizedBox(height: 14.0),
                  _receiptDash(),
                  const SizedBox(height: 12.0),
                  _receiptSectionTitle(dialogContext, 'Payment Details'),
                  const SizedBox(height: 6.0),
                  _receiptLine('Invoice No.', _receiptReference),
                  _receiptLine(
                    'Payment Time',
                    '${DateFormat('h:mm a').format(issued)}    ${DateFormat('dd/MM/yyyy').format(issued)}',
                    numeric: true,
                  ),
                  _receiptLine('Payment Method', widget.crypto),
                  _receiptLine('Payment Status', 'Successful'),
                  _receiptLine(
                    'Amount',
                    '₦${widget.settlementAmount}',
                    numeric: true,
                  ),
                  const SizedBox(height: 10.0),
                  _receiptDash(),
                  const SizedBox(height: 12.0),
                  _receiptSectionTitle(dialogContext, 'Settlement Details'),
                  const SizedBox(height: 6.0),
                  _receiptLine('Receiver', widget.beneficiaryName),
                  _receiptLine('Bank', widget.bankName),
                  _receiptLine(
                    'Account',
                    widget.accountNumber,
                    numeric: true,
                  ),
                  _receiptLine(
                    'Crypto',
                    _cryptoOnlyAmount,
                    numeric: true,
                  ),
                  _receiptLine(
                    'Network',
                    widget.network,
                    numeric: true,
                  ),
                  const SizedBox(height: 10.0),
                  _receiptDash(),
                  const SizedBox(height: 12.0),
                  StatusActionButton(
                    text: 'Share Receipt',
                    isLoading: false,
                    isDone: false,
                    onPressed: _shareReceipt,
                    idleIcon: Icons.ios_share_rounded,
                    backgroundColor: Colors.white,
                    textColor: _blue,
                    iconBackgroundColor: _blue,
                    iconColor: Colors.white,
                    height: 42.0,
                    horizontalPadding: 16.0,
                    trailingPadding: 4.0,
                    iconBoxSize: 32.0,
                    iconSize: 18.0,
                    fontSize: 12.0,
                    gap: 7.0,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _receiptDash() {
    return Row(
      children: List.generate(
        34,
        (index) => Expanded(
          child: Container(
            height: 1.0,
            margin: const EdgeInsets.symmetric(horizontal: 2.0),
            color: const Color(0xFFB8B8B8),
          ),
        ),
      ),
    );
  }

  Widget _receiptSectionTitle(BuildContext context, String title) {
    final theme = FlutterFlowTheme.of(context);
    return Text(
      title,
      style: theme.titleSmall.override(
        font: TextStyle(
          fontWeight: FontWeight.w700,
          fontStyle: theme.titleSmall.fontStyle,
        ),
        color: theme.primaryText,
        fontSize: 15.5,
        letterSpacing: 0.0,
        fontWeight: FontWeight.w700,
        fontStyle: theme.titleSmall.fontStyle,
      ),
    );
  }

  Widget _receiptLine(
    String label,
    String value, {
    bool numeric = false,
  }) {
    final theme = FlutterFlowTheme.of(context);
    final valueStyle = numeric
        ? GoogleFonts.inter(
            color: theme.primaryText,
            fontSize: 13.0,
            fontWeight: FontWeight.w600,
          )
        : theme.bodyMedium.override(
            font: TextStyle(
              fontWeight: FontWeight.normal,
              fontStyle: theme.bodyMedium.fontStyle,
            ),
            color: theme.primaryText,
            fontSize: 13.0,
            letterSpacing: 0.0,
            fontWeight: FontWeight.normal,
            fontStyle: theme.bodyMedium.fontStyle,
          );
    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(0.0, 4.5, 0.0, 4.5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 5,
            child: Text(
              label,
              style: theme.bodyMedium.override(
                font: TextStyle(
                  fontWeight: FontWeight.normal,
                  fontStyle: theme.bodyMedium.fontStyle,
                ),
                color: theme.secondaryText,
                fontSize: 13.0,
                letterSpacing: 0.0,
                fontWeight: FontWeight.normal,
                fontStyle: theme.bodyMedium.fontStyle,
              ),
            ),
          ),
          Text(
            ':',
            style: GoogleFonts.inter(
              color: theme.primaryText,
              fontSize: 13.0,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 18.0),
          Expanded(
            flex: 7,
            child: Text(
              value,
              style: valueStyle,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _shareReceipt() async {
    final sharedImage = await _shareReceiptImage();
    if (sharedImage) return;
    try {
      await _shareChannel.invokeMethod('shareText', {
        'subject': '2Settle transaction receipt',
        'text': _receiptText,
      });
    } catch (_) {
      await Clipboard.setData(ClipboardData(text: _receiptText));
      if (!mounted) return;
      showTopNotice(
        context,
        message: 'Receipt copied. Share is unavailable on this device.',
        type: TopNoticeType.info,
      );
    }
  }

  Future<bool> _shareReceiptImage() async {
    try {
      await Future<void>.delayed(const Duration(milliseconds: 80));
      final boundary = _receiptImageKey.currentContext?.findRenderObject()
          as RenderRepaintBoundary?;
      if (boundary == null) return false;
      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      final bytes = byteData?.buffer.asUint8List();
      if (bytes == null) return false;
      final directory = await getTemporaryDirectory();
      final file =
          File('${directory.path}/2settle_receipt_$_receiptReference.png');
      await file.writeAsBytes(bytes, flush: true);
      await _shareChannel.invokeMethod('shareFile', {
        'subject': '2Settle transaction receipt',
        'path': file.path,
        'mimeType': 'image/png',
      });
      return true;
    } catch (_) {
      return false;
    }
  }

  Widget _confirmedDetail(String label, String value) {
    final theme = FlutterFlowTheme.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: theme.bodySmall.override(
            font: TextStyle(
              fontWeight: FontWeight.normal,
              fontStyle: theme.bodySmall.fontStyle,
            ),
            color: theme.secondaryText,
            fontSize: 11.0,
            letterSpacing: 0.0,
            fontWeight: FontWeight.normal,
            fontStyle: theme.bodySmall.fontStyle,
          ),
        ),
        Text(
          value,
          style: GoogleFonts.inter(
            color: theme.primaryText,
            fontSize: 11.5,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }

  Widget _labeledAction({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    Color? color,
  }) {
    final theme = FlutterFlowTheme.of(context);
    final actionColor = color ?? _blue;
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16.0),
        child: Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(4.0, 6.0, 4.0, 6.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 44.0,
                height: 44.0,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: actionColor.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: actionColor, size: 22.0),
              ),
              const SizedBox(height: 6.0),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.bodySmall.override(
                  font: TextStyle(
                    fontWeight: FontWeight.normal,
                    fontStyle: theme.bodySmall.fontStyle,
                  ),
                  color: theme.primaryText,
                  fontSize: 10.6,
                  letterSpacing: 0.0,
                  fontWeight: FontWeight.normal,
                  fontStyle: theme.bodySmall.fontStyle,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => ConfirmationPageModel());
  }

  @override
  void dispose() {
    _model.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: scaffoldKey,
      backgroundColor: FlutterFlowTheme.of(context).secondaryBackground,
      body: RepaintBoundary(
        key: _receiptImageKey,
        child: SafeArea(
          top: true,
          child: Column(
            mainAxisSize: MainAxisSize.max,
            children: [
              Padding(
                padding: EdgeInsetsDirectional.fromSTEB(20.0, 24.0, 20.0, 0.0),
                child: Row(
                  mainAxisSize: MainAxisSize.max,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    FlutterFlowIconButton(
                      borderColor: Colors.transparent,
                      borderRadius: 30.0,
                      buttonSize: 46.0,
                      fillColor: FlutterFlowTheme.of(context).primaryBackground,
                      icon: Icon(
                        Icons.close_rounded,
                        color: Color(0xFFC30000),
                        size: 25.0,
                      ),
                      onPressed: () async {
                        context.pushNamed(DashboardWidget.routeName);
                      },
                    ),
                  ],
                ),
              ),
              Padding(
                padding: EdgeInsetsDirectional.fromSTEB(0.0, 24.0, 0.0, 0.0),
                child: TweenAnimationBuilder<double>(
                  tween: Tween<double>(begin: 0.72, end: 1.0),
                  duration: const Duration(milliseconds: 680),
                  curve: Curves.elasticOut,
                  builder: (context, scale, child) {
                    return Transform.scale(
                      scale: scale,
                      child: Container(
                        width: 120.0,
                        height: 120.0,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: _blue.withValues(alpha: 0.14),
                          shape: BoxShape.circle,
                        ),
                        child: Card(
                          clipBehavior: Clip.antiAliasWithSaveLayer,
                          color: _blue,
                          elevation: 3.0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(70.0),
                          ),
                          child: const Padding(
                            padding: EdgeInsets.all(24.0),
                            child: Icon(
                              Icons.check_rounded,
                              color: Colors.white,
                              size: 60.0,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                  child: const SizedBox.shrink(),
                ),
              ),
              Padding(
                padding: EdgeInsetsDirectional.fromSTEB(0.0, 24.0, 0.0, 0.0),
                child: Text(
                  'Payment Confirmed!',
                  style: FlutterFlowTheme.of(context).displaySmall.override(
                        font: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontStyle: FlutterFlowTheme.of(context)
                              .displaySmall
                              .fontStyle,
                        ),
                        color: _blue,
                        fontSize: 24.0,
                        letterSpacing: 0.0,
                        fontWeight: FontWeight.bold,
                        fontStyle:
                            FlutterFlowTheme.of(context).displaySmall.fontStyle,
                      ),
                ),
              ),
              Padding(
                padding: EdgeInsetsDirectional.fromSTEB(0.0, 24.0, 0.0, 0.0),
                child: Text(
                  '₦${widget.settlementAmount}',
                  style: GoogleFonts.overpass(
                    color: FlutterFlowTheme.of(context).primaryText,
                    fontWeight: FontWeight.w300,
                    fontSize: 30.0,
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsetsDirectional.fromSTEB(24.0, 8.0, 24.0, 0.0),
                child: Text(
                  'Your payment has been confirmed. Settlement is now processing and may take up to 15 minutes.',
                  textAlign: TextAlign.center,
                  style: FlutterFlowTheme.of(context).bodySmall.override(
                        font: TextStyle(
                          fontWeight: FontWeight.w500,
                          fontStyle:
                              FlutterFlowTheme.of(context).bodySmall.fontStyle,
                        ),
                        letterSpacing: 0.0,
                        fontWeight: FontWeight.w500,
                        fontStyle:
                            FlutterFlowTheme.of(context).bodySmall.fontStyle,
                      ),
                ),
              ),
              Padding(
                padding: EdgeInsetsDirectional.fromSTEB(0.0, 20.0, 0.0, 0.0),
                child: Container(
                  width: 300.0,
                  height: 70.0,
                  decoration: BoxDecoration(
                    color: FlutterFlowTheme.of(context).primaryBackground,
                    borderRadius: BorderRadius.circular(8.0),
                    border: Border.all(
                      color: FlutterFlowTheme.of(context).primaryBackground,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.max,
                    children: [
                      Padding(
                        padding:
                            EdgeInsetsDirectional.fromSTEB(20.0, 0.0, 0.0, 0.0),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(10.0),
                          child: Image.asset(
                            'assets/images/a_avatar.png',
                            width: 40.0,
                            height: 40.0,
                            fit: BoxFit.fitWidth,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Padding(
                          padding: EdgeInsetsDirectional.fromSTEB(
                              16.0, 0.0, 12.0, 0.0),
                          child: Column(
                            mainAxisSize: MainAxisSize.max,
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding: EdgeInsetsDirectional.fromSTEB(
                                    0.0, 0.0, 0.0, 4.0),
                                child: Text(
                                  '${widget.bankName} • ${widget.accountNumber}',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
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
                                        color: Color(0xFF8B97A2),
                                        fontSize: 14.0,
                                        letterSpacing: 0.0,
                                        fontWeight: FontWeight.normal,
                                        fontStyle: FlutterFlowTheme.of(context)
                                            .bodySmall
                                            .fontStyle,
                                      ),
                                ),
                              ),
                              Padding(
                                padding: EdgeInsetsDirectional.fromSTEB(
                                    0.0, 0.0, 0.0, 4.0),
                                child: Text(
                                  widget.beneficiaryName,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: FlutterFlowTheme.of(context)
                                      .titleSmall
                                      .override(
                                        font: TextStyle(
                                          fontWeight:
                                              FlutterFlowTheme.of(context)
                                                  .titleSmall
                                                  .fontWeight,
                                          fontStyle:
                                              FlutterFlowTheme.of(context)
                                                  .titleSmall
                                                  .fontStyle,
                                        ),
                                        color: _blue,
                                        letterSpacing: 0.0,
                                        fontWeight: FlutterFlowTheme.of(context)
                                            .titleSmall
                                            .fontWeight,
                                        fontStyle: FlutterFlowTheme.of(context)
                                            .titleSmall
                                            .fontStyle,
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
              ),
              Padding(
                padding:
                    const EdgeInsetsDirectional.fromSTEB(24.0, 10.0, 24.0, 0.0),
                child: Container(
                  width: 300.0,
                  padding: const EdgeInsetsDirectional.fromSTEB(
                      14.0, 10.0, 14.0, 10.0),
                  decoration: BoxDecoration(
                    color: _blue.withValues(alpha: 0.07),
                    borderRadius: BorderRadius.circular(10.0),
                  ),
                  child: Column(
                    children: [
                      _confirmedDetail('Crypto paid', _cryptoOnlyAmount),
                      const SizedBox(height: 6.0),
                      _confirmedDetail('Network', widget.network),
                      const SizedBox(height: 6.0),
                      _confirmedDetail('Rate', '${widget.rate}/\$'),
                    ],
                  ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: EdgeInsetsDirectional.fromSTEB(0.0, 0.0, 0.0, 32.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.max,
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Padding(
                        padding: const EdgeInsetsDirectional.fromSTEB(
                            28.0, 0.0, 28.0, 0.0),
                        child: Row(
                          children: [
                            _labeledAction(
                              icon: Icons.receipt_long_rounded,
                              label: 'Receipt',
                              onTap: _showReceipt,
                            ),
                            _labeledAction(
                              icon: Icons.ios_share_rounded,
                              label: 'Share',
                              onTap: _shareReceipt,
                            ),
                            _labeledAction(
                              icon: Icons.home_rounded,
                              label: 'Home',
                              onTap: () {
                                context.pushNamed(DashboardWidget.routeName);
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
