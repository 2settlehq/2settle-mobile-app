import '/components/top_notice.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/index.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

class GiftCreatedWidget extends StatefulWidget {
  const GiftCreatedWidget({
    super.key,
    this.amount = '0',
    this.crypto = 'USDT',
    this.network = 'TRC20',
    this.cryptoAmount = '0.00000 USDT',
    this.reference = '',
    this.paymentId = '',
    this.depositAddress = '',
    this.status = 'pending',
    this.expiresAt = '',
    this.chargeFiat = '',
    this.chargeCrypto = '',
    this.rate = '',
    this.transactionUsd = '',
  });

  static String routeName = 'GiftCreated';
  static String routePath = 'giftCreated';

  final String amount;
  final String crypto;
  final String network;
  final String cryptoAmount;
  final String reference;
  final String paymentId;
  final String depositAddress;
  final String status;
  final String expiresAt;
  final String chargeFiat;
  final String chargeCrypto;
  final String rate;
  final String transactionUsd;

  @override
  State<GiftCreatedWidget> createState() => _GiftCreatedWidgetState();
}

class _GiftCreatedWidgetState extends State<GiftCreatedWidget> {
  static const _blue = Color(0xFF4472C4);
  static const _giftHistoryStorageKey = '2settle_gift_history';
  static const _transactionStorageKey = '2settle_initiated_transactions';
  static const _nativeChannel = MethodChannel('com.sirfitech.settleio/share');
  String _giftCode = '';

  @override
  void initState() {
    super.initState();
    _createGift();
  }

  String _formatAmount(String value) {
    final parsed = double.tryParse(value.replaceAll(',', '').trim()) ?? 0;
    final fixed = parsed.toStringAsFixed(0);
    final buffer = StringBuffer();
    for (var index = 0; index < fixed.length; index++) {
      final remaining = fixed.length - index;
      buffer.write(fixed[index]);
      if (remaining > 1 && remaining % 3 == 1) buffer.write(',');
    }
    return '₦${buffer.toString()}';
  }

