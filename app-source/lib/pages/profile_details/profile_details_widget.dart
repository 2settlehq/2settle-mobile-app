import 'dart:async';

import '/flutter_flow/flutter_flow_icon_button.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/components/status_action_button.dart';
import '/components/top_notice.dart';
import '/components/user_avatar.dart';
import '/index.dart';
import '/services/auth_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'profile_details_model.dart';
export 'profile_details_model.dart';

class ProfileDetailsWidget extends StatefulWidget {
  const ProfileDetailsWidget({super.key});

  static String routeName = 'Profile_Details';
  static String routePath = 'profileDetails';

  @override
  State<ProfileDetailsWidget> createState() => _ProfileDetailsWidgetState();
}

class _ProfileDetailsWidgetState extends State<ProfileDetailsWidget> {
  late ProfileDetailsModel _model;

  final scaffoldKey = GlobalKey<ScaffoldState>();
  final _usernameController = TextEditingController();
  final _referralCodeController = TextEditingController();
  bool _isSaving = false;
  bool _isSaved = false;
  static const _usernameStorageKey = '2settle_profile_username';
  static const _referralStorageKey = '2settle_profile_referral_code';
  String _rawUserId = '';
  String _avatarUrl = '';

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => ProfileDetailsModel());

    _model.emailTextController ??= TextEditingController();
    _model.emailFocusNode ??= FocusNode();

    _model.myBioTextController ??= TextEditingController();
    _model.myBioFocusNode ??= FocusNode();
    _loadProfile();
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _referralCodeController.dispose();
    _model.dispose();

    super.dispose();
  }

  Future<void> _loadProfile() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    _model.emailTextController?.text = 'account@2settle.io';
    _usernameController.text = prefs.getString(_usernameStorageKey) ?? '';
    _referralCodeController.text = prefs.getString(_referralStorageKey) ?? '';
    _rawUserId = await AuthService.getUserId() ?? '';
    _avatarUrl = await AuthService.getAvatarUrl() ?? '';
    safeSetState(() {});
  }

  Future<void> _copyUserId() async {
    if (_rawUserId.isEmpty) return;
    // Copy the full id exactly as the server returned it — no case change,
    // no truncation, and without the 2S- prefix (that's display-only).
    await Clipboard.setData(ClipboardData(text: _rawUserId));
    if (!mounted) return;
    showTopNotice(
      context,
      message: 'User ID copied',
      type: TopNoticeType.info,
    );
  }

  Future<void> _saveProfile() async {
    if (_isSaving) return;
    final username = _usernameController.text.trim();
    if (username.isEmpty) {
      showTopNotice(
        context,
        message: 'Enter a username before saving.',
        type: TopNoticeType.caution,
      );
      return;
    }
    safeSetState(() {
      _isSaving = true;
      _isSaved = false;
    });
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_usernameStorageKey, username);
    await prefs.setString(
        _referralStorageKey, _referralCodeController.text.trim());
    unawaited(AuthService.updateProfile(displayName: username));
    await Future.delayed(const Duration(milliseconds: 520));
    if (!mounted) return;
    safeSetState(() {
      _isSaving = false;
      _isSaved = true;
    });
    await Future.delayed(const Duration(milliseconds: 420));
    if (!mounted) return;
    context.pushNamed(SettingsWidget.routeName);
  }

  @override
  Widget build(BuildContext context) {
    InputDecoration profileInputDecoration(String label,
        {String? hint, Widget? suffixIcon}) {
      return InputDecoration(
        labelText: label,
        hintText: hint,
        suffixIcon: suffixIcon,
        labelStyle: FlutterFlowTheme.of(context).bodySmall.override(
              color: FlutterFlowTheme.of(context).secondaryText,
              fontSize: 11.0,
              letterSpacing: 0.0,
              fontWeight: FontWeight.w500,
            ),
        hintStyle: FlutterFlowTheme.of(context).bodySmall.override(
              color: FlutterFlowTheme.of(context).secondaryText,
              fontSize: 11.0,
              letterSpacing: 0.0,
              fontWeight: FontWeight.w500,
            ),
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(
            color: FlutterFlowTheme.of(context).primaryBackground,
            width: 2.0,
          ),
          borderRadius: BorderRadius.circular(8.0),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(
            color: FlutterFlowTheme.of(context).primary,
            width: 1.4,
          ),
          borderRadius: BorderRadius.circular(8.0),
        ),
        filled: true,
        fillColor: FlutterFlowTheme.of(context).secondaryBackground,
        contentPadding:
            const EdgeInsetsDirectional.fromSTEB(20.0, 18.0, 14.0, 18.0),
      );
    }

    return Scaffold(
      key: scaffoldKey,
      backgroundColor: FlutterFlowTheme.of(context).secondaryBackground,
      appBar: AppBar(
        backgroundColor: FlutterFlowTheme.of(context).primary,
        automaticallyImplyLeading: false,
        leading: FlutterFlowIconButton(
          borderColor: Colors.transparent,
          borderRadius: 30.0,
          borderWidth: 1.0,
          buttonSize: 60.0,
          icon: Icon(
            Icons.arrow_back_rounded,
            color: Colors.white,
            size: 30.0,
          ),
          onPressed: () async {
            context.pop();
          },
        ),
        title: Text(
          'Profile',
          style: FlutterFlowTheme.of(context).headlineMedium.override(
                font: TextStyle(
                  fontWeight:
                      FlutterFlowTheme.of(context).headlineMedium.fontWeight,
                  fontStyle:
                      FlutterFlowTheme.of(context).headlineMedium.fontStyle,
                ),
                color: Colors.white,
                fontSize: 22.0,
                letterSpacing: 0.0,
                fontWeight:
                    FlutterFlowTheme.of(context).headlineMedium.fontWeight,
                fontStyle:
                    FlutterFlowTheme.of(context).headlineMedium.fontStyle,
              ),
        ),
        actions: [],
        centerTitle: false,
        elevation: 2.0,
      ),
      body: SafeArea(
        top: true,
        child: ListView(
          padding: const EdgeInsetsDirectional.only(bottom: 28.0),
          children: [
            Padding(
              padding: EdgeInsetsDirectional.fromSTEB(0.0, 30.0, 0.0, 0.0),
              child: Row(
                mainAxisSize: MainAxisSize.max,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 100.0,
                    height: 100.0,
                    decoration: BoxDecoration(
                      color: Color(0xFFDBE2E7),
                      shape: BoxShape.circle,
                    ),
                    child: Padding(
                      padding: EdgeInsets.all(2.0),
                      child: Container(
                        width: 90.0,
                        height: 90.0,
                        clipBehavior: Clip.antiAlias,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                        ),
                        child: UserAvatar(
                          avatarUrl: _avatarUrl,
                          fit: BoxFit.fitWidth,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: EdgeInsetsDirectional.fromSTEB(0.0, 12.0, 0.0, 16.0),
              child: Row(
                mainAxisSize: MainAxisSize.max,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Change Photo',
                    style: FlutterFlowTheme.of(context).bodyMedium.override(
                          font: TextStyle(
                            fontWeight: FontWeight.w500,
                            fontStyle: FlutterFlowTheme.of(context)
                                .bodyMedium
                                .fontStyle,
                          ),
                          color: FlutterFlowTheme.of(context).primary,
                          fontSize: 13.0,
                          letterSpacing: 0.0,
                          fontWeight: FontWeight.w500,
                          fontStyle:
                              FlutterFlowTheme.of(context).bodyMedium.fontStyle,
                        ),
                  ),
                ],
              ),
            ),
            Padding(
              padding:
                  const EdgeInsetsDirectional.fromSTEB(20.0, 0.0, 20.0, 16.0),
              child: TextFormField(
                controller: _usernameController,
                decoration: profileInputDecoration('Username', hint: 'kayode'),
                style: FlutterFlowTheme.of(context).bodyMedium.override(
                      letterSpacing: 0.0,
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ),
            Padding(
              padding:
                  const EdgeInsetsDirectional.fromSTEB(20.0, 0.0, 20.0, 16.0),
              child: TextFormField(
                controller: _referralCodeController,
                textCapitalization: TextCapitalization.characters,
                decoration: profileInputDecoration('Referral code',
                    hint: 'Optional referral code'),
                style: FlutterFlowTheme.of(context).bodyMedium.override(
                      letterSpacing: 0.0,
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ),
            Padding(
              padding:
                  const EdgeInsetsDirectional.fromSTEB(20.0, 0.0, 20.0, 16.0),
              child: Container(
                padding: const EdgeInsetsDirectional.fromSTEB(
                    20.0, 12.0, 8.0, 12.0),
                decoration: BoxDecoration(
                  color: FlutterFlowTheme.of(context).secondaryBackground,
                  borderRadius: BorderRadius.circular(8.0),
                  border: Border.all(
                    color: FlutterFlowTheme.of(context).primaryBackground,
                    width: 2.0,
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'User ID',
                            style: FlutterFlowTheme.of(context)
                                .bodySmall
                                .override(
                                  color: FlutterFlowTheme.of(context)
                                      .secondaryText,
                                  fontSize: 11.0,
                                  letterSpacing: 0.0,
                                  fontWeight: FontWeight.w500,
                                ),
                          ),
                          const SizedBox(height: 4.0),
                          Text(
                            _rawUserId.isEmpty ? '' : '2S-$_rawUserId',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: FlutterFlowTheme.of(context)
                                .bodyMedium
                                .override(
                                  letterSpacing: 0.0,
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: Icon(
                        Icons.copy_rounded,
                        color: FlutterFlowTheme.of(context).secondaryText,
                        size: 20.0,
                      ),
                      onPressed: _copyUserId,
                    ),
                  ],
                ),
              ),
            ),
            Align(
              alignment: AlignmentDirectional.centerEnd,
              child: Padding(
                padding:
                    EdgeInsetsDirectional.fromSTEB(20.0, 16.0, 20.0, 0.0),
                child: StatusActionButton(
                  text: 'Save Changes',
                  isLoading: _isSaving,
                  isDone: _isSaved,
                  onPressed: _saveProfile,
                  idleIcon: Icons.save_rounded,
                  height: 48.0,
                  horizontalPadding: 16.0,
                  trailingPadding: 5.0,
                  iconBoxSize: 38.0,
                  iconSize: 19.0,
                  fontSize: 13.2,
                  backgroundColor: FlutterFlowTheme.of(context).primary,
                  textColor: Colors.white,
                  iconBackgroundColor: Colors.white,
                  iconColor: FlutterFlowTheme.of(context).primary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
