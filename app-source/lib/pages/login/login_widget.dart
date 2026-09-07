import '/components/status_action_button.dart';
import '/components/settle_numeric_keypad.dart';
import '/flutter_flow/flutter_flow_icon_button.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/index.dart';
import '/services/mobile_identity_service.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'login_model.dart';
export 'login_model.dart';

class LoginWidget extends StatefulWidget {
  const LoginWidget({
    super.key,
    this.mode = 'connect',
  });

  static String routeName = 'Login';
  static String routePath = 'login';

  final String mode;

  @override
  State<LoginWidget> createState() => _LoginWidgetState();
}

class _CountryDialCode {
  const _CountryDialCode(this.flag, this.name, this.code);

  final String flag;
  final String name;
  final String code;
}

const _countryDialCodes = [
  _CountryDialCode('🇳🇬', 'Nigeria', '+234'),
  _CountryDialCode('🇺🇸', 'United States', '+1'),
  _CountryDialCode('🇦🇫', 'Afghanistan', '+93'),
  _CountryDialCode('🇦🇱', 'Albania', '+355'),
  _CountryDialCode('🇩🇿', 'Algeria', '+213'),
  _CountryDialCode('🇦🇩', 'Andorra', '+376'),
  _CountryDialCode('🇦🇴', 'Angola', '+244'),
  _CountryDialCode('🇦🇬', 'Antigua and Barbuda', '+1-268'),
  _CountryDialCode('🇦🇷', 'Argentina', '+54'),
  _CountryDialCode('🇦🇲', 'Armenia', '+374'),
  _CountryDialCode('🇦🇺', 'Australia', '+61'),
  _CountryDialCode('🇦🇹', 'Austria', '+43'),
  _CountryDialCode('🇦🇿', 'Azerbaijan', '+994'),
  _CountryDialCode('🇧🇸', 'Bahamas', '+1-242'),
  _CountryDialCode('🇧🇭', 'Bahrain', '+973'),
  _CountryDialCode('🇧🇩', 'Bangladesh', '+880'),
  _CountryDialCode('🇧🇧', 'Barbados', '+1-246'),
  _CountryDialCode('🇧🇾', 'Belarus', '+375'),
  _CountryDialCode('🇧🇪', 'Belgium', '+32'),
  _CountryDialCode('🇧🇿', 'Belize', '+501'),
  _CountryDialCode('🇧🇯', 'Benin', '+229'),
  _CountryDialCode('🇧🇹', 'Bhutan', '+975'),
  _CountryDialCode('🇧🇴', 'Bolivia', '+591'),
  _CountryDialCode('🇧🇦', 'Bosnia and Herzegovina', '+387'),
  _CountryDialCode('🇧🇼', 'Botswana', '+267'),
  _CountryDialCode('🇧🇷', 'Brazil', '+55'),
  _CountryDialCode('🇧🇳', 'Brunei', '+673'),
  _CountryDialCode('🇧🇬', 'Bulgaria', '+359'),
  _CountryDialCode('🇧🇫', 'Burkina Faso', '+226'),
  _CountryDialCode('🇧🇮', 'Burundi', '+257'),
  _CountryDialCode('🇰🇭', 'Cambodia', '+855'),
  _CountryDialCode('🇨🇲', 'Cameroon', '+237'),
  _CountryDialCode('🇨🇦', 'Canada', '+1'),
  _CountryDialCode('🇨🇻', 'Cape Verde', '+238'),
  _CountryDialCode('🇨🇫', 'Central African Republic', '+236'),
  _CountryDialCode('🇹🇩', 'Chad', '+235'),
  _CountryDialCode('🇨🇱', 'Chile', '+56'),
  _CountryDialCode('🇨🇳', 'China', '+86'),
  _CountryDialCode('🇨🇴', 'Colombia', '+57'),
  _CountryDialCode('🇰🇲', 'Comoros', '+269'),
  _CountryDialCode('🇨🇬', 'Congo', '+242'),
  _CountryDialCode('🇨🇩', 'Congo DR', '+243'),
  _CountryDialCode('🇨🇷', 'Costa Rica', '+506'),
  _CountryDialCode('🇨🇮', 'Cote d’Ivoire', '+225'),
  _CountryDialCode('🇭🇷', 'Croatia', '+385'),
  _CountryDialCode('🇨🇺', 'Cuba', '+53'),
  _CountryDialCode('🇨🇾', 'Cyprus', '+357'),
  _CountryDialCode('🇨🇿', 'Czech Republic', '+420'),
  _CountryDialCode('🇩🇰', 'Denmark', '+45'),
  _CountryDialCode('🇩🇯', 'Djibouti', '+253'),
  _CountryDialCode('🇩🇲', 'Dominica', '+1-767'),
  _CountryDialCode('🇩🇴', 'Dominican Republic', '+1-809'),
  _CountryDialCode('🇪🇨', 'Ecuador', '+593'),
  _CountryDialCode('🇪🇬', 'Egypt', '+20'),
  _CountryDialCode('🇸🇻', 'El Salvador', '+503'),
  _CountryDialCode('🇬🇶', 'Equatorial Guinea', '+240'),
  _CountryDialCode('🇪🇷', 'Eritrea', '+291'),
  _CountryDialCode('🇪🇪', 'Estonia', '+372'),
  _CountryDialCode('🇸🇿', 'Eswatini', '+268'),
  _CountryDialCode('🇪🇹', 'Ethiopia', '+251'),
  _CountryDialCode('🇫🇯', 'Fiji', '+679'),
  _CountryDialCode('🇫🇮', 'Finland', '+358'),
  _CountryDialCode('🇫🇷', 'France', '+33'),
  _CountryDialCode('🇬🇦', 'Gabon', '+241'),
  _CountryDialCode('🇬🇲', 'Gambia', '+220'),
  _CountryDialCode('🇬🇪', 'Georgia', '+995'),
  _CountryDialCode('🇩🇪', 'Germany', '+49'),
  _CountryDialCode('🇬🇭', 'Ghana', '+233'),
  _CountryDialCode('🇬🇷', 'Greece', '+30'),
  _CountryDialCode('🇬🇩', 'Grenada', '+1-473'),
  _CountryDialCode('🇬🇹', 'Guatemala', '+502'),
  _CountryDialCode('🇬🇳', 'Guinea', '+224'),
  _CountryDialCode('🇬🇼', 'Guinea-Bissau', '+245'),
  _CountryDialCode('🇬🇾', 'Guyana', '+592'),
  _CountryDialCode('🇭🇹', 'Haiti', '+509'),
  _CountryDialCode('🇭🇳', 'Honduras', '+504'),
  _CountryDialCode('🇭🇺', 'Hungary', '+36'),
  _CountryDialCode('🇮🇸', 'Iceland', '+354'),
  _CountryDialCode('🇮🇳', 'India', '+91'),
  _CountryDialCode('🇮🇩', 'Indonesia', '+62'),
  _CountryDialCode('🇮🇷', 'Iran', '+98'),
  _CountryDialCode('🇮🇶', 'Iraq', '+964'),
  _CountryDialCode('🇮🇪', 'Ireland', '+353'),
  _CountryDialCode('🇮🇱', 'Israel', '+972'),
  _CountryDialCode('🇮🇹', 'Italy', '+39'),
  _CountryDialCode('🇯🇲', 'Jamaica', '+1-876'),
  _CountryDialCode('🇯🇵', 'Japan', '+81'),
  _CountryDialCode('🇯🇴', 'Jordan', '+962'),
  _CountryDialCode('🇰🇿', 'Kazakhstan', '+7'),
  _CountryDialCode('🇰🇪', 'Kenya', '+254'),
  _CountryDialCode('🇰🇮', 'Kiribati', '+686'),
  _CountryDialCode('🇰🇼', 'Kuwait', '+965'),
  _CountryDialCode('🇰🇬', 'Kyrgyzstan', '+996'),
  _CountryDialCode('🇱🇦', 'Laos', '+856'),
  _CountryDialCode('🇱🇻', 'Latvia', '+371'),
  _CountryDialCode('🇱🇧', 'Lebanon', '+961'),
  _CountryDialCode('🇱🇸', 'Lesotho', '+266'),
  _CountryDialCode('🇱🇷', 'Liberia', '+231'),
  _CountryDialCode('🇱🇾', 'Libya', '+218'),
  _CountryDialCode('🇱🇮', 'Liechtenstein', '+423'),
  _CountryDialCode('🇱🇹', 'Lithuania', '+370'),
  _CountryDialCode('🇱🇺', 'Luxembourg', '+352'),
  _CountryDialCode('🇲🇬', 'Madagascar', '+261'),
  _CountryDialCode('🇲🇼', 'Malawi', '+265'),
  _CountryDialCode('🇲🇾', 'Malaysia', '+60'),
  _CountryDialCode('🇲🇻', 'Maldives', '+960'),
  _CountryDialCode('🇲🇱', 'Mali', '+223'),
  _CountryDialCode('🇲🇹', 'Malta', '+356'),
  _CountryDialCode('🇲🇭', 'Marshall Islands', '+692'),
  _CountryDialCode('🇲🇷', 'Mauritania', '+222'),
  _CountryDialCode('🇲🇺', 'Mauritius', '+230'),
  _CountryDialCode('🇲🇽', 'Mexico', '+52'),
  _CountryDialCode('🇫🇲', 'Micronesia', '+691'),
  _CountryDialCode('🇲🇩', 'Moldova', '+373'),
  _CountryDialCode('🇲🇨', 'Monaco', '+377'),
  _CountryDialCode('🇲🇳', 'Mongolia', '+976'),
  _CountryDialCode('🇲🇪', 'Montenegro', '+382'),
  _CountryDialCode('🇲🇦', 'Morocco', '+212'),
  _CountryDialCode('🇲🇿', 'Mozambique', '+258'),
  _CountryDialCode('🇲🇲', 'Myanmar', '+95'),
  _CountryDialCode('🇳🇦', 'Namibia', '+264'),
  _CountryDialCode('🇳🇷', 'Nauru', '+674'),
  _CountryDialCode('🇳🇵', 'Nepal', '+977'),
  _CountryDialCode('🇳🇱', 'Netherlands', '+31'),
  _CountryDialCode('🇳🇿', 'New Zealand', '+64'),
  _CountryDialCode('🇳🇮', 'Nicaragua', '+505'),
  _CountryDialCode('🇳🇪', 'Niger', '+227'),
  _CountryDialCode('🇰🇵', 'North Korea', '+850'),
  _CountryDialCode('🇲🇰', 'North Macedonia', '+389'),
  _CountryDialCode('🇳🇴', 'Norway', '+47'),
  _CountryDialCode('🇴🇲', 'Oman', '+968'),
  _CountryDialCode('🇵🇰', 'Pakistan', '+92'),
  _CountryDialCode('🇵🇼', 'Palau', '+680'),
  _CountryDialCode('🇵🇦', 'Panama', '+507'),
  _CountryDialCode('🇵🇬', 'Papua New Guinea', '+675'),
  _CountryDialCode('🇵🇾', 'Paraguay', '+595'),
  _CountryDialCode('🇵🇪', 'Peru', '+51'),
  _CountryDialCode('🇵🇭', 'Philippines', '+63'),
  _CountryDialCode('🇵🇱', 'Poland', '+48'),
  _CountryDialCode('🇵🇹', 'Portugal', '+351'),
  _CountryDialCode('🇶🇦', 'Qatar', '+974'),
  _CountryDialCode('🇷🇴', 'Romania', '+40'),
  _CountryDialCode('🇷🇺', 'Russia', '+7'),
  _CountryDialCode('🇷🇼', 'Rwanda', '+250'),
  _CountryDialCode('🇰🇳', 'Saint Kitts and Nevis', '+1-869'),
  _CountryDialCode('🇱🇨', 'Saint Lucia', '+1-758'),
  _CountryDialCode('🇻🇨', 'Saint Vincent', '+1-784'),
  _CountryDialCode('🇼🇸', 'Samoa', '+685'),
  _CountryDialCode('🇸🇲', 'San Marino', '+378'),
  _CountryDialCode('🇸🇹', 'Sao Tome and Principe', '+239'),
  _CountryDialCode('🇸🇦', 'Saudi Arabia', '+966'),
  _CountryDialCode('🇸🇳', 'Senegal', '+221'),
  _CountryDialCode('🇷🇸', 'Serbia', '+381'),
  _CountryDialCode('🇸🇨', 'Seychelles', '+248'),
  _CountryDialCode('🇸🇱', 'Sierra Leone', '+232'),
  _CountryDialCode('🇸🇬', 'Singapore', '+65'),
  _CountryDialCode('🇸🇰', 'Slovakia', '+421'),
  _CountryDialCode('🇸🇮', 'Slovenia', '+386'),
  _CountryDialCode('🇸🇧', 'Solomon Islands', '+677'),
  _CountryDialCode('🇸🇴', 'Somalia', '+252'),
  _CountryDialCode('🇿🇦', 'South Africa', '+27'),
  _CountryDialCode('🇰🇷', 'South Korea', '+82'),
  _CountryDialCode('🇸🇸', 'South Sudan', '+211'),
  _CountryDialCode('🇪🇸', 'Spain', '+34'),
  _CountryDialCode('🇱🇰', 'Sri Lanka', '+94'),
  _CountryDialCode('🇸🇩', 'Sudan', '+249'),
  _CountryDialCode('🇸🇷', 'Suriname', '+597'),
  _CountryDialCode('🇸🇪', 'Sweden', '+46'),
  _CountryDialCode('🇨🇭', 'Switzerland', '+41'),
  _CountryDialCode('🇸🇾', 'Syria', '+963'),
  _CountryDialCode('🇹🇼', 'Taiwan', '+886'),
  _CountryDialCode('🇹🇯', 'Tajikistan', '+992'),
  _CountryDialCode('🇹🇿', 'Tanzania', '+255'),
  _CountryDialCode('🇹🇭', 'Thailand', '+66'),
  _CountryDialCode('🇹🇱', 'Timor-Leste', '+670'),
  _CountryDialCode('🇹🇬', 'Togo', '+228'),
  _CountryDialCode('🇹🇴', 'Tonga', '+676'),
  _CountryDialCode('🇹🇹', 'Trinidad and Tobago', '+1-868'),
  _CountryDialCode('🇹🇳', 'Tunisia', '+216'),
  _CountryDialCode('🇹🇷', 'Turkey', '+90'),
  _CountryDialCode('🇹🇲', 'Turkmenistan', '+993'),
  _CountryDialCode('🇹🇻', 'Tuvalu', '+688'),
  _CountryDialCode('🇺🇬', 'Uganda', '+256'),
  _CountryDialCode('🇺🇦', 'Ukraine', '+380'),
  _CountryDialCode('🇦🇪', 'United Arab Emirates', '+971'),
  _CountryDialCode('🇬🇧', 'United Kingdom', '+44'),
  _CountryDialCode('🇺🇾', 'Uruguay', '+598'),
  _CountryDialCode('🇺🇿', 'Uzbekistan', '+998'),
  _CountryDialCode('🇻🇺', 'Vanuatu', '+678'),
  _CountryDialCode('🇻🇦', 'Vatican City', '+379'),
  _CountryDialCode('🇻🇪', 'Venezuela', '+58'),
  _CountryDialCode('🇻🇳', 'Vietnam', '+84'),
  _CountryDialCode('🇾🇪', 'Yemen', '+967'),
  _CountryDialCode('🇿🇲', 'Zambia', '+260'),
  _CountryDialCode('🇿🇼', 'Zimbabwe', '+263'),
];

