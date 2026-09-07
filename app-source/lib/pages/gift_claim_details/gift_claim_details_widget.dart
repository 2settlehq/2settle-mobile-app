import 'dart:async';

import '/components/top_notice.dart';
import '/flutter_flow/flutter_flow_icon_button.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/index.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class GiftClaimDetailsWidget extends StatefulWidget {
  const GiftClaimDetailsWidget({
    super.key,
    required this.reference,
    required this.amount,
    required this.bankName,
    required this.accountNumber,
    required this.accountName,
    required this.bankCode,
    required this.status,
    required this.createdAt,
    required this.settlingStartedAt,
    required this.settledAt,
    required this.settlementDuration,
    this.type = '',
    this.crypto = 'USDT',
    this.network = 'TRC20',
    this.cryptoAmount = '',
    this.paymentId = '',
    this.depositAddress = '',
    this.expiresAt = '',
    this.chargeFiat = '',
    this.chargeCrypto = '',
    this.rate = '',
    this.transactionUsd = '',
  });

  static String routeName = 'GiftClaimDetails';
  static String routePath = 'giftClaimDetails';

  final String reference;
  final String amount;
  final String bankName;
  final String accountNumber;
  final String accountName;
  final String bankCode;
  final String status;
  final String createdAt;
  final String settlingStartedAt;
  final String settledAt;
  final String settlementDuration;
  final String type;
  final String crypto;
  final String network;
  final String cryptoAmount;
  final String paymentId;
  final String depositAddress;
  final String expiresAt;
  final String chargeFiat;
  final String chargeCrypto;
  final String rate;
  final String transactionUsd;

  @override
  State<GiftClaimDetailsWidget> createState() => _GiftClaimDetailsWidgetState();
}

class _GiftClaimDetailsWidgetState extends State<GiftClaimDetailsWidget> {
  static const _blue = Color(0xFF4472C4);
  static const _giftClaimBaseUrl = 'https://2settlemobile.vercel.app/api/gifts';
  static const _giftHistoryStorageKey = '2settle_gift_history';
  static const _transactionStorageKey = '2settle_initiated_transactions';
  static const _nativeChannel = MethodChannel('com.sirfitech.settleio/share');

  Timer? _pollTimer;
  Timer? _countdownTimer;
  late String _status;
  bool _notifiedSettled = false;
  bool _isCancelling = false;
  String _settlementDuration = '';
  String _countdownLabel = '';

  @override
  void initState() {
    super.initState();
    _status = widget.status.toLowerCase();
    _settlementDuration = widget.settlementDuration;
    if (_settlementDuration.isEmpty && _status == 'settled') {
      final start = DateTime.tryParse(widget.settlingStartedAt);
      final end = DateTime.tryParse(widget.settledAt);
      if (start != null && end != null) {
        _settlementDuration = _durationLabel(start, end);
      }
    }
    if (_status == 'pending' ||
        _status == 'settling' ||
        _status == 'confirmed') {
      _startPolling();
    }
    _updateCountdown();
    if (widget.expiresAt.trim().isNotEmpty) {
      _countdownTimer =
          Timer.periodic(const Duration(seconds: 1), (_) => _updateCountdown());
    }
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _countdownTimer?.cancel();
    super.dispose();
  }

  String get _cleanAmount =>
      widget.amount.replaceAll('₦', '').replaceAll(',', '').trim();

  String get _formattedAmount {
    final parsed = double.tryParse(_cleanAmount);
    if (parsed == null) return widget.amount;
    return '₦${NumberFormat('#,##0.##', 'en_US').format(parsed)}';
  }

  String get _maskedAccount {
    final value = widget.accountNumber;
    if (value.length <= 4) return value;
    return '******${value.substring(value.length - 4)}';
  }

  String get _displayCrypto {
    final crypto = widget.crypto.trim().toUpperCase();
    final network = widget.network.trim().toUpperCase();
    if (crypto.isEmpty || crypto == 'GIFT') {
      return ['USDT', 'BTC', 'ETH', 'BNB', 'TRX'].contains(network)
          ? network
          : 'USDT';
    }
    return crypto;
  }

