import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:nano_app/core/constants/routes/route_names.dart';
import 'package:nano_app/core/theme/theme.dart';
import 'package:nano_app/features/dashboard/domain/entities/dashboard_entity.dart';
import 'package:nano_app/features/dashboard/providers/dashboard_provider.dart';
import 'package:nano_app/features/settings/domain/entities/settings_preferences_entity.dart';
import 'package:nano_app/features/settings/providers/settings_provider.dart';

import 'dev_database_viewer_page.dart';

class SettingsView extends ConsumerWidget {
  const SettingsView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashboardAsync = ref.watch(dashboardProvider);
    final preferencesAsync = ref.watch(settingsPreferencesControllerProvider);
    final cacheSizeAsync = ref.watch(settingsCacheSizeProvider);
    final preferences =
        preferencesAsync.value ?? SettingsPreferencesEntity.defaults();
    final dashboard = dashboardAsync.value;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(dashboardProvider);
            ref.invalidate(settingsPreferencesControllerProvider);
            ref.invalidate(settingsCacheSizeProvider);
            try {
              await ref.read(dashboardProvider.future);
            } catch (_) {}
            try {
              await ref.read(settingsPreferencesControllerProvider.future);
            } catch (_) {}
            try {
              await ref.read(settingsCacheSizeProvider.future);
            } catch (_) {}
          },
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.pagePadding),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _Header(isLoading: dashboardAsync.isLoading),
                      const SizedBox(height: AppSpacing.lg),
                      _ProfileCard(dashboard: dashboard),
                      const SizedBox(height: AppSpacing.xl),
                      _SectionTitle('Tài khoản'),
                      const SizedBox(height: AppSpacing.md),
                      _MenuCard(
                        children: [
                          _MenuItem(
                            icon: Icons.person_rounded,
                            title: 'Thông tin cá nhân',
                            subtitle: dashboard == null
                                ? 'Chưa có hồ sơ trong SQLite'
                                : _profileSubtitle(dashboard),
                            onTap: () => context.push(RoutePaths.profile),
                          ),
                          const _DividerLine(),
                          _MenuItem(
                            icon: Icons.lock_rounded,
                            title: 'Bảo mật',
                            subtitle:
                                'Phiên đăng nhập Supabase và dữ liệu local của bạn',
                          ),
                          const _DividerLine(),
                          _MenuItem(
                            icon: Icons.notifications_rounded,
                            title: 'Thông báo',
                            subtitle: preferences.pushEnabled
                                ? 'Đang bật nhắc nhở local'
                                : 'Đang tắt nhắc nhở local',
                            trailing: Switch(
                              value: preferences.pushEnabled,
                              activeThumbColor: AppColors.primary,
                              onChanged: preferencesAsync.isLoading
                                  ? null
                                  : (value) => ref
                                        .read(
                                          settingsPreferencesControllerProvider
                                              .notifier,
                                        )
                                        .setPushEnabled(value),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.xl),
                      _SectionTitle('Ứng dụng'),
                      const SizedBox(height: AppSpacing.md),
                      _MenuCard(
                        children: [
                          _MenuItem(
                            icon: Icons.dark_mode_rounded,
                            title: 'Chế độ tối',
                            subtitle: preferences.isDarkMode
                                ? 'Đang lưu lựa chọn dark mode'
                                : 'Đang lưu lựa chọn light mode',
                            trailing: Switch(
                              value: preferences.isDarkMode,
                              activeThumbColor: AppColors.primary,
                              onChanged: preferencesAsync.isLoading
                                  ? null
                                  : (value) => ref
                                        .read(
                                          settingsPreferencesControllerProvider
                                              .notifier,
                                        )
                                        .setDarkMode(value),
                            ),
                          ),
                          const _DividerLine(),
                          _MenuItem(
                            icon: Icons.language_rounded,
                            title: 'Ngôn ngữ',
                            subtitle: _languageLabel(preferences.languageCode),
                          ),
                          const _DividerLine(),
                          _MenuItem(
                            icon: Icons.storage_rounded,
                            title: 'Dung lượng',
                            subtitle: cacheSizeAsync.when(
                              data: _formatBytes,
                              loading: () => 'Đang đọc cache...',
                              error: (_, __) => 'Chưa đọc được cache',
                            ),
                            trailing: IconButton(
                              tooltip: 'Dọn cache',
                              icon: const Icon(Icons.cleaning_services_rounded),
                              onPressed: () => ref
                                  .read(
                                    settingsPreferencesControllerProvider
                                        .notifier,
                                  )
                                  .clearCache(),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.xl),
                      _SectionTitle('Dev'),
                      const SizedBox(height: AppSpacing.md),
                      _MenuCard(
                        children: [
                          _MenuItem(
                            icon: Icons.developer_mode_rounded,
                            title: 'Database',
                            subtitle:
                                'Xem bảng, cấu trúc cột và dữ liệu SQLite local',
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute<void>(
                                  builder: (_) => const DevDatabaseViewerPage(),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.xl),
                      _SectionTitle('AI & Sức khỏe'),
                      const SizedBox(height: AppSpacing.md),
                      _MenuCard(
                        children: [
                          _MenuItem(
                            icon: Icons.auto_awesome_rounded,
                            title: 'Phong cách AI',
                            subtitle: _aiPersonalityLabel(
                              preferences.aiPersonality,
                            ),
                          ),
                          const _DividerLine(),
                          _MenuItem(
                            icon: Icons.favorite_rounded,
                            title: 'Mục tiêu sức khỏe',
                            subtitle: dashboard == null
                                ? 'Chưa có mục tiêu trong SQLite'
                                : _goalsSubtitle(dashboard.goals),
                          ),
                          const _DividerLine(),
                          _MenuItem(
                            icon: Icons.sync_rounded,
                            title: 'Dữ liệu của bạn',
                            subtitle: _privacyModeLabel(
                              preferences.dataPrivacyMode,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.xl),
                      _DangerCard(
                        email: dashboard?.email.trim().isEmpty == false
                            ? dashboard!.email
                            : null,
                      ),
                      const SizedBox(height: AppSpacing.xxxl),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final bool isLoading;

  const _Header({required this.isLoading});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Cài đặt',
                style: AppTextStyles.heading1.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                isLoading
                    ? 'Đang đọc tùy chỉnh từ local storage...'
                    : 'Các tùy chỉnh được đọc từ SQLite và SharedPreferences.',
                style: AppTextStyles.bodyMedium,
              ),
            ],
          ),
        ),
        Container(
          height: 58,
          width: 58,
          decoration: AppDecoration.gradient(
            colors: const [AppColors.primary, AppColors.secondary],
            radius: AppRadius.circular,
            shadows: AppShadows.primary,
          ),
          child: const Icon(
            Icons.settings_rounded,
            color: Colors.white,
            size: 28,
          ),
        ),
      ],
    );
  }
}

class _ProfileCard extends StatelessWidget {
  final DashboardEntity? dashboard;

  const _ProfileCard({required this.dashboard});

  @override
  Widget build(BuildContext context) {
    final fullName = _displayText(
      dashboard?.fullName,
      fallback: 'Chưa có hồ sơ',
    );
    final subtitle = dashboard == null
        ? 'Hoàn thành onboarding để lưu hồ sơ vào SQLite'
        : _subscriptionLabel(dashboard!.subscriptionTier);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: AppDecoration.gradient(
        colors: const [Color(0xFF2563EB), Color(0xFF06B6D4)],
        radius: AppRadius.xxl,
        shadows: AppShadows.lg,
      ),
      child: Row(
        children: [
          Container(
            height: 72,
            width: 72,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: .18),
              borderRadius: BorderRadius.circular(AppRadius.circular),
            ),
            child: const Icon(
              Icons.person_rounded,
              color: Colors.white,
              size: 36,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  fullName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.heading3.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  subtitle,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: Colors.white.withValues(alpha: .9),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.sm,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: .16),
                    borderRadius: BorderRadius.circular(AppRadius.circular),
                  ),
                  child: Text(
                    dashboard == null
                        ? 'Chưa có dữ liệu local'
                        : 'Đồng bộ từ SQLite',
                    style: AppTextStyles.labelMedium.copyWith(
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Icon(
            Icons.arrow_forward_ios_rounded,
            color: Colors.white70,
            size: 18,
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;

  const _SectionTitle(this.title);

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: AppTextStyles.heading3.copyWith(fontWeight: FontWeight.w700),
    );
  }
}

class _MenuCard extends StatelessWidget {
  final List<Widget> children;

  const _MenuCard({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: AppDecoration.card(
        radius: AppRadius.xxl,
        shadows: AppShadows.soft,
      ),
      child: Column(children: children),
    );
  }
}

class _MenuItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;

  const _MenuItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(AppRadius.xl),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          children: [
            Container(
              height: 54,
              width: 54,
              decoration: BoxDecoration(
                gradient: AppGradients.primary,
                borderRadius: BorderRadius.circular(AppRadius.lg),
              ),
              child: Icon(icon, color: Colors.white),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTextStyles.labelLarge.copyWith(fontSize: 15),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: AppTextStyles.bodySmall.copyWith(height: 1.5),
                  ),
                ],
              ),
            ),
            trailing ??
                const Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 18,
                  color: AppColors.textHint,
                ),
          ],
        ),
      ),
    );
  }
}

