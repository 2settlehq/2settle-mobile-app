import 'dart:async';

import '/config/api_config.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/index.dart';
import '/services/auth_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dashboard_model.dart';
export 'dashboard_model.dart';

class DashboardWidget extends StatefulWidget {
  const DashboardWidget({super.key});

  static String routeName = 'Dashboard';
  static String routePath = 'dashboard';

  @override
  State<DashboardWidget> createState() => _DashboardWidgetState();
}

class _DashboardWidgetState extends State<DashboardWidget>
    with TickerProviderStateMixin {
  late DashboardModel _model;
  late AnimationController _ratePulseController;
  late Animation<double> _ratePulseScale;
  late PageController _updatesPageController;

  final scaffoldKey = GlobalKey<ScaffoldState>();
  static const _blue = Color(0xFF4472C4);
  static const _rateUrl = 'https://api.2settle.io/v1/rate';
  static const _transactionStorageKey = '2settle_initiated_transactions';
  static const _receiveStorageKey = '2settle_receive_requests';
  static const _giftHistoryStorageKey = '2settle_gift_history';
  static const _giftClaimBaseUrl = ApiConfig.giftsBaseUrl;
  static const _nativeChannel = MethodChannel('com.sirfitech.settleio/share');
  Timer? _rateTypingTimer;
  Timer? _rateRefreshTimer;
  Timer? _updatesTimer;
  Timer? _giftStatusTimer;
  String _todayRate = '';
  String _visibleRate = '****';
  String _lastUpdatedLabel = 'Last updated today';
  bool _showNgnRate = true;
  bool _isRateHidden = false;
  int _updatesPageIndex = 0;
  int _unreadNotifications = 0;
  int _rateNotificationPromptIndex = 0;
  String _displayName = 'Kayode';
  List<_DashboardActivity> _activities = [];

  static const _rateNotificationPrompts = [
    'Send money instantly now',
    'Spend money instantly now',
    'Settle transaction at the speed of light',
    'It is a good time to send some gift',
    'Request that payment now',
  ];

  static const _updates = [
    _UpdateSlideData(
      title: 'New release',
      body: 'Live rate switcher is now available on your home screen.',
      icon: Icons.rocket_launch_rounded,
    ),
    _UpdateSlideData(
      title: 'Market update',
      body: 'USDT/NGN refreshes automatically while you transact.',
      icon: Icons.trending_up_rounded,
    ),
    _UpdateSlideData(
      title: 'Complete receive details',
      body: 'Add bank, dollar, and wallet destinations for direct payments.',
      icon: Icons.fact_check_rounded,
      opensReceiveDetails: true,
    ),
    _UpdateSlideData(
      title: 'Announcement',
      body:
          'Send, receive, gift, and convert shortcuts are now easier to reach.',
      icon: Icons.campaign_rounded,
    ),
    _UpdateSlideData(
      title: 'Security',
      body: 'Hide live balances anytime from your dashboard.',
      icon: Icons.visibility_off_rounded,
    ),
    _UpdateSlideData(
      title: 'Coming next',
      body: 'Beneficiaries and settlement history are getting a cleaner flow.',
      icon: Icons.auto_awesome_rounded,
    ),
  ];

  void _openTab(int index) {
    switch (index) {
      case 1:
        context.pushNamed(MainTransactionWidget.routeName);
        break;
      case 2:
        context.pushNamed(AllServicesWidget.routeName);
        break;
      case 3:
        context
            .pushNamed(PayPageWidget.routeName)
            .then((_) => _loadActivities());
        break;
      case 4:
        context.pushNamed(SettingsWidget.routeName);
        break;
      default:
        break;
    }
  }

  Widget _quickServiceAction({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    final theme = FlutterFlowTheme.of(context);

    return Expanded(
      child: InkWell(
        splashColor: Colors.transparent,
        focusColor: Colors.transparent,
        hoverColor: Colors.transparent,
        highlightColor: Colors.transparent,
        onTap: onTap,
        borderRadius: BorderRadius.circular(10.0),
        child: Container(
          height: 68.0,
          margin: const EdgeInsets.symmetric(horizontal: 4.0),
          decoration: BoxDecoration(
            color: theme.primary,
            borderRadius: BorderRadius.circular(10.0),
            boxShadow: const [
              BoxShadow(
                blurRadius: 4.0,
                color: Color(0x26000000),
                offset: Offset(0.0, 2.0),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: Colors.white,
                size: 27.0,
              ),
              const SizedBox(height: 5.0),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.bodySmall.override(
                  font: TextStyle(
                    fontWeight: FontWeight.w500,
                    fontStyle: theme.bodySmall.fontStyle,
                  ),
                  color: Colors.white,
                  fontSize: 11.0,
                  letterSpacing: 0.0,
                  fontWeight: FontWeight.w500,
                  fontStyle: theme.bodySmall.fontStyle,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _rateToggleOption({
    required String label,
    required bool selected,
  }) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOut,
      padding: const EdgeInsetsDirectional.fromSTEB(8.0, 3.0, 8.0, 3.0),
      decoration: BoxDecoration(
        color: selected ? const Color(0xFF4472C4) : Colors.transparent,
        borderRadius: BorderRadius.circular(14.0),
      ),
      child: Text(
        label,
        style: GoogleFonts.inter(
          color: selected ? Colors.white : const Color(0xFF4472C4),
          fontSize: 10.0,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.0,
        ),
      ),
    );
  }

  Widget _updatesCarousel() {
    final theme = FlutterFlowTheme.of(context);

    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(18.0, 22.0, 18.0, 0.0),
      child: Column(
        children: [
          SizedBox(
            height: 104.0,
            child: PageView.builder(
              controller: _updatesPageController,
              itemCount: _updates.length,
              onPageChanged: (index) {
                safeSetState(() => _updatesPageIndex = index);
              },
              itemBuilder: (context, index) {
                final item = _updates[index];
                return InkWell(
                  onTap: item.opensReceiveDetails
                      ? () => context
                          .pushNamed(ReceivePaymentDetailsWidget.routeName)
                      : null,
                  borderRadius: BorderRadius.circular(10.0),
                  child: Container(
                    margin: const EdgeInsetsDirectional.fromSTEB(
                        2.0, 0.0, 2.0, 0.0),
                    padding: const EdgeInsetsDirectional.fromSTEB(
                        15.0, 13.0, 15.0, 13.0),
                    decoration: BoxDecoration(
                      color: const Color(0xFF4472C4).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10.0),
                      border: Border.all(
                        color: const Color(0xFF4472C4).withValues(alpha: 0.18),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 42.0,
                          height: 42.0,
                          decoration: BoxDecoration(
                            color: theme.primary,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            item.icon,
                            color: Colors.white,
                            size: 21.0,
                          ),
                        ),
                        const SizedBox(width: 12.0),
                        Expanded(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: theme.bodyMedium.override(
                                  font: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontStyle: theme.bodyMedium.fontStyle,
                                  ),
                                  color: theme.primaryText,
                                  fontSize: 13.5,
                                  letterSpacing: 0.0,
                                  fontWeight: FontWeight.w700,
                                  fontStyle: theme.bodyMedium.fontStyle,
                                ),
                              ),
                              const SizedBox(height: 5.0),
                              Text(
                                item.body,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: theme.bodySmall.override(
                                  font: TextStyle(
                                    fontWeight: FontWeight.w500,
                                    fontStyle: theme.bodySmall.fontStyle,
                                  ),
                                  color: theme.secondaryText,
                                  fontSize: 11.0,
                                  letterSpacing: 0.0,
                                  fontWeight: FontWeight.w500,
                                  fontStyle: theme.bodySmall.fontStyle,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 8.0),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(_updates.length, (index) {
              final selected = index == _updatesPageIndex;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                margin:
                    const EdgeInsetsDirectional.fromSTEB(3.0, 0.0, 3.0, 0.0),
                width: selected ? 14.0 : 5.0,
                height: 5.0,
                decoration: BoxDecoration(
                  color: selected
                      ? theme.primary
                      : theme.primary.withValues(alpha: 0.22),
                  borderRadius: BorderRadius.circular(5.0),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _activityCard({
    required String date,
    required String account,
    required String amountUsd,
    required String amountNgn,
    _DashboardActivity? activity,
  }) {
    final theme = FlutterFlowTheme.of(context);
    final signalColor = activity?.signalColor ?? _blue;
    return InkWell(
      splashColor: Colors.transparent,
      focusColor: Colors.transparent,
      hoverColor: Colors.transparent,
      highlightColor: Colors.transparent,
      onTap: () async {
        if ((activity?.isGift ?? false) || (activity?.isCreateGift ?? false)) {
          context.pushNamed(
            GiftClaimDetailsWidget.routeName,
            queryParameters: activity!.toGiftQueryParameters(),
          );
          return;
        }
        if (activity?.isReceivePayment ?? false) {
          context.pushNamed(
            ReceiveRequestDetailsWidget.routeName,
            queryParameters: {
              'requestId': serializeParam(activity!.id, ParamType.String),
            }.withoutNulls,
          );
          return;
        }
        context.pushNamed(
          TransactionDetailsWidget.routeName,
          queryParameters: activity?.toQueryParameters() ?? {},
          extra: <String, dynamic>{
            '__transition_info__': TransitionInfo(
              hasTransition: true,
              transitionType: PageTransitionType.rightToLeft,
            ),
          },
        );
      },
      child: Container(
        width: double.infinity,
        margin: const EdgeInsetsDirectional.fromSTEB(18.0, 0.0, 18.0, 0.0),
        padding: const EdgeInsetsDirectional.fromSTEB(2.0, 10.0, 2.0, 10.0),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: const Color(0xFFE2E5EA),
              width: 0.7,
            ),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 30.0,
              height: 30.0,
              decoration: BoxDecoration(
                color: signalColor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: activity?.isSettling ?? false
                  ? const Padding(
                      padding: EdgeInsets.all(8.0),
                      child: CircularProgressIndicator(
                        strokeWidth: 2.0,
                        valueColor: AlwaysStoppedAnimation<Color>(_blue),
                      ),
                    )
                  : Icon(
                      activity?.signalIcon ?? Icons.call_made_rounded,
                      color: signalColor,
                      size: 16.0,
                    ),
            ),
            const SizedBox(width: 4.0),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    date,
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
                    account,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.bodySmall.override(
                      font: TextStyle(
                        fontWeight: FontWeight.w500,
                        fontStyle: theme.bodySmall.fontStyle,
                      ),
                      color: theme.secondaryText,
                      fontSize: 11.0,
                      letterSpacing: 0.0,
                      fontWeight: FontWeight.w500,
                      fontStyle: theme.bodySmall.fontStyle,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10.0),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  amountUsd,
                  style: activity?.isGift ?? false
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
                          letterSpacing: 0.0,
                        ),
                ),
                const SizedBox(height: 3.0),
                Text(
                  amountNgn,
                  style: GoogleFonts.inter(
                    color: theme.grayIcon,
                    fontSize: 10.0,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.0,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _historyEmptyState() {
    final theme = FlutterFlowTheme.of(context);
    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(18.0, 0.0, 18.0, 4.0),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsetsDirectional.fromSTEB(14.0, 16.0, 14.0, 16.0),
        decoration: BoxDecoration(
          color: _blue.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(14.0),
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
                Icons.receipt_long_rounded,
                color: _blue,
                size: 23.0,
              ),
            ),
            const SizedBox(height: 9.0),
            Text(
              'No history yet',
              style: theme.bodySmall.override(
                font: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontStyle: theme.bodySmall.fontStyle,
                ),
                color: theme.primaryText,
                fontSize: 11.4,
                letterSpacing: 0.0,
                fontWeight: FontWeight.w600,
                fontStyle: theme.bodySmall.fontStyle,
              ),
            ),
            const SizedBox(height: 4.0),
            Text(
              'You are yet to send money.',
              textAlign: TextAlign.center,
              style: theme.bodySmall.override(
                font: TextStyle(
                  fontWeight: FontWeight.normal,
                  fontStyle: theme.bodySmall.fontStyle,
                ),
                color: theme.secondaryText,
                fontSize: 10.4,
                letterSpacing: 0.0,
                fontWeight: FontWeight.normal,
                fontStyle: theme.bodySmall.fontStyle,
              ),
            ),
          ],
        ),
      ),
    );
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
          .map((item) => _DashboardActivity.fromJson(
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
      // Keep the design fallback if stored activities are malformed.
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

  Future<void> _markGiftSettled(_DashboardActivity item) async {
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

  Future<void> _markGiftStatus(_DashboardActivity item, String status) async {
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

  double? _parseRate(dynamic value) {
    if (value is num && value.isFinite) {
      return value.toDouble();
    }
    if (value is String) {
      final parsed = double.tryParse(value.replaceAll(',', '').trim());
      if (parsed != null && parsed.isFinite) {
        return parsed;
      }
    }
    return null;
  }

  double? _parseRatePayload(dynamic payload) {
    final direct = _parseRate(payload);
    if (direct != null) {
      return direct;
    }

    if (payload is List) {
      for (final item in payload) {
        final parsed = _parseRatePayload(item);
        if (parsed != null) {
          return parsed;
        }
      }
      return null;
    }

    if (payload is! Map) {
      return null;
    }

    final keys = [
      'rate',
      'price',
      'value',
      'amount',
      'currentRate',
      'exchangeRate',
      'buyRate',
      'sellRate',
    ];

    for (final key in keys) {
      final parsed = _parseRate(payload[key]);
      if (parsed != null) {
        return parsed;
      }
    }

    for (final key in ['data', 'result']) {
      final nested = _parseRatePayload(payload[key]);
      if (nested != null) {
        return nested;
      }
    }

    return null;
  }

  String _formatNairaRate(double rate) {
    final roundedDown = (rate * 100).floor() / 100;
    return '₦${NumberFormat('#,##0.00', 'en_US').format(roundedDown)}';
  }

  String _formatLastUpdated(DateTime value) {
    final time = DateFormat('h:mma').format(value).toLowerCase();
    return 'Last updated today, $time';
  }

  String get _ratePairLabel => _showNgnRate ? 'USDT/NGN' : 'USDT/USD';

  String get _displayRateText {
    if (_isRateHidden) {
      return '****';
    }

    if (!_showNgnRate) {
      return '\$1.00';
    }

    return _visibleRate.isEmpty ? _todayRate : _visibleRate;
  }

  void _toggleRatePair() {
    safeSetState(() {
      _showNgnRate = !_showNgnRate;
    });
  }

  void _toggleRateVisibility() {
    safeSetState(() {
      _isRateHidden = !_isRateHidden;
    });
  }

  void _animateRate(String rate) {
    _rateTypingTimer?.cancel();
    _ratePulseController.stop();
    _ratePulseController.value = 0.0;

    safeSetState(() {
      _todayRate = rate;
      _visibleRate = '';
    });

    _rateTypingTimer =
        Timer.periodic(const Duration(milliseconds: 90), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_visibleRate.length >= _todayRate.length) {
        timer.cancel();
        _ratePulseController.repeat(reverse: true);
        return;
      }
      safeSetState(() {
        _visibleRate = _todayRate.substring(0, _visibleRate.length + 1);
      });
    });
  }

  Future<double?> _fetchRateFrom(String url) async {
    final response = await http.get(
      Uri.parse(url),
      headers: const {'accept': 'application/json'},
    ).timeout(const Duration(seconds: 6));

    if (response.statusCode < 200 || response.statusCode >= 300) {
      return null;
    }

    final raw = response.body.trim();
    dynamic payload;
    try {
      payload = raw.isEmpty ? null : jsonDecode(raw);
    } catch (_) {
      payload = raw;
    }

    final parsed = _parseRatePayload(payload);
    if (parsed != null) {
      return parsed;
    }

    final match = RegExp(r'-?\d[\d,]*(?:\.\d+)?').firstMatch(raw);
    return _parseRate(match?.group(0));
  }

  Future<void> _loadLiveRate() async {
    try {
      final rate = await _fetchRateFrom(_rateUrl);

      if (!mounted || rate == null) {
        return;
      }

      final formattedRate = _formatNairaRate(rate);
      safeSetState(() {
        _lastUpdatedLabel = _formatLastUpdated(DateTime.now());
      });

      if (formattedRate != _todayRate) {
        _animateRate(formattedRate);
      }
      await _showRateNotification(formattedRate);
    } catch (_) {
      // Keep the current visible rate if the endpoint is unavailable.
    }
  }

  Future<void> _showRateNotification(String rate) async {
    try {
      final prompt = _rateNotificationPrompts[
          _rateNotificationPromptIndex % _rateNotificationPrompts.length];
      _rateNotificationPromptIndex += 1;
      await _nativeChannel.invokeMethod('showRateNotification', {
        'title': '2Settle rate update',
        'body': 'Current USDT/NGN rate is $rate.\n$prompt',
      });
    } catch (_) {
      // Local phone notifications are Android-native; ignore if unavailable.
    }
  }

  Future<void> _loadUnreadNotifications() async {
    final count = await NotificationsWidget.unreadCount();
    if (!mounted) return;
    safeSetState(() => _unreadNotifications = count);
  }

  Future<void> _loadProfileName() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString('2settle_profile_username')?.trim();
    if (!mounted || stored == null || stored.isEmpty) return;
    final firstWord = stored.split(RegExp(r'\s+')).first;
    safeSetState(() => _displayName =
        '${firstWord[0].toUpperCase()}${firstWord.substring(1)}');
  }

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => DashboardModel());
    _updatesPageController = PageController(viewportFraction: 1.0);
    _ratePulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1050),
    );
    _ratePulseScale = Tween<double>(
      begin: 0.985,
      end: 1.035,
    ).animate(
      CurvedAnimation(
        parent: _ratePulseController,
        curve: Curves.easeInOut,
      ),
    );
    _loadLiveRate();
    _loadActivities();
    _giftStatusTimer = Timer.periodic(
      const Duration(seconds: 10),
      (_) => _refreshSettlingGifts(),
    );
    _refreshSettlingGifts();
    _loadUnreadNotifications();
    _loadProfileName();
    _rateRefreshTimer =
        Timer.periodic(const Duration(hours: 1), (_) => _loadLiveRate());
    _updatesTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (!mounted || !_updatesPageController.hasClients) return;
      final next = (_updatesPageIndex + 1) % _updates.length;
      _updatesPageController.animateToPage(
        next,
        duration: const Duration(milliseconds: 430),
        curve: Curves.easeInOutCubic,
      );
    });
  }

  @override
  void dispose() {
    _rateTypingTimer?.cancel();
    _rateRefreshTimer?.cancel();
    _updatesTimer?.cancel();
    _giftStatusTimer?.cancel();
    _ratePulseController.dispose();
    _updatesPageController.dispose();
    _model.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: scaffoldKey,
      backgroundColor: FlutterFlowTheme.of(context).primaryBackground,
      bottomNavigationBar: _HomeBottomNavigationBar(onTap: _openTab),
      body: SafeArea(
        top: true,
        child: SingleChildScrollView(
          padding: const EdgeInsetsDirectional.only(bottom: 18.0),
          child: Column(
            mainAxisSize: MainAxisSize.max,
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Padding(
                padding: EdgeInsetsDirectional.fromSTEB(16.0, 8.0, 16.0, 0.0),
                child: Row(
                  mainAxisSize: MainAxisSize.max,
                  children: [
                    Expanded(
                      child: Padding(
                        padding:
                            EdgeInsetsDirectional.fromSTEB(0.0, 0.0, 0.0, 0.0),
                        child: Column(
                          mainAxisSize: MainAxisSize.max,
                          mainAxisAlignment: MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisSize: MainAxisSize.max,
                              children: [
                                Text(
                                  'Welcome,',
                                  style: FlutterFlowTheme.of(context)
                                      .headlineSmall
                                      .override(
                                        fontFamily: 'Hornbill',
                                        font: TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontStyle:
                                              FlutterFlowTheme.of(context)
                                                  .headlineSmall
                                                  .fontStyle,
                                        ),
                                        fontSize: 17.0,
                                        letterSpacing: 0.0,
                                        fontWeight: FontWeight.w600,
                                        fontStyle: FlutterFlowTheme.of(context)
                                            .headlineSmall
                                            .fontStyle,
                                      ),
                                ),
                                Padding(
                                  padding: EdgeInsetsDirectional.fromSTEB(
                                      4.0, 0.0, 0.0, 0.0),
                                  child: Text(
                                    _displayName,
                                    style: FlutterFlowTheme.of(context)
                                        .headlineSmall
                                        .override(
                                          fontFamily: 'Hornbill',
                                          font: TextStyle(
                                            fontWeight: FontWeight.w600,
                                            fontStyle:
                                                FlutterFlowTheme.of(context)
                                                    .headlineSmall
                                                    .fontStyle,
                                          ),
                                          color: FlutterFlowTheme.of(context)
                                              .primary,
                                          fontSize: 17.0,
                                          letterSpacing: 0.0,
                                          fontWeight: FontWeight.w600,
                                          fontStyle:
                                              FlutterFlowTheme.of(context)
                                                  .headlineSmall
                                                  .fontStyle,
                                        ),
                                  ),
                                ),
                              ],
                            ),
                            Padding(
                              padding: EdgeInsetsDirectional.fromSTEB(
                                  0.0, 4.0, 0.0, 0.0),
                              child: Text(
                                'Settle transaction instantly.',
                                style: FlutterFlowTheme.of(context)
                                    .bodyMedium
                                    .override(
                                      font: TextStyle(
                                        fontWeight: FontWeight.normal,
                                        fontStyle: FlutterFlowTheme.of(context)
                                            .bodyMedium
                                            .fontStyle,
                                      ),
                                      color:
                                          FlutterFlowTheme.of(context).grayIcon,
                                      fontSize: 12.0,
                                      letterSpacing: 0.0,
                                      fontWeight: FontWeight.normal,
                                      fontStyle: FlutterFlowTheme.of(context)
                                          .bodyMedium
                                          .fontStyle,
                                    ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 10.0),
                    InkWell(
                      splashColor: Colors.transparent,
                      focusColor: Colors.transparent,
                      hoverColor: Colors.transparent,
                      highlightColor: Colors.transparent,
                      onTap: () async {
                        await context.pushNamed(NotificationsWidget.routeName);
                        _loadUnreadNotifications();
                      },
                      borderRadius: BorderRadius.circular(18.0),
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Container(
                            width: 40.0,
                            height: 40.0,
                            decoration: BoxDecoration(
                              color: FlutterFlowTheme.of(context)
                                  .secondaryBackground,
                              shape: BoxShape.circle,
                              boxShadow: const [
                                BoxShadow(
                                  blurRadius: 5.0,
                                  color: Color(0x22000000),
                                  offset: Offset(0.0, 2.0),
                                ),
                              ],
                            ),
                            child: Icon(
                              Icons.notifications_none_rounded,
                              color: FlutterFlowTheme.of(context).primary,
                              size: 22.0,
                            ),
                          ),
                          if (_unreadNotifications > 0)
                            Positioned(
                              top: -3.0,
                              right: -3.0,
                              child: Container(
                                constraints: const BoxConstraints(
                                  minWidth: 18.0,
                                  minHeight: 18.0,
                                ),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 5.0,
                                  vertical: 2.0,
                                ),
                                decoration: const BoxDecoration(
                                  color: Color(0xFFD84A3A),
                                  shape: BoxShape.circle,
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  _unreadNotifications > 9
                                      ? '9+'
                                      : '$_unreadNotifications',
                                  style: GoogleFonts.inter(
                                    color: Colors.white,
                                    fontSize: 9.0,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8.0),
                    InkWell(
                      splashColor: Colors.transparent,
                      focusColor: Colors.transparent,
                      hoverColor: Colors.transparent,
                      highlightColor: Colors.transparent,
                      onTap: () async {
                        await AuthService.logout();
                        if (!context.mounted) return;
                        context.goNamed(LoginWidget.routeName);
                      },
                      borderRadius: BorderRadius.circular(18.0),
                      child: Container(
                        width: 40.0,
                        height: 40.0,
                        decoration: BoxDecoration(
                          color:
                              FlutterFlowTheme.of(context).secondaryBackground,
                          shape: BoxShape.circle,
                          boxShadow: const [
                            BoxShadow(
                              blurRadius: 5.0,
                              color: Color(0x22000000),
                              offset: Offset(0.0, 2.0),
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.logout_rounded,
                          color: FlutterFlowTheme.of(context).primary,
                          size: 21.0,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: EdgeInsetsDirectional.fromSTEB(0.0, 12.0, 0.0, 0.0),
                child: Row(
                  mainAxisSize: MainAxisSize.max,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: MediaQuery.sizeOf(context).width * 0.92,
                      child: Stack(
                        children: [
                          Positioned.fill(
                            top: 10.0,
                            left: 10.0,
                            child: Container(
                              decoration: BoxDecoration(
                                color: const Color(0xFF4472C4)
                                    .withValues(alpha: 0.18),
                                borderRadius: BorderRadius.circular(10.0),
                              ),
                            ),
                          ),
                          Container(
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: FlutterFlowTheme.of(context).tertiary,
                              image: DecorationImage(
                                fit: BoxFit.cover,
                                image: Image.asset(
                                  'assets/images/g2t7j_2.jpg',
                                ).image,
                              ),
                              boxShadow: const [
                                BoxShadow(
                                  blurRadius: 6.0,
                                  color: Color(0x4B1A1F24),
                                  offset: Offset(0.0, 2.0),
                                )
                              ],
                              borderRadius: BorderRadius.circular(8.0),
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.max,
                              children: [
                                Padding(
                                  padding: const EdgeInsetsDirectional.fromSTEB(
                                      18.0, 14.0, 12.0, 0.0),
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    children: [
                                      Expanded(
                                        child: Text(
                                          'Today\'s rate',
                                          textAlign: TextAlign.left,
                                          style: FlutterFlowTheme.of(context)
                                              .bodyMedium
                                              .override(
                                                font: TextStyle(
                                                  fontWeight: FontWeight.w700,
                                                  fontStyle:
                                                      FlutterFlowTheme.of(
                                                              context)
                                                          .bodyMedium
                                                          .fontStyle,
                                                ),
                                                color: const Color(0xFF232B31)
                                                    .withValues(alpha: 0.72),
                                                fontSize: 17.0,
                                                fontWeight: FontWeight.w700,
                                                letterSpacing: 0.0,
                                                fontStyle:
                                                    FlutterFlowTheme.of(context)
                                                        .bodyMedium
                                                        .fontStyle,
                                              ),
                                        ),
                                      ),
                                      InkWell(
                                        splashColor: Colors.transparent,
                                        focusColor: Colors.transparent,
                                        hoverColor: Colors.transparent,
                                        highlightColor: Colors.transparent,
                                        onTap: _toggleRatePair,
                                        borderRadius:
                                            BorderRadius.circular(18.0),
                                        child: Container(
                                          height: 30.0,
                                          padding: const EdgeInsetsDirectional
                                              .fromSTEB(4.0, 4.0, 4.0, 4.0),
                                          decoration: BoxDecoration(
                                            color: Colors.white
                                                .withValues(alpha: 0.82),
                                            borderRadius:
                                                BorderRadius.circular(18.0),
                                            border: Border.all(
                                              color: const Color(0xFF4472C4)
                                                  .withValues(alpha: 0.28),
                                            ),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              _rateToggleOption(
                                                label: 'NGN',
                                                selected: _showNgnRate,
                                              ),
                                              _rateToggleOption(
                                                label: 'USD',
                                                selected: !_showNgnRate,
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 6.0),
                                      InkWell(
                                        splashColor: Colors.transparent,
                                        focusColor: Colors.transparent,
                                        hoverColor: Colors.transparent,
                                        highlightColor: Colors.transparent,
                                        onTap: _toggleRateVisibility,
                                        borderRadius:
                                            BorderRadius.circular(16.0),
                                        child: Container(
                                          width: 30.0,
                                          height: 30.0,
                                          decoration: BoxDecoration(
                                            color: Colors.white
                                                .withValues(alpha: 0.82),
                                            shape: BoxShape.circle,
                                            border: Border.all(
                                              color: const Color(0xFF4472C4)
                                                  .withValues(alpha: 0.28),
                                            ),
                                          ),
                                          child: Icon(
                                            _isRateHidden
                                                ? Icons.visibility_off_rounded
                                                : Icons.visibility_rounded,
                                            color: const Color(0xFF4472C4),
                                            size: 17.0,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsetsDirectional.fromSTEB(
                                      20.0, 2.0, 20.0, 0.0),
                                  child: AnimatedBuilder(
                                    animation: _ratePulseController,
                                    builder: (context, child) {
                                      final glow = 0.18 +
                                          (_ratePulseController.value * 0.34);
                                      return Transform.scale(
                                        scale: _ratePulseScale.value,
                                        child: Text(
                                          _displayRateText,
                                          textAlign: TextAlign.center,
                                          style: GoogleFonts.inter(
                                            color: const Color(0xFF4472C4),
                                            fontSize: 41.0,
                                            fontWeight: FontWeight.w900,
                                            letterSpacing: 0.0,
                                            shadows: [
                                              Shadow(
                                                blurRadius: 18.0,
                                                color: const Color(0xFF4472C4)
                                                    .withValues(alpha: glow),
                                              ),
                                            ],
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsetsDirectional.fromSTEB(
                                      20.0, 0.0, 20.0, 16.0),
                                  child: Column(
                                    children: [
                                      Text(
                                        _lastUpdatedLabel,
                                        textAlign: TextAlign.center,
                                        style: FlutterFlowTheme.of(context)
                                            .bodySmall
                                            .override(
                                              font: TextStyle(
                                                fontWeight: FontWeight.w500,
                                                fontStyle:
                                                    FlutterFlowTheme.of(context)
                                                        .bodySmall
                                                        .fontStyle,
                                              ),
                                              color: const Color(0xFF232B31)
                                                  .withValues(alpha: 0.56),
                                              fontSize: 11.0,
                                              fontWeight: FontWeight.w500,
                                              letterSpacing: 0.0,
                                              fontStyle:
                                                  FlutterFlowTheme.of(context)
                                                      .bodySmall
                                                      .fontStyle,
                                            ),
                                      ),
                                      const SizedBox(height: 3.0),
                                      Text(
                                        _ratePairLabel,
                                        textAlign: TextAlign.center,
                                        style: GoogleFonts.inter(
                                          color: const Color(0xFF232B31)
                                              .withValues(alpha: 0.58),
                                          fontSize: 10.5,
                                          fontWeight: FontWeight.w700,
                                          letterSpacing: 0.0,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: EdgeInsetsDirectional.fromSTEB(0.0, 20.0, 0.0, 0.0),
                child: Container(
                  width: MediaQuery.sizeOf(context).width * 1.0,
                  decoration: BoxDecoration(
                    color: FlutterFlowTheme.of(context).secondaryBackground,
                    boxShadow: [
                      BoxShadow(
                        blurRadius: 4.0,
                        color: Color(0x39000000),
                        offset: Offset(
                          0.0,
                          -1.0,
                        ),
                      )
                    ],
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(16.0),
                      topRight: Radius.circular(16.0),
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.max,
                    children: [
                      Padding(
                        padding: EdgeInsetsDirectional.fromSTEB(
                            20.0, 16.0, 20.0, 0.0),
                        child: Row(
                          mainAxisSize: MainAxisSize.max,
                          children: [
                            Text(
                              'Quick Service',
                              style: FlutterFlowTheme.of(context)
                                  .bodyMedium
                                  .override(
                                    font: TextStyle(
                                      fontWeight: FontWeight.w500,
                                      fontStyle: FlutterFlowTheme.of(context)
                                          .bodyMedium
                                          .fontStyle,
                                    ),
                                    color: Color(0xFF4472C4),
                                    letterSpacing: 0.0,
                                    fontWeight: FontWeight.w500,
                                    fontStyle: FlutterFlowTheme.of(context)
                                        .bodyMedium
                                        .fontStyle,
                                  ),
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: EdgeInsetsDirectional.fromSTEB(
                            16.0, 12.0, 16.0, 0.0),
                        child: Row(
                          mainAxisSize: MainAxisSize.max,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _quickServiceAction(
                              icon: Icons.account_balance_wallet_rounded,
                              label: 'Receive',
                              onTap: () {
                                context.pushNamed(PayPageWidget.routeName).then(
                                      (_) => _loadActivities(),
                                    );
                              },
                            ),
                            _quickServiceAction(
                              icon: Icons.card_giftcard_rounded,
                              label: 'Gift',
                              onTap: () {
                                context.pushNamed(GiftWidget.routeName);
                              },
                            ),
                            _quickServiceAction(
                              icon: Icons.currency_exchange_rounded,
                              label: 'Convert',
                              onTap: () {
                                context.pushNamed(
                                  ConvertWidget.routeName,
                                  extra: <String, dynamic>{
                                    '__transition_info__': TransitionInfo(
                                      hasTransition: true,
                                      transitionType:
                                          PageTransitionType.rightToLeft,
                                    ),
                                  },
                                );
                              },
                            ),
                            _quickServiceAction(
                              icon: Icons.account_balance_outlined,
                              label: 'Bank',
                              onTap: () {
                                context
                                    .pushNamed(AccountDetailsWidget.routeName);
                              },
                            ),
                          ],
                        ),
                      ),
                      _updatesCarousel(),
                      Padding(
                        padding: EdgeInsetsDirectional.fromSTEB(
                            20.0, 24.0, 20.0, 12.0),
                        child: Row(
                          mainAxisSize: MainAxisSize.max,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'History',
                              style: FlutterFlowTheme.of(context)
                                  .bodyMedium
                                  .override(
                                    font: TextStyle(
                                      fontWeight: FontWeight.w500,
                                      fontStyle: FlutterFlowTheme.of(context)
                                          .bodyMedium
                                          .fontStyle,
                                    ),
                                    color: Color(0xFF4472C4),
                                    letterSpacing: 0.0,
                                    fontWeight: FontWeight.w500,
                                    fontStyle: FlutterFlowTheme.of(context)
                                        .bodyMedium
                                        .fontStyle,
                                  ),
                            ),
                            InkWell(
                              splashColor: Colors.transparent,
                              focusColor: Colors.transparent,
                              hoverColor: Colors.transparent,
                              highlightColor: Colors.transparent,
                              onTap: () async {
                                context.pushNamed(HistoryWidget.routeName);
                              },
                              child: Icon(
                                Icons.history_rounded,
                                color: Color(0xFF4472C4),
                                size: 22.0,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (_activities.isEmpty)
                        _historyEmptyState()
                      else ...[
                        ..._activities.take(3).map(
                              (activity) => _activityCard(
                                date: activity.dateLabel,
                                account: activity.accountLabel,
                                amountUsd: activity.cryptoOnlyAmount,
                                amountNgn: activity.formattedSettlementAmount,
                                activity: activity,
                              ),
                            ),
                        if (_activities.length > 3)
                          Padding(
                            padding: const EdgeInsetsDirectional.fromSTEB(
                                20.0, 8.0, 20.0, 0.0),
                            child: Align(
                              alignment: AlignmentDirectional.centerEnd,
                              child: InkWell(
                                onTap: () =>
                                    context.pushNamed(HistoryWidget.routeName),
                                borderRadius: BorderRadius.circular(14.0),
                                child: Padding(
                                  padding: const EdgeInsetsDirectional.fromSTEB(
                                      10.0, 6.0, 10.0, 6.0),
                                  child: Text(
                                    'View all',
                                    style: FlutterFlowTheme.of(context)
                                        .bodySmall
                                        .override(
                                          color: _blue,
                                          fontSize: 11.0,
                                          letterSpacing: 0.0,
                                          fontWeight: FontWeight.w700,
                                        ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],
                      const SizedBox(height: 22.0),
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

class _HomeBottomNavigationBar extends StatefulWidget {
  const _HomeBottomNavigationBar({
    required this.onTap,
  });

  final ValueChanged<int> onTap;

  @override
  State<_HomeBottomNavigationBar> createState() =>
      _HomeBottomNavigationBarState();
}

class _DashboardActivity {
  const _DashboardActivity({
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

  factory _DashboardActivity.fromJson(Map<String, dynamic> json) {
    return _DashboardActivity(
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

  String _roundDownCrypto(String value) {
    final parsed = double.tryParse(value.replaceAll(',', '').trim());
    if (parsed == null) return value;
    return ((parsed * 100000).floor() / 100000).toStringAsFixed(5);
  }

  bool get hasValue {
    final settlement = double.tryParse(
            settlementAmount.replaceAll(',', '').replaceAll('₦', '')) ??
        0;
    final cryptoValue =
        double.tryParse(cryptoAmount.split(' ').first.trim()) ?? 0;
    return settlement > 0 || cryptoValue > 0;
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
  bool get isSettling => status.toLowerCase() == 'settling';
  bool get isSettled => status.toLowerCase() == 'settled';
  bool get isReceivePaid => status.toLowerCase() == 'paid';
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

  String get formattedSettlementAmount {
    final parsed = double.tryParse(
      settlementAmount.replaceAll(',', '').replaceAll('₦', '').trim(),
    );
    if (parsed == null) return '₦$settlementAmount';
    return '₦${NumberFormat('#,##0.##', 'en_US').format(parsed)}';
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

class _HomeBottomNavigationBarState extends State<_HomeBottomNavigationBar>
    with SingleTickerProviderStateMixin {
  late AnimationController _avatarPulseController;
  late Animation<double> _avatarPulseScale;

  @override
  void initState() {
    super.initState();
    _avatarPulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..repeat(reverse: true);
    _avatarPulseScale = Tween<double>(
      begin: 0.96,
      end: 1.08,
    ).animate(
      CurvedAnimation(
        parent: _avatarPulseController,
        curve: Curves.easeInOut,
      ),
    );
  }

  @override
  void dispose() {
    _avatarPulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    final items = const [
      _NavItem(Icons.home_rounded, 'Home'),
      _NavItem(Icons.swap_horiz_rounded, 'Send'),
      _NavItem(Icons.circle, ''),
      _NavItem(Icons.account_balance_wallet_rounded, 'Receive'),
      _NavItem(Icons.settings_rounded, 'Settings'),
    ];

    return Container(
      padding: EdgeInsetsDirectional.fromSTEB(
        8.0,
        6.0,
        8.0,
        6.0 + MediaQuery.paddingOf(context).bottom,
      ),
      decoration: BoxDecoration(
        color: theme.secondaryBackground,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(18.0),
          topRight: Radius.circular(18.0),
        ),
        boxShadow: const [
          BoxShadow(
            blurRadius: 10.0,
            color: Color(0x18000000),
            offset: Offset(0.0, -2.0),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: List.generate(items.length, (index) {
          final item = items[index];
          final selected = index == 0;
          final isCenter = index == 2;

          return Expanded(
            child: InkWell(
              onTap: () => widget.onTap(index),
              borderRadius: BorderRadius.circular(isCenter ? 36.0 : 14.0),
              child: Container(
                height: isCenter ? 74.0 : 54.0,
                decoration: BoxDecoration(
                  color: selected && !isCenter
                      ? theme.primary.withValues(alpha: 0.1)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(isCenter ? 36.0 : 14.0),
                ),
                child: isCenter
                    ? _buildCenterAvatar(theme)
                    : _buildNavItem(context, item, selected),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildCenterAvatar(FlutterFlowTheme theme) {
    return Center(
      child: ScaleTransition(
        scale: _avatarPulseScale,
        child: Container(
          width: 68.0,
          height: 68.0,
          padding: const EdgeInsets.all(3.0),
          decoration: BoxDecoration(
            color: theme.primary,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                blurRadius: 14.0,
                color: theme.primary.withValues(alpha: 0.35),
                offset: const Offset(0.0, 4.0),
              ),
            ],
          ),
          child: ClipOval(
            child: Image.asset(
              'assets/images/app_launcher_icon.jpg',
              fit: BoxFit.cover,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(BuildContext context, _NavItem item, bool selected) {
    final theme = FlutterFlowTheme.of(context);

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          item.icon,
          color: selected ? theme.primary : theme.secondaryText,
          size: 22.0,
        ),
        const SizedBox(height: 3.0),
        Text(
          item.label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: theme.bodySmall.override(
            font: GoogleFonts.inter(
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              fontStyle: theme.bodySmall.fontStyle,
            ),
            color: selected ? theme.primary : theme.secondaryText,
            fontSize: 10.5,
            letterSpacing: 0.0,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            fontStyle: theme.bodySmall.fontStyle,
          ),
        ),
      ],
    );
  }
}

class _UpdateSlideData {
  const _UpdateSlideData({
    required this.title,
    required this.body,
    required this.icon,
    this.opensReceiveDetails = false,
  });

  final String title;
  final String body;
  final IconData icon;
  final bool opensReceiveDetails;
}

class _NavItem {
  const _NavItem(this.icon, this.label);

  final IconData icon;
  final String label;
}
