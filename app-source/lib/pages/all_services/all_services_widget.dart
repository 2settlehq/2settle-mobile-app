import '/components/top_notice.dart';
import '/flutter_flow/flutter_flow_icon_button.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/index.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AllServicesWidget extends StatelessWidget {
  const AllServicesWidget({super.key});

  static String routeName = 'AllServices';
  static String routePath = 'allServices';
  static const _blue = Color(0xFF4472C4);

  void _comingSoon(BuildContext context, String service) {
    showTopNotice(
      context,
      message: '$service is being prepared.',
      type: TopNoticeType.info,
    );
  }

  Widget _serviceIcon({
    required BuildContext context,
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    final theme = FlutterFlowTheme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16.0),
      child: Container(
        height: 92.0,
        padding: const EdgeInsetsDirectional.fromSTEB(8.0, 10.0, 8.0, 8.0),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16.0),
          border: Border.all(color: _blue.withValues(alpha: 0.1)),
          boxShadow: [
            BoxShadow(
              blurRadius: 14.0,
              color: const Color(0x14000000),
              offset: const Offset(0.0, 6.0),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 38.0,
              height: 38.0,
              decoration: BoxDecoration(
                color: _blue,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    blurRadius: 10.0,
                    color: _blue.withValues(alpha: 0.18),
                    offset: const Offset(0.0, 4.0),
                  ),
                ],
              ),
              child: Icon(icon, color: Colors.white, size: 20.0),
            ),
            const SizedBox(height: 8.0),
            Text(
              title,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: theme.bodySmall.override(
                color: theme.primaryText,
                fontSize: 10.6,
                letterSpacing: 0.0,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _section({
    required BuildContext context,
    required String title,
    required List<Widget> children,
  }) {
    final theme = FlutterFlowTheme.of(context);
    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(18.0, 14.0, 18.0, 0.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: theme.bodySmall.override(
              color: _blue,
              fontSize: 12.0,
              letterSpacing: 0.0,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 9.0),
          GridView.count(
            crossAxisCount: 3,
            crossAxisSpacing: 10.0,
            mainAxisSpacing: 10.0,
            childAspectRatio: 0.96,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            children: children,
          ),
        ],
      ),
    );
  }

  Widget _waleServiceIcon(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    return InkWell(
      onTap: () => context.goNamed(WaleSpendWidget.routeName),
      borderRadius: BorderRadius.circular(16.0),
      child: Container(
        height: 92.0,
        padding: const EdgeInsetsDirectional.fromSTEB(8.0, 10.0, 8.0, 8.0),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16.0),
          border: Border.all(color: _blue.withValues(alpha: 0.1)),
          boxShadow: const [
            BoxShadow(
              blurRadius: 14.0,
              color: Color(0x14000000),
              offset: Offset(0.0, 6.0),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ClipOval(
              child: Image.asset(
                'assets/images/a_avatar.png',
                width: 38.0,
                height: 38.0,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(height: 8.0),
            Text(
              'Wale',
              textAlign: TextAlign.center,
              style: theme.bodySmall.override(
                color: theme.primaryText,
                fontSize: 10.6,
                letterSpacing: 0.0,
                fontWeight: FontWeight.w600,
              ),
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
          padding: const EdgeInsetsDirectional.only(bottom: 26.0),
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
                    onPressed: () => context.goNamed(DashboardWidget.routeName),
                  ),
                  Expanded(
                    child: Text(
                      'All Services',
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
                'Everything you can do with 2Settle in one place.',
                style: GoogleFonts.inter(
                  color: theme.secondaryText,
                  fontSize: 11.2,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            _section(
              context: context,
              title: 'PAYMENT',
              children: [
                _serviceIcon(
                  context: context,
                  icon: Icons.swap_horiz_rounded,
                  title: 'Transfer money',
                  onTap: () => context.goNamed(MainTransactionWidget.routeName),
                ),
                _serviceIcon(
                  context: context,
                  icon: Icons.call_received_rounded,
                  title: 'Receive payment',
                  onTap: () => context.goNamed(PayPageWidget.routeName),
                ),
                _serviceIcon(
                  context: context,
                  icon: Icons.credit_card_rounded,
                  title: 'My card',
                  onTap: () => context.goNamed(MyCardsWidget.routeName),
                ),
                _serviceIcon(
                  context: context,
                  icon: Icons.card_giftcard_rounded,
                  title: 'Gift',
                  onTap: () => context.goNamed(GiftWidget.routeName),
                ),
                _serviceIcon(
                  context: context,
                  icon: Icons.public_rounded,
                  title: 'Remit',
                  onTap: () => _comingSoon(context, 'Remit'),
                ),
                _waleServiceIcon(context),
              ],
            ),
            _section(
              context: context,
              title: 'SERVICE',
              children: [
                _serviceIcon(
                  context: context,
                  icon: Icons.receipt_long_rounded,
                  title: 'Pay bills',
                  onTap: () => _comingSoon(context, 'Pay bills'),
                ),
                _serviceIcon(
                  context: context,
                  icon: Icons.wifi_rounded,
                  title: 'Recharge data',
                  onTap: () => _comingSoon(context, 'Recharge data'),
                ),
                _serviceIcon(
                  context: context,
                  icon: Icons.phone_android_rounded,
                  title: 'Recharge airtime',
                  onTap: () => _comingSoon(context, 'Recharge airtime'),
                ),
                _serviceIcon(
                  context: context,
                  icon: Icons.subscriptions_rounded,
                  title: 'Subscriptions',
                  onTap: () => _comingSoon(context, 'Subscriptions'),
                ),
                _serviceIcon(
                  context: context,
                  icon: Icons.report_problem_rounded,
                  title: 'Reportly',
                  onTap: () => _comingSoon(context, 'Reportly'),
                ),
                _serviceIcon(
                  context: context,
                  icon: Icons.storefront_rounded,
                  title: 'Merchant',
                  onTap: () => _comingSoon(context, 'Merchant'),
                ),
                _serviceIcon(
                  context: context,
                  icon: Icons.group_add_rounded,
                  title: 'Referral',
                  onTap: () => _comingSoon(context, 'Referral'),
                ),
                _serviceIcon(
                  context: context,
                  icon: Icons.feedback_rounded,
                  title: 'Feedback',
                  onTap: () => _comingSoon(context, 'Feedback'),
                ),
                _serviceIcon(
                  context: context,
                  icon: Icons.support_agent_rounded,
                  title: 'Support',
                  onTap: () => _comingSoon(context, 'Support'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
