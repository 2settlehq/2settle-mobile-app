import '/flutter_flow/flutter_flow_theme.dart';
import 'package:flutter/material.dart';

class StatusActionButton extends StatelessWidget {
  const StatusActionButton({
    super.key,
    required this.text,
    required this.isLoading,
    required this.isDone,
    required this.onPressed,
    this.idleIcon = Icons.arrow_forward_rounded,
    this.width,
    this.backgroundColor,
    this.textColor = Colors.white,
    this.iconBackgroundColor = Colors.white,
    this.iconColor,
    this.height = 52.0,
    this.horizontalPadding = 20.0,
    this.trailingPadding = 8.0,
    this.iconBoxSize = 42.0,
    this.iconSize = 22.0,
    this.fontSize = 16.0,
    this.gap = 14.0,
    this.shadowBlur = 12.0,
    this.shadowOffset = const Offset(4.0, 4.0),
  });

  final String text;
  final bool isLoading;
  final bool isDone;
  final VoidCallback onPressed;
  final IconData idleIcon;
  final double? width;
  final Color? backgroundColor;
  final Color textColor;
  final Color iconBackgroundColor;
  final Color? iconColor;
  final double height;
  final double horizontalPadding;
  final double trailingPadding;
  final double iconBoxSize;
  final double iconSize;
  final double fontSize;
  final double gap;
  final double shadowBlur;
  final Offset shadowOffset;

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    final color = backgroundColor ?? theme.primary;
    final resolvedIconColor = iconColor ?? color;

    return InkWell(
      onTap: isLoading ? null : onPressed,
      borderRadius: BorderRadius.circular(28.0),
      child: Container(
        width: width,
        height: height,
        padding: EdgeInsetsDirectional.fromSTEB(
          horizontalPadding,
          0.0,
          trailingPadding,
          0.0,
        ),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(28.0),
          boxShadow: [
            BoxShadow(
              blurRadius: shadowBlur,
              color: const Color(0x33000000),
              offset: shadowOffset,
            ),
          ],
        ),
        child: Row(
          mainAxisSize: width == null ? MainAxisSize.min : MainAxisSize.max,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              text,
              style: theme.titleSmall.override(
                font: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontStyle: theme.titleSmall.fontStyle,
                ),
                color: textColor,
                fontSize: fontSize,
                letterSpacing: 0.0,
                fontWeight: FontWeight.w600,
                fontStyle: theme.titleSmall.fontStyle,
              ),
            ),
            SizedBox(width: gap),
            Container(
              width: iconBoxSize,
              height: iconBoxSize,
              decoration: BoxDecoration(
                color: iconBackgroundColor,
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 220),
                child: isDone
                    ? Icon(
                        Icons.check_rounded,
                        key: const ValueKey('done'),
                        color: resolvedIconColor,
                        size: iconSize + 2.0,
                      )
                    : isLoading
                        ? SizedBox(
                            key: const ValueKey('loading'),
                            width: iconSize - 2.0,
                            height: iconSize - 2.0,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.4,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                resolvedIconColor,
                              ),
                            ),
                          )
                        : Icon(
                            idleIcon,
                            key: const ValueKey('idle'),
                            color: resolvedIconColor,
                            size: iconSize,
                          ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
