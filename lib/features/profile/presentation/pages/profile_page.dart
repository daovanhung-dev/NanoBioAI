import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:nano_app/core/theme/theme.dart';
import 'package:nano_app/features/dashboard/domain/entities/dashboard_entity.dart';
import 'package:nano_app/features/dashboard/providers/dashboard_provider.dart';

class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashboardAsync = ref.watch(dashboardProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: dashboardAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => _EmptyProfile(
            message: 'Chưa đọc được hồ sơ từ SQLite: $error',
            onRetry: () => ref.invalidate(dashboardProvider),
          ),
          data: (dashboard) => RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(dashboardProvider);
              await ref.read(dashboardProvider.future);
            },
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(
                parent: BouncingScrollPhysics(),
              ),
              slivers: [
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.md,
                    AppSpacing.xxl,
                    AppSpacing.md,
                    128,
                  ),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      _ProfileHeader(dashboard: dashboard),
                      const SizedBox(height: AppSpacing.lg),
                      _MetricGrid(dashboard: dashboard),
                      const SizedBox(height: AppSpacing.lg),
                      _InfoSection(
                        title: 'Thông tin cá nhân',
                        rows: [
                          _InfoRow('Email', dashboard.email),
                          _InfoRow('Điện thoại', dashboard.phone),
                          _InfoRow('Giới tính', dashboard.gender),
                          _InfoRow(
                            'Năm sinh',
                            dashboard.birthYear > 0
                                ? dashboard.birthYear.toString()
                                : '',
                          ),
                          _InfoRow('Nghề nghiệp', dashboard.occupation),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      _ChipSection(
                        title: 'Mục tiêu',
                        emptyMessage: 'Chưa có mục tiêu trong SQLite',
                        items: dashboard.goals,
                        icon: Icons.flag_rounded,
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      _ChipSection(
                        title: 'Tình trạng cần lưu ý',
                        emptyMessage:
                            'Chưa có tình trạng sức khỏe trong SQLite',
                        items: dashboard.conditions,
                        icon: Icons.health_and_safety_rounded,
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      _ChipSection(
                        title: 'Thói quen',
                        emptyMessage: 'Chưa có thói quen trong SQLite',
                        items: dashboard.habits,
                        icon: Icons.restaurant_rounded,
                      ),
                    ]),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  final DashboardEntity dashboard;

  const _ProfileHeader({required this.dashboard});

  @override
  Widget build(BuildContext context) {
    final name = _displayText(dashboard.fullName, fallback: 'Chưa có tên');
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: AppDecoration.gradient(
        colors: const [AppColors.primary, AppColors.secondary],
        radius: AppRadius.xxl,
        shadows: AppShadows.lg,
      ),
      child: Row(
        children: [
          Container(
            width: 76,
            height: 76,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: .18),
              borderRadius: BorderRadius.circular(AppRadius.circular),
            ),
            child: const Icon(
              Icons.person_rounded,
              color: Colors.white,
              size: 40,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.heading2.copyWith(
                    color: Colors.white,
                    fontWeight: AppTypography.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  _subscriptionLabel(dashboard.subscriptionTier),
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: Colors.white.withValues(alpha: .9),
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'Dữ liệu được đọc từ bảng users, health_profiles, goals và conditions.',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: Colors.white.withValues(alpha: .78),
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricGrid extends StatelessWidget {
  final DashboardEntity dashboard;

  const _MetricGrid({required this.dashboard});

  @override
  Widget build(BuildContext context) {
    final metrics = [
      _Metric(
        'Chiều cao',
        dashboard.heightCm > 0
            ? '${dashboard.heightCm.toStringAsFixed(0)} cm'
            : '--',
        Icons.height_rounded,
      ),
      _Metric(
        'Cân nặng',
        dashboard.weightKg > 0
            ? '${dashboard.weightKg.toStringAsFixed(1)} kg'
            : '--',
        Icons.monitor_weight_rounded,
      ),
      _Metric(
        'BMI',
        dashboard.bmi > 0 ? dashboard.bmi.toStringAsFixed(1) : '--',
        Icons.speed_rounded,
      ),
      _Metric(
        'Nước/ngày',
        _displayText(dashboard.waterPerDay, fallback: '--'),
        Icons.water_drop_rounded,
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 620 ? 4 : 2;
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: metrics.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            mainAxisSpacing: AppSpacing.md,
            crossAxisSpacing: AppSpacing.md,
            childAspectRatio: 1.25,
          ),
          itemBuilder: (context, index) => _MetricCard(metric: metrics[index]),
        );
      },
    );
  }
}

class _Metric {
  final String label;
  final String value;
  final IconData icon;

  const _Metric(this.label, this.value, this.icon);
}

class _MetricCard extends StatelessWidget {
  final _Metric metric;

  const _MetricCard({required this.metric});

  @override
  Widget build(BuildContext context) {
    return _SurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(metric.icon, color: AppColors.primary),
          const Spacer(),
          Text(
            metric.value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.heading3.copyWith(
              fontWeight: AppTypography.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(metric.label, style: AppTextStyles.bodySmall),
        ],
      ),
    );
  }
}

class _InfoSection extends StatelessWidget {
  final String title;
  final List<_InfoRow> rows;

  const _InfoSection({required this.title, required this.rows});

  @override
  Widget build(BuildContext context) {
    return _SurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppTextStyles.heading4),
          const SizedBox(height: AppSpacing.md),
          for (var i = 0; i < rows.length; i++) ...[
            _InfoLine(row: rows[i]),
            if (i != rows.length - 1) const Divider(height: 24),
          ],
        ],
      ),
    );
  }
}

