import '/flutter_flow/flutter_flow_theme.dart';
import 'package:flutter/material.dart';

enum TopNoticeType { info, caution }

void showTopNotice(
  BuildContext context, {
  required String message,
  TopNoticeType type = TopNoticeType.info,
}) {
  final overlay = Overlay.of(context);
  late OverlayEntry entry;
  final isCaution = type == TopNoticeType.caution;
  final color = isCaution ? const Color(0xFFB42318) : const Color(0xFF4472C4);
  final backgroundColor =
      isCaution ? const Color(0xFFFFF4F2) : const Color(0xFF4472C4);
  final borderColor =
      isCaution ? const Color(0xFFFECACA) : const Color(0xFF4472C4);
  final iconBackground = isCaution
      ? const Color(0xFFFEE4E2)
      : Colors.white.withValues(alpha: 0.18);
  final textColor = isCaution ? const Color(0xFF7A271A) : Colors.white;
  final icon = isCaution
      ? Icons.warning_amber_rounded
      : Icons.check_circle_outline_rounded;

  entry = OverlayEntry(
    builder: (context) {
      final top = MediaQuery.paddingOf(context).top + 10.0;
      return Positioned(
        top: top,
        left: 16.0,
        right: 16.0,
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: -24.0, end: 0.0),
          duration: const Duration(milliseconds: 260),
          curve: Curves.easeOutCubic,
          builder: (context, offset, child) {
            return Transform.translate(
              offset: Offset(0.0, offset),
              child: child,
            );
          },
          child: Material(
            color: Colors.transparent,
            child: Container(
              padding:
                  const EdgeInsetsDirectional.fromSTEB(12.0, 10.0, 12.0, 10.0),
              decoration: BoxDecoration(
                color: backgroundColor,
                borderRadius: BorderRadius.circular(14.0),
                border: Border.all(color: borderColor, width: 0.8),
                boxShadow: [
                  BoxShadow(
                    blurRadius: 18.0,
                    color: color.withValues(alpha: isCaution ? 0.12 : 0.28),
                    offset: const Offset(0.0, 8.0),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 32.0,
                    height: 32.0,
                    decoration: BoxDecoration(
                      color: iconBackground,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(icon, color: color, size: 19.0),
                  ),
                  const SizedBox(width: 10.0),
                  Expanded(
                    child: Text(
                      message,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: FlutterFlowTheme.of(context).bodySmall.override(
                            font: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontStyle: FlutterFlowTheme.of(context)
                                  .bodySmall
                                  .fontStyle,
                            ),
                            color: textColor,
                            letterSpacing: 0.0,
                            fontWeight: FontWeight.w600,
                            fontStyle: FlutterFlowTheme.of(context)
                                .bodySmall
                                .fontStyle,
                          ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    },
  );

  overlay.insert(entry);
  Future.delayed(const Duration(seconds: 2), () {
    if (entry.mounted) entry.remove();
  });
}