class _LoginWidgetState extends State<LoginWidget> {
  late LoginModel _model;

  final scaffoldKey = GlobalKey<ScaffoldState>();
  String _connectMethod = 'phone';
  _CountryDialCode _selectedCountry = _countryDialCodes.first;
  final _referralCodeController = TextEditingController();
  bool _isContinuing = false;
  bool _isContinueDone = false;

  bool get _isRecoverPinMode => widget.mode == 'recover_pin';

  String get _inputLabel {
    switch (_connectMethod) {
      case 'wallet':
        return 'Wallet Address';
      case 'email':
        return 'Email Address';
      case 'google':
        return 'Google Email';
      default:
        return 'Your Phone Number...';
    }
  }

  String get _inputHint {
    switch (_connectMethod) {
      case 'wallet':
        return '0x0000... or wallet address';
      case 'email':
        return 'you@example.com';
      case 'google':
        return 'yourgoogle@gmail.com';
      default:
        return '(204) 204-2056';
    }
  }

  TextInputType get _keyboardType {
    switch (_connectMethod) {
      case 'email':
      case 'google':
        return TextInputType.emailAddress;
      case 'wallet':
        return TextInputType.text;
      default:
        return TextInputType.phone;
    }
  }

  String get _connectMethodLabel {
    switch (_connectMethod) {
      case 'wallet':
        return 'Wallet address';
      case 'email':
        return 'Email';
      case 'google':
        return 'Google';
      default:
        return 'Phone number';
    }
  }

