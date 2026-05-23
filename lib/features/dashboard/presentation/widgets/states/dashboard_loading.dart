import 'package:flutter/material.dart';
import 'package:nano_app/core/theme/theme.dart';

import 'skeleton_box.dart';

class DashboardLoading extends StatelessWidget {
  const DashboardLoading({super.key});

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      physics: const NeverScrollableScrollPhysics(),
      slivers: [
        const SliverToBoxAdapter(
          child: SkeletonBox(
            height: 280,
            radius: AppRadius.xxl,
            margin: EdgeInsets.zero,
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              const SizedBox(height: AppSpacing.lg),
              const SkeletonBox(height: 200),
              const SizedBox(height: AppSpacing.lg),
              const Row(
                children: [
                  Expanded(child: SkeletonBox(height: 80)),
                  SizedBox(width: AppSpacing.sm),
                  Expanded(child: SkeletonBox(height: 80)),
                  SizedBox(width: AppSpacing.sm),
                  Expanded(child: SkeletonBox(height: 80)),
                  SizedBox(width: AppSpacing.sm),
                  Expanded(child: SkeletonBox(height: 80)),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              const SkeletonBox(height: 160),
              const SizedBox(height: AppSpacing.lg),
              const SkeletonBox(height: 240),
            ]),
          ),
        ),
      ],
    );
  }
}
