import '/flutter_flow/flutter_flow_icon_button.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/index.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class VersionHistoryWidget extends StatelessWidget {
  const VersionHistoryWidget({super.key});

  static String routeName = 'VersionHistory';
  static String routePath = 'versionHistory';
  static const _blue = Color(0xFF4472C4);

  static const _versions = [
    _VersionNote(
      version: 'V2.36.5',
      title: 'Navigation and receive request status',
      items: [
        'Fixed Receive Payment, Bank Details, and Receive Request back navigation loops.',
        'Changed receive request Copy Link and Share to compact icon widgets.',
        'Added manual receive request status dropdown and paid progression.',
      ],
    ),
    _VersionNote(
      version: 'V2.36.4',
      title: 'Receive payment details pages',
      items: [
        'Split Receive Payment Details into Naira, Dollar, and Wallet setup pages.',
        'Added live Naira bank validation and default account handling.',
        'Made Receive Transactions clickable with a detail/preview page.',
      ],
    ),
    _VersionNote(
      version: 'V2.36.3',
      title: 'Account hub and receive setup',
      items: [
        'Added Account submenu under Settings.',
        'Moved Bank & beneficiary and Receive Payment Details under Account.',
        'Prepared receive destination storage for bank, dollar, and wallet details.',
      ],
    ),
    _VersionNote(
      version: 'V2.36.x',
      title: 'Live conversion and notification polish',
      items: [
        'Refined live conversion card cut-outs and selector placement.',
        'Adjusted rate notification timing to reduce user fatigue.',
        'Improved conversion page hierarchy and calculator behavior.',
      ],
    ),
    _VersionNote(
      version: 'V2.35',
      title: 'Settings and profile polish',
      items: [
        'Redesigned Settings into grouped fintech cards.',
        'Connected profile name to Home and Cards greetings.',
        'Added quick action icons for signout, KYC, and tier level.',
      ],
    ),
    _VersionNote(
      version: 'V2.34',
      title: 'Receive payment form',
      items: [
        'Built receive request form with amount, payer edit choice, description, expiry, and usage.',
        'Added settlement destination choices for 2Settle, saved beneficiary, manual account, and crypto.',
      ],
    ),
    _VersionNote(
      version: 'V2.30 - V2.33',
      title: 'History, cards, and transaction storage',
      items: [
        'Saved initiated transactions locally for Activities and History.',
        'Expanded History behavior and transaction detail display.',
        'Iterated virtual card stack and card details visual direction.',
      ],
    ),
    _VersionNote(
      version: 'V2.24 - V2.29',
      title: 'Funding, receipts, and confirmation flow',
      items: [
        'Reworked Confirm Transaction and funding review layout.',
        'Added receive crypto / fund transaction page direction.',
        'Improved receipt layout and payment confirmed actions.',
      ],
    ),
    _VersionNote(
      version: 'V2.18 - V2.23',
      title: 'Bank validation and passcode flows',
      items: [
        'Added searchable bank list and live account validation.',
        'Added local beneficiary save/default/edit/delete flow.',
        'Added passcode, recovery direction, and receive QR stage planning.',
      ],
    ),
    _VersionNote(
      version: 'V2.10 - V2.17',
      title: 'Home, send money, and confirmation basics',
      items: [
        'Added five-tab bottom navigation and live rate card.',
        'Connected Send Money flow to confirmation and funding details.',
        'Built six-digit code confirmation and app passcode setup direction.',
      ],
    ),
    _VersionNote(
      version: 'V2.0 - V2.09',
      title: 'Splash, onboarding, and first V2 shell',
      items: [
        'Rebuilt splash sequence with sliding onboarding and Start Now buttons.',
        'Added Hornbill styling with Inter fallback for numeric values.',
        'Fixed overflow issues and began systematic page-by-page mobile polish.',
      ],
    ),
    _VersionNote(
      version: 'V1.01 - V1.12',
      title: 'Original APK and source-based rebuild',
      items: [
        'Established direct Android APK build and install workflow.',
        'Reviewed Flutter/source direction and preserved original design first.',
        'Prepared the project for V2 progressive app iterations.',
      ],
    ),
  ];

  Widget _versionCard(BuildContext context, _VersionNote note) {
    final theme = FlutterFlowTheme.of(context);
    return Container(
      margin: const EdgeInsetsDirectional.only(bottom: 11.0),
      padding: const EdgeInsetsDirectional.fromSTEB(13.0, 12.0, 13.0, 12.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.0),
        border: Border.all(color: const Color(0xFFE5EAF1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsetsDirectional.fromSTEB(8.0, 4.0, 8.0, 4.0),
                decoration: BoxDecoration(
                  color: _blue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12.0),
                ),
                child: Text(
                  note.version,
                  style: GoogleFonts.inter(
                    color: _blue,
                    fontSize: 10.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: 9.0),
              Expanded(
                child: Text(
                  note.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.bodySmall.override(
                    color: theme.primaryText,
                    fontSize: 12.5,
                    letterSpacing: 0.0,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8.0),
          ...note.items.map(
            (item) => Padding(
              padding: const EdgeInsetsDirectional.only(bottom: 4.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsetsDirectional.only(top: 5.0),
                    child: Icon(Icons.circle, size: 5.0, color: _blue),
                  ),
                  const SizedBox(width: 7.0),
                  Expanded(
                    child: Text(
                      item,
                      style: GoogleFonts.inter(
                        color: theme.secondaryText,
                        fontSize: 10.7,
                        height: 1.32,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
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
                    onPressed: () =>
                        context.goNamed(NotificationsWidget.routeName),
                  ),
                  Expanded(
                    child: Text(
                      'Version History',
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
                  const EdgeInsetsDirectional.fromSTEB(22.0, 2.0, 22.0, 14.0),
              child: Text(
                'What changed across the mobile APK releases, newest first.',
                style: GoogleFonts.inter(
                  color: theme.secondaryText,
                  fontSize: 11.2,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Padding(
              padding:
                  const EdgeInsetsDirectional.fromSTEB(18.0, 0.0, 18.0, 0.0),
              child: Column(
                children: _versions
                    .map((note) => _versionCard(context, note))
                    .toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _VersionNote {
  const _VersionNote({
    required this.version,
    required this.title,
    required this.items,
  });

  final String version;
  final String title;
  final List<String> items;
}
