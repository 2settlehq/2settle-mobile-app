import 'dart:async';

import '/components/status_action_button.dart';
import '/components/top_notice.dart';
import '/config/api_config.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/index.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ConfirmGiftClaimWidget extends StatefulWidget {
  const ConfirmGiftClaimWidget({
    super.key,
    required this.reference,
    required this.amount,
    required this.bankName,
    required this.accountNumber,
    required this.accountName,
    required this.bankCode,
  });

  static String routeName = 'ConfirmGiftClaim';
  static String routePath = 'confirmGiftClaim';

  final String reference;
  final String amount;
  final String bankName;
  final String accountNumber;
  final String accountName;
  final String bankCode;

  @override
  State<ConfirmGiftClaimWidget> createState() => _ConfirmGiftClaimWidgetState();
}

class _ConfirmGiftClaimWidgetState extends State<ConfirmGiftClaimWidget> {
  static const _blue = Color(0xFF4472C4);
  static const _giftClaimBaseUrl = ApiConfig.giftsBaseUrl;
  static const _giftHistoryStorageKey = '2settle_gift_history';
  static const _transactionStorageKey = '2settle_initiated_transactions';
  static const _nativeChannel = MethodChannel('com.sirfitech.settleio/share');

  Timer? _pollTimer;
  bool _isClaiming = false;
  String _status = 'ready';
  String _message = 'Review the details before claiming this gift.';

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  String get _cleanAmount =>
      widget.amount.replaceAll('₦', '').replaceAll(',', '').trim();

  String get _displayAmount {
    final parsed = double.tryParse(_cleanAmount);
    if (parsed == null) return widget.amount;
    final fixed = parsed == parsed.truncateToDouble()
        ? parsed.toStringAsFixed(0)
        : parsed.toStringAsFixed(2);
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
    final value = parts.length > 1
        ? '${buffer.toString()}.${parts.last}'
        : buffer.toString();
    return '₦$value';
  }

