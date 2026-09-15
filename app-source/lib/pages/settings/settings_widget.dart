import '/flutter_flow/flutter_flow_icon_button.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/components/top_notice.dart';
import '/components/user_avatar.dart';
import '/index.dart';
import '/services/auth_service.dart';
import '/services/mobile_identity_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'settings_model.dart';
export 'settings_model.dart';

class SettingsWidget extends StatefulWidget {
  const SettingsWidget({super.key});

  static String routeName = 'settings';
  static String routePath = 'settings';

  @override
  State<SettingsWidget> createState() => _SettingsWidgetState();
}

class _SettingsWidgetState extends State<SettingsWidget>
    with SingleTickerProviderStateMixin {
  late SettingsModel _model;
  late AnimationController _avatarPulseController;
  late Animation<double> _avatarPulseScale;

  final scaffoldKey = GlobalKey<ScaffoldState>();
  static const _blue = Color(0xFF4472C4);
  String _displayName = 'Sirfitech';
  String _mobileId = 'Loading...';
  String _userIdDisplay = '';
  String _contactValue = '';
  IconData _contactIcon = Icons.phone_rounded;
  String _avatarUrl = '';

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => SettingsModel());
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
    _loadProfileName();
    _loadMobileId();
    _loadUserId();
    _loadContact();
    _loadAvatar();
  }

  @override
  void dispose() {
    _avatarPulseController.dispose();
    _model.dispose();

    super.dispose();
  }

  Future<void> _openLegalPage(String path) async {
    final uri = Uri.https('spend.2settle.io', path);
    try {
      if (await launchUrl(uri, mode: LaunchMode.inAppBrowserView)) return;
    } catch (_) {
      // Try the default browser when an in-app browser is unavailable.
    }
    try {
      if (await launchUrl(uri, mode: LaunchMode.externalApplication)) return;
    } catch (_) {
      // Report launch failures without interrupting Settings.
    }
    if (!mounted) return;
    showTopNotice(context,
        message: 'Unable to open this page. Please try again.',
        type: TopNoticeType.caution);
  }

  void _openTab(int index) {
    switch (index) {
      case 0:
        context.pushNamed(DashboardWidget.routeName);
        break;
      case 1:
        context.pushNamed(MainTransactionWidget.routeName);
        break;
      case 2:
        context.pushNamed(MyCardsWidget.routeName);
        break;
      case 3:
        context.pushNamed(PayPageWidget.routeName);
        break;
      default:
        break;
    }
  }

  Future<void> _loadProfileName() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString('2settle_profile_username')?.trim();
    if (!mounted || stored == null || stored.isEmpty) return;
    safeSetState(() =>
        _displayName = '${stored[0].toUpperCase()}${stored.substring(1)}');
  }

  Future<void> _loadMobileId() async {
    final mobileId = await MobileIdentityService.getOrCreateMobileId();
    if (!mounted) return;
    safeSetState(() => _mobileId = mobileId);
  }

  Future<void> _loadUserId() async {
    final rawId = await AuthService.getUserId();
    if (!mounted || rawId == null || rawId.isEmpty) return;
    safeSetState(() => _userIdDisplay = '2S-$rawId');
  }

  Future<void> _loadAvatar() async {
    final avatarUrl = await AuthService.getAvatarUrl();
    if (!mounted || avatarUrl == null || avatarUrl.isEmpty) return;
    safeSetState(() => _avatarUrl = avatarUrl);
  }

  /// Whichever identity the account actually logged in with — email or
  /// phone — rather than a hardcoded placeholder for one or the other.
  Future<void> _loadContact() async {
    final prefs = await SharedPreferences.getInstance();
    final channel = prefs.getString(MobileIdentityService.loginChannelKey);
    final identifier = prefs.getString(MobileIdentityService.loginIdentifierKey);
    if (!mounted || channel == null || identifier == null || identifier.isEmpty) {
      return;
    }
    safeSetState(() {
      _contactValue = identifier;
      _contactIcon = channel == 'email' ? Icons.email_rounded : Icons.phone_rounded;
    });
  }

  Widget _section({
    required String label,
    required List<Widget> children,
  }) {
    final theme = FlutterFlowTheme.of(context);

    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(18.0, 16.0, 18.0, 0.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsetsDirectional.only(start: 4.0, bottom: 7.0),
            child: Text(
              label,
              style: GoogleFonts.inter(
                color: theme.secondaryText,
                fontSize: 10.5,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.8,
              ),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFD),
              borderRadius: BorderRadius.circular(18.0),
              border: Border.all(
                color: const Color(0xFFE7ECF4),
                width: 1.0,
              ),
              boxShadow: const [
                BoxShadow(
                  blurRadius: 14.0,
                  color: Color(0x0F16202A),
                  offset: Offset(0.0, 5.0),
                ),
              ],
            ),
            child: Column(children: children),
          ),
        ],
      ),
    );
  }

  Widget _settingsRow({
    required IconData icon,
    required String title,
    String? subtitle,
    VoidCallback? onTap,
    bool showDivider = true,
    bool showChevron = true,
    Widget? trailing,
  }) {
    final theme = FlutterFlowTheme.of(context);
    final row = Container(
      constraints: const BoxConstraints(minHeight: 58.0),
      padding: const EdgeInsetsDirectional.fromSTEB(13.0, 9.0, 12.0, 9.0),
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
            width: 36.0,
            height: 36.0,
            decoration: BoxDecoration(
              color: _blue.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12.0),
            ),
            child: Icon(icon, color: _blue, size: 19.0),
          ),
          const SizedBox(width: 12.0),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.bodySmall.override(
                    font: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontStyle: theme.bodySmall.fontStyle,
                    ),
                    color: theme.primaryText,
                    fontSize: 12.4,
                    letterSpacing: 0.0,
                    fontWeight: FontWeight.w600,
                    fontStyle: theme.bodySmall.fontStyle,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 2.0),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      color: theme.secondaryText,
                      fontSize: 10.3,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (trailing != null) ...[
            const SizedBox(width: 10.0),
            trailing,
          ] else if (showChevron) ...[
            const SizedBox(width: 10.0),
            Icon(
              Icons.arrow_forward_ios_rounded,
              color: theme.secondaryText.withValues(alpha: 0.72),
              size: 15.0,
            ),
          ],
        ],
      ),
    );

    if (onTap == null) {
      return row;
    }

    return InkWell(
      splashColor: Colors.transparent,
      focusColor: Colors.transparent,
      hoverColor: Colors.transparent,
      highlightColor: Colors.transparent,
      onTap: onTap,
      child: row,
    );
  }

  Widget _profileHeader() {
    final theme = FlutterFlowTheme.of(context);

    return Container(
      margin: const EdgeInsetsDirectional.fromSTEB(18.0, 10.0, 18.0, 0.0),
      padding: const EdgeInsetsDirectional.fromSTEB(14.0, 13.0, 14.0, 13.0),
      decoration: BoxDecoration(
        color: _blue,
        borderRadius: BorderRadius.circular(18.0),
        boxShadow: [
          BoxShadow(
            blurRadius: 16.0,
            color: _blue.withValues(alpha: 0.22),
            offset: const Offset(0.0, 8.0),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 58.0,
            height: 58.0,
            padding: const EdgeInsets.all(2.0),
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: ClipOval(
              child: UserAvatar(avatarUrl: _avatarUrl),
            ),
          ),
          const SizedBox(width: 13.0),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _displayName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.headlineSmall.override(
                    font: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontStyle: theme.headlineSmall.fontStyle,
                    ),
                    color: Colors.white,
                    fontSize: 18.0,
                    letterSpacing: 0.0,
                    fontWeight: FontWeight.w700,
                    fontStyle: theme.headlineSmall.fontStyle,
                  ),
                ),
                if (_userIdDisplay.isNotEmpty) ...[
                  const SizedBox(height: 4.0),
                  Text(
                    'User ID: $_userIdDisplay',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      color: Colors.white.withValues(alpha: 0.76),
                      fontSize: 10.8,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
                if (_contactValue.isNotEmpty) ...[
                  const SizedBox(height: 4.0),
                  Row(
                    children: [
                      Icon(
                        _contactIcon,
                        color: Colors.white.withValues(alpha: 0.72),
                        size: 14.0,
                      ),
                      const SizedBox(width: 5.0),
                      Flexible(
                        child: Text(
                          _contactValue,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.inter(
                            color: Colors.white.withValues(alpha: 0.72),
                            fontSize: 10.8,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _quickActions() {
    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(18.0, 12.0, 18.0, 0.0),
      child: Row(
        children: [
          _quickAction(
            icon: Icons.logout_rounded,
            label: 'Sign out',
            onTap: () async {
              await AuthService.logout();
              if (!context.mounted) return;
              context.goNamed(LoginWidget.routeName);
            },
          ),
          const SizedBox(width: 9.0),
          _quickAction(
            icon: Icons.verified_user_rounded,
            label: 'KYC',
            onTap: () => showTopNotice(
              context,
              message: 'KYC flow will be connected next.',
            ),
          ),
          const SizedBox(width: 9.0),
          _quickAction(
            icon: Icons.workspace_premium_rounded,
            label: 'Tier level',
            onTap: () => showTopNotice(
              context,
              message: 'Tier level is coming next.',
            ),
          ),
        ],
      ),
    );
  }

  Widget _quickAction({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    final theme = FlutterFlowTheme.of(context);
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14.0),
        child: Container(
          height: 70.0,
          decoration: BoxDecoration(
            color: theme.secondaryBackground,
            borderRadius: BorderRadius.circular(14.0),
            border: Border.all(color: const Color(0xFFE7ECF4)),
            boxShadow: const [
              BoxShadow(
                blurRadius: 10.0,
                color: Color(0x0F16202A),
                offset: Offset(0.0, 4.0),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: _blue, size: 21.0),
              const SizedBox(height: 6.0),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.bodySmall.override(
                  font: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontStyle: theme.bodySmall.fontStyle,
                  ),
                  color: theme.primaryText,
                  fontSize: 10.5,
                  letterSpacing: 0.0,
                  fontWeight: FontWeight.w600,
                  fontStyle: theme.bodySmall.fontStyle,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);

    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
        FocusManager.instance.primaryFocus?.unfocus();
      },
      child: Scaffold(
        key: scaffoldKey,
        backgroundColor: const Color(0xFFF4F6FA),
        bottomNavigationBar: _SettingsBottomNavigationBar(
          activeIndex: 4,
          onTap: _openTab,
          avatarPulseScale: _avatarPulseScale,
        ),
        body: SafeArea(
          top: true,
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
                      onPressed: () async {
                        context.pushNamed(DashboardWidget.routeName);
                      },
                    ),
                    Expanded(
                      child: Text(
                        'Settings & Support',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
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
              _profileHeader(),
              _quickActions(),
              _section(
                label: 'ACCOUNT',
                children: [
                  _settingsRow(
                    icon: Icons.account_circle_rounded,
                    title: 'Edit Profile',
                    onTap: () {
                      context.pushNamed(ProfileDetailsWidget.routeName);
                    },
                  ),
                  _settingsRow(
                    icon: Icons.account_balance_rounded,
                    title: 'Account',
                    onTap: () {
                      context.pushNamed(AccountWidget.routeName);
                    },
                  ),
                  _settingsRow(
                    icon: Icons.wallet_rounded,
                    title: 'Default Wallet ID',
                    subtitle: _mobileId,
                    showDivider: false,
                    showChevron: false,
                    trailing: InkWell(
                      onTap: () async {
                        await Clipboard.setData(ClipboardData(text: _mobileId));
                        if (!mounted) return;
                        showTopNotice(
                          context,
                          message: 'Default Wallet ID copied.',
                          type: TopNoticeType.info,
                        );
                      },
                      borderRadius: BorderRadius.circular(12.0),
                      child: Container(
                        width: 34.0,
                        height: 34.0,
                        decoration: BoxDecoration(
                          color: _blue.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.copy_rounded,
                          color: _blue,
                          size: 16.0,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              _section(
                label: 'SECURITY',
                children: [
                  _settingsRow(
                    icon: Icons.security_rounded,
                    title: 'Security',
                    onTap: () {
                      context.pushNamed(SecurityWidget.routeName);
                    },
                  ),
                  _settingsRow(
                    icon: Icons.privacy_tip_rounded,
                    title: 'Privacy Policy',
                    onTap: () => _openLegalPage('/privacy'),
                  ),
                  _settingsRow(
                    icon: Icons.description_outlined,
                    title: 'Terms & Conditions',
                    onTap: () => _openLegalPage('/terms'),
                    showDivider: false,
                  ),
                ],
              ),
              _section(
                label: 'PREFERENCES',
                children: [
                  _settingsRow(
                    icon: Icons.notifications_none_rounded,
                    title: 'Notification',
                    onTap: () {
                      context.pushNamed(NotificationSettingsWidget.routeName);
                    },
                  ),
                  _settingsRow(
                    icon: Icons.attach_money_rounded,
                    title: 'Currency Options',
                  ),
                  _settingsRow(
                    icon: Icons.help_outline_rounded,
                    title: 'Support',
                  ),
                  _settingsRow(
                    icon: Icons.ios_share_rounded,
                    title: 'Invite Friends',
                    showDivider: false,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SettingsBottomNavigationBar extends StatelessWidget {
  const _SettingsBottomNavigationBar({
    required this.activeIndex,
    required this.onTap,
    required this.avatarPulseScale,
  });

  final int activeIndex;
  final ValueChanged<int> onTap;
  final Animation<double> avatarPulseScale;

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    final items = const [
      _SettingsNavItem(Icons.home_rounded, 'Home'),
      _SettingsNavItem(Icons.swap_horiz_rounded, 'Send'),
      _SettingsNavItem(Icons.circle, ''),
      _SettingsNavItem(Icons.account_balance_wallet_rounded, 'Receive'),
      _SettingsNavItem(Icons.settings_rounded, 'Settings'),
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
          final selected = index == activeIndex;
          final isCenter = index == 2;

          return Expanded(
            child: InkWell(
              onTap: () => onTap(index),
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
        scale: avatarPulseScale,
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

  Widget _buildNavItem(
    BuildContext context,
    _SettingsNavItem item,
    bool selected,
  ) {
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

class _SettingsNavItem {
  const _SettingsNavItem(this.icon, this.label);

  final IconData icon;
  final String label;
}
