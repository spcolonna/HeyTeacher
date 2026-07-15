import 'package:flutter/material.dart';
import '../theme/theme.dart';

enum AppSnackType { success, error, info }

/// Themed snackbar helper. Replaces ad-hoc
/// `ScaffoldMessenger.of(context).showSnackBar(SnackBar(...))` call sites
/// so success/error/info colors and icons stay consistent.
void showAppSnack(
  BuildContext context,
  String message, {
  AppSnackType type = AppSnackType.info,
}) {
  final scheme = Theme.of(context).colorScheme;
  final decor = Theme.of(context).extension<AppDecor>()!;

  final (color, icon) = switch (type) {
    AppSnackType.success => (decor.success, Icons.check_circle_rounded),
    AppSnackType.error => (scheme.error, Icons.error_rounded),
    AppSnackType.info => (scheme.inverseSurface, Icons.info_rounded),
  };

  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        backgroundColor: color,
        content: Row(
          children: [
            Icon(icon,
                color: type == AppSnackType.info
                    ? scheme.onInverseSurface
                    : Colors.white,
                size: 20),
            const SizedBox(width: Spacing.md),
            Expanded(
              child: Text(
                message,
                style: TextStyle(
                  color: type == AppSnackType.info
                      ? scheme.onInverseSurface
                      : Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
}
