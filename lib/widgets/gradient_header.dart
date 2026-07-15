import 'package:flutter/material.dart';
import '../theme/theme.dart';

/// Brand-gradient header block. Replaces the inline blue→purple
/// LinearGradients previously duplicated across screens. The gradient and
/// its dark variant come from the active palette via [AppDecor].
///
/// Text/icons inside should use [AppDecor.onGradient] (or rely on the
/// [DefaultTextStyle] this widget provides).
class GradientHeader extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final BorderRadius? borderRadius;
  final bool safeArea;

  const GradientHeader({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(Spacing.xl),
    this.borderRadius,
    this.safeArea = false,
  });

  @override
  Widget build(BuildContext context) {
    final decor = Theme.of(context).extension<AppDecor>()!;
    final content = Padding(padding: padding, child: child);

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: decor.primaryGradient,
        borderRadius: borderRadius,
      ),
      child: DefaultTextStyle.merge(
        style: TextStyle(color: decor.onGradient),
        child: IconTheme.merge(
          data: IconThemeData(color: decor.onGradient),
          child: safeArea ? SafeArea(bottom: false, child: content) : content,
        ),
      ),
    );
  }
}