class _InfoRow {
  final String label;
  final String value;

  const _InfoRow(this.label, this.value);
}

class _InfoLine extends StatelessWidget {
  final _InfoRow row;

  const _InfoLine({required this.row});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: Text(row.label, style: AppTextStyles.bodyMedium)),
        const SizedBox(width: AppSpacing.md),
        Flexible(
          child: Text(
            _displayText(row.value, fallback: '--'),
            textAlign: TextAlign.right,
            style: AppTextStyles.labelLarge,
          ),
        ),
      ],
    );
  }
}

class _ChipSection extends StatelessWidget {
  final String title;
  final String emptyMessage;
  final List<String> items;
  final IconData icon;

  const _ChipSection({
    required this.title,
    required this.emptyMessage,
    required this.items,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return _SurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppTextStyles.heading4),
          const SizedBox(height: AppSpacing.md),
          if (items.isEmpty)
            Text(emptyMessage, style: AppTextStyles.bodyMedium)
          else
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: items.map((item) {
                return Chip(
                  avatar: Icon(icon, size: 16, color: AppColors.primary),
                  label: Text(item),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }
}

class _SurfaceCard extends StatelessWidget {
  final Widget child;

  const _SurfaceCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: AppDecoration.card(
        radius: AppRadius.xl,
        shadows: AppShadows.sm,
      ),
      child: child,
    );
  }
}

class _EmptyProfile extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _EmptyProfile({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.person_off_rounded,
              color: AppColors.textMuted,
              size: 42,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Chưa có hồ sơ',
              style: AppTextStyles.heading4.copyWith(
                fontWeight: AppTypography.bold,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              message,
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyMedium.copyWith(height: 1.45),
            ),
            const SizedBox(height: AppSpacing.md),
            TextButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Thử lại'),
            ),
          ],
        ),
      ),
    );
  }
}

String _displayText(String? value, {required String fallback}) {
  final text = value?.trim() ?? '';
  return text.isEmpty ? fallback : text;
}

String _subscriptionLabel(String value) {
  final normalized = value.trim().toLowerCase();
  if (normalized.isEmpty || normalized == 'free') return 'Gói Free';
  if (normalized == 'premium') return 'Gói Premium';
  if (normalized == 'pro') return 'Gói Pro';
  return 'Gói ${value.trim()}';
}
