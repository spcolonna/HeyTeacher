import 'package:flutter/material.dart';
import '../theme/theme.dart';

enum StatusKind { success, warning, error, info, neutral }

/// Small semantic status chip (e.g. application Pending / Accepted /
/// Rejected, job Active). Colors come from the palette's semantic tokens
/// so they stay legible in dark mode.
class StatusChip extends StatelessWidget {
  final String label;
  final StatusKind kind;

  const StatusChip({super.key, required this.label, required this.kind});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final decor = Theme.of(context).extension<AppDecor>()!;

    final color = switch (kind) {
      StatusKind.success => decor.success,
      StatusKind.warning => decor.warning,
      StatusKind.error => scheme.error,
      StatusKind.info => decor.info,
      StatusKind.neutral => scheme.onSurfaceVariant,
    };

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: Spacing.md,
        vertical: Spacing.xs,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(Radii.pill),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
            ),
      ),
    );
  }
}
