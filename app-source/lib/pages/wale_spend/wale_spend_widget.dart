import '/flutter_flow/flutter_flow_icon_button.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/index.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class WaleSpendWidget extends StatelessWidget {
  const WaleSpendWidget({super.key});

  static String routeName = 'WaleSpend';
  static String routePath = 'waleSpend';
  static const _blue = Color(0xFF4472C4);
  static const _spendUrl = 'https://spend.2settle.io';

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
          borderRadius: 28.0,
          buttonSize: 48.0,
          icon: Icon(Icons.arrow_back_rounded,
              color: theme.primaryText, size: 24.0),
          onPressed: () => context.goNamed(AllServicesWidget.routeName),
        ),
        actions: [
          FlutterFlowIconButton(
            borderColor: Colors.transparent,
            borderRadius: 28.0,
            buttonSize: 48.0,
            icon: const Icon(Icons.home_rounded, color: _blue, size: 22.0),
            onPressed: () => context.goNamed(DashboardWidget.routeName),
          ),
        ],
        title: Text(
          'Wale',
          style: theme.titleMedium.override(
            color: theme.primaryText,
            fontSize: 18.0,
            letterSpacing: 0.0,
            fontWeight: FontWeight.w800,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(20.0, 20.0, 20.0, 28.0),
          child: Column(
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsetsDirectional.fromSTEB(
                    18.0, 22.0, 18.0, 22.0),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(22.0),
                  border: Border.all(color: _blue.withValues(alpha: 0.1)),
                  boxShadow: const [
                    BoxShadow(
                      blurRadius: 18.0,
                      color: Color(0x14000000),
                      offset: Offset(0.0, 8.0),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    ClipOval(
                      child: Image.asset(
                        'assets/images/a_avatar.png',
                        width: 88.0,
                        height: 88.0,
                        fit: BoxFit.cover,
                      ),
                    ),
                    const SizedBox(height: 14.0),
                    Text(
                      'Spend with 2Settle',
                      style: theme.titleMedium.override(
                        color: theme.primaryText,
                        fontSize: 20.0,
                        letterSpacing: 0.0,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 6.0),
                    Text(
                      _spendUrl,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                        color: theme.secondaryText,
                        fontSize: 12.0,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 18.0),
                    InkWell(
                      onTap: () => launchURL(_spendUrl),
                      borderRadius: BorderRadius.circular(26.0),
                      child: Container(
                        padding: const EdgeInsetsDirectional.fromSTEB(
                            18.0, 12.0, 9.0, 12.0),
                        decoration: BoxDecoration(
                          color: _blue,
                          borderRadius: BorderRadius.circular(26.0),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Open Spend',
                              style: theme.bodySmall.override(
                                color: Colors.white,
                                fontSize: 13.0,
                                letterSpacing: 0.0,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(width: 10.0),
                            Container(
                              width: 34.0,
                              height: 34.0,
                              decoration: const BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.open_in_new_rounded,
                                  color: _blue, size: 18.0),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
