import '/flutter_flow/flutter_flow_icon_button.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/index.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'security_model.dart';
export 'security_model.dart';

class SecurityWidget extends StatefulWidget {
  const SecurityWidget({super.key});

  static String routeName = 'Security';
  static String routePath = 'security';

  @override
  State<SecurityWidget> createState() => _SecurityWidgetState();
}

class _SecurityWidgetState extends State<SecurityWidget> {
  late SecurityModel _model;
  final scaffoldKey = GlobalKey<ScaffoldState>();
  static const _passcodeLengthStorageKey = '2settle_app_passcode_length';
  int _pinLength = 6;

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => SecurityModel());
    _loadPinLength();
  }

  @override
  void dispose() {
    _model.dispose();
    super.dispose();
  }

  Future<void> _loadPinLength() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    safeSetState(() {
      _pinLength = prefs.getInt(_passcodeLengthStorageKey) ?? 6;
    });
  }

  Future<void> _setPinLength(int length) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_passcodeLengthStorageKey, length);
    if (!mounted) return;
    safeSetState(() => _pinLength = length);
  }

  Future<void> _showLinkStatus(String label) async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: FlutterFlowTheme.of(context).secondaryBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18.0)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding:
                const EdgeInsetsDirectional.fromSTEB(20.0, 18.0, 20.0, 24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Link $label',
                  style: FlutterFlowTheme.of(context).headlineSmall.override(
                        font: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontStyle: FlutterFlowTheme.of(context)
                              .headlineSmall
                              .fontStyle,
                        ),
                        color: FlutterFlowTheme.of(context).primary,
                        letterSpacing: 0.0,
                        fontWeight: FontWeight.w700,
                        fontStyle: FlutterFlowTheme.of(context)
                            .headlineSmall
                            .fontStyle,
                      ),
                ),
                const SizedBox(height: 10.0),
                Text(
                  'This will let you connect to 2Settle with $label after it has been verified.',
                  style: FlutterFlowTheme.of(context).bodySmall.override(
                        font: TextStyle(
                          fontWeight: FontWeight.normal,
                          fontStyle:
                              FlutterFlowTheme.of(context).bodySmall.fontStyle,
                        ),
                        letterSpacing: 0.0,
                        fontWeight: FontWeight.normal,
                        fontStyle:
                            FlutterFlowTheme.of(context).bodySmall.fontStyle,
                      ),
                ),
                const SizedBox(height: 18.0),
                _SecurityTile(
                  icon: Icons.add_link_rounded,
                  title: 'Start linking',
                  subtitle: 'Verification flow will be connected next.',
                  onTap: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: scaffoldKey,
      backgroundColor: FlutterFlowTheme.of(context).primaryBackground,
      appBar: AppBar(
        backgroundColor: FlutterFlowTheme.of(context).secondaryBackground,
        automaticallyImplyLeading: false,
        leading: FlutterFlowIconButton(
          borderColor: Colors.transparent,
          borderRadius: 30.0,
          borderWidth: 1.0,
          buttonSize: 60.0,
          icon: Icon(
            Icons.arrow_back_rounded,
            color: FlutterFlowTheme.of(context).primaryText,
            size: 30.0,
          ),
          onPressed: () async {
            context.pushNamed(SettingsWidget.routeName);
          },
        ),
        title: Text(
          'Security',
          style: FlutterFlowTheme.of(context).titleSmall.override(
                font: TextStyle(
                  fontWeight:
                      FlutterFlowTheme.of(context).titleSmall.fontWeight,
                  fontStyle: FlutterFlowTheme.of(context).titleSmall.fontStyle,
                ),
                letterSpacing: 0.0,
                fontWeight: FlutterFlowTheme.of(context).titleSmall.fontWeight,
                fontStyle: FlutterFlowTheme.of(context).titleSmall.fontStyle,
              ),
        ),
        centerTitle: true,
        elevation: 0.0,
      ),
      body: SafeArea(
        top: true,
        child: ListView(
          padding: const EdgeInsetsDirectional.fromSTEB(16.0, 18.0, 16.0, 24.0),
          children: [
            Text(
              'Manage Appcode',
              style: FlutterFlowTheme.of(context).titleSmall.override(
                    font: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontStyle:
                          FlutterFlowTheme.of(context).titleSmall.fontStyle,
                    ),
                    color: const Color(0xFF6E99E2),
                    letterSpacing: 0.0,
                    fontWeight: FontWeight.w600,
                    fontStyle:
                        FlutterFlowTheme.of(context).titleSmall.fontStyle,
                  ),
            ),
            const SizedBox(height: 10.0),
            _SecurityTile(
              icon: Icons.password_rounded,
              title: 'Change app passcode',
              subtitle: 'Update your $_pinLength digit app access pin.',
              onTap: () => context.pushNamed(
                SetAppPasscodeWidget.routeName,
                queryParameters: {'mode': 'change'},
              ),
            ),
            Container(
              width: double.infinity,
              margin: const EdgeInsetsDirectional.only(bottom: 12.0),
              padding:
                  const EdgeInsetsDirectional.fromSTEB(12.0, 10.0, 12.0, 10.0),
              decoration: BoxDecoration(
                color: FlutterFlowTheme.of(context).secondaryBackground,
                borderRadius: BorderRadius.circular(12.0),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Pin length',
                      style: FlutterFlowTheme.of(context).bodySmall.override(
                            font: TextStyle(
                              fontWeight: FontWeight.normal,
                              fontStyle: FlutterFlowTheme.of(context)
                                  .bodySmall
                                  .fontStyle,
                            ),
                            letterSpacing: 0.0,
                            fontWeight: FontWeight.normal,
                            fontStyle: FlutterFlowTheme.of(context)
                                .bodySmall
                                .fontStyle,
                          ),
                    ),
                  ),
                  _SecurityPinChip(
                    label: '4',
                    selected: _pinLength == 4,
                    onTap: () => _setPinLength(4),
                  ),
                  const SizedBox(width: 8.0),
                  _SecurityPinChip(
                    label: '6',
                    selected: _pinLength == 6,
                    onTap: () => _setPinLength(6),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 22.0),
            Text(
              'Link Account',
              style: FlutterFlowTheme.of(context).titleSmall.override(
                    font: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontStyle:
                          FlutterFlowTheme.of(context).titleSmall.fontStyle,
                    ),
                    color: const Color(0xFF6E99E2),
                    letterSpacing: 0.0,
                    fontWeight: FontWeight.w600,
                    fontStyle:
                        FlutterFlowTheme.of(context).titleSmall.fontStyle,
                  ),
            ),
            const SizedBox(height: 10.0),
            _SecurityTile(
              icon: Icons.phone_iphone_rounded,
              title: 'Phone number',
              subtitle: 'Current connection method.',
              trailingText: 'Linked',
              onTap: () => _showLinkStatus('phone number'),
            ),
            _SecurityTile(
              icon: Icons.account_balance_wallet_rounded,
              title: 'Wallet address',
              subtitle: 'Connect later with your wallet.',
              onTap: () => _showLinkStatus('wallet address'),
            ),
            _SecurityTile(
              icon: Icons.mail_rounded,
              title: 'Email',
              subtitle: 'Connect later with your email.',
              onTap: () => _showLinkStatus('email'),
            ),
            _SecurityTile(
              icon: Icons.g_mobiledata_rounded,
              title: 'Google',
              subtitle: 'Connect later with Google.',
              onTap: () => _showLinkStatus('Google'),
            ),
          ],
        ),
      ),
    );
  }
}