  String get _maskedAccount {
    final value = widget.accountNumber;
    if (value.length <= 4) return value;
    return '******${value.substring(value.length - 4)}';
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
    final createdAt = '${existingGift?['createdAt'] ?? nowIso}';
    final settlingStartedAt =
        '${existingGift?['settlingStartedAt'] ?? (status == 'settling' ? nowIso : createdAt)}';
    final settledAt = status == 'settled'
        ? '${existingGift?['settledAt'] ?? nowIso}'
        : '${existingGift?['settledAt'] ?? ''}';
    final start = DateTime.tryParse(settlingStartedAt) ?? now;
    final end = DateTime.tryParse(settledAt) ?? now;
    final durationLabel = status == 'settled' ? _durationLabel(start, end) : '';

    final giftItem = {
      'id': widget.reference,
      'type': 'gift_claim',
      'reference': widget.reference,
      'amount': _displayAmount,
      'bankName': widget.bankName,
      'accountNumber': widget.accountNumber,
      'accountName': widget.accountName,
      'bankCode': widget.bankCode,
      'status': status,
      'createdAt': createdAt,
      'settlingStartedAt': settlingStartedAt,
      'settledAt': settledAt,
      'settlementDuration': durationLabel,
    };
    giftList.removeWhere((item) =>
        item is Map &&
        '${item['reference'] ?? item['id']}' == widget.reference);
    giftList.insert(0, giftItem);
    await prefs.setString(
        _giftHistoryStorageKey, jsonEncode(giftList.take(30).toList()));

    final activityItem = {
      'id': widget.reference,
      'type': 'gift_claim',
      'reference': widget.reference,
      'createdAt': createdAt,
      'settlementAmount': _cleanAmount,
      'cryptoAmount': '0.00000 GIFT',
      'crypto': 'GIFT',
      'network': '2SETTLE',
      'beneficiaryName': widget.accountName,
      'bankName': widget.bankName,
      'accountNumber': widget.accountNumber,
      'accountName': widget.accountName,
      'bankCode': widget.bankCode,
      'rate': 'Gift claim',
      'status': status,
      'settlingStartedAt': settlingStartedAt,
      'settledAt': settledAt,
      'settlementDuration': durationLabel,
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
    try {
      await _nativeChannel.invokeMethod('showRateNotification', {
        'title': 'Gift settlement complete',
        'body':
            '${widget.reference} has settled successfully.\n${_displayAmount} is now paid to ${widget.bankName}.',
      });
    } catch (_) {
      // Phone notifications are Android-native; ignore if unavailable.
    }
  }

  Future<void> _claimGift() async {
    safeSetState(() {
      _isClaiming = true;
      _status = 'claiming';
      _message = 'Submitting claim and starting settlement...';
    });
    try {
      final response = await http
          .post(
            Uri.parse(
              '$_giftClaimBaseUrl/${Uri.encodeComponent(widget.reference)}/claim/confirm',
            ),
            headers: const {
              'accept': 'application/json',
              'content-type': 'application/json',
            },
            body: jsonEncode({
              'receiver': {
                'bankCode': widget.bankCode,
                'accountNumber': widget.accountNumber,
              },
            }),
          )
          .timeout(const Duration(seconds: 12));
      final payload = response.body.isEmpty
          ? <String, dynamic>{}
          : jsonDecode(response.body) as Map<String, dynamic>;
      final ok = response.statusCode >= 200 &&
          response.statusCode < 300 &&
          payload['ok'] != false;
      if (!mounted) return;
      if (!ok) {
        safeSetState(() {
          _isClaiming = false;
          _status = 'failed';
          _message = _payloadString(payload, const ['error', 'message']) ??
              'Gift claim could not be confirmed.';
        });
        showTopNotice(context, message: _message, type: TopNoticeType.caution);
        return;
      }
      await _saveHistories('settling');
      if (!mounted) return;
      safeSetState(() {
        _isClaiming = false;
        _status = 'settling';
        _message = 'Claim successful. Settlement is in progress.';
      });
      showTopNotice(
        context,
        message: 'Gift claim successful.',
        type: TopNoticeType.info,
      );
      _startPolling();
    } catch (_) {
      if (!mounted) return;
      safeSetState(() {
        _isClaiming = false;
        _status = 'failed';
        _message = 'Gift claim API needs secure server access.';
      });
      showTopNotice(context, message: _message, type: TopNoticeType.caution);
    }
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
          _message = 'Gift settled successfully.';
        });
        return;
      }
      safeSetState(() {
        _status = status == 'confirmed' ? 'settling' : status;
        _message = 'Settlement is in progress.';
      });
    } catch (_) {
      // Keep the visible settling state; the next poll can recover.
    }
  }

  Widget _detailRow(
    String label,
    String value, {
    bool interValue = false,
  }) {
    final theme = FlutterFlowTheme.of(context);
    return Padding(
      padding: const EdgeInsetsDirectional.symmetric(vertical: 7.0),
      child: Row(
        children: [
          SizedBox(
            width: 104.0,
            child: Text(
              label,
              style: theme.bodySmall.override(
                color: theme.secondaryText,
                fontSize: 10.7,
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
                      fontSize: 11.2,
                      fontWeight: FontWeight.w700,
                    )
                  : theme.bodySmall.override(
                      color: theme.primaryText,
                      fontSize: 11.2,
                      letterSpacing: 0.0,
                      fontWeight: FontWeight.w700,
                    ),
            ),
          ),
        ],
      ),
    );
  }

  bool get _isProgressStatus =>
      _status == 'claiming' || _status == 'settling' || _status == 'confirmed';

  bool get _isSuccessStatus => _status == 'settled';

  Color get _statusAccent {
    if (_isSuccessStatus) return const Color(0xFF22C55E);
    if (_isProgressStatus || _status == 'ready') return _blue;
    return const Color(0xFFB42318);
  }

  Color get _statusBackground {
    if (_isSuccessStatus) return const Color(0xFFEAF8EF);
    if (_isProgressStatus || _status == 'ready') {
      return _blue.withValues(alpha: 0.1);
    }
    return const Color(0xFFFFF4F2);
  }

  Color get _statusBorder {
    if (_isSuccessStatus) return const Color(0xFFBDECCB);
    if (_isProgressStatus || _status == 'ready') {
      return _blue.withValues(alpha: 0.24);
    }
    return const Color(0xFFFECACA);
  }

  IconData get _statusIcon {
    if (_isSuccessStatus) return Icons.check_circle_outline_rounded;
    if (_isProgressStatus) return Icons.autorenew_rounded;
    if (_status == 'ready') return Icons.info_outline_rounded;
    return Icons.warning_amber_rounded;
  }

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    final canClaim =
        !_isClaiming && (_status == 'ready' || _status == 'failed');
    return Scaffold(
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
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Flexible(
                          child: Text(
                            'Confirm Gift Claim',
                            textAlign: TextAlign.center,
                            style: theme.titleMedium.override(
                              color: theme.primaryText,
                              fontSize: 18.0,
                              letterSpacing: 0.0,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8.0),
                    Text(
                      'Please review all details carefully.',
                      textAlign: TextAlign.center,
                      style: theme.bodySmall.override(
                        color: theme.secondaryText,
                        fontSize: 11.6,
                        letterSpacing: 0.0,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 7.0),
                    Container(
                      padding: const EdgeInsetsDirectional.fromSTEB(
                          10.0, 7.0, 10.0, 7.0),
                      decoration: BoxDecoration(
                        color: _statusBackground,
                        borderRadius: BorderRadius.circular(12.0),
                        border: Border.all(color: _statusBorder),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (_isProgressStatus)
                            SizedBox(
                              width: 16.0,
                              height: 16.0,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.0,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                    _statusAccent),
                              ),
                            )
                          else
                            Icon(
                              _statusIcon,
                              color: _statusAccent,
                              size: 16.0,
                            ),
                          const SizedBox(width: 6.0),
                          Flexible(
                            child: Text(
                              _status.toUpperCase(),
                              style: theme.bodySmall.override(
                                color: _statusAccent,
                                fontSize: 10.8,
                                letterSpacing: 0.0,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12.0),
                    Text(
                      _displayAmount,
                      style: GoogleFonts.inter(
                        color: _blue,
                        fontSize: 40.0,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.0,
                      ),
                    ),
                    Text(
                      'Gift claim',
                      style: theme.bodySmall.override(
                        color: theme.secondaryText,
                        fontSize: 12.0,
                        letterSpacing: 0.0,
                        fontWeight: FontWeight.w600,
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
                            'Claim review',
                            style: theme.bodySmall.override(
                              color: _blue,
                              fontSize: 12.0,
                              letterSpacing: 0.0,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 4.0),
                          _detailRow('Gift ID', widget.reference,
                              interValue: true),
                          const Divider(
                              height: 1.0,
                              thickness: 0.7,
                              color: Color(0xFFE5E8EF)),
                          _detailRow('Receiver', widget.accountName),
                          const Divider(
                              height: 1.0,
                              thickness: 0.7,
                              color: Color(0xFFE5E8EF)),
                          _detailRow('Bank', widget.bankName),
                          const Divider(
                              height: 1.0,
                              thickness: 0.7,
                              color: Color(0xFFE5E8EF)),
                          _detailRow('Account', _maskedAccount,
                              interValue: true),
                          const Divider(
                              height: 1.0,
                              thickness: 0.7,
                              color: Color(0xFFE5E8EF)),
                          _detailRow('Status', _status.toUpperCase()),
                        ],
                      ),
                    ),
                    if (_status == 'settling') ...[
                      const SizedBox(height: 10.0),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsetsDirectional.fromSTEB(
                            11.0, 9.0, 11.0, 9.0),
                        decoration: BoxDecoration(
                          color: _blue.withValues(alpha: 0.09),
                          borderRadius: BorderRadius.circular(13.0),
                          border:
                              Border.all(color: _blue.withValues(alpha: 0.16)),
                        ),
                        child: Row(
                          children: [
                            const SizedBox(
                              width: 16.0,
                              height: 16.0,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.0,
                                valueColor:
                                    AlwaysStoppedAnimation<Color>(_blue),
                              ),
                            ),
                            const SizedBox(width: 8.0),
                            Expanded(
                              child: Text(
                                'Gift has been claimed. Settlement is in progress. You will be notified when it is settled.',
                                style: theme.bodySmall.override(
                                  color: theme.primaryText,
                                  fontSize: 10.6,
                                  letterSpacing: 0.0,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 14.0),
                    if (_status == 'ready' ||
                        _status == 'claiming' ||
                        _status == 'failed')
                      StatusActionButton(
                        text: _isClaiming ? 'Claiming' : 'Claim',
                        isLoading: _isClaiming,
                        isDone: false,
                        onPressed: canClaim ? _claimGift : () {},
                        idleIcon: Icons.check_rounded,
                        height: 48.0,
                        horizontalPadding: 18.0,
                        trailingPadding: 5.0,
                        iconBoxSize: 38.0,
                        iconSize: 20.0,
                        fontSize: 14.0,
                        gap: 10.0,
                        backgroundColor:
                            canClaim ? _blue : const Color(0xFFB8C0CC),
                        textColor: Colors.white,
                        iconBackgroundColor: Colors.white,
                        iconColor: _blue,
                      ),
                    if (_status == 'settling' || _status == 'settled')
                      Align(
                        alignment: AlignmentDirectional.center,
                        child: InkWell(
                          onTap: () =>
                              context.goNamed(DashboardWidget.routeName),
                          borderRadius: BorderRadius.circular(22.0),
                          child: Container(
                            width: 44.0,
                            height: 44.0,
                            decoration: BoxDecoration(
                              color: _blue.withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: _blue.withValues(alpha: 0.22),
                              ),
                            ),
                            child: const Icon(
                              Icons.home_rounded,
                              color: _blue,
                              size: 20.0,
                            ),
                          ),
                        ),
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
                  onPressed: () => context.goNamed(ClaimGiftWidget.routeName),
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
                  onPressed: () => context.goNamed(DashboardWidget.routeName),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
