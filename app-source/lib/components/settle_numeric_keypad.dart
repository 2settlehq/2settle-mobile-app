import '/flutter_flow/flutter_flow_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

class SettleNumericKeypad extends StatefulWidget {
  const SettleNumericKeypad({
    super.key,
    required this.title,
    required this.initialValue,
    required this.onDone,
    this.onChanged,
    this.allowDecimal = false,
    this.maxLength,
    this.obscurePreview = false,
    this.showPreview = false,
  });

  final String title;
  final String initialValue;
  final ValueChanged<String> onDone;
  final ValueChanged<String>? onChanged;
  final bool allowDecimal;
  final int? maxLength;
  final bool obscurePreview;
  final bool showPreview;

  static Future<void> show(
    BuildContext context, {
    required String title,
    required String initialValue,
    required ValueChanged<String> onDone,
    ValueChanged<String>? onChanged,
    bool allowDecimal = false,
    int? maxLength,
    bool obscurePreview = false,
    bool showPreview = false,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      requestFocus: false,
      barrierColor: Colors.transparent,
      backgroundColor: Colors.transparent,
      builder: (_) => SettleNumericKeypad(
        title: title,
        initialValue: initialValue,
        onDone: onDone,
        onChanged: onChanged,
        allowDecimal: allowDecimal,
        maxLength: maxLength,
        obscurePreview: obscurePreview,
        showPreview: showPreview,
      ),
    );
  }

  @override
  State<SettleNumericKeypad> createState() => _SettleNumericKeypadState();
}

class _SettleNumericKeypadState extends State<SettleNumericKeypad> {
  static const _blue = Color(0xFF4472C4);
  late String _value;
  bool _hapticsEnabled = true;

  @override
  void initState() {
    super.initState();
    _value = widget.initialValue;
  }

  void _tap(String key) {
    if (_hapticsEnabled) {
      HapticFeedback.selectionClick();
    }
    setState(() {
      if (key == 'back') {
        if (_value.isNotEmpty) _value = _value.substring(0, _value.length - 1);
      } else if (key == 'clear') {
        _value = '';
      } else if (key == '.') {
        if (!widget.allowDecimal || _value.contains('.')) return;
        _value = _value.isEmpty ? '0.' : '$_value.';
      } else if (widget.maxLength != null &&
          _value.length >= widget.maxLength!) {
        return;
      } else {
        _value = '$_value$key';
      }
    });
    widget.onChanged?.call(_value);
  }

  String get _previewText {
    if (_value.isEmpty) return '0';
    if (!widget.obscurePreview) return _value;
    return List.filled(_value.length, '*').join();
  }

  Widget _key(String label, {IconData? icon, String? value}) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.all(5.0),
        child: InkWell(
          onTap: () => _tap(value ?? label),
          borderRadius: BorderRadius.circular(14.0),
          child: Container(
            height: 52.0,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: _blue.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(14.0),
              border: Border.all(color: _blue.withValues(alpha: 0.12)),
            ),
            child: icon == null
                ? Text(
                    label,
                    style: GoogleFonts.inter(
                      color: _blue,
                      fontSize: 22.0,
                      fontWeight: FontWeight.w800,
                    ),
                  )
                : Icon(icon, color: _blue, size: 22.0),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset + 10.0),
      child: Container(
        margin: const EdgeInsetsDirectional.fromSTEB(10.0, 0.0, 10.0, 0.0),
        padding: const EdgeInsetsDirectional.fromSTEB(18.0, 12.0, 18.0, 16.0),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24.0)),
          boxShadow: [
            BoxShadow(
              blurRadius: 26.0,
              spreadRadius: 2.0,
              color: Color(0x33000000),
              offset: Offset(0.0, -8.0),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 42.0,
              height: 4.0,
              decoration: BoxDecoration(
                color: const Color(0xFFE1E6F0),
                borderRadius: BorderRadius.circular(100.0),
              ),
            ),
            const SizedBox(height: 14.0),
            Row(
              children: [
                IconButton(
                  onPressed: () {
                    setState(() => _hapticsEnabled = !_hapticsEnabled);
                  },
                  icon: Icon(
                    _hapticsEnabled
                        ? Icons.vibration_rounded
                        : Icons.notifications_off_rounded,
                    color: _hapticsEnabled
                        ? _blue
                        : FlutterFlowTheme.of(context).secondaryText,
                    size: 20.0,
                  ),
                  tooltip: _hapticsEnabled ? 'Vibration on' : 'Vibration off',
                ),
                const SizedBox(width: 2.0),
                Expanded(
                  child: Text(
                    widget.title,
                    style: theme.bodyMedium.override(
                      font: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontStyle: theme.bodyMedium.fontStyle,
                      ),
                      color: theme.primaryText,
                      fontSize: 14.0,
                      letterSpacing: 0.0,
                      fontWeight: FontWeight.w600,
                      fontStyle: theme.bodyMedium.fontStyle,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () {
                    widget.onDone(_value);
                    Navigator.of(context).pop();
                  },
                  child: Text(
                    'Done',
                    style: theme.bodyMedium.override(
                      font: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontStyle: theme.bodyMedium.fontStyle,
                      ),
                      color: _blue,
                      letterSpacing: 0.0,
                      fontWeight: FontWeight.w700,
                      fontStyle: theme.bodyMedium.fontStyle,
                    ),
                  ),
                ),
              ],
            ),
            if (widget.showPreview) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsetsDirectional.fromSTEB(
                    16.0, 10.0, 16.0, 10.0),
                decoration: BoxDecoration(
                  color: _blue.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(14.0),
                ),
                alignment: Alignment.centerRight,
                child: Text(
                  _previewText,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    color: _blue,
                    fontSize: 24.0,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const SizedBox(height: 8.0),
            ],
            for (final row in const [
              ['1', '2', '3'],
              ['4', '5', '6'],
              ['7', '8', '9'],
            ])
              Row(children: row.map(_key).toList()),
            Row(
              children: [
                _key(widget.allowDecimal ? '.' : 'C',
                    value: widget.allowDecimal ? '.' : 'clear'),
                _key('0'),
                _key('', icon: Icons.backspace_outlined, value: 'back'),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