  String get _displayNetwork {
    final network = widget.network.trim();
    if (network.isEmpty || network.toUpperCase() == 'GIFT') return 'TRC20';
    if (network.toUpperCase() == _displayCrypto) return 'TRC20';
    return network;
  }

  String get _dateTimeLabel {
    final created = DateTime.tryParse(widget.createdAt);
    if (created == null) return 'Not available';
    return DateFormat('MMM d, yyyy • h:mm a').format(created);
  }

  String get _expiryDateLabel {
    final expiry = DateTime.tryParse(widget.expiresAt);
    if (expiry == null) return widget.expiresAt;
    return DateFormat('d, MMM, yyyy').format(expiry).toLowerCase();
  }

  void _updateCountdown() {
    final expiry = DateTime.tryParse(widget.expiresAt);
    if (expiry == null) return;
    final remaining = expiry.difference(DateTime.now());
    final next = remaining.isNegative
        ? 'Expired'
        : '${remaining.inHours.toString().padLeft(2, '0')}:${(remaining.inMinutes % 60).toString().padLeft(2, '0')}:${(remaining.inSeconds % 60).toString().padLeft(2, '0')}';
    if (!mounted) {
      _countdownLabel = next;
      return;
    }
    if (_countdownLabel != next) safeSetState(() => _countdownLabel = next);
  }

  String get _receiptText => '''
${_isCreatedGift ? '2Settle Gift Created' : '2Settle Gift Claim'}
Gift ID: ${widget.reference}
Amount: $_formattedAmount
${_isCreatedGift ? 'Crypto: $_displayCrypto\nNetwork: $_displayNetwork${widget.depositAddress.isEmpty ? '' : '\nDeposit: ${widget.depositAddress}'}' : 'Receiver: ${widget.accountName}\nBank: ${widget.bankName}\nAccount: $_maskedAccount'}
Status: ${_status.toUpperCase()}
${_status == 'settled' && _settlementDuration.isNotEmpty ? 'Completed in: $_settlementDuration' : ''}
''';

  bool get _isCancelled => _status == 'cancelled' || _status == 'canceled';

  bool get _isCreatedGift =>
      widget.type.toLowerCase() == 'create_gift' ||
      widget.type.toLowerCase() == 'gift_create' ||
      widget.type.toLowerCase() == 'gift_created' ||
      widget.type.toLowerCase() == 'creategift' ||
      widget.bankName.toLowerCase() == 'gift' ||
      (widget.accountNumber.trim().isEmpty &&
          (widget.paymentId.trim().isNotEmpty ||
              widget.depositAddress.trim().isNotEmpty ||
              widget.cryptoAmount.trim().isNotEmpty));

  Future<void> _shareGiftClaim() async {
    try {
      await _nativeChannel.invokeMethod('shareText', {
        'subject': '2Settle gift claim',
        'text': _receiptText,
      });
    } catch (_) {
      await Clipboard.setData(ClipboardData(text: _receiptText));
      if (!mounted) return;
      showTopNotice(
        context,
        message: 'Gift claim details copied.',
        type: TopNoticeType.info,
      );
    }
  }