class _SecurityTile extends StatelessWidget {
  const _SecurityTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.trailingText,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final String? trailingText;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsetsDirectional.only(bottom: 12.0),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12.0),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12.0),
          decoration: BoxDecoration(
            color: FlutterFlowTheme.of(context).secondaryBackground,
            borderRadius: BorderRadius.circular(12.0),
            boxShadow: const [
              BoxShadow(
                blurRadius: 5.0,
                color: Color(0x3416202A),
                offset: Offset(0.0, 2.0),
              ),
            ],
          ),
          child: Row(
            children: [
              Icon(
                icon,
                color: FlutterFlowTheme.of(context).secondaryText,
                size: 24.0,
              ),
              const SizedBox(width: 12.0),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: FlutterFlowTheme.of(context).bodyMedium.override(
                            font: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontStyle: FlutterFlowTheme.of(context)
                                  .bodyMedium
                                  .fontStyle,
                            ),
                            letterSpacing: 0.0,
                            fontWeight: FontWeight.w600,
                            fontStyle: FlutterFlowTheme.of(context)
                                .bodyMedium
                                .fontStyle,
                          ),
                    ),
                    const SizedBox(height: 3.0),
                    Text(
                      subtitle,
                      style: FlutterFlowTheme.of(context).bodySmall.override(
                            font: TextStyle(
                              fontWeight: FontWeight.normal,
                              fontStyle: FlutterFlowTheme.of(context)
                                  .bodySmall
                                  .fontStyle,
                            ),
                            color: FlutterFlowTheme.of(context).secondaryText,
                            fontSize: 12.0,
                            letterSpacing: 0.0,
                            fontWeight: FontWeight.normal,
                            fontStyle: FlutterFlowTheme.of(context)
                                .bodySmall
                                .fontStyle,
                          ),
                    ),
                  ],
                ),
              ),
              if (trailingText != null)
                Text(
                  trailingText!,
                  style: FlutterFlowTheme.of(context).bodySmall.override(
                        font: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontStyle:
                              FlutterFlowTheme.of(context).bodySmall.fontStyle,
                        ),
                        color: FlutterFlowTheme.of(context).primary,
                        fontSize: 12.0,
                        letterSpacing: 0.0,
                        fontWeight: FontWeight.w600,
                        fontStyle:
                            FlutterFlowTheme.of(context).bodySmall.fontStyle,
                      ),
                )
              else
                Icon(
                  Icons.arrow_forward_ios,
                  color: FlutterFlowTheme.of(context).secondaryText,
                  size: 16.0,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SecurityPinChip extends StatelessWidget {
  const _SecurityPinChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final blue = FlutterFlowTheme.of(context).primary;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999.0),
      child: Container(
        width: 36.0,
        height: 30.0,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? blue : blue.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(999.0),
          border: Border.all(color: blue.withValues(alpha: 0.18)),
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(
            color: selected ? Colors.white : blue,
            fontSize: 12.0,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}
