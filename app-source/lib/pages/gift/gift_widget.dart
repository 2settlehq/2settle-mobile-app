import 'dart:async';

import '/config/api_config.dart';
import '/flutter_flow/flutter_flow_icon_button.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/index.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class GiftWidget extends StatefulWidget {
  const GiftWidget({super.key});

  static String routeName = 'Gift';
  static String routePath = 'gift';

  @override
  State<GiftWidget> createState() => _GiftWidgetState();
}

class _GiftWidgetState extends State<GiftWidget> {
  static const _blue = Color(0xFF4472C4);
  static const _green = Color(0xFF17A34A);
  static const _giftHistoryStorageKey = '2settle_gift_history';
  static const _transactionStorageKey = '2settle_initiated_transactions';
  static const _giftClaimBaseUrl = ApiConfig.giftsBaseUrl;

  List<_GiftHistoryItem> _history = [];
  Timer? _giftStatusTimer;

  @override
  void initState() {
    super.initState();
    _loadHistory();
    _giftStatusTimer = Timer.periodic(
      const Duration(seconds: 10),
      (_) => _refreshSettlingGifts(),
    );
    _refreshSettlingGifts();
  }

  @override
  void dispose() {
    _giftStatusTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString(_giftHistoryStorageKey);
    if (stored == null || stored.isEmpty) return;
    try {
      final decoded = jsonDecode(stored);
      if (decoded is! List) return;
      final history = decoded
          .whereType<Map>()
          .map((item) =>
              _GiftHistoryItem.fromJson(Map<String, dynamic>.from(item)))
          .toList();
      if (!mounted) return;
      safeSetState(() => _history = history);
    } catch (_) {}
  }

