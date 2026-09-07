import '/flutter_flow/flutter_flow_icon_button.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/components/status_action_button.dart';
import '/components/top_notice.dart';
import '/index.dart';
import 'package:flutter/material.dart';
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
  final _userIdController = TextEditingController();
  bool _isSaving = false;
  bool _isSaved = false;
  static const _profileNameStorageKey = '2settle_profile_name';
  static const _usernameStorageKey = '2settle_profile_username';
  static const _referralStorageKey = '2settle_profile_referral_code';
  static const _userIdStorageKey = '2settle_profile_user_id';

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => ProfileDetailsModel());

    _model.yourNameTextController ??= TextEditingController();
    _model.yourNameFocusNode ??= FocusNode();

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
    _userIdController.dispose();
    _model.dispose();

    super.dispose();
  }

  Future<void> _loadProfile() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    _model.yourNameTextController?.text =
        prefs.getString(_profileNameStorageKey) ?? 'Kayode';
    _model.emailTextController?.text = 'account@2settle.io';
    _usernameController.text = prefs.getString(_usernameStorageKey) ?? 'kayode';
    _referralCodeController.text = prefs.getString(_referralStorageKey) ?? '';
    var userId = prefs.getString(_userIdStorageKey);
    if (userId == null || userId.isEmpty) {
      userId = '2S-${DateTime.now().millisecondsSinceEpoch}';
      await prefs.setString(_userIdStorageKey, userId);
    }
    _userIdController.text = userId;
    safeSetState(() {});
  }

  Future<void> _saveProfile() async {
    if (_isSaving) return;
    final name = _model.yourNameTextController.text.trim();
    if (name.isEmpty) {
      showTopNotice(
        context,
        message: 'Enter your name before saving.',
        type: TopNoticeType.caution,
      );
      return;
    }
    safeSetState(() {
      _isSaving = true;
      _isSaved = false;
    });
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_profileNameStorageKey, name);
    await prefs.setString(_usernameStorageKey, _usernameController.text.trim());
    await prefs.setString(
        _referralStorageKey, _referralCodeController.text.trim());
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
    InputDecoration profileInputDecoration(String label, {String? hint}) {
      return InputDecoration(
        labelText: label,
        hintText: hint,
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
                        child: Image.asset(
                          'assets/images/a_avatar.png',
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
              padding: EdgeInsetsDirectional.fromSTEB(20.0, 0.0, 20.0, 16.0),
              child: TextFormField(
                controller: _model.yourNameTextController,
                focusNode: _model.yourNameFocusNode,
                obscureText: false,
                decoration: InputDecoration(
                  labelText: 'Wálé',
                  labelStyle: FlutterFlowTheme.of(context).bodySmall.override(
                        font: TextStyle(
                          fontWeight: FontWeight.w500,
                          fontStyle:
                              FlutterFlowTheme.of(context).bodySmall.fontStyle,
                        ),
                        letterSpacing: 0.0,
                        fontWeight: FontWeight.w500,
                        fontStyle:
                            FlutterFlowTheme.of(context).bodySmall.fontStyle,
                      ),
                  hintStyle: FlutterFlowTheme.of(context).bodySmall.override(
                        font: TextStyle(
                          fontWeight:
                              FlutterFlowTheme.of(context).bodySmall.fontWeight,
                          fontStyle:
                              FlutterFlowTheme.of(context).bodySmall.fontStyle,
                        ),
                        letterSpacing: 0.0,
                        fontWeight:
                            FlutterFlowTheme.of(context).bodySmall.fontWeight,
                        fontStyle:
                            FlutterFlowTheme.of(context).bodySmall.fontStyle,
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
                      color: Color(0x00000000),
                      width: 2.0,
                    ),
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  errorBorder: OutlineInputBorder(
                    borderSide: BorderSide(
                      color: Color(0x00000000),
                      width: 2.0,
                    ),
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  focusedErrorBorder: OutlineInputBorder(
                    borderSide: BorderSide(
                      color: Color(0x00000000),
                      width: 2.0,
                    ),
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  filled: true,
                  fillColor: FlutterFlowTheme.of(context).secondaryBackground,
                  contentPadding:
                      EdgeInsetsDirectional.fromSTEB(20.0, 24.0, 0.0, 24.0),
                ),
                style: FlutterFlowTheme.of(context).bodyMedium.override(
                      font: TextStyle(
                        fontWeight:
                            FlutterFlowTheme.of(context).bodyMedium.fontWeight,
                        fontStyle:
                            FlutterFlowTheme.of(context).bodyMedium.fontStyle,
                      ),
                      letterSpacing: 0.0,
                      fontWeight:
                          FlutterFlowTheme.of(context).bodyMedium.fontWeight,
                      fontStyle:
                          FlutterFlowTheme.of(context).bodyMedium.fontStyle,
                    ),
                maxLines: null,
                validator:
                    _model.yourNameTextControllerValidator.asValidator(context),
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
              child: TextFormField(
                controller: _userIdController,
                readOnly: true,
                decoration: profileInputDecoration('User ID'),
                style: FlutterFlowTheme.of(context).bodyMedium.override(
                      letterSpacing: 0.0,
                      fontWeight: FontWeight.w600,
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
