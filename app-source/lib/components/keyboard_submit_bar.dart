import '/components/status_action_button.dart';
import 'package:flutter/material.dart';

/// A Scaffold bottomNavigationBar that keeps the form action above a native
/// keyboard. Custom modal keypads provide their own action inside the sheet.
class KeyboardSubmitBar extends StatelessWidget {
  const KeyboardSubmitBar({
    super.key,
    required this.text,
    required this.onPressed,
    this.isLoading = false,
    this.isDone = false,
  });

  final String text;
  final VoidCallback onPressed;
  final bool isLoading;
  final bool isDone;

  @override
  Widget build(BuildContext context) {
    final keyboardHeight = MediaQuery.viewInsetsOf(context).bottom;
    if (keyboardHeight == 0) return const SizedBox.shrink();
    return Padding(
      padding: EdgeInsets.only(bottom: keyboardHeight),
      child: SafeArea(
        top: false,
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
          child: StatusActionButton(
            text: text,
            isLoading: isLoading,
            isDone: isDone,
            onPressed: onPressed,
            width: double.infinity,
          ),
        ),
      ),
    );
  }
}