  Future<void> _cancelGift() async {
    if (_isCancelling || !_isCreatedGift || _status != 'pending') return;
    safeSetState(() => _isCancelling = true);
    try {
      final response = await http.post(
        Uri.parse(
          '$_giftClaimBaseUrl/${Uri.encodeComponent(widget.reference)}/cancel',
        ),
        headers: const {'accept': 'application/json'},
      ).timeout(const Duration(seconds: 12));
      final payload = response.body.isEmpty
          ? <String, dynamic>{}
          : jsonDecode(response.body) as Map<String, dynamic>;
      final ok = response.statusCode >= 200 &&
          response.statusCode < 300 &&
          payload['ok'] != false;
      if (!ok) {
        throw Exception(
          _payloadString(payload, const ['error', 'message']) ??
              'Gift could not be cancelled.',
        );
      }
      final status =
          (_payloadString(payload, const ['status', 'state']) ?? 'cancelled')
              .toLowerCase();
      await _saveHistories(status);
      _pollTimer?.cancel();
      if (!mounted) return;
      safeSetState(() {
        _status = status;
        _isCancelling = false;
      });
      showTopNotice(
        context,
        message: 'Gift cancelled.',
        type: TopNoticeType.info,
      );
    } catch (error) {
      if (!mounted) return;
      safeSetState(() => _isCancelling = false);
      showTopNotice(
        context,
        message: error.toString().replaceFirst('Exception: ', ''),
        type: TopNoticeType.caution,
      );
    }
  }

  String? _payloadString(Map<String, dynamic> payload, List<String> keys) {
    for (final key in keys) {
      final value = payload[key];
      if (value is String && value.trim().isNotEmpty) return value.trim();
      if (value is num) return value.toString();
      for (final container in ['data', 'gift', 'result', 'payment']) {
        final nested = payload[container];
        if (nested is Map) {
          final nestedValue = nested[key];
          if (nestedValue is String && nestedValue.trim().isNotEmpty) {
            return nestedValue.trim();
          }
          if (nestedValue is num) return nestedValue.toString();
        }
      }
    }
    return null;
  }

  String _durationLabel(DateTime start, DateTime end) {
    final seconds = end.difference(start).inSeconds.clamp(0, 86400);
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    if (minutes <= 0) return '${remainingSeconds}s';
    return '${minutes}m ${remainingSeconds}s';
  }

  Future<void> _saveHistories(String status) async {
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now();
    final nowIso = now.toIso8601String();
    final storedGift = prefs.getString(_giftHistoryStorageKey);
    final giftList = storedGift == null || storedGift.isEmpty
        ? <dynamic>[]
        : (jsonDecode(storedGift) as List? ?? <dynamic>[]);
    Map<String, dynamic>? existingGift;
    for (final item in giftList) {
      if (item is Map &&
          '${item['reference'] ?? item['id']}' == widget.reference) {
        existingGift = Map<String, dynamic>.from(item);
        break;
      }
    }
    final createdAt =
        '${existingGift?['createdAt'] ?? (widget.createdAt.isEmpty ? nowIso : widget.createdAt)}';
    final settlingStartedAt =
        '${existingGift?['settlingStartedAt'] ?? (status == 'settling' ? nowIso : createdAt)}';
    final settledAt = status == 'settled'
        ? '${existingGift?['settledAt'] ?? nowIso}'
        : '${existingGift?['settledAt'] ?? ''}';
    final start = DateTime.tryParse(settlingStartedAt) ?? now;
    final end = DateTime.tryParse(settledAt) ?? now;
    final durationLabel = status == 'settled' ? _durationLabel(start, end) : '';
    if (durationLabel.isNotEmpty) {
      _settlementDuration = durationLabel;
    }

    final giftItem = {
      'id': widget.reference,
      'type': _isCreatedGift ? 'create_gift' : 'gift_claim',
      'reference': widget.reference,
      'amount': widget.amount,
      'bankName': widget.bankName,
      'accountNumber': widget.accountNumber,
      'accountName': widget.accountName,
      'bankCode': widget.bankCode,
      'status': status,
      'createdAt': createdAt,
      'settlingStartedAt': settlingStartedAt,
      'settledAt': settledAt,
      'settlementDuration': durationLabel,
      'crypto': _displayCrypto,
      'network': _displayNetwork,
      'cryptoAmount': widget.cryptoAmount,
      'paymentId': widget.paymentId,
      'depositAddress': widget.depositAddress,
      'expiresAt': widget.expiresAt,
      'chargeFiat': widget.chargeFiat,
      'chargeCrypto': widget.chargeCrypto,
      'rate': widget.rate,
      'transactionUsd': widget.transactionUsd,
    };
    giftList.removeWhere((item) =>
        item is Map &&
        '${item['reference'] ?? item['id']}' == widget.reference);
    giftList.insert(0, giftItem);
    await prefs.setString(
      _giftHistoryStorageKey,
      jsonEncode(giftList.take(30).toList()),
    );

    final activityItem = {
      'id': widget.reference,
      'type': _isCreatedGift ? 'create_gift' : 'gift_claim',
      'reference': widget.reference,
      'createdAt': createdAt,
      'settlementAmount': _cleanAmount,
      'cryptoAmount': widget.cryptoAmount.isEmpty
          ? '0.00000 ${widget.crypto}'
          : widget.cryptoAmount,
      'crypto': widget.crypto,
      'network': widget.network,
      'beneficiaryName': widget.accountName,
      'bankName': widget.bankName,
      'accountNumber': widget.accountNumber,
      'accountName': widget.accountName,
      'bankCode': widget.bankCode,
      'rate': _isCreatedGift
          ? (widget.rate.isEmpty ? widget.reference : widget.rate)
          : 'Gift claim',
      'status': status,
      'settlingStartedAt': settlingStartedAt,
      'settledAt': settledAt,
      'settlementDuration': durationLabel,
      'paymentId': widget.paymentId,
      'depositAddress': widget.depositAddress,
      'expiresAt': widget.expiresAt,
      'chargeFiat': widget.chargeFiat,
      'chargeCrypto': widget.chargeCrypto,
      'transactionUsd': widget.transactionUsd,
    };
    final storedTransactions = prefs.getString(_transactionStorageKey);
    final activityList =
        storedTransactions == null || storedTransactions.isEmpty
            ? <dynamic>[]
            : (jsonDecode(storedTransactions) as List? ?? <dynamic>[]);
    activityList.removeWhere(
        (item) => item is Map && '${item['id'] ?? ''}' == widget.reference);
    activityList.insert(0, activityItem);
    await prefs.setString(
      _transactionStorageKey,
      jsonEncode(activityList.take(50).toList()),
    );
  }

