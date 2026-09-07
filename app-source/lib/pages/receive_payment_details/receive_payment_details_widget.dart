import '/flutter_flow/flutter_flow_icon_button.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/index.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ReceivePaymentDetailsWidget extends StatefulWidget {
  const ReceivePaymentDetailsWidget({super.key});

  static String routeName = 'ReceivePaymentDetails';
  static String routePath = 'receivePaymentDetails';
  static const storageKey = '2settle_receive_payment_details';

  static Future<bool> hasSavedDetails() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString(storageKey);
    if (stored == null || stored.isEmpty) return false;
    try {
      final decoded = jsonDecode(stored);
      if (decoded is! Map) return false;
      bool hasDefault(String key) {
        final raw = decoded[key];
        if (raw is! List) return false;
        return raw.any((item) => item is Map && item['isDefault'] == true);
      }

      return hasDefault('nairaAccounts') ||
          hasDefault('dollarAccounts') ||
          hasDefault('wallets');
    } catch (_) {
      return false;
    }
  }

  @override
  State<ReceivePaymentDetailsWidget> createState() =>
      _ReceivePaymentDetailsWidgetState();
}

class _ReceivePaymentDetailsWidgetState
    extends State<ReceivePaymentDetailsWidget> {
  static const _blue = Color(0xFF4472C4);
  static const _red = Color(0xFFC30000);
  static const _green = Color(0xFF25A55F);

  bool _nairaDone = false;
  bool _dollarDone = false;
  bool _walletDone = false;

  @override
  void initState() {
    super.initState();
    _loadStatus();
  }

  Future<void> _loadStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString(ReceivePaymentDetailsWidget.storageKey);
    if (stored == null || stored.isEmpty) return;
    try {
      final decoded = jsonDecode(stored);
      if (decoded is! Map) return;
      bool hasDefault(String key) {
        final raw = decoded[key];
        if (raw is! List) return false;
        return raw.any((item) => item is Map && item['isDefault'] == true);
      }

      if (!mounted) return;
      safeSetState(() {
        _nairaDone = hasDefault('nairaAccounts');
        _dollarDone = hasDefault('dollarAccounts');
        _walletDone = hasDefault('wallets');
      });
    } catch (_) {}
  }

  Widget _statusRow({
    required String title,
    required String subtitle,
    required bool done,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    final theme = FlutterFlowTheme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16.0),
      child: Container(
        margin: const EdgeInsetsDirectional.only(bottom: 10.0),
        padding: const EdgeInsetsDirectional.fromSTEB(12.0, 11.0, 11.0, 11.0),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16.0),
          border: Border.all(color: const Color(0xFFE6EBF2)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.025),
              blurRadius: 12.0,
              offset: const Offset(0.0, 6.0),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 37.0,
              height: 37.0,
              decoration: BoxDecoration(
                color: _blue.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: _blue, size: 18.0),
            ),
            const SizedBox(width: 10.0),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.bodySmall.override(
                      color: theme.primaryText,
                      fontSize: 12.8,
                      letterSpacing: 0.0,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2.0),
                  Text(
                    subtitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      color: theme.secondaryText,
                      fontSize: 10.4,
                      fontWeight: FontWeight.w500,
                      height: 1.25,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              done ? Icons.check_circle_rounded : Icons.cancel_rounded,
              color: done ? _green : _red,
              size: 21.0,
            ),
            const SizedBox(width: 6.0),
            Icon(Icons.chevron_right_rounded,
                color: theme.secondaryText, size: 21.0),
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
                    onPressed: () => context.goNamed(AccountWidget.routeName),
                  ),
                  Expanded(
                    child: Text(
                      'Receive Payment Details',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.titleMedium.override(
                        color: theme.primaryText,
                        fontSize: 19.0,
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
                'Set where direct receive payments should settle. Add multiple destinations and choose one default per section.',
                style: GoogleFonts.inter(
                  color: theme.secondaryText,
                  fontSize: 11.3,
                  fontWeight: FontWeight.w500,
                  height: 1.35,
                ),
              ),
            ),
            Padding(
              padding:
                  const EdgeInsetsDirectional.fromSTEB(18.0, 16.0, 18.0, 0.0),
              child: Column(
                children: [
                  _statusRow(
                    title: 'Naira account',
                    subtitle:
                        'Validate Nigerian bank accounts and set a default.',
                    done: _nairaDone,
                    icon: Icons.account_balance_rounded,
                    onTap: () =>
                        context.pushNamed(ReceiveNairaAccountWidget.routeName),
                  ),
                  _statusRow(
                    title: 'Dollar account',
                    subtitle: 'Save USD receiving accounts and set a default.',
                    done: _dollarDone,
                    icon: Icons.attach_money_rounded,
                    onTap: () =>
                        context.pushNamed(ReceiveDollarAccountWidget.routeName),
                  ),
                  _statusRow(
                    title: 'Wallet addresses',
                    subtitle:
                        'Set EVM, BTC, and TRON wallets for direct crypto payments.',
                    done: _walletDone,
                    icon: Icons.account_balance_wallet_rounded,
                    onTap: () =>
                        context.pushNamed(ReceiveCryptoWalletWidget.routeName),
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
