import '/flutter_flow/flutter_flow_icon_button.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/index.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AccountWidget extends StatelessWidget {
  const AccountWidget({super.key});

  static String routeName = 'Account';
  static String routePath = 'account';
  static const _blue = Color(0xFF4472C4);

  Widget _row({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    bool showDivider = true,
  }) {
    final theme = FlutterFlowTheme.of(context);
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsetsDirectional.fromSTEB(13.0, 11.0, 12.0, 11.0),
        decoration: BoxDecoration(
          border: showDivider
              ? Border(
                  bottom: BorderSide(
                    color: const Color(0xFFE3E8F0).withValues(alpha: 0.82),
                    width: 0.8,
                  ),
                )
              : null,
        ),
        child: Row(
          children: [
            Container(
              width: 38.0,
              height: 38.0,
              decoration: BoxDecoration(
                color: _blue.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12.0),
              ),
              child: Icon(icon, color: _blue, size: 20.0),
            ),
            const SizedBox(width: 12.0),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.bodySmall.override(
                      font: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontStyle: theme.bodySmall.fontStyle,
                      ),
                      color: theme.primaryText,
                      fontSize: 13.0,
                      letterSpacing: 0.0,
                      fontWeight: FontWeight.w700,
                      fontStyle: theme.bodySmall.fontStyle,
                    ),
                  ),
                  const SizedBox(height: 3.0),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      color: theme.secondaryText,
                      fontSize: 10.5,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios_rounded,
              color: theme.secondaryText.withValues(alpha: 0.72),
              size: 15.0,
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
          padding: const EdgeInsetsDirectional.only(bottom: 24.0),
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
                    onPressed: () => context.goNamed(SettingsWidget.routeName),
                  ),
                  Expanded(
                    child: Text(
                      'Account',
                      style: theme.titleMedium.override(
                        font: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontStyle: theme.titleMedium.fontStyle,
                        ),
                        color: theme.primaryText,
                        fontSize: 20.0,
                        letterSpacing: 0.0,
                        fontWeight: FontWeight.w800,
                        fontStyle: theme.titleMedium.fontStyle,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding:
                  const EdgeInsetsDirectional.fromSTEB(18.0, 14.0, 18.0, 0.0),
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF3F8),
                  borderRadius: BorderRadius.circular(16.0),
                  boxShadow: const [
                    BoxShadow(
                      blurRadius: 10.0,
                      color: Color(0x0F16202A),
                      offset: Offset(0.0, 4.0),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    _row(
                      context: context,
                      icon: Icons.account_balance_rounded,
                      title: 'Bank & beneficiary',
                      subtitle: 'Saved banks, beneficiaries, and defaults',
                      onTap: () => context.pushNamed(
                        AccountDetailsWidget.routeName,
                        queryParameters: {'origin': 'account'},
                      ),
                    ),
                    _row(
                      context: context,
                      icon: Icons.account_balance_wallet_rounded,
                      title: 'Receive payment details',
                      subtitle: 'Direct bank, dollar, and wallet destinations',
                      showDivider: false,
                      onTap: () => context.pushNamed(
                        ReceivePaymentDetailsWidget.routeName,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