  Future<void> _showSettledNotification() async {
    if (_notifiedSettled) return;
    _notifiedSettled = true;
    try {
      await _nativeChannel.invokeMethod('showRateNotification', {
        'title': 'Gift settlement complete',
        'body':
            '${widget.reference} has settled successfully.\n${widget.amount} is now paid to ${widget.bankName}.',
      });
    } catch (_) {}
  }

  void _startPolling() {
    _pollTimer?.cancel();
    _pollTimer =
        Timer.periodic(const Duration(seconds: 8), (_) => _checkStatus());
    _checkStatus();
  }

  Future<void> _checkStatus() async {
    try {
      final response = await http.get(
        Uri.parse(
          '$_giftClaimBaseUrl/${Uri.encodeComponent(widget.reference)}?ts=${DateTime.now().millisecondsSinceEpoch}',
        ),
        headers: const {'accept': 'application/json'},
      ).timeout(const Duration(seconds: 8));
      final payload = response.body.isEmpty
          ? <String, dynamic>{}
          : jsonDecode(response.body) as Map<String, dynamic>;
      final status =
          (_payloadString(payload, const ['status', 'state']) ?? _status)
              .toLowerCase();
      if (!mounted) return;
      if (status == 'settled') {
        _pollTimer?.cancel();
        await _saveHistories('settled');
        await _showSettledNotification();
        if (!mounted) return;
        safeSetState(() {
          _status = 'settled';
          _settlementDuration = _settlementDuration.isNotEmpty
              ? _settlementDuration
              : 'Completed';
        });
        return;
      }
      if (status == 'confirmed') {
        await _saveHistories('confirmed');
      }
      safeSetState(() => _status = status);
    } catch (_) {
      // Keep the current visual state; the next poll can recover.
    }
  }