  Future<void> _refreshSettlingGifts() async {
    final settling = _history
        .where(
            (item) => item.status == 'settling' || item.status == 'confirmed')
        .followedBy(_history.where((item) => item.status == 'pending'))
        .toList();
    if (settling.isEmpty) return;
    var changed = false;
    for (final item in settling) {
      try {
        final response = await http.get(
          Uri.parse(
            '$_giftClaimBaseUrl/${Uri.encodeComponent(item.reference)}?ts=${DateTime.now().millisecondsSinceEpoch}',
          ),
          headers: const {'accept': 'application/json'},
        ).timeout(const Duration(seconds: 8));
        final payload = response.body.isEmpty
            ? <String, dynamic>{}
            : jsonDecode(response.body) as Map<String, dynamic>;
        final status =
            _payloadString(payload, const ['status', 'state'])?.toLowerCase() ??
                item.status;
        if (status == 'settled') {
          await _markGiftSettled(item);
          changed = true;
        } else if (status != item.status &&
            (status == 'confirmed' ||
                status == 'settling' ||
                status == 'expired' ||
                status == 'cancelled' ||
                status == 'canceled' ||
                status == 'failed' ||
                status == 'rejected')) {
          await _markGiftStatus(item, status);
          changed = true;
        }
      } catch (_) {}
    }
    if (changed) await _loadHistory();
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

  Future<void> _markGiftSettled(_GiftHistoryItem item) async {
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now();
    final nowIso = now.toIso8601String();
    final start = DateTime.tryParse(item.settlingStartedAt) ??
        DateTime.tryParse(item.createdAt) ??
        now;
    final duration = _durationLabel(start, now);
    final storedGift = prefs.getString(_giftHistoryStorageKey);
    final giftList = storedGift == null || storedGift.isEmpty
        ? <dynamic>[]
        : (jsonDecode(storedGift) as List? ?? <dynamic>[]);
    final updatedGift = giftList.map((entry) {
      if (entry is Map &&
          '${entry['reference'] ?? entry['id']}' == item.reference) {
        final next = Map<String, dynamic>.from(entry);
        next['status'] = 'settled';
        next['settledAt'] = nowIso;
        next['settlementDuration'] = duration;
        return next;
      }
      return entry;
    }).toList();
    await prefs.setString(_giftHistoryStorageKey, jsonEncode(updatedGift));

    final storedActivity = prefs.getString(_transactionStorageKey);
    if (storedActivity == null || storedActivity.isEmpty) return;
    final activityList =
        (jsonDecode(storedActivity) as List? ?? <dynamic>[]).map((entry) {
      if (entry is Map &&
          '${entry['id'] ?? entry['reference']}' == item.reference) {
        final next = Map<String, dynamic>.from(entry);
        next['status'] = 'settled';
        next['settledAt'] = nowIso;
        next['settlementDuration'] = duration;
        return next;
      }
      return entry;
    }).toList();
    await prefs.setString(_transactionStorageKey, jsonEncode(activityList));
  }

  Future<void> _markGiftStatus(_GiftHistoryItem item, String status) async {
    final prefs = await SharedPreferences.getInstance();
    final storedGift = prefs.getString(_giftHistoryStorageKey);
    final giftList = storedGift == null || storedGift.isEmpty
        ? <dynamic>[]
        : (jsonDecode(storedGift) as List? ?? <dynamic>[]);
    final updatedGift = giftList.map((entry) {
      if (entry is Map &&
          '${entry['reference'] ?? entry['id']}' == item.reference) {
        final next = Map<String, dynamic>.from(entry);
        next['status'] = status;
        return next;
      }
      return entry;
    }).toList();
    await prefs.setString(_giftHistoryStorageKey, jsonEncode(updatedGift));

    final storedActivity = prefs.getString(_transactionStorageKey);
    if (storedActivity == null || storedActivity.isEmpty) return;
    final activityList =
        (jsonDecode(storedActivity) as List? ?? <dynamic>[]).map((entry) {
      if (entry is Map &&
          '${entry['id'] ?? entry['reference']}' == item.reference) {
        final next = Map<String, dynamic>.from(entry);
        next['status'] = status;
        return next;
      }
      return entry;
    }).toList();
    await prefs.setString(_transactionStorageKey, jsonEncode(activityList));
  }

  Widget _giftAction({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    final theme = FlutterFlowTheme.of(context);
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18.0),
        child: Container(
          height: 124.0,
          padding: const EdgeInsetsDirectional.fromSTEB(11.0, 13.0, 11.0, 11.0),
          decoration: BoxDecoration(
            color: _blue,
            borderRadius: BorderRadius.circular(18.0),
            boxShadow: [
              BoxShadow(
                blurRadius: 14.0,
                color: _blue.withValues(alpha: 0.18),
                offset: const Offset(0.0, 6.0),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 44.0,
                height: 44.0,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.18),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: Colors.white, size: 23.0),
              ),
              const SizedBox(height: 10.0),
              Text(
                title,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.bodySmall.override(
                  color: Colors.white,
                  fontSize: 12.8,
                  letterSpacing: 0.0,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4.0),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.inter(
                  color: Colors.white.withValues(alpha: 0.78),
                  fontSize: 9.6,
                  fontWeight: FontWeight.w500,
                  height: 1.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _emptyHistory(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsetsDirectional.fromSTEB(16.0, 20.0, 16.0, 20.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18.0),
        border: Border.all(color: const Color(0xFFE5EAF1)),
      ),
      child: Column(
        children: [
          Container(
            width: 48.0,
            height: 48.0,
            decoration: BoxDecoration(
              color: _blue.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.card_giftcard_rounded,
              color: _blue,
              size: 23.0,
            ),
          ),
          const SizedBox(height: 10.0),
          Text(
            'No gift history yet',
            style: theme.bodySmall.override(
              color: theme.primaryText,
              fontSize: 12.5,
              letterSpacing: 0.0,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4.0),
          Text(
            'Created and claimed gifts will appear here.',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              color: theme.secondaryText,
              fontSize: 10.5,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _historyRow(BuildContext context, _GiftHistoryItem item) {
    final theme = FlutterFlowTheme.of(context);
    final isSettled = item.status == 'settled';
    final isPending = item.status == 'pending';
    final isCancelled = item.isUnsuccessful;
    final isCreated = item.isCreatedGift;
    final statusColor = isSettled
        ? _green
        : isCancelled
            ? const Color(0xFFD64242)
            : isPending
                ? const Color(0xFFE08A1E)
                : _blue;
    return InkWell(
      onTap: () => context.pushNamed(
        GiftClaimDetailsWidget.routeName,
        queryParameters: item.toQueryParameters(),
      ),
      child: Container(
        padding: const EdgeInsetsDirectional.fromSTEB(2.0, 10.0, 2.0, 10.0),
        decoration: const BoxDecoration(
          border: Border(
            bottom: BorderSide(color: Color(0xFFE2E7EF), width: 0.8),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 38.0,
              height: 38.0,
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: isSettled
                  ? const Icon(
                      Icons.checklist_rtl_rounded,
                      color: _green,
                      size: 18.0,
                    )
                  : isCreated
                      ? Icon(
                          isPending
                              ? Icons.hourglass_empty_rounded
                              : isCancelled
                                  ? Icons.cancel_rounded
                                  : Icons.deblur_rounded,
                          color: statusColor,
                          size: 18.0,
                        )
                      : const Padding(
                          padding: EdgeInsets.all(10.0),
                          child: CircularProgressIndicator(
                            strokeWidth: 2.0,
                            valueColor: AlwaysStoppedAnimation<Color>(_blue),
                          ),
                        ),
            ),
            const SizedBox(width: 10.0),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    item.dateLabel,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      color: theme.primaryText,
                      fontSize: 11.0,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.0,
                    ),
                  ),
                  const SizedBox(height: 5.0),
                  Text(
                    isCreated
                        ? '${isCancelled ? item.unsuccessfulLabel : isPending ? 'Not funded' : 'Created'} gift ${item.reference}'
                        : '${isCancelled ? item.unsuccessfulLabel : isSettled ? 'Settled' : 'Settling'} ${item.reference} to ${item.accountTail}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.bodySmall.override(
                      color: theme.secondaryText,
                      fontSize: 11.0,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 0.0,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8.0),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  item.historyTypeLabel,
                  style: theme.bodySmall.override(
                    color: statusColor,
                    fontSize: 12.4,
                    letterSpacing: 0.0,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 3.0),
                Text(
                  item.formattedAmount,
                  style: GoogleFonts.inter(
                    color: theme.grayIcon,
                    fontSize: 10.0,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
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
                    onPressed: () =>
                        context.goNamed(AllServicesWidget.routeName),
                  ),
                  Expanded(
                    child: Text(
                      'Gift',
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
                  const EdgeInsetsDirectional.fromSTEB(22.0, 2.0, 22.0, 0.0),
              child: Text(
                'Create or claim crypto-powered gifts.',
                style: GoogleFonts.inter(
                  color: theme.secondaryText,
                  fontSize: 11.2,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Padding(
              padding:
                  const EdgeInsetsDirectional.fromSTEB(18.0, 18.0, 18.0, 0.0),
              child: Row(
                children: [
                  _giftAction(
                    context: context,
                    icon: Icons.add_card_rounded,
                    title: 'CREATE',
                    subtitle: 'Send value with a gift link',
                    onTap: () => context.goNamed(CreateGiftWidget.routeName),
                  ),
                  const SizedBox(width: 12.0),
                  _giftAction(
                    context: context,
                    icon: Icons.redeem_rounded,
                    title: 'CLAIM',
                    subtitle: 'Redeem a received gift',
                    onTap: () => context.goNamed(ClaimGiftWidget.routeName),
                  ),
                ],
              ),
            ),
            Padding(
              padding:
                  const EdgeInsetsDirectional.fromSTEB(18.0, 22.0, 18.0, 0.0),
              child: Text(
                'HISTORY',
                style: theme.bodySmall.override(
                  color: _blue,
                  fontSize: 12.0,
                  letterSpacing: 0.0,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            if (_history.isNotEmpty)
              Padding(
                padding:
                    const EdgeInsetsDirectional.fromSTEB(18.0, 9.0, 18.0, 0.0),
                child: Column(
                  children: _history
                      .take(8)
                      .map((item) => _historyRow(context, item))
                      .toList(),
                ),
              )
            else
              Padding(
                padding:
                    const EdgeInsetsDirectional.fromSTEB(18.0, 9.0, 18.0, 0.0),
                child: _emptyHistory(context),
              ),
          ],
        ),
      ),
    );
  }
}

class _GiftHistoryItem {
  const _GiftHistoryItem({
    required this.reference,
    required this.type,
    required this.amount,
    required this.bankName,
    required this.accountName,
    required this.accountNumber,
    required this.bankCode,
    required this.status,
    required this.createdAt,
    required this.settlingStartedAt,
    required this.settledAt,
    required this.settlementDuration,
    required this.crypto,
    required this.network,
    required this.cryptoAmount,
    required this.paymentId,
    required this.depositAddress,
    required this.expiresAt,
    required this.chargeFiat,
    required this.chargeCrypto,
    required this.rate,
    required this.transactionUsd,
  });

  factory _GiftHistoryItem.fromJson(Map<String, dynamic> json) {
    return _GiftHistoryItem(
      reference: '${json['reference'] ?? json['id'] ?? ''}',
      type: '${json['type'] ?? ''}',
      amount: '${json['amount'] ?? '₦0'}',
      bankName: '${json['bankName'] ?? 'Bank'}',
      accountName: '${json['accountName'] ?? 'Receiver'}',
      accountNumber: '${json['accountNumber'] ?? ''}',
      bankCode: '${json['bankCode'] ?? ''}',
      status: '${json['status'] ?? 'settling'}'.toLowerCase(),
      createdAt: '${json['createdAt'] ?? DateTime.now().toIso8601String()}',
      settlingStartedAt: '${json['settlingStartedAt'] ?? ''}',
      settledAt: '${json['settledAt'] ?? ''}',
      settlementDuration: '${json['settlementDuration'] ?? ''}',
      crypto: '${json['crypto'] ?? 'USDT'}',
      network: '${json['network'] ?? 'TRC20'}',
      cryptoAmount: '${json['cryptoAmount'] ?? ''}',
      paymentId: '${json['paymentId'] ?? ''}',
      depositAddress: '${json['depositAddress'] ?? ''}',
      expiresAt: '${json['expiresAt'] ?? ''}',
      chargeFiat: '${json['chargeFiat'] ?? ''}',
      chargeCrypto: '${json['chargeCrypto'] ?? ''}',
      rate: '${json['rate'] ?? ''}',
      transactionUsd: '${json['transactionUsd'] ?? ''}',
    );
  }

  final String reference;
  final String type;
  final String amount;
  final String bankName;
  final String accountName;
  final String accountNumber;
  final String bankCode;
  final String status;
  final String createdAt;
  final String settlingStartedAt;
  final String settledAt;
  final String settlementDuration;
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

  String get dateLabel {
    final date = DateTime.tryParse(createdAt) ?? DateTime.now();
    return DateFormat('MMM. d, yyyy; HH:mm:ss').format(date);
  }

  String get formattedAmount {
    final raw = amount.replaceAll('₦', '').replaceAll(',', '').trim();
    final parsed = double.tryParse(raw);
    if (parsed == null) return amount;
    return '₦${NumberFormat('#,##0.##', 'en_US').format(parsed)}';
  }

  bool get isCreatedGift {
    final normalizedType = type.toLowerCase();
    if (normalizedType == 'create_gift' ||
        normalizedType == 'gift_create' ||
        normalizedType == 'gift_created' ||
        normalizedType == 'creategift') {
      return true;
    }
    if (bankName.toLowerCase() == 'gift') return true;
    return accountNumber.trim().isEmpty &&
        (paymentId.trim().isNotEmpty ||
            depositAddress.trim().isNotEmpty ||
            cryptoAmount.trim().isNotEmpty);
  }

  String get historyTypeLabel => isCreatedGift ? 'Gift created' : 'Gift claim';

  bool get isUnsuccessful {
    final value = status.toLowerCase();
    return value == 'cancelled' ||
        value == 'canceled' ||
        value == 'expired' ||
        value == 'failed' ||
        value == 'unsuccessful' ||
        value == 'rejected';
  }

  String get unsuccessfulLabel {
    final value = status.toLowerCase();
    if (value == 'expired') return 'Expired';
    if (value == 'failed' || value == 'unsuccessful') return 'Failed';
    if (value == 'rejected') return 'Rejected';
    return 'Cancelled';
  }

  String get accountTail {
    if (accountNumber.length <= 4) return accountNumber;
    return '...${accountNumber.substring(accountNumber.length - 4)}';
  }

  Map<String, String> toQueryParameters() => {
        'reference': reference,
        'type': isCreatedGift ? 'create_gift' : 'gift_claim',
        'amount': formattedAmount,
        'bankName': bankName,
        'accountNumber': accountNumber,
        'accountName': accountName,
        'bankCode': bankCode,
        'status': status,
        'createdAt': createdAt,
        'settlingStartedAt': settlingStartedAt,
        'settledAt': settledAt,
        'settlementDuration': settlementDuration,
        'crypto': crypto,
        'network': network,
        'cryptoAmount': cryptoAmount,
        'paymentId': paymentId,
        'depositAddress': depositAddress,
        'expiresAt': expiresAt,
        'chargeFiat': chargeFiat,
        'chargeCrypto': chargeCrypto,
        'rate': rate,
        'transactionUsd': transactionUsd,
      };
}
