import '/flutter_flow/flutter_flow_icon_button.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/index.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class CardDetailsWidget extends StatefulWidget {
  const CardDetailsWidget({super.key});

  static String routeName = 'Card_Details';
  static String routePath = 'cardDetails';

  @override
  State<CardDetailsWidget> createState() => _CardDetailsWidgetState();
}

class _CardDetailsWidgetState extends State<CardDetailsWidget> {
  static const _blue = Color(0xFF4472C4);
  bool _showDetails = false;

  String _masked(String value, {String mask = '***'}) {
    return _showDetails ? value : mask;
  }

  Widget _previewCard() {
    return Container(
      height: 168.0,
      padding: const EdgeInsetsDirectional.fromSTEB(18.0, 16.0, 18.0, 16.0),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: _blue,
        borderRadius: BorderRadius.circular(24.0),
        boxShadow: const [
          BoxShadow(
            blurRadius: 18.0,
            color: Color(0x22000000),
            offset: Offset(0.0, 9.0),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -20.0,
            bottom: -36.0,
            child: Opacity(
              opacity: 0.16,
              child: Image.asset(
                'assets/images/a_avatar.png',
                width: 150.0,
                height: 150.0,
                fit: BoxFit.contain,
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'VISA',
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontSize: 18.0,
                  fontWeight: FontWeight.w900,
                  fontStyle: FontStyle.italic,
                ),
              ),
              const Spacer(flex: 2),
              Row(
                children: [
                  _meta('Exp Date', _masked('02/28', mask: '**/**')),
                  const SizedBox(width: 20.0),
                  _meta('CVV', _masked('583')),
                ],
              ),
              const SizedBox(height: 8.0),
              Text(
                _showDetails ? '4321  8840  5502  9743' : '***  ***  ***9743',
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontSize: _showDetails ? 18.0 : 22.0,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.12,
                ),
              ),
              const SizedBox(height: 9.0),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _meta('Holder', 'Kayode Adewale'),
                ],
              ),
            ],
          ),
          Positioned(
            top: 0.0,
            right: 0.0,
            child: Icon(
              _showDetails
                  ? Icons.visibility_off_rounded
                  : Icons.visibility_rounded,
              color: Colors.white.withValues(alpha: 0.9),
              size: 20.0,
            ),
          ),
        ],
      ),
    );
  }

  static Widget _meta(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            color: Colors.white.withValues(alpha: 0.62),
            fontSize: 9.5,
            fontWeight: FontWeight.w700,
          ),
        ),
        Text(
          value,
          style: GoogleFonts.inter(
            color: Colors.white,
            fontSize: 12.0,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }

  Widget _field(BuildContext context, String label, String value) {
    final theme = FlutterFlowTheme.of(context);
    return Container(
      height: 50.0,
      alignment: Alignment.centerLeft,
      padding: const EdgeInsetsDirectional.fromSTEB(15.0, 0.0, 15.0, 0.0),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.84),
        borderRadius: BorderRadius.circular(14.0),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: theme.bodySmall.override(
                font: TextStyle(
                  fontWeight: FontWeight.normal,
                  fontStyle: theme.bodySmall.fontStyle,
                ),
                color: theme.primaryText,
                fontSize: 12.0,
                letterSpacing: 0.0,
                fontWeight: FontWeight.normal,
                fontStyle: theme.bodySmall.fontStyle,
              ),
            ),
          ),
          Text(
            value,
            style: GoogleFonts.inter(
              color: theme.primaryText,
              fontSize: 12.2,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF4F6FA),
        elevation: 0.0,
        leading: FlutterFlowIconButton(
          borderColor: Colors.transparent,
          borderRadius: 30.0,
          buttonSize: 52.0,
          icon: const Icon(Icons.arrow_back_rounded, color: _blue, size: 24.0),
          onPressed: () => context.goNamed(MyCardsWidget.routeName),
        ),
        title: Text(
          'Card details',
          style: theme.titleSmall.override(
            font: TextStyle(
              fontWeight: FontWeight.w800,
              fontStyle: theme.titleSmall.fontStyle,
            ),
            color: theme.primaryText,
            letterSpacing: 0.0,
            fontWeight: FontWeight.w800,
            fontStyle: theme.titleSmall.fontStyle,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsetsDirectional.fromSTEB(28.0, 14.0, 28.0, 28.0),
          children: [
            _previewCard(),
            const SizedBox(height: 26.0),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Card detail',
                    style: theme.titleSmall.override(
                      font: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontStyle: theme.titleSmall.fontStyle,
                      ),
                      color: theme.primaryText,
                      fontSize: 18.0,
                      letterSpacing: 0.0,
                      fontWeight: FontWeight.w800,
                      fontStyle: theme.titleSmall.fontStyle,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => safeSetState(() {
                    _showDetails = !_showDetails;
                  }),
                  icon: Icon(
                    _showDetails
                        ? Icons.visibility_off_rounded
                        : Icons.visibility_rounded,
                    color: _blue,
                    size: 21.0,
                  ),
                  tooltip: _showDetails ? 'Hide details' : 'Show details',
                ),
              ],
            ),
            const SizedBox(height: 10.0),
            _field(
              context,
              'Card number',
              _masked('4321 8840 5502 9743', mask: '**** **** **** 9743'),
            ),
            const SizedBox(height: 10.0),
            Row(
              children: [
                Expanded(
                  child: _field(
                      context, 'Expiry date', _masked('02/28', mask: '**/**')),
                ),
                const SizedBox(width: 10.0),
                Expanded(child: _field(context, 'VCC', _masked('583'))),
              ],
            ),
            const SizedBox(height: 10.0),
            _field(context, 'Card holder', 'Kayode Adewale'),
            const SizedBox(height: 10.0),
            _field(context, 'Country', 'Nigeria'),
          ],
        ),
      ),
    );
  }
}
