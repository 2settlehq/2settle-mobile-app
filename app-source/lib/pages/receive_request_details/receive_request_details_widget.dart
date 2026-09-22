import '/services/payment_request_service.dart';
import '/components/top_notice.dart';
import '/flutter_flow/flutter_flow_icon_button.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/index.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ReceiveRequestDetailsWidget extends StatefulWidget {
  const ReceiveRequestDetailsWidget({
    super.key,
    required this.requestId,
  });

  static String routeName = 'ReceiveRequestDetails';
  static String routePath = 'receiveRequestDetails';

  final String requestId;

  @override
  State<ReceiveRequestDetailsWidget> createState() =>
      _ReceiveRequestDetailsWidgetState();
}

class _ReceiveRequestDetailsWidgetState
    extends State<ReceiveRequestDetailsWidget> {
  static const _blue = Color(0xFF4472C4);
  static const _storageKey = '2settle_receive_requests';
  static const _transactionStorageKey = '2settle_initiated_transactions';

  _ReceiveRequest? _request;
  bool _isLoading = true;
  bool _isConfirmingPaid = false;

  @override
  void initState() {
    super.initState();
    _loadRequest();
  }

  Future<void> _loadRequest() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString(_storageKey);
    if (stored == null || stored.isEmpty) {
      if (mounted) safeSetState(() => _isLoading = false);
      return;
    }
    try {
      final decoded = jsonDecode(stored);
      if (decoded is! List) {
        if (mounted) safeSetState(() => _isLoading = false);
        return;
      }
      final requests = decoded
          .whereType<Map>()
          .map((item) => _ReceiveRequest.fromJson(
                Map<String, dynamic>.from(item),
              ))
          .toList();
      final found = requests
          .where((item) => item.id == widget.requestId)
          .cast<_ReceiveRequest?>()
          .firstOrNull;
      if (!mounted) return;
      safeSetState(() {
        _request = found;
        _isLoading = false;
      });
    } catch (_) {
      if (mounted) safeSetState(() => _isLoading = false);
    }
  }

  int get _statusIndex {
    switch (_request?.status) {
      case 'opened':
        return 1;
      case 'partPaid':
        return 2;
      case 'paid':
        return 3;
      default:
        return 0;
    }
  }

  String get _statusLabel {
    switch (_request?.status) {
      case 'opened':
        return 'Opened';
      case 'partPaid':
        return 'Part paid';
      case 'paid':
        return 'Paid';
      default:
        return 'Created';
    }
  }

  Future<void> _persistStatus(String status) async {
    final request = _request;
    if (request == null) return;
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString(_storageKey);
    if (stored == null || stored.isEmpty) return;
    try {
      final decoded = jsonDecode(stored);
      if (decoded is! List) return;
      final updated = decoded.map((item) {
        if (item is Map && item['id']?.toString() == request.id) {
          final next = Map<String, dynamic>.from(item);
          next['status'] = status;
          next['statusUpdatedAt'] = DateTime.now().toIso8601String();
          return next;
        }
        return item;
      }).toList();
      await prefs.setString(_storageKey, jsonEncode(updated));
      await _syncActivityStatus(status);
    } catch (_) {}
  }

  Future<void> _syncActivityStatus(String status) async {
    final request = _request;
    if (request == null) return;
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString(_transactionStorageKey);
    if (stored == null || stored.isEmpty) return;
    try {
      final decoded = jsonDecode(stored);
      if (decoded is! List) return;
      final updated = decoded.map((item) {
        if (item is Map && item['id']?.toString() == request.id) {
          final next = Map<String, dynamic>.from(item);
          next['status'] = status;
          return next;
        }
        return item;
      }).toList();
      await prefs.setString(_transactionStorageKey, jsonEncode(updated));
    } catch (_) {}
  }

  Future<void> _setStatus(String status) async {
    final request = _request;
    if (request == null) return;
    safeSetState(() => _request = request.copyWith(status: status));
    await _persistStatus(status);
  }

  Future<void> _confirmPaid() async {
    if (_isConfirmingPaid || _request == null) return;
    safeSetState(() => _isConfirmingPaid = true);
    for (final status in const ['opened', 'partPaid', 'paid']) {
      await Future.delayed(const Duration(milliseconds: 420));
      if (!mounted) return;
      await _setStatus(status);
    }
    if (!mounted) return;
    safeSetState(() => _isConfirmingPaid = false);
    showTopNotice(context, message: 'Receive request marked as paid.');
  }

  String get _link {
    final id = _request?.id ?? widget.requestId;
    return paymentRequestLink(id);
  }

  Future<void> _copyLink() async {
    if (_link.isEmpty) {
      showTopNotice(context,
          message:
              'This old request has no payment link. Create a new payment request.');
      return;
    }
    await Clipboard.setData(ClipboardData(text: _link));
    if (!mounted) return;
    showTopNotice(context, message: 'Payment link copied.');
  }

  Future<void> _shareLink() async {
    if (_link.isEmpty) {
      showTopNotice(context,
          message:
              'This old request has no payment link. Create a new payment request.');
      return;
    }
    final request = _request;
    final text = request == null
        ? _link
        : 'Pay ${request.currency} ${request.amount} for ${request.description}\n$_link';
    await Clipboard.setData(ClipboardData(text: text));
    if (!mounted) return;
    showTopNotice(context, message: 'Share text copied.');
  }

  String _formatMoney(String currency, String amount) {
    final symbol = currency.toUpperCase() == 'NGN'
        ? '₦'
        : currency.toUpperCase() == 'USD'
            ? r'$'
            : currency;
    final parsed = double.tryParse(amount.replaceAll(',', '').trim());
    if (parsed == null) return '$symbol$amount';
    final fixed = parsed == parsed.truncateToDouble()
        ? parsed.toStringAsFixed(0)
        : parsed.toStringAsFixed(2);
    final parts = fixed.split('.');
    final whole = parts.first;
    final buffer = StringBuffer();
    for (var index = 0; index < whole.length; index++) {
      final remaining = whole.length - index;
      buffer.write(whole[index]);
      if (remaining > 1 && remaining % 3 == 1) buffer.write(',');
    }
    final value = parts.length > 1
        ? '${buffer.toString()}.${parts.last}'
        : buffer.toString();
    return '$symbol$value';
  }

  String _historyTimeLabel(DateTime value) {
    final difference = DateTime.now().difference(value);
    if (difference.inHours < 48) {
      return '${dateTimeFormat('relative', value)} • ${DateFormat('h:mm a').format(value)}';
    }
    return DateFormat('MMM d, yyyy • h:mm a').format(value);
  }

  Widget _statusStep({
    required String label,
    required IconData icon,
    required int index,
    bool withMenu = false,
  }) {
    final theme = FlutterFlowTheme.of(context);
    final active = _statusIndex >= index;
    final circle = AnimatedContainer(
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOutCubic,
      width: 32.0,
      height: 32.0,
      decoration: BoxDecoration(
        color: active ? _blue : const Color(0xFFE7ECF3),
        shape: BoxShape.circle,
        boxShadow: active
            ? [
                BoxShadow(
                  color: _blue.withValues(alpha: 0.28),
                  blurRadius: 10.0,
                  offset: const Offset(0.0, 4.0),
                ),
              ]
            : null,
      ),
      child: _isConfirmingPaid && index == _statusIndex + 1
          ? const Padding(
              padding: EdgeInsets.all(8.0),
              child: CircularProgressIndicator(
                strokeWidth: 2.0,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            )
          : Icon(
              icon,
              color: active ? Colors.white : theme.secondaryText,
              size: 16.0,
            ),
    );

    return Expanded(
      child: Column(
        children: [
          if (withMenu)
            PopupMenuButton<String>(
              tooltip: 'Update status',
              onSelected: (value) {
                if (value == 'paid') {
                  _confirmPaid();
                } else {
                  _setStatus(value);
                }
              },
              itemBuilder: (context) => const [
                PopupMenuItem(value: 'created', child: Text('Created')),
                PopupMenuItem(value: 'opened', child: Text('Opened')),
                PopupMenuItem(value: 'partPaid', child: Text('Part paid')),
                PopupMenuItem(value: 'paid', child: Text('Confirm paid')),
              ],
              child: circle,
            )
          else
            circle,
          const SizedBox(height: 5.0),
          Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.inter(
              color: active ? _blue : theme.secondaryText,
              fontSize: 9.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _statusConnector(int beforeIndex) {
    final active = _statusIndex > beforeIndex;
    return Expanded(
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
        height: 3.0,
        margin: const EdgeInsetsDirectional.only(bottom: 20.0),
        decoration: BoxDecoration(
          color: active ? _blue : const Color(0xFFE7ECF3),
          borderRadius: BorderRadius.circular(4.0),
        ),
      ),
    );
  }

  Widget _iconAction({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    final theme = FlutterFlowTheme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14.0),
      child: Container(
        padding: const EdgeInsetsDirectional.fromSTEB(10.0, 9.0, 10.0, 9.0),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14.0),
          border: Border.all(color: const Color(0xFFE7ECF3)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 34.0,
              height: 34.0,
              decoration: const BoxDecoration(
                color: _blue,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: Colors.white, size: 17.0),
            ),
            const SizedBox(height: 5.0),
            Text(
              label,
              style: theme.bodySmall.override(
                color: theme.primaryText,
                fontSize: 10.2,
                letterSpacing: 0.0,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    final theme = FlutterFlowTheme.of(context);
    return Padding(
      padding: const EdgeInsetsDirectional.symmetric(vertical: 6.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              label,
              style: theme.bodySmall.override(
                color: theme.secondaryText,
                fontSize: 11.0,
                letterSpacing: 0.0,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(width: 12.0),
          Expanded(
            flex: 2,
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: GoogleFonts.inter(
                color: theme.primaryText,
                fontSize: 11.2,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _paymentLinkRow() {
    final theme = FlutterFlowTheme.of(context);
    return Padding(
      padding: const EdgeInsetsDirectional.symmetric(vertical: 6.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            'Payment link',
            style: theme.bodySmall.override(
              color: theme.secondaryText,
              fontSize: 11.0,
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
                Flexible(
                  child: Text(
                    _link,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      color: theme.primaryText,
                      fontSize: 11.2,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(width: 8.0),
                InkWell(
                  onTap: _copyLink,
                  borderRadius: BorderRadius.circular(12.0),
                  child: Container(
                    width: 26.0,
                    height: 26.0,
                    decoration: BoxDecoration(
                      color: _blue.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.copy_rounded,
                      color: _blue,
                      size: 14.0,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    final request = _request;
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF4F6FA),
        automaticallyImplyLeading: false,
        elevation: 0.0,
        leading: FlutterFlowIconButton(
          borderColor: Colors.transparent,
          borderRadius: 30.0,
          buttonSize: 48.0,
          icon: Icon(Icons.arrow_back_rounded,
              color: theme.primaryText, size: 24.0),
          onPressed: () => context.goNamed(PayPageWidget.routeName),
        ),
        title: Text(
          'Receive Request',
          style: theme.titleMedium.override(
            color: theme.primaryText,
            fontSize: 18.0,
            letterSpacing: 0.0,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      body: SafeArea(
        top: false,
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(_blue),
                ),
              )
            : request == null
                ? Center(
                    child: Text(
                      'Receive request not found.',
                      style: theme.bodyMedium.override(
                        color: theme.secondaryText,
                        letterSpacing: 0.0,
                      ),
                    ),
                  )
                : ListView(
                    padding: const EdgeInsetsDirectional.fromSTEB(
                        18.0, 10.0, 18.0, 26.0),
                    children: [
                      Container(
                        padding: const EdgeInsetsDirectional.fromSTEB(
                            16.0, 16.0, 16.0, 16.0),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(18.0),
                          border: Border.all(color: const Color(0xFFE7ECF3)),
                        ),
                        child: Column(
                          children: [
                            Container(
                              width: 54.0,
                              height: 54.0,
                              decoration: BoxDecoration(
                                color: _blue.withValues(alpha: 0.12),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.qr_code_2_rounded,
                                  color: _blue, size: 26.0),
                            ),
                            const SizedBox(height: 10.0),
                            Text(
                              _formatMoney(request.currency, request.amount),
                              textAlign: TextAlign.center,
                              style: GoogleFonts.inter(
                                color: _blue,
                                fontSize: 28.0,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 4.0),
                            Text(
                              request.description,
                              textAlign: TextAlign.center,
                              style: theme.bodySmall.override(
                                color: theme.secondaryText,
                                fontSize: 11.0,
                                letterSpacing: 0.0,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 16.0),
                            Row(
                              children: [
                                _statusStep(
                                  label: 'Created',
                                  icon: Icons.check_rounded,
                                  index: 0,
                                ),
                                _statusConnector(0),
                                _statusStep(
                                  label: 'Opened',
                                  icon: Icons.visibility_rounded,
                                  index: 1,
                                ),
                                _statusConnector(1),
                                _statusStep(
                                  label: 'Part paid',
                                  icon: Icons.payments_rounded,
                                  index: 2,
                                ),
                                _statusConnector(2),
                                _statusStep(
                                  label: 'Paid',
                                  icon: Icons.verified_rounded,
                                  index: 3,
                                  withMenu: true,
                                ),
                              ],
                            ),
                            const SizedBox(height: 8.0),
                            Text(
                              'Status: $_statusLabel',
                              style: GoogleFonts.inter(
                                color: _blue,
                                fontSize: 10.8,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 10.0),
                            Align(
                              alignment: AlignmentDirectional.center,
                              child: Text(
                                'Tap the Paid icon to update manually.',
                                style: theme.bodySmall.override(
                                  color: theme.secondaryText,
                                  fontSize: 10.2,
                                  letterSpacing: 0.0,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12.0),
                      Container(
                        padding: const EdgeInsetsDirectional.fromSTEB(
                            14.0, 12.0, 14.0, 12.0),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16.0),
                          border: Border.all(color: const Color(0xFFE7ECF3)),
                        ),
                        child: Column(
                          children: [
                            _paymentLinkRow(),
                            _detailRow('Created',
                                _historyTimeLabel(request.createdAt)),
                            _detailRow('Payer can edit',
                                request.payerCanEdit ? 'Yes' : 'No'),
                            _detailRow('Usage', request.usage),
                            _detailRow('Expiry', request.expiryLabel),
                            _detailRow('Settlement', request.settlementMode),
                            _detailRow(
                              'Destination',
                              [
                                request.settlementLabel,
                                request.network,
                                request.accountNumber,
                              ]
                                  .where((item) => item.trim().isNotEmpty)
                                  .join(' • '),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14.0),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Expanded(
                            child: _iconAction(
                              icon: Icons.link_rounded,
                              label: 'Copy link',
                              onTap: _copyLink,
                            ),
                          ),
                          const SizedBox(width: 10.0),
                          Expanded(
                            child: _iconAction(
                              icon: Icons.ios_share_rounded,
                              label: 'Share',
                              onTap: _shareLink,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
      ),
    );
  }
}

class _ReceiveRequest {
  const _ReceiveRequest({
    required this.id,
    required this.amount,
    required this.currency,
    required this.description,
    required this.expiryLabel,
    required this.usage,
    required this.payerCanEdit,
    required this.settlementMode,
    required this.settlementLabel,
    required this.network,
    required this.accountNumber,
    required this.status,
    required this.createdAt,
  });

  final String id;
  final String amount;
  final String currency;
  final String description;
  final String expiryLabel;
  final String usage;
  final bool payerCanEdit;
  final String settlementMode;
  final String settlementLabel;
  final String network;
  final String accountNumber;
  final String status;
  final DateTime createdAt;

  factory _ReceiveRequest.fromJson(Map<String, dynamic> json) {
    return _ReceiveRequest(
      id: json['id']?.toString() ?? '',
      amount: json['amount']?.toString() ?? '0',
      currency: json['currency']?.toString() ?? 'NGN',
      description: json['description']?.toString() ?? 'Payment request',
      expiryLabel: json['expiryLabel']?.toString() ??
          json['expiry']?.toString() ??
          '24 hours',
      usage: json['usage']?.toString() ?? 'Use once',
      payerCanEdit: json['payerCanEdit'] == true,
      settlementMode: json['settlementMode']?.toString() ?? 'Default account',
      settlementLabel: json['settlementLabel']?.toString() ?? '',
      network: json['network']?.toString() ?? '',
      accountNumber: json['accountNumber']?.toString() ?? '',
      status: json['status']?.toString() ?? 'created',
      createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? '') ??
          DateTime.now(),
    );
  }

  _ReceiveRequest copyWith({String? status}) {
    return _ReceiveRequest(
      id: id,
      amount: amount,
      currency: currency,
      description: description,
      expiryLabel: expiryLabel,
      usage: usage,
      payerCanEdit: payerCanEdit,
      settlementMode: settlementMode,
      settlementLabel: settlementLabel,
      network: network,
      accountNumber: accountNumber,
      status: status ?? this.status,
      createdAt: createdAt,
    );
  }
}
