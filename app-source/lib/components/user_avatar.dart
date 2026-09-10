import 'package:flutter/material.dart';

/// The account's avatar: the server-provided avatarUrl when there is one,
/// otherwise the app's default avatar image — also used if avatarUrl is
/// set but fails to load.
class UserAvatar extends StatelessWidget {
  const UserAvatar({
    super.key,
    required this.avatarUrl,
    this.fit = BoxFit.cover,
  });

  final String avatarUrl;
  final BoxFit fit;

  static const _fallbackAsset = 'assets/images/a_avatar.png';

  @override
  Widget build(BuildContext context) {
    if (avatarUrl.isEmpty) {
      return Image.asset(_fallbackAsset, fit: fit);
    }
    return Image.network(
      avatarUrl,
      fit: fit,
      errorBuilder: (context, error, stackTrace) =>
          Image.asset(_fallbackAsset, fit: fit),
    );
  }
}
