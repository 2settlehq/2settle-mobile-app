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
import 'history_model.dart';
export 'history_model.dart';

class HistoryWidget extends StatefulWidget {
  const HistoryWidget({super.key});

  static String routeName = 'History';
  static String routePath = 'history';

  @override
  State<HistoryWidget> createState() => _HistoryWidgetState();
}

class _HistoryWidgetState extends State<HistoryWidget> {
  late HistoryModel _model;

  final scaffoldKey = GlobalKey<ScaffoldState>();
  static const _blue = Color(0xFF4472C4);
  static const _transactionStorageKey = '2settle_initiated_transactions';
  static const _receiveStorageKey = '2settle_receive_requests';
  static const _giftHistoryStorageKey = '2settle_gift_history';
  static const _giftClaimBaseUrl = ApiConfig.giftsBaseUrl;
  String _filter = 'All';
  String _typeFilter = 'All';
  DateTime? _fromDate;
  DateTime? _toDate;
  String _minAmount = '';
  String _maxAmount = '';
  String _cryptoFilter = 'All';
  String _bankFilter = '';
  List<_HistoryActivity> _activities = [];
  Timer? _giftStatusTimer;

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => HistoryModel());
    _loadActivities();
    _giftStatusTimer = Timer.periodic(
      const Duration(seconds: 10),
      (_) => _refreshSettlingGifts(),
    );
    _refreshSettlingGifts();
  }

  @override
  void dispose() {
    _giftStatusTimer?.cancel();
    _model.dispose();
    super.dispose();
  }

  Future<void> _loadActivities() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString(_transactionStorageKey);
    final receiveStored = prefs.getString(_receiveStorageKey);
    final giftStored = prefs.getString(_giftHistoryStorageKey);

    try {
      final decoded = stored == null || stored.isEmpty
          ? <dynamic>[]
          : (jsonDecode(stored) as List? ?? <dynamic>[]);
      final receiveDecoded = receiveStored == null || receiveStored.isEmpty
          ? <dynamic>[]
          : (jsonDecode(receiveStored) as List? ?? <dynamic>[]);
      final giftDecoded = giftStored == null || giftStored.isEmpty
          ? <dynamic>[]
          : (jsonDecode(giftStored) as List? ?? <dynamic>[]);
      final records = <Map<String, dynamic>>[
        ...decoded
            .whereType<Map>()
            .map((item) => Map<String, dynamic>.from(item)),
        ...giftDecoded.whereType<Map>().map((item) {
          final gift = Map<String, dynamic>.from(item);
          final rawType =
              '${gift['type'] ?? gift['purpose'] ?? ''}'.toLowerCase();
          final accountNumber = '${gift['accountNumber'] ?? ''}';
          final isCreatedGift = rawType == 'create_gift' ||
              rawType == 'gift_create' ||
              rawType == 'gift_created' ||
              rawType == 'creategift' ||
              '${gift['beneficiaryName'] ?? ''}'.toLowerCase() ==
                  'created gift' ||
              '${gift['bankName'] ?? ''}'.toLowerCase() == 'gift' ||
              (accountNumber.trim().isEmpty &&
                  ('${gift['paymentId'] ?? ''}'.trim().isNotEmpty ||
                      '${gift['depositAddress'] ?? ''}'.trim().isNotEmpty ||
                      '${gift['cryptoAmount'] ?? ''}'.trim().isNotEmpty));
          return {
            'id': gift['reference'] ?? gift['id'] ?? '',
            'type': isCreatedGift ? 'create_gift' : 'gift_claim',
            'reference': gift['reference'] ?? gift['id'] ?? '',
            'createdAt': gift['createdAt'] ?? DateTime.now().toIso8601String(),
            'settlementAmount': '${gift['amount'] ?? '0'}'.replaceAll('₦', ''),
            'cryptoAmount': '${gift['cryptoAmount'] ?? '0.00000 GIFT'}',
            'crypto': '${gift['crypto'] ?? 'GIFT'}',
            'network': '${gift['network'] ?? 'GIFT'}',
            'beneficiaryName': '${gift['accountName'] ?? 'Gift recipient'}',
            'bankName': '${gift['bankName'] ?? 'Gift'}',
            'accountNumber': '${gift['accountNumber'] ?? ''}',
            'accountName': '${gift['accountName'] ?? 'Gift recipient'}',
            'bankCode': '${gift['bankCode'] ?? ''}',
            'rate': '${gift['rate'] ?? 'Gift'}',
            'status': '${gift['status'] ?? 'pending'}',
            'settlingStartedAt': '${gift['settlingStartedAt'] ?? ''}',
            'settledAt': '${gift['settledAt'] ?? ''}',
            'settlementDuration': '${gift['settlementDuration'] ?? ''}',
            'paymentId': '${gift['paymentId'] ?? ''}',
            'depositAddress': '${gift['depositAddress'] ?? ''}',
            'expiresAt': '${gift['expiresAt'] ?? ''}',
            'chargeFiat': '${gift['chargeFiat'] ?? ''}',
            'chargeCrypto': '${gift['chargeCrypto'] ?? ''}',
            'transactionUsd': '${gift['transactionUsd'] ?? ''}',
          };
        }),
        ...receiveDecoded.whereType<Map>().map((item) {
          final request = Map<String, dynamic>.from(item);
          return {
            'id': request['id'] ?? '',
            'type': 'receive_payment',
            'reference': request['id'] ?? '',
            'createdAt':
                request['createdAt'] ?? DateTime.now().toIso8601String(),
            'settlementAmount': '${request['amount'] ?? '0'}',
            'cryptoAmount': '0.00000 RECEIVE',
            'crypto': 'RECEIVE',
            'network': '${request['currency'] ?? 'NGN'}',
            'beneficiaryName': '${request['description'] ?? 'Receive payment'}',
            'bankName': '${request['settlementMode'] ?? 'Receive'}',
            'accountNumber': '${request['accountNumber'] ?? ''}',
            'accountName': '${request['settlementLabel'] ?? ''}',
            'bankCode': '',
            'rate': 'https://receive.2settle.io/pay/${request['id'] ?? ''}',
            'status': '${request['status'] ?? 'created'}',
          };
        }),
      ];
      final seen = <String>{};
      final activities = records
          .map((item) => _HistoryActivity.fromJson(
                item,
              ))
          .where((activity) => activity.hasValue)
          .where((activity) => seen.add(activity.reference.isEmpty
              ? activity.id
              : '${activity.type}:${activity.reference}'))
          .toList();
      activities.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      if (!mounted) return;
      safeSetState(() => _activities = activities);
    } catch (_) {
      // Keep the empty state if stored history cannot be parsed.
    }
  }

  Future<void> _refreshSettlingGifts() async {
    final settling = _activities
        .where((item) =>
            (item.isGift || item.isCreateGift) &&
            (item.status.toLowerCase() == 'settling' ||
                item.status.toLowerCase() == 'confirmed' ||
                item.status.toLowerCase() == 'pending'))
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
    if (changed) await _loadActivities();
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

  Future<void> _markGiftSettled(_HistoryActivity item) async {
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now();
    final nowIso = now.toIso8601String();
    final start = DateTime.tryParse(item.settlingStartedAt) ?? item.createdAt;
    final duration = _durationLabel(start, now);
    final storedGift = prefs.getString(_giftHistoryStorageKey);
    if (storedGift != null && storedGift.isNotEmpty) {
      final giftList =
          (jsonDecode(storedGift) as List? ?? <dynamic>[]).map((entry) {
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
      await prefs.setString(_giftHistoryStorageKey, jsonEncode(giftList));
    }
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

  Future<void> _markGiftStatus(_HistoryActivity item, String status) async {
    final prefs = await SharedPreferences.getInstance();
    final storedGift = prefs.getString(_giftHistoryStorageKey);
    if (storedGift != null && storedGift.isNotEmpty) {
      final giftList =
          (jsonDecode(storedGift) as List? ?? <dynamic>[]).map((entry) {
        if (entry is Map &&
            '${entry['reference'] ?? entry['id']}' == item.reference) {
          final next = Map<String, dynamic>.from(entry);
          next['status'] = status;
          return next;
        }
        return entry;
      }).toList();
      await prefs.setString(_giftHistoryStorageKey, jsonEncode(giftList));
    }

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

  List<_HistoryActivity> get _filteredActivities {
    final now = DateTime.now();
    Iterable<_HistoryActivity> result = _activities;
    if (_filter == 'Today') {
      result = result.where((item) =>
          item.createdAt.year == now.year &&
          item.createdAt.month == now.month &&
          item.createdAt.day == now.day);
    } else if (_filter == '7 days') {
      final threshold = now.subtract(const Duration(days: 7));
      result = result.where((item) => item.createdAt.isAfter(threshold));
    }
    final minAmount = double.tryParse(_minAmount.replaceAll(',', '').trim());
    final maxAmount = double.tryParse(_maxAmount.replaceAll(',', '').trim());
    return result.where((item) {
      if (_typeFilter != 'All' && item.typeFilterLabel != _typeFilter) {
        return false;
      }
      if (_fromDate != null && item.createdAt.isBefore(_fromDate!)) {
        return false;
      }
      if (_toDate != null &&
          item.createdAt.isAfter(_toDate!.add(const Duration(days: 1)))) {
        return false;
      }
      if (minAmount != null && item.settlementValue < minAmount) {
        return false;
      }
      if (maxAmount != null && item.settlementValue > maxAmount) {
        return false;
      }
      if (_cryptoFilter != 'All' &&
          item.crypto.toUpperCase() != _cryptoFilter.toUpperCase()) {
        return false;
      }
      if (_bankFilter.trim().isNotEmpty &&
          !item.bankName
              .toLowerCase()
              .contains(_bankFilter.trim().toLowerCase())) {
        return false;
      }
      return true;
    }).toList();
  }

  List<String> get _cryptoOptions {
    final set = _activities.map((item) => item.crypto.toUpperCase()).toSet();
    return ['All', ...set.toList()..sort()];
  }

  double get _totalTransacted => _filteredActivities.fold<double>(
        0,
        (sum, item) => sum + item.transactedValue,
      );

  void _openDetails(_HistoryActivity activity) {
    if (activity.isReceivePayment) {
      context.pushNamed(
        ReceiveRequestDetailsWidget.routeName,
        queryParameters: {
          'requestId': serializeParam(activity.id, ParamType.String),
        }.withoutNulls,
      );
      return;
    }
    context.pushNamed(
      TransactionDetailsWidget.routeName,
      queryParameters: activity.toQueryParameters(),
      extra: <String, dynamic>{
        '__transition_info__': TransitionInfo(
          hasTransition: true,
          transitionType: PageTransitionType.rightToLeft,
        ),
      },
    );
  }

  Widget _filterChip(String label) {
    final selected = _filter == label;
    return InkWell(
      onTap: () => safeSetState(() => _filter = label),
      borderRadius: BorderRadius.circular(18.0),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsetsDirectional.fromSTEB(12.0, 7.0, 12.0, 7.0),
        decoration: BoxDecoration(
          color: selected ? _blue : _blue.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(18.0),
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(
            color: selected ? Colors.white : _blue,
            fontSize: 11.0,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }

  Widget _typeFilterChip(String label) {
    final selected = _typeFilter == label;
    return InkWell(
      onTap: () => safeSetState(() => _typeFilter = label),
      borderRadius: BorderRadius.circular(18.0),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsetsDirectional.fromSTEB(11.0, 7.0, 11.0, 7.0),
        decoration: BoxDecoration(
          color: selected ? _blue : Colors.white,
          borderRadius: BorderRadius.circular(18.0),
          border: Border.all(
            color: selected ? _blue : const Color(0xFFE2E7EF),
            width: 0.8,
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(
            color: selected ? Colors.white : _blue,
            fontSize: 10.6,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }

  Future<void> _pickDateRange() async {
    final now = DateTime.now();
    final range = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year - 2),
      lastDate: DateTime(now.year + 1),
      initialDateRange: _fromDate != null && _toDate != null
          ? DateTimeRange(start: _fromDate!, end: _toDate!)
          : null,
    );
    if (range == null) return;
    safeSetState(() {
      _filter = 'Custom';
      _fromDate = range.start;
      _toDate = range.end;
    });
  }

  Widget _customFilters() {
    final theme = FlutterFlowTheme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 12.0),
        Row(
          children: [
            Expanded(
              child: _miniInput(
                label: 'Min ₦',
                value: _minAmount,
                onChanged: (value) => safeSetState(() {
                  _filter = 'Custom';
                  _minAmount = value;
                }),
              ),
            ),
            const SizedBox(width: 8.0),
            Expanded(
              child: _miniInput(
                label: 'Max ₦',
                value: _maxAmount,
                onChanged: (value) => safeSetState(() {
                  _filter = 'Custom';
                  _maxAmount = value;
                }),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8.0),
        Row(
          children: [
            Expanded(
              child: InkWell(
                onTap: _pickDateRange,
                borderRadius: BorderRadius.circular(10.0),
                child: Container(
                  height: 42.0,
                  padding: const EdgeInsetsDirectional.fromSTEB(
                      12.0, 0.0, 12.0, 0.0),
                  alignment: Alignment.centerLeft,
                  decoration: BoxDecoration(
                    color: _blue.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(10.0),
                  ),
                  child: Text(
                    _fromDate == null || _toDate == null
                        ? 'Date range'
                        : '${DateFormat('MMM d').format(_fromDate!)} - ${DateFormat('MMM d').format(_toDate!)}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      color: _blue,
                      fontSize: 11.0,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8.0),
            Expanded(
              child: Container(
                height: 42.0,
                padding:
                    const EdgeInsetsDirectional.fromSTEB(12.0, 0.0, 8.0, 0.0),
                decoration: BoxDecoration(
                  color: _blue.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(10.0),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _cryptoFilter,
                    isExpanded: true,
                    icon: const Icon(Icons.keyboard_arrow_down_rounded,
                        color: _blue, size: 17.0),
                    items: _cryptoOptions
                        .map((asset) => DropdownMenuItem(
                              value: asset,
                              child: Text(
                                asset == 'All' ? 'Crypto asset' : asset,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.inter(
                                  color: _blue,
                                  fontSize: 11.0,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ))
                        .toList(),
                    onChanged: (value) {
                      if (value == null) return;
                      safeSetState(() {
                        _filter = 'Custom';
                        _cryptoFilter = value;
                      });
                    },
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8.0),
        TextField(
          onChanged: (value) => safeSetState(() {
            _filter = 'Custom';
            _bankFilter = value;
          }),
          style: GoogleFonts.inter(
            color: theme.primaryText,
            fontSize: 11.5,
            fontWeight: FontWeight.w600,
          ),
          decoration: InputDecoration(
            hintText: 'Bank used',
            hintStyle: GoogleFonts.inter(
              color: theme.secondaryText,
              fontSize: 11.5,
              fontWeight: FontWeight.w500,
            ),
            isDense: true,
            filled: true,
            fillColor: _blue.withValues(alpha: 0.06),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10.0),
              borderSide: BorderSide.none,
            ),
            contentPadding:
                const EdgeInsetsDirectional.fromSTEB(12.0, 12.0, 12.0, 12.0),
          ),
        ),
      ],
    );
  }

  Widget _miniInput({
    required String label,
    required String value,
    required ValueChanged<String> onChanged,
  }) {
    return TextField(
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      onChanged: onChanged,
      style: GoogleFonts.inter(
        color: FlutterFlowTheme.of(context).primaryText,
        fontSize: 11.5,
        fontWeight: FontWeight.w600,
      ),
      decoration: InputDecoration(
        hintText: label,
        hintStyle: GoogleFonts.inter(
          color: FlutterFlowTheme.of(context).secondaryText,
          fontSize: 11.5,
          fontWeight: FontWeight.w500,
        ),
        isDense: true,
        filled: true,
        fillColor: _blue.withValues(alpha: 0.06),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10.0),
          borderSide: BorderSide.none,
        ),
        contentPadding:
            const EdgeInsetsDirectional.fromSTEB(12.0, 12.0, 12.0, 12.0),
      ),
    );
  }

  Widget _emptyState() {
    final theme = FlutterFlowTheme.of(context);
    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(24.0, 64.0, 24.0, 0.0),
      child: Column(
        children: [
          Container(
            width: 74.0,
            height: 74.0,
            decoration: BoxDecoration(
              color: _blue.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.receipt_long_rounded,
              color: _blue,
              size: 34.0,
            ),
          ),
          const SizedBox(height: 14.0),
          Text(
            'No history yet',
            style: theme.titleSmall.override(
              font: TextStyle(
                fontWeight: FontWeight.w600,
                fontStyle: theme.titleSmall.fontStyle,
              ),
              color: theme.primaryText,
              letterSpacing: 0.0,
              fontWeight: FontWeight.w600,
              fontStyle: theme.titleSmall.fontStyle,
            ),
          ),
          const SizedBox(height: 6.0),
          Text(
            'You are yet to send money with 2Settle.',
            textAlign: TextAlign.center,
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
          ),
        ],
      ),
    );
  }

  Widget _historyRow(_HistoryActivity activity) {
    final theme = FlutterFlowTheme.of(context);
    final signalColor = activity.signalColor;
    return InkWell(
      onTap: () {
        if (activity.isGift || activity.isCreateGift) {
          context.pushNamed(
            GiftClaimDetailsWidget.routeName,
            queryParameters: activity.toGiftQueryParameters(),
          );
          return;
        }
        _openDetails(activity);
      },
      borderRadius: BorderRadius.circular(12.0),
      child: Container(
        margin: const EdgeInsetsDirectional.fromSTEB(16.0, 0.0, 16.0, 9.0),
        padding: const EdgeInsetsDirectional.fromSTEB(12.0, 11.0, 12.0, 11.0),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12.0),
          boxShadow: const [
            BoxShadow(
              blurRadius: 8.0,
              color: Color(0x14000000),
              offset: Offset(0.0, 4.0),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 38.0,
              height: 38.0,
              decoration: BoxDecoration(
                color: signalColor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: activity.isSettling
                  ? const Padding(
                      padding: EdgeInsets.all(10.0),
                      child: CircularProgressIndicator(
                        strokeWidth: 2.0,
                        valueColor: AlwaysStoppedAnimation<Color>(_blue),
                      ),
                    )
                  : Icon(
                      activity.signalIcon,
                      color: signalColor,
                      size: 18.0,
                    ),
            ),
            const SizedBox(width: 10.0),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    activity.dateLabel,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      color: theme.primaryText,
                      fontSize: 11.0,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4.0),
                  Text(
                    activity.accountLabel,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
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
                ],
              ),
            ),
            const SizedBox(width: 10.0),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  activity.cryptoOnlyAmount,
                  style: activity.isGift
                      ? theme.bodySmall.override(
                          color: signalColor,
                          fontSize: 12.4,
                          letterSpacing: 0.0,
                          fontWeight: FontWeight.w600,
                        )
                      : GoogleFonts.inter(
                          color: signalColor,
                          fontSize: 12.4,
                          fontWeight: FontWeight.w600,
                        ),
                ),
                const SizedBox(height: 3.0),
                Text(
                  activity.formattedSettlementAmount,
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
    final activities = _filteredActivities;
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
          onPressed: () => context.pushNamed(DashboardWidget.routeName),
        ),
        title: Text(
          'History',
          style: theme.headlineMedium.override(
            font: TextStyle(
              fontWeight: FontWeight.w600,
              fontStyle: theme.headlineMedium.fontStyle,
            ),
            color: Colors.white,
            fontSize: 22.0,
            letterSpacing: 0.0,
            fontWeight: FontWeight.w600,
            fontStyle: theme.headlineMedium.fontStyle,
          ),
        ),
        elevation: 0.0,
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            Padding(
              padding:
                  const EdgeInsetsDirectional.fromSTEB(16.0, 16.0, 16.0, 14.0),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsetsDirectional.fromSTEB(
                    16.0, 14.0, 16.0, 14.0),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14.0),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '₦${NumberFormat('#,##0.00', 'en_US').format(_totalTransacted)}',
                      style: GoogleFonts.inter(
                        color: _blue,
                        fontSize: 24.0,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 3.0),
                    Text(
                      'Total transacted',
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
                    ),
                    const SizedBox(height: 12.0),
                    Row(
                      children: [
                        _filterChip('All'),
                        const SizedBox(width: 8.0),
                        _filterChip('Today'),
                        const SizedBox(width: 8.0),
                        _filterChip('7 days'),
                      ],
                    ),
                    const SizedBox(height: 10.0),
                    Wrap(
                      spacing: 8.0,
                      runSpacing: 8.0,
                      children: [
                        _typeFilterChip('All'),
                        _typeFilterChip('Send'),
                        _typeFilterChip('Receive'),
                        _typeFilterChip('Gift created'),
                        _typeFilterChip('Gift claim'),
                      ],
                    ),
                    _customFilters(),
                  ],
                ),
              ),
            ),
            Padding(
              padding:
                  const EdgeInsetsDirectional.fromSTEB(18.0, 0.0, 18.0, 10.0),
              child: Row(
                children: [
                  Text(
                    'Recent Transactions',
                    style: theme.bodySmall.override(
                      font: TextStyle(
                        fontWeight: FontWeight.normal,
                        fontStyle: theme.bodySmall.fontStyle,
                      ),
                      color: _blue,
                      letterSpacing: 0.0,
                      fontWeight: FontWeight.normal,
                      fontStyle: theme.bodySmall.fontStyle,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: activities.isEmpty
                  ? _emptyState()
                  : ListView(
                      padding: EdgeInsets.zero,
                      children: activities.map(_historyRow).toList(),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HistoryActivity {
  const _HistoryActivity({
    required this.id,
    required this.type,
    required this.reference,
    required this.createdAt,
    required this.settlementAmount,
    required this.cryptoAmount,
    required this.crypto,
    required this.network,
    required this.beneficiaryName,
    required this.bankName,
    required this.accountNumber,
    required this.accountName,
    required this.bankCode,
    required this.rate,
    required this.status,
    required this.settlingStartedAt,
    required this.settledAt,
    required this.settlementDuration,
    required this.paymentId,
    required this.depositAddress,
    required this.expiresAt,
    required this.chargeFiat,
    required this.chargeCrypto,
    required this.transactionUsd,
  });

  factory _HistoryActivity.fromJson(Map<String, dynamic> json) {
    return _HistoryActivity(
      id: '${json['id'] ?? ''}',
      type: '${json['type'] ?? ''}',
      reference: '${json['reference'] ?? json['id'] ?? ''}',
      createdAt: DateTime.tryParse('${json['createdAt']}') ?? DateTime.now(),
      settlementAmount: '${json['settlementAmount'] ?? '0.00'}',
      cryptoAmount: '${json['cryptoAmount'] ?? '0.00000 USDT'}',
      crypto: '${json['crypto'] ?? 'USDT'}',
      network: '${json['network'] ?? 'TRC20'}',
      beneficiaryName: '${json['beneficiaryName'] ?? 'Beneficiary'}',
      bankName: '${json['bankName'] ?? 'Bank'}',
      accountNumber: '${json['accountNumber'] ?? ''}',
      accountName:
          '${json['accountName'] ?? json['beneficiaryName'] ?? 'Receiver'}',
      bankCode: '${json['bankCode'] ?? ''}',
      rate: '${json['rate'] ?? '...'}',
      status: '${json['status'] ?? 'funding'}',
      settlingStartedAt: '${json['settlingStartedAt'] ?? ''}',
      settledAt: '${json['settledAt'] ?? ''}',
      settlementDuration: '${json['settlementDuration'] ?? ''}',
      paymentId: '${json['paymentId'] ?? ''}',
      depositAddress: '${json['depositAddress'] ?? ''}',
      expiresAt: '${json['expiresAt'] ?? ''}',
      chargeFiat: '${json['chargeFiat'] ?? ''}',
      chargeCrypto: '${json['chargeCrypto'] ?? ''}',
      transactionUsd: '${json['transactionUsd'] ?? ''}',
    );
  }

  final String id;
  final String type;
  final String reference;
  final DateTime createdAt;
  final String settlementAmount;
  final String cryptoAmount;
  final String crypto;
  final String network;
  final String beneficiaryName;
  final String bankName;
  final String accountNumber;
  final String accountName;
  final String bankCode;
  final String rate;
  final String status;
  final String settlingStartedAt;
  final String settledAt;
  final String settlementDuration;
  final String paymentId;
  final String depositAddress;
  final String expiresAt;
  final String chargeFiat;
  final String chargeCrypto;
  final String transactionUsd;

  double get settlementValue =>
      double.tryParse(
          settlementAmount.replaceAll(',', '').replaceAll('₦', '')) ??
      0;

  double get transactedValue {
    if (isUnsuccessful) return 0;
    if (isReceivePayment && !isReceivePaid) return 0;
    return settlementValue;
  }

  bool get hasValue {
    final cryptoValue =
        double.tryParse(cryptoAmount.split(' ').first.trim()) ?? 0;
    return settlementValue > 0 || cryptoValue > 0;
  }

  String get dateLabel => DateTime.now().difference(createdAt).inHours < 48
      ? dateTimeFormat('relative', createdAt)
      : DateFormat('MMM d, yyyy; h:mm a').format(createdAt);

  String get cryptoOnlyAmount {
    if (isCreateGift) return 'Gift created';
    if (isGift) return 'Gift claim';
    if (isReceivePayment) return 'RECEIVE';
    final number = _roundDownCrypto(cryptoAmount.split(' ').first.trim());
    return '$number $crypto';
  }

  bool get isSettling => status.toLowerCase() == 'settling';
  bool get isSettled => status.toLowerCase() == 'settled';
  bool get isReceivePaid => status.toLowerCase() == 'paid';
  bool get isGift =>
      !isCreateGift &&
      (type == 'gift_claim' ||
          type == 'gift' ||
          crypto.toUpperCase() == 'GIFT');
  bool get isCreateGift =>
      type == 'create_gift' ||
      type == 'gift_create' ||
      type == 'gift_created' ||
      type == 'createGift';
  bool get isReceivePayment =>
      type == 'receive_payment' ||
      type == 'receive' ||
      type == 'payment_receive' ||
      type == 'receivePayment';
  bool get isPending => status.toLowerCase() == 'pending';
  bool get isReceiveUnpaid =>
      isReceivePayment &&
      (status.toLowerCase() == 'created' ||
          status.toLowerCase() == 'opened' ||
          status.toLowerCase() == 'partpaid' ||
          status.toLowerCase() == 'part_paid');
  bool get isUnsuccessful {
    final value = status.toLowerCase();
    return value == 'cancelled' ||
        value == 'canceled' ||
        value == 'expired' ||
        value == 'failed' ||
        value == 'unsuccessful' ||
        value == 'rejected';
  }

  IconData get historyIcon {
    if (isCreateGift) return Icons.deblur_rounded;
    if (isGift) return Icons.checklist_rtl_rounded;
    if (isReceivePayment) return Icons.check_rounded;
    return Icons.call_made_rounded;
  }

  Color get signalColor {
    if (isUnsuccessful) return const Color(0xFFD64242);
    if (isReceivePayment && isReceivePaid) return const Color(0xFF1E9D5A);
    if (isReceiveUnpaid) return const Color(0xFFE08A1E);
    if (isPending) return const Color(0xFFE08A1E);
    if (isSettling) return const Color(0xFF4472C4);
    if (isSettled) return const Color(0xFF1E9D5A);
    return const Color(0xFF4472C4);
  }

  IconData get signalIcon {
    if (isUnsuccessful) return Icons.cancel_rounded;
    if (isReceivePayment && isReceivePaid) return Icons.check_rounded;
    if (isReceiveUnpaid) return Icons.hourglass_empty_rounded;
    if (isPending) return Icons.hourglass_empty_rounded;
    return historyIcon;
  }

  String get typeFilterLabel {
    if (isCreateGift) return 'Gift created';
    if (isGift) return 'Gift claim';
    if (isReceivePayment) return 'Receive';
    return 'Send';
  }

  String get unsuccessfulLabel {
    final value = status.toLowerCase();
    if (value == 'expired') return 'Expired';
    if (value == 'failed' || value == 'unsuccessful') return 'Failed';
    if (value == 'rejected') return 'Rejected';
    return 'Cancelled';
  }

  String _roundDownCrypto(String value) {
    final parsed = double.tryParse(value.replaceAll(',', '').trim());
    if (parsed == null) return value;
    return ((parsed * 100000).floor() / 100000).toStringAsFixed(5);
  }

  String get accountLabel {
    if (isCreateGift) {
      if (isUnsuccessful) return '$unsuccessfulLabel gift $reference';
      return status.toLowerCase() == 'pending'
          ? 'Not funded gift $reference'
          : 'Created gift $reference';
    }
    if (isGift) {
      return '${isUnsuccessful ? unsuccessfulLabel : isSettled ? 'Settled' : 'Settling'} gift $reference to $accountTail';
    }
    if (isReceivePayment) {
      return '$beneficiaryName • ${rate.startsWith('https://') ? rate : reference}';
    }
    final lastDigits = accountNumber.length > 4
        ? accountNumber.substring(accountNumber.length - 4)
        : accountNumber;
    return '**** $lastDigits to $bankName';
  }

  Map<String, String> toQueryParameters() => {
        'id': id,
        'createdAt': createdAt.toIso8601String(),
        'settlementAmount': settlementAmount,
        'cryptoAmount': cryptoOnlyAmount,
        'crypto': crypto,
        'network': network,
        'beneficiaryName': beneficiaryName,
        'bankName': bankName,
        'accountNumber': accountNumber,
        'rate': rate,
        'status': status,
        'paymentId': paymentId,
        'depositAddress': depositAddress,
        'expiresAt': expiresAt,
        'chargeFiat': chargeFiat,
        'chargeCrypto': chargeCrypto,
        'transactionUsd': transactionUsd,
      };

  String get accountTail {
    if (accountNumber.length <= 4) return accountNumber;
    return '...${accountNumber.substring(accountNumber.length - 4)}';
  }

  String get formattedSettlementAmount {
    final parsed = double.tryParse(
      settlementAmount.replaceAll(',', '').replaceAll('₦', '').trim(),
    );
    if (parsed == null) return '₦$settlementAmount';
    return '₦${NumberFormat('#,##0.##', 'en_US').format(parsed)}';
  }

  Map<String, String> toGiftQueryParameters() => {
        'reference': reference,
        'type': isCreateGift ? 'create_gift' : 'gift_claim',
        'amount': '₦$settlementAmount',
        'bankName': bankName,
        'accountNumber': accountNumber,
        'accountName': accountName,
        'bankCode': bankCode,
        'status': status,
        'createdAt': createdAt.toIso8601String(),
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