class _DangerCard extends StatelessWidget {
  final String? email;

  const _DangerCard({required this.email});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: AppDecoration.card(
        radius: AppRadius.xxl,
        shadows: AppShadows.sm,
      ),
      child: Column(
        children: [
          Container(
            height: 72,
            width: 72,
            decoration: BoxDecoration(
              color: AppColors.errorSoft,
              borderRadius: BorderRadius.circular(AppRadius.circular),
            ),
            child: const Icon(
              Icons.logout_rounded,
              color: AppColors.error,
              size: 34,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Đăng xuất',
            style: AppTextStyles.heading3.copyWith(color: AppColors.error),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            email == null
                ? 'Chưa có email người dùng trong SQLite.'
                : 'Tài khoản hiện tại: $email',
            textAlign: TextAlign.center,
            style: AppTextStyles.bodyMedium,
          ),
          const SizedBox(height: AppSpacing.lg),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error,
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                ),
              ),
              onPressed: null,
              child: const Text('Đăng xuất'),
            ),
          ),
        ],
      ),
    );
  }
}

class _DividerLine extends StatelessWidget {
  const _DividerLine();

  @override
  Widget build(BuildContext context) {
    return const Divider(height: 1, thickness: 1, color: AppColors.borderLight);
  }
}

String _displayText(String? value, {required String fallback}) {
  final text = value?.trim() ?? '';
  return text.isEmpty ? fallback : text;
}