  String _makeCode() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final seed = DateTime.now().microsecondsSinceEpoch;
    return List.generate(6, (i) => chars[(seed + i * 11) % chars.length])
        .join();
  }

  Future<void> _createGift() async {
    final reference = widget.reference.trim().isNotEmpty
        ? widget.reference.trim()
        : '2S-${_makeCode()}';
    final now = DateTime.now().toIso8601String();
    final status = widget.status.trim().isEmpty
        ? 'pending'
        : widget.status.trim().toLowerCase();
    final giftItem = {
      'id': reference,
      'type': 'create_gift',
      'reference': reference,
      'amount': _formatAmount(widget.amount),
      'bankName': 'Pending claim',
      'accountNumber': '',
      'accountName': 'Gift recipient',
      'bankCode': '',
      'status': status,
      'createdAt': now,
      'crypto': widget.crypto,
      'network': widget.network,
      'cryptoAmount': widget.cryptoAmount,
      'paymentId': widget.paymentId,
      'depositAddress': widget.depositAddress,
      'expiresAt': widget.expiresAt,
      'chargeFiat': widget.chargeFiat,
      'chargeCrypto': widget.chargeCrypto,
      'rate': widget.rate,
      'transactionUsd': widget.transactionUsd,
    };
    final activityItem = {
      'id': reference,
      'type': 'create_gift',
      'reference': reference,
      'createdAt': now,
      'settlementAmount': widget.amount,
      'cryptoAmount': widget.cryptoAmount,
      'crypto': widget.crypto,
      'network': widget.network,
      'beneficiaryName': 'Created gift',
      'bankName': 'Gift',
      'accountNumber': '',
      'accountName': 'Gift recipient',
      'bankCode': '',
      'rate': widget.rate.isEmpty ? reference : widget.rate,
      'status': status,
      'paymentId': widget.paymentId,
      'depositAddress': widget.depositAddress,
      'expiresAt': widget.expiresAt,
      'chargeFiat': widget.chargeFiat,
      'chargeCrypto': widget.chargeCrypto,
      'transactionUsd': widget.transactionUsd,
    };
    final prefs = await SharedPreferences.getInstance();
    final storedGift = prefs.getString(_giftHistoryStorageKey);
    final gifts = storedGift == null || storedGift.isEmpty
        ? <dynamic>[]
        : (jsonDecode(storedGift) as List? ?? <dynamic>[]);
    gifts.insert(0, giftItem);
    await prefs.setString(
      _giftHistoryStorageKey,
      jsonEncode(gifts.take(30).toList()),
    );
    final storedActivity = prefs.getString(_transactionStorageKey);
    final activities = storedActivity == null || storedActivity.isEmpty
        ? <dynamic>[]
        : (jsonDecode(storedActivity) as List? ?? <dynamic>[]);
    activities.insert(0, activityItem);
    await prefs.setString(
      _transactionStorageKey,
      jsonEncode(activities.take(50).toList()),
    );
    if (!mounted) return;
    safeSetState(() => _giftCode = reference);
  }

  String get _shareText => '''
2Settle Gift Created
Gift ID: $_giftCode
Amount: ${_formatAmount(widget.amount)}
Funded with: ${widget.crypto}
Network: ${widget.network}
Status: ${_statusLabel.toUpperCase()}
''';

  String get _statusLabel {
    final status = widget.status.toLowerCase();
    if (status == 'confirmed') return 'Ready to claim';
    if (status == 'settled') return 'Claimed';
    if (status == 'settling') return 'Settling';
    return 'Not funded yet';
  }

  Color get _statusColor {
    final status = widget.status.toLowerCase();
    if (status == 'confirmed' || status == 'settled') {
      return const Color(0xFF1E9D5A);
    }
    if (status == 'settling') return _blue;
    return const Color(0xFFE08A1E);
  }

  Future<void> _shareGift() async {
    if (_giftCode.isEmpty) return;
    try {
      await _nativeChannel.invokeMethod('shareText', {
        'subject': '2Settle gift code',
        'text': _shareText,
      });
    } catch (_) {
      await Clipboard.setData(ClipboardData(text: _shareText));
      if (!mounted) return;
      showTopNotice(context, message: 'Gift details copied.');
    }
  }

  Widget _actionIcon({
    required IconData icon,
    required String label,
    required VoidCallback? onTap,
  }) {
    final theme = FlutterFlowTheme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: _blue.withValues(alpha: .1),
              shape: BoxShape.circle,
              border: Border.all(color: _blue.withValues(alpha: .18)),
            ),
            child: Icon(icon, color: _blue, size: 19),
          ),
          const SizedBox(height: 5),
          Text(
            label,
            style: theme.bodySmall.override(
              color: theme.secondaryText,
              fontSize: 10.6,
              letterSpacing: 0,
              fontWeight: FontWeight.w500,
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
      backgroundColor: const Color(0xFFF4F6FA),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(18, 28, 18, 28),
          child: Column(
            children: [
              const Spacer(),
              Container(
                width: double.infinity,
                padding: const EdgeInsetsDirectional.fromSTEB(18, 24, 18, 24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: _blue.withValues(alpha: .12)),
                  boxShadow: const [
                    BoxShadow(
                      blurRadius: 22,
                      color: Color(0x16000000),
                      offset: Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Container(
                      width: 66,
                      height: 66,
                      decoration: BoxDecoration(
                        color: _blue.withValues(alpha: .12),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.deblur_rounded,
                          color: _blue, size: 34),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      'Gift Created',
                      style: theme.titleMedium.override(
                        color: theme.primaryText,
                        fontSize: 20,
                        letterSpacing: 0,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _giftCode.isEmpty ? 'Creating...' : _giftCode,
                      style: GoogleFonts.inter(
                        color: _blue,
                        fontSize: 32,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      '${_formatAmount(widget.amount)} funded with ${widget.crypto} on ${widget.network}',
                      textAlign: TextAlign.center,
                      style: theme.bodySmall.override(
                        color: theme.secondaryText,
                        fontSize: 11.2,
                        letterSpacing: 0,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding:
                          const EdgeInsetsDirectional.fromSTEB(11, 7, 12, 7),
                      decoration: BoxDecoration(
                        color: _statusColor.withValues(alpha: .1),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                            color: _statusColor.withValues(alpha: .18)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            widget.status.toLowerCase() == 'pending'
                                ? Icons.hourglass_empty_rounded
                                : Icons.verified_rounded,
                            color: _statusColor,
                            size: 15,
                          ),
                          const SizedBox(width: 5),
                          Text(
                            _statusLabel,
                            style: theme.bodySmall.override(
                              color: _statusColor,
                              fontSize: 10.8,
                              letterSpacing: 0,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (widget.status.toLowerCase() == 'pending') ...[
                          _actionIcon(
                            icon: Icons.account_balance_wallet_rounded,
                            label: 'Fund',
                            onTap: _giftCode.isEmpty
                                ? null
                                : () => context.pushNamed(
                                      ReceiveFundingWidget.routeName,
                                      queryParameters: {
                                        'settlementAmount': widget.amount,
                                        'cryptoAmount': widget.cryptoAmount,
                                        'crypto': widget.crypto,
                                        'network': widget.network,
                                        'beneficiaryName': 'Created gift',
                                        'bankName': 'Gift',
                                        'accountNumber': '',
                                        'rate': widget.rate,
                                        'purpose': 'create_gift',
                                        'paymentId': widget.paymentId,
                                        'reference': _giftCode,
                                        'depositAddress': widget.depositAddress,
                                        'paymentStatus': widget.status,
                                        'expiresAt': widget.expiresAt,
                                        'chargeFiat': widget.chargeFiat,
                                        'chargeCrypto': widget.chargeCrypto,
                                        'transactionUsd': widget.transactionUsd,
                                      }.withoutNulls,
                                    ),
                          ),
                          const SizedBox(width: 20),
                        ],
                        _actionIcon(
                          icon: Icons.copy_rounded,
                          label: 'Copy',
                          onTap: _giftCode.isEmpty
                              ? null
                              : () {
                                  Clipboard.setData(
                                      ClipboardData(text: _giftCode));
                                  showTopNotice(context,
                                      message: 'Gift code copied.');
                                },
                        ),
                        const SizedBox(width: 20),
                        _actionIcon(
                          icon: Icons.ios_share_rounded,
                          label: 'Share',
                          onTap: _shareGift,
                        ),
                        const SizedBox(width: 20),
                        _actionIcon(
                          icon: Icons.home_rounded,
                          label: 'Home',
                          onTap: () =>
                              context.goNamed(DashboardWidget.routeName),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }
}