  Future<void> _showConnectOptions() async {
    final selected = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: FlutterFlowTheme.of(context).secondaryBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18.0)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding:
                const EdgeInsetsDirectional.fromSTEB(20.0, 16.0, 20.0, 22.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Connect options',
                  style: FlutterFlowTheme.of(context).headlineSmall.override(
                        fontFamily: 'Hornbill',
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
                const SizedBox(height: 12.0),
                _connectOptionTile(
                  context,
                  value: 'phone',
                  label: 'Phone number',
                  icon: Icons.phone_iphone_rounded,
                ),
                _connectOptionTile(
                  context,
                  value: 'wallet',
                  label: 'Wallet address',
                  icon: Icons.account_balance_wallet_rounded,
                ),
                _connectOptionTile(
                  context,
                  value: 'email',
                  label: 'Email',
                  icon: Icons.mail_rounded,
                ),
                _connectOptionTile(
                  context,
                  value: 'google',
                  label: 'Google',
                  icon: Icons.g_mobiledata_rounded,
                ),
              ],
            ),
          ),
        );
      },
    );

    if (selected == null || selected == _connectMethod) {
      return;
    }

    safeSetState(() {
      _connectMethod = selected;
      _model.phoneNumberTextController?.clear();
    });
  }

  Future<void> _showCountryCodes() async {
    final selected = await showModalBottomSheet<_CountryDialCode>(
      context: context,
      backgroundColor: FlutterFlowTheme.of(context).secondaryBackground,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18.0)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.72,
          minChildSize: 0.42,
          maxChildSize: 0.9,
          builder: (context, scrollController) {
            return SafeArea(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsetsDirectional.fromSTEB(
                        20.0, 16.0, 20.0, 10.0),
                    child: Text(
                      'Country code',
                      style:
                          FlutterFlowTheme.of(context).headlineSmall.override(
                                fontFamily: 'Hornbill',
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
                  ),
                  Expanded(
                    child: ListView.separated(
                      controller: scrollController,
                      padding: const EdgeInsetsDirectional.fromSTEB(
                          20.0, 0.0, 20.0, 22.0),
                      itemCount: _countryDialCodes.length,
                      separatorBuilder: (_, __) => Divider(
                        height: 1.0,
                        color: FlutterFlowTheme.of(context).primaryBackground,
                      ),
                      itemBuilder: (context, index) {
                        final country = _countryDialCodes[index];
                        final selected = country == _selectedCountry;

                        return ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: Text(
                            country.flag,
                            style: const TextStyle(
                              fontFamily: 'sans-serif',
                              fontSize: 22.0,
                            ),
                          ),
                          title: Text(
                            country.name,
                            style: FlutterFlowTheme.of(context)
                                .bodyLarge
                                .override(
                                  fontFamily: 'Hornbill',
                                  font: TextStyle(
                                    fontWeight: selected
                                        ? FontWeight.w700
                                        : FontWeight.normal,
                                    fontStyle: FlutterFlowTheme.of(context)
                                        .bodyLarge
                                        .fontStyle,
                                  ),
                                  color:
                                      FlutterFlowTheme.of(context).primaryText,
                                  fontSize: 14.0,
                                  letterSpacing: 0.0,
                                  fontWeight: selected
                                      ? FontWeight.w700
                                      : FontWeight.normal,
                                  fontStyle: FlutterFlowTheme.of(context)
                                      .bodyLarge
                                      .fontStyle,
                                ),
                          ),
                          trailing: Text(
                            country.code,
                            style: GoogleFonts.inter(
                              color: selected
                                  ? FlutterFlowTheme.of(context).primary
                                  : FlutterFlowTheme.of(context).secondaryText,
                              fontSize: 14.0,
                              fontWeight:
                                  selected ? FontWeight.w700 : FontWeight.w500,
                              letterSpacing: 0.0,
                            ),
                          ),
                          onTap: () => Navigator.pop(context, country),
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );

    if (selected == null || selected == _selectedCountry) {
      return;
    }

    safeSetState(() {
      _selectedCountry = selected;
    });
  }

  Widget _connectOptionTile(
    BuildContext context, {
    required String value,
    required String label,
    required IconData icon,
  }) {
    final selected = value == _connectMethod;

    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(
        icon,
        color: selected
            ? FlutterFlowTheme.of(context).primary
            : FlutterFlowTheme.of(context).secondaryText,
      ),
      title: Text(
        label,
        style: FlutterFlowTheme.of(context).bodyLarge.override(
              fontFamily: 'Hornbill',
              font: TextStyle(
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                fontStyle: FlutterFlowTheme.of(context).bodyLarge.fontStyle,
              ),
              color: selected
                  ? FlutterFlowTheme.of(context).primary
                  : FlutterFlowTheme.of(context).primaryText,
              letterSpacing: 0.0,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              fontStyle: FlutterFlowTheme.of(context).bodyLarge.fontStyle,
            ),
      ),
      trailing: selected
          ? Icon(
              Icons.check_rounded,
              color: FlutterFlowTheme.of(context).primary,
            )
          : null,
      onTap: () => Navigator.pop(context, value),
    );
  }

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => LoginModel());

    _model.phoneNumberTextController ??= TextEditingController();
    _model.phoneNumberFocusNode ??= FocusNode();
  }

  @override
  void dispose() {
    _referralCodeController.dispose();
    _model.dispose();

    super.dispose();
  }

  Future<void> _handleContinuePressed() async {
    if (_isContinuing) {
      return;
    }

    safeSetState(() {
      _isContinuing = true;
      _isContinueDone = false;
    });
    await Future.delayed(const Duration(milliseconds: 650));
    if (!mounted) {
      return;
    }
    safeSetState(() => _isContinueDone = true);
    await Future.delayed(const Duration(milliseconds: 450));
    if (!mounted) {
      return;
    }
    if (_connectMethod == 'phone') {
      await MobileIdentityService.savePhone(
        _model.phoneNumberTextController?.text ?? '',
        dialCode: _selectedCountry.code,
      );
    }
    await context.pushNamed(
      ConfirmCodeWidget.routeName,
      queryParameters: _isRecoverPinMode ? {'mode': 'recover'} : {},
    );
    if (!mounted) return;
    safeSetState(() {
      _isContinuing = false;
      _isContinueDone = false;
    });
  }

  Future<void> _openPhoneKeypad() async {
    _model.phoneNumberFocusNode?.requestFocus();
    final fieldContext = _model.phoneNumberFocusNode?.context;
    if (fieldContext != null) {
      await Scrollable.ensureVisible(
        fieldContext,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        alignment: 0.02,
      );
    }
    await Future.delayed(const Duration(milliseconds: 80));
    if (!mounted) return;
    SettleNumericKeypad.show(
      context,
      title: 'Phone number',
      initialValue: _model.phoneNumberTextController?.text ?? '',
      maxLength: 15,
      onChanged: (value) {
        _model.phoneNumberTextController?.text = value;
        safeSetState(() {});
      },
      onDone: (value) {
        _model.phoneNumberTextController?.text = value;
        safeSetState(() {});
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
        FocusManager.instance.primaryFocus?.unfocus();
      },
      child: Scaffold(
        key: scaffoldKey,
        backgroundColor: FlutterFlowTheme.of(context).primaryBackground,
        body: Container(
          width: double.infinity,
          height: MediaQuery.sizeOf(context).height * 1.0,
          decoration: BoxDecoration(
            color: FlutterFlowTheme.of(context).primaryBackground,
          ),
          child: Align(
            alignment: AlignmentDirectional(0.0, 1.0),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.max,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Padding(
                    padding:
                        EdgeInsetsDirectional.fromSTEB(0.0, 70.0, 0.0, 0.0),
                    child: Row(
                      mainAxisSize: MainAxisSize.max,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Image.asset(
                          'assets/images/long_logo_short.png',
                          width: 173.5,
                          height: 60.0,
                          fit: BoxFit.fitWidth,
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding:
                        EdgeInsetsDirectional.fromSTEB(0.0, 10.0, 0.0, 0.0),
                    child: Text(
                      'Transact money easily...',
                      style: FlutterFlowTheme.of(context).bodyMedium.override(
                            fontFamily: 'Hornbill',
                            font: TextStyle(
                              fontWeight: FontWeight.normal,
                              fontStyle: FlutterFlowTheme.of(context)
                                  .bodyMedium
                                  .fontStyle,
                            ),
                            letterSpacing: 0.0,
                            fontWeight: FontWeight.normal,
                            fontStyle: FlutterFlowTheme.of(context)
                                .bodyMedium
                                .fontStyle,
                          ),
                    ),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.max,
                    children: [
                      Padding(
                        padding:
                            EdgeInsetsDirectional.fromSTEB(0.0, 0.0, 0.0, 20.0),
                        child: Image.asset(
                          'assets/images/vnimc_1.png',
                          width: MediaQuery.sizeOf(context).width * 0.92,
                          height: MediaQuery.sizeOf(context).height * 0.34,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: FlutterFlowTheme.of(context).secondaryBackground,
                      boxShadow: [
                        BoxShadow(
                          blurRadius: 4.0,
                          color: Color(0x3600000F),
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
                              Padding(
                                padding: EdgeInsetsDirectional.fromSTEB(
                                    0.0, 0.0, 16.0, 0.0),
                                child: FlutterFlowIconButton(
                                  borderColor: FlutterFlowTheme.of(context)
                                      .primaryBackground,
                                  borderRadius: 30.0,
                                  borderWidth: 2.0,
                                  buttonSize: 44.0,
                                  icon: Icon(
                                    Icons.arrow_back_rounded,
                                    color: FlutterFlowTheme.of(context)
                                        .secondaryText,
                                    size: 24.0,
                                  ),
                                  onPressed: () async {
                                    context.pop();
                                  },
                                ),
                              ),
                              Expanded(
                                child: Text(
                                  _isRecoverPinMode ? 'Recover Pin' : 'Connect',
                                  style: FlutterFlowTheme.of(context)
                                      .headlineMedium
                                      .override(
                                        fontFamily: 'Hornbill',
                                        font: TextStyle(
                                          fontWeight:
                                              FlutterFlowTheme.of(context)
                                                  .headlineMedium
                                                  .fontWeight,
                                          fontStyle:
                                              FlutterFlowTheme.of(context)
                                                  .headlineMedium
                                                  .fontStyle,
                                        ),
                                        color: Color(0xFF4472C4),
                                        letterSpacing: 0.0,
                                        fontWeight: FlutterFlowTheme.of(context)
                                            .headlineMedium
                                            .fontWeight,
                                        fontStyle: FlutterFlowTheme.of(context)
                                            .headlineMedium
                                            .fontStyle,
                                      ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsetsDirectional.fromSTEB(
                              20.0, 10.0, 20.0, 0.0),
                          child: TextFormField(
                            controller: _referralCodeController,
                            textCapitalization: TextCapitalization.characters,
                            decoration: InputDecoration(
                              labelText: 'Referral code',
                              hintText: 'Optional',
                              labelStyle: FlutterFlowTheme.of(context)
                                  .bodySmall
                                  .override(
                                    fontFamily: 'Hornbill',
                                    color: FlutterFlowTheme.of(context)
                                        .secondaryText,
                                    fontSize: 11.0,
                                    letterSpacing: 0.0,
                                    fontWeight: FontWeight.w500,
                                  ),
                              hintStyle: FlutterFlowTheme.of(context)
                                  .bodySmall
                                  .override(
                                    fontFamily: 'Hornbill',
                                    color: FlutterFlowTheme.of(context)
                                        .secondaryText,
                                    fontSize: 11.0,
                                    letterSpacing: 0.0,
                                    fontWeight: FontWeight.w500,
                                  ),
                              filled: true,
                              fillColor: FlutterFlowTheme.of(context)
                                  .secondaryBackground,
                              contentPadding:
                                  const EdgeInsetsDirectional.fromSTEB(
                                      16.0, 12.0, 16.0, 12.0),
                              enabledBorder: OutlineInputBorder(
                                borderSide: BorderSide(
                                  color: FlutterFlowTheme.of(context)
                                      .primaryBackground,
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
                            ),
                            style: FlutterFlowTheme.of(context)
                                .bodyMedium
                                .override(
                                  fontFamily: 'Hornbill',
                                  color:
                                      FlutterFlowTheme.of(context).primaryText,
                                  fontSize: 13.0,
                                  letterSpacing: 0.0,
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                        ),
                        Padding(
                          padding: EdgeInsetsDirectional.fromSTEB(
                              20.0, 12.0, 20.0, 0.0),
                          child: InkWell(
                            onTap: _showConnectOptions,
                            borderRadius: BorderRadius.circular(8.0),
                            child: Padding(
                              padding: const EdgeInsetsDirectional.fromSTEB(
                                  0.0, 4.0, 0.0, 4.0),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      'Connect with other options',
                                      style: FlutterFlowTheme.of(context)
                                          .bodySmall
                                          .override(
                                            fontFamily: 'Hornbill',
                                            font: TextStyle(
                                              fontWeight: FontWeight.normal,
                                              fontStyle:
                                                  FlutterFlowTheme.of(context)
                                                      .bodySmall
                                                      .fontStyle,
                                            ),
                                            color: FlutterFlowTheme.of(context)
                                                .primary,
                                            fontSize: 11.0,
                                            letterSpacing: 0.0,
                                            fontWeight: FontWeight.normal,
                                            fontStyle:
                                                FlutterFlowTheme.of(context)
                                                    .bodySmall
                                                    .fontStyle,
                                          ),
                                    ),
                                  ),
                                  Text(
                                    _connectMethodLabel,
                                    style: FlutterFlowTheme.of(context)
                                        .bodySmall
                                        .override(
                                          fontFamily: 'Hornbill',
                                          font: TextStyle(
                                            fontWeight: FontWeight.normal,
                                            fontStyle:
                                                FlutterFlowTheme.of(context)
                                                    .bodySmall
                                                    .fontStyle,
                                          ),
                                          color: FlutterFlowTheme.of(context)
                                              .secondaryText,
                                          fontSize: 11.0,
                                          letterSpacing: 0.0,
                                          fontWeight: FontWeight.normal,
                                          fontStyle:
                                              FlutterFlowTheme.of(context)
                                                  .bodySmall
                                                  .fontStyle,
                                        ),
                                  ),
                                  Icon(
                                    Icons.keyboard_arrow_down_rounded,
                                    color: FlutterFlowTheme.of(context)
                                        .secondaryText,
                                    size: 20.0,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        Padding(
                          padding: EdgeInsetsDirectional.fromSTEB(
                              20.0, 6.0, 20.0, 0.0),
                          child: Row(
                            mainAxisSize: MainAxisSize.max,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              if (_connectMethod == 'phone')
                                InkWell(
                                  onTap: _showCountryCodes,
                                  borderRadius: BorderRadius.circular(8.0),
                                  child: Container(
                                    height: 46.0,
                                    padding:
                                        const EdgeInsetsDirectional.fromSTEB(
                                            10.0, 0.0, 8.0, 0.0),
                                    margin: const EdgeInsetsDirectional.only(
                                        end: 8.0),
                                    alignment: Alignment.center,
                                    decoration: BoxDecoration(
                                      color: FlutterFlowTheme.of(context)
                                          .secondaryBackground,
                                      borderRadius: BorderRadius.circular(8.0),
                                      border: Border.all(
                                        color: FlutterFlowTheme.of(context)
                                            .primaryBackground,
                                        width: 2.0,
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          _selectedCountry.flag,
                                          style: const TextStyle(
                                            fontFamily: 'sans-serif',
                                            fontSize: 18.0,
                                          ),
                                        ),
                                        const SizedBox(width: 5.0),
                                        Text(
                                          _selectedCountry.code,
                                          style: GoogleFonts.inter(
                                            color: FlutterFlowTheme.of(context)
                                                .primaryText,
                                            fontSize: 14.0,
                                            fontWeight: FontWeight.w600,
                                            letterSpacing: 0.0,
                                          ),
                                        ),
                                        Icon(
                                          Icons.keyboard_arrow_down_rounded,
                                          color: FlutterFlowTheme.of(context)
                                              .secondaryText,
                                          size: 17.0,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              Expanded(
                                child: TextFormField(
                                  controller: _model.phoneNumberTextController,
                                  focusNode: _model.phoneNumberFocusNode,
                                  readOnly: _connectMethod == 'phone',
                                  showCursor: true,
                                  cursorColor:
                                      FlutterFlowTheme.of(context).primary,
                                  cursorWidth: 2.0,
                                  onTap: _connectMethod == 'phone'
                                      ? _openPhoneKeypad
                                      : null,
                                  keyboardType: _keyboardType,
                                  obscureText: false,
                                  decoration: InputDecoration(
                                    labelText: _inputLabel,
                                    labelStyle: FlutterFlowTheme.of(context)
                                        .titleSmall
                                        .override(
                                          fontFamily: 'Hornbill',
                                          font: TextStyle(
                                            fontWeight: FontWeight.w500,
                                            fontStyle:
                                                FlutterFlowTheme.of(context)
                                                    .titleSmall
                                                    .fontStyle,
                                          ),
                                          letterSpacing: 0.0,
                                          fontWeight: FontWeight.w500,
                                          fontStyle:
                                              FlutterFlowTheme.of(context)
                                                  .titleSmall
                                                  .fontStyle,
                                        ),
                                    hintText: _inputHint,
                                    hintStyle: GoogleFonts.inter(
                                      color: FlutterFlowTheme.of(context)
                                          .secondaryText,
                                      fontSize: 14.0,
                                      fontWeight: FontWeight.normal,
                                      letterSpacing: 0.0,
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderSide: BorderSide(
                                        color: FlutterFlowTheme.of(context)
                                            .primaryBackground,
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
                                    fillColor: FlutterFlowTheme.of(context)
                                        .secondaryBackground,
                                    contentPadding:
                                        EdgeInsetsDirectional.fromSTEB(
                                            16.0, 12.0, 16.0, 12.0),
                                  ),
                                  style: GoogleFonts.inter(
                                    color: FlutterFlowTheme.of(context)
                                        .primaryText,
                                    fontSize: 18.0,
                                    fontWeight: FontWeight.w500,
                                    letterSpacing: 0.0,
                                  ),
                                  maxLines: 1,
                                  validator: _model
                                      .phoneNumberTextControllerValidator
                                      .asValidator(context),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Padding(
                          padding: EdgeInsetsDirectional.fromSTEB(
                              20.0, 12.0, 20.0, 32.0),
                          child: Row(
                            mainAxisSize: MainAxisSize.max,
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              StatusActionButton(
                                text: 'Continue',
                                isLoading: _isContinuing && !_isContinueDone,
                                isDone: _isContinueDone,
                                onPressed: _handleContinuePressed,
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
          ),
        ),
      ),
    );
  }
}