String _profileSubtitle(DashboardEntity dashboard) {
  final items = [
    if (dashboard.email.trim().isNotEmpty) dashboard.email.trim(),
    if (dashboard.phone.trim().isNotEmpty) dashboard.phone.trim(),
  ];
  return items.isEmpty ? 'Hồ sơ được lưu trong SQLite' : items.join(' • ');
}

String _goalsSubtitle(List<String> goals) {
  if (goals.isEmpty) return 'Chưa có mục tiêu trong SQLite';
  if (goals.length == 1) return goals.single;
  return '${goals.length} mục tiêu đang hoạt động';
}

String _subscriptionLabel(String value) {
  final normalized = value.trim().toLowerCase();
  if (normalized.isEmpty || normalized == 'free') return 'Gói Free';
  if (normalized == 'premium') return 'Gói Premium';
  if (normalized == 'pro') return 'Gói Pro';
  return 'Gói ${value.trim()}';
}

String _languageLabel(String code) {
  switch (code) {
    case 'en':
      return 'English';
    case 'vi':
      return 'Tiếng Việt';
    default:
      return code.isEmpty ? '--' : code;
  }
}

String _aiPersonalityLabel(String value) {
  switch (value) {
    case 'professional':
      return 'Chuyên nghiệp';
    case 'motivational':
      return 'Động viên';
    case 'friendly':
      return 'Thân thiện';
    default:
      return value.isEmpty ? '--' : value;
  }
}

String _privacyModeLabel(String value) {
  switch (value) {
    case 'cloud':
      return 'Ưu tiên đồng bộ cloud';
    case 'local':
      return 'Chỉ lưu trên thiết bị';
    default:
      return value.isEmpty ? '--' : value;
  }
}

String _formatBytes(int bytes) {
  if (bytes <= 0) return '0 B';
  const units = ['B', 'KB', 'MB', 'GB'];
  var value = bytes.toDouble();
  var unitIndex = 0;
  while (value >= 1024 && unitIndex < units.length - 1) {
    value /= 1024;
    unitIndex++;
  }
  return '${value.toStringAsFixed(unitIndex == 0 ? 0 : 1)} ${units[unitIndex]}';
}
