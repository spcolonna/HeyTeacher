import 'package:flutter/material.dart';
import 'package:skeletonizer/skeletonizer.dart';
import '../theme/theme.dart';

/// Skeleton placeholder for card lists (jobs, applicants, notifications).
/// Shows bone versions of a generic card while the first snapshot loads.
class SkeletonList extends StatelessWidget {
  final int count;
  final EdgeInsetsGeometry padding;

  const SkeletonList({
    super.key,
    this.count = 6,
    this.padding = const EdgeInsets.all(Spacing.lg),
  });

  @override
  Widget build(BuildContext context) {
    return Skeletonizer(
      enabled: true,
      child: ListView.builder(
        physics: const NeverScrollableScrollPhysics(),
        padding: padding,
        itemCount: count,
        itemBuilder: (_, __) => const _BoneCard(),
      ),
    );
  }
}

/// Skeleton placeholder for 2-column grids (materials, marketplace).
class SkeletonGrid extends StatelessWidget {
  final int count;
  final double childAspectRatio;
  final EdgeInsetsGeometry padding;

  const SkeletonGrid({
    super.key,
    this.count = 6,
    this.childAspectRatio = 0.65,
    this.padding = const EdgeInsets.all(Spacing.lg),
  });

  @override
  Widget build(BuildContext context) {
    return Skeletonizer(
      enabled: true,
      child: GridView.builder(
        physics: const NeverScrollableScrollPhysics(),
        padding: padding,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: Spacing.lg,
          mainAxisSpacing: Spacing.lg,
          childAspectRatio: childAspectRatio,
        ),
        itemCount: count,
        itemBuilder: (_, __) => const _BoneTile(),
      ),
    );
  }
}

class _BoneCard extends StatelessWidget {
  const _BoneCard();

  @override
  Widget build(BuildContext context) {
    return const Card(
      margin: EdgeInsets.only(bottom: Spacing.md),
      child: Padding(
        padding: EdgeInsets.all(Spacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Bone.circle(size: 40),
                SizedBox(width: Spacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Bone.text(words: 3),
                      SizedBox(height: Spacing.xs),
                      Bone.text(words: 2),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: Spacing.md),
            Bone.text(words: 6),
            SizedBox(height: Spacing.sm),
            Bone.text(words: 4),
          ],
        ),
      ),
    );
  }
}

class _BoneTile extends StatelessWidget {
  const _BoneTile();

  @override
  Widget build(BuildContext context) {
    return const Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Bone(width: double.infinity, height: 120),
          Padding(
            padding: EdgeInsets.all(Spacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Bone.text(words: 3),
                SizedBox(height: Spacing.xs),
                Bone.text(words: 2),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