  Widget _statusHero(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    final isSettled = _status == 'settled';
    final isCancelled = _isCancelled;
    if (_isCreatedGift) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsetsDirectional.fromSTEB(18.0, 20.0, 18.0, 18.0),
        decoration: BoxDecoration(
          color: _blue,
          borderRadius: BorderRadius.circular(22.0),
          boxShadow: [
            BoxShadow(
              blurRadius: 20.0,
              color: _blue.withValues(alpha: 0.2),
              offset: const Offset(0.0, 8.0),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              width: 62.0,
              height: 62.0,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.18),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.deblur_rounded,
                  color: Colors.white, size: 31.0),
            ),
            const SizedBox(height: 12.0),
            Text(
              isCancelled ? 'Gift cancelled' : 'Gift Created',
              style: theme.titleMedium.override(
                color: Colors.white,
                fontSize: 18.0,
                letterSpacing: 0.0,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8.0),
            Text(
              _formattedAmount,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                color: Colors.white,
                fontSize: 30.0,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      );
    }
    return Container(
      width: double.infinity,
      padding: const EdgeInsetsDirectional.fromSTEB(18.0, 18.0, 18.0, 18.0),
      decoration: BoxDecoration(
        color: _blue,
        borderRadius: BorderRadius.circular(22.0),
        boxShadow: [
          BoxShadow(
            blurRadius: 18.0,
            color: _blue.withValues(alpha: 0.2),
            offset: const Offset(0.0, 8.0),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 62.0,
            height: 62.0,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.18),
              shape: BoxShape.circle,
            ),
            child: isSettled
                ? const Icon(Icons.verified_rounded,
                    color: Colors.white, size: 32.0)
                : const Padding(
                    padding: EdgeInsets.all(17.0),
                    child: CircularProgressIndicator(
                      strokeWidth: 2.6,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  ),
          ),
          const SizedBox(height: 12.0),
          Text(
            isSettled ? 'Gift settled' : 'Gift settling',
            style: theme.titleMedium.override(
              color: Colors.white,
              fontSize: 18.0,
              letterSpacing: 0.0,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 5.0),
          Text(
            isSettled
                ? 'This claim has been paid successfully.'
                : 'We are checking settlement status automatically.',
            textAlign: TextAlign.center,
            style: theme.bodySmall.override(
              color: Colors.white.withValues(alpha: 0.82),
              fontSize: 11.2,
              letterSpacing: 0.0,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _statusPill() {
    final theme = FlutterFlowTheme.of(context);
    final isClaimed = _status == 'settled';
    final isReady = _status == 'confirmed' || _status == 'created';
    final isNotFunded = _status == 'pending';
    final color = isClaimed
        ? const Color(0xFF1E9D5A)
        : _isCancelled
            ? const Color(0xFFD64242)
            : isReady
                ? const Color(0xFF1E9D5A)
                : isNotFunded
                    ? const Color(0xFFE08A1E)
                    : _blue;
    final label = isClaimed
        ? 'Claimed'
        : _isCancelled
            ? 'Cancelled'
            : isReady
                ? 'Ready to claim'
                : isNotFunded
                    ? 'Not funded yet'
                    : _status;
    final icon = isClaimed
        ? Icons.verified_rounded
        : _isCancelled
            ? Icons.cancel_rounded
            : isReady
                ? Icons.check_circle_rounded
                : isNotFunded
                    ? Icons.hourglass_empty_rounded
                    : Icons.hourglass_top_rounded;
    return Align(
      alignment: AlignmentDirectional.center,
      child: Container(
        padding: const EdgeInsetsDirectional.fromSTEB(11.0, 7.0, 12.0, 7.0),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(18.0),
          border: Border.all(color: color.withValues(alpha: 0.18)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 15.0),
            const SizedBox(width: 5.0),
            Text(
              label,
              style: theme.bodySmall.override(
                color: color,
                fontSize: 10.8,
                letterSpacing: 0.0,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _detailRow(
    String label,
    String value, {
    bool interValue = false,
  }) {
    final theme = FlutterFlowTheme.of(context);
    return Padding(
      padding: const EdgeInsetsDirectional.symmetric(vertical: 8.0),
      child: Row(
        children: [
          SizedBox(
            width: 104.0,
            child: Text(
              label,
              style: theme.bodySmall.override(
                color: theme.secondaryText,
                fontSize: 10.8,
                letterSpacing: 0.0,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(width: 10.0),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.end,
              overflow: TextOverflow.ellipsis,
              style: interValue
                  ? GoogleFonts.inter(
                      color: theme.primaryText,
                      fontSize: 11.3,
                      fontWeight: FontWeight.w600,
                    )
                  : theme.bodySmall.override(
                      color: theme.primaryText,
                      fontSize: 11.3,
                      letterSpacing: 0.0,
                      fontWeight: FontWeight.w600,
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _centerInfoSection({
    required String label,
    required String value,
    bool copyable = false,
    bool amountStyle = false,
  }) {
    final theme = FlutterFlowTheme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsetsDirectional.fromSTEB(14.0, 12.0, 14.0, 12.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18.0),
        border: Border.all(color: const Color(0xFFE5EAF1)),
      ),
      child: Column(
        children: [
          Text(
            label,
            textAlign: TextAlign.center,
            style: theme.bodySmall.override(
              color: theme.secondaryText,
              fontSize: 10.8,
              letterSpacing: 0.0,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 7.0),
          Container(
            width: double.infinity,
            padding: const EdgeInsetsDirectional.fromSTEB(10.0, 8.0, 8.0, 8.0),
            decoration: BoxDecoration(
              color: _blue.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(13.0),
              border: Border.all(color: _blue.withValues(alpha: 0.12)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (copyable) const SizedBox(width: 26.0),
                Expanded(
                  child: Text(
                    value,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      color: amountStyle ? _blue : theme.primaryText,
                      fontSize: amountStyle ? 23.0 : 12.2,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                if (copyable) ...[
                  const SizedBox(width: 8.0),
                  InkWell(
                    onTap: () async {
                      await Clipboard.setData(ClipboardData(text: value));
                      if (!mounted) return;
                      showTopNotice(context, message: '$label copied.');
                    },
                    borderRadius: BorderRadius.circular(12.0),
                    child: Container(
                      width: 26.0,
                      height: 26.0,
                      decoration: BoxDecoration(
                        color: _blue.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.copy_rounded,
                          color: _blue, size: 14.0),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _previewActionIcon({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    Color? color,
    bool loading = false,
  }) {
    final theme = FlutterFlowTheme.of(context);
    final iconColor = color ?? _blue;
    return InkWell(
      onTap: loading ? null : onTap,
      borderRadius: BorderRadius.circular(18.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 38.0,
            height: 38.0,
            decoration: BoxDecoration(
              color: _blue.withValues(alpha: 0.1),
              shape: BoxShape.circle,
              border: Border.all(color: iconColor.withValues(alpha: 0.22)),
            ),
            child: loading
                ? Padding(
                    padding: const EdgeInsets.all(10.0),
                    child: CircularProgressIndicator(
                      strokeWidth: 2.0,
                      valueColor: AlwaysStoppedAnimation<Color>(iconColor),
                    ),
                  )
                : Icon(icon, color: iconColor, size: 18.0),
          ),
          const SizedBox(height: 5.0),
          Text(
            label,
            style: theme.bodySmall.override(
              color: theme.secondaryText,
              fontSize: 10.4,
              letterSpacing: 0.0,
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
                    onPressed: () => context.safePop(),
                  ),
                  Expanded(
                    child: Text(
                      _isCreatedGift ? 'Gift Created' : 'Gift Claim',
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
                  const EdgeInsetsDirectional.fromSTEB(18.0, 12.0, 18.0, 0.0),
              child: _statusHero(context),
            ),
            Padding(
              padding:
                  const EdgeInsetsDirectional.fromSTEB(18.0, 14.0, 18.0, 0.0),
              child: _isCreatedGift
                  ? _centerInfoSection(
                      label: 'Gift ID',
                      value: widget.reference,
                      copyable: true,
                    )
                  : _centerInfoSection(
                      label: 'Amount',
                      value: _formattedAmount,
                      amountStyle: true,
                    ),
            ),
            if (_isCreatedGift)
              Padding(
                padding:
                    const EdgeInsetsDirectional.fromSTEB(18.0, 10.0, 18.0, 0.0),
                child: _statusPill(),
              ),
            Padding(
              padding:
                  const EdgeInsetsDirectional.fromSTEB(18.0, 14.0, 18.0, 0.0),
              child: Container(
                padding: const EdgeInsetsDirectional.fromSTEB(
                    16.0, 14.0, 16.0, 14.0),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18.0),
                  border: Border.all(color: const Color(0xFFE5EAF1)),
                ),
                child: Column(
                  children: [
                    if (_isCreatedGift) ...[
                      _detailRow('Crypto', _displayCrypto),
                      _detailRow('Network', _displayNetwork, interValue: true),
                      if (widget.depositAddress.isNotEmpty)
                        _detailRow('Deposit', widget.depositAddress,
                            interValue: true),
                      if (widget.expiresAt.isNotEmpty)
                        _detailRow('Expires', _expiryDateLabel,
                            interValue: true),
                      if (_countdownLabel.isNotEmpty)
                        _detailRow('Countdown', _countdownLabel,
                            interValue: true),
                      _detailRow('Created', _dateTimeLabel, interValue: true),
                    ] else ...[
                      _detailRow('Gift ID', widget.reference, interValue: true),
                      _detailRow('Created', _dateTimeLabel, interValue: true),
                      _detailRow('Receiver', widget.accountName),
                      _detailRow('Bank', widget.bankName),
                      _detailRow('Account', _maskedAccount, interValue: true),
                    ],
                    if (!_isCreatedGift) _statusPill(),
                    if (_status == 'settled' && _settlementDuration.isNotEmpty)
                      _detailRow('Completed in', _settlementDuration,
                          interValue: true),
                  ],
                ),
              ),
            ),
            Padding(
              padding:
                  const EdgeInsetsDirectional.fromSTEB(18.0, 16.0, 18.0, 0.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (_isCreatedGift && _status == 'pending') ...[
                    _previewActionIcon(
                      icon: Icons.account_balance_wallet_rounded,
                      label: 'Fund',
                      onTap: () => context.pushNamed(
                        ReceiveFundingWidget.routeName,
                        queryParameters: {
                          'settlementAmount': _cleanAmount,
                          'cryptoAmount': widget.cryptoAmount.isEmpty
                              ? '0.00000 $_displayCrypto'
                              : widget.cryptoAmount,
                          'crypto': _displayCrypto,
                          'network': _displayNetwork,
                          'beneficiaryName': 'Created gift',
                          'bankName': 'Gift',
                          'accountNumber': '',
                          'rate': widget.rate,
                          'purpose': 'create_gift',
                          'paymentId': widget.paymentId,
                          'reference': widget.reference,
                          'depositAddress': widget.depositAddress,
                          'paymentStatus': _status,
                          'expiresAt': widget.expiresAt,
                          'chargeFiat': widget.chargeFiat,
                          'chargeCrypto': widget.chargeCrypto,
                          'transactionUsd': widget.transactionUsd,
                        }.withoutNulls,
                      ),
                    ),
                    const SizedBox(width: 24.0),
                    _previewActionIcon(
                      icon: Icons.cancel_rounded,
                      label: 'Cancel',
                      color: const Color(0xFFD64242),
                      loading: _isCancelling,
                      onTap: _cancelGift,
                    ),
                    const SizedBox(width: 24.0),
                  ],
                  _previewActionIcon(
                    icon: Icons.ios_share_rounded,
                    label: 'Share',
                    onTap: _shareGiftClaim,
                  ),
                  const SizedBox(width: 34.0),
                  _previewActionIcon(
                    icon: Icons.home_rounded,
                    label: 'Home',
                    onTap: () => context.goNamed(DashboardWidget.routeName),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
