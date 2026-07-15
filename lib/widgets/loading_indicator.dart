import 'package:flutter/material.dart';

/// Centered, platform-adaptive loading indicator (Cupertino spinner on
/// iOS, Material on Android). Use for full-area loading; prefer the
/// skeleton loaders in `skeletons.dart` for list/grid screens.
class LoadingIndicator extends StatelessWidget {
  const LoadingIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(child: CircularProgressIndicator.adaptive());
  }
}
