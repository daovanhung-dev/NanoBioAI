import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:nano_app/core/theme/theme.dart';
import 'package:nano_app/app_versions/v1/features/dashboard/domain/entities/dashboard_entity.dart';
import 'package:nano_app/app_versions/v1/features/dashboard/providers/dashboard_provider.dart';
import 'package:nano_app/app_versions/v1/features/settings/data/datasources/settings_local_datasource.dart';
import 'package:nano_app/app_versions/v1/features/settings/providers/settings_provider.dart';
import 'package:nano_app/app_versions/v1/features/settings/utils/profile_validator.dart';
import 'package:nano_app/services/supabase/auth/current_auth_user.dart';

class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashboardAsync = ref.watch(dashboardProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      floatingActionButton: dashboardAsync.value == null
          ? null
          : FloatingActionButton.extended(
              onPressed: () =>
                  _showEditProfileSheet(context, ref, dashboardAsync.value!),
              icon: const Icon(Icons.edit_rounded),
              label: const Text('Chỉnh sửa'),
            ),
      body: SafeArea(
        child: dashboardAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => _EmptyProfile(
            message:
                'Nabichưa thể mở hồ sơ của bạn lúc này. Mình thử lại sau một chút nhé.',
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
                        emptyMessage: 'Nabichưa thấy mục tiêu nào được chọn.',
                        items: dashboard.goals,
                        icon: Icons.flag_rounded,
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      _ChipSection(
                        title: 'Tình trạng cần lưu ý',
                        emptyMessage: 'Nabichưa thấy tình trạng nào cần lưu ý.',
                        items: dashboard.conditions,
                        icon: Icons.health_and_safety_rounded,
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      _ChipSection(
                        title: 'Thói quen',
                        emptyMessage:
                            'Nabichưa thấy thói quen nào được ghi nhớ.',
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

  Future<void> _showEditProfileSheet(
    BuildContext context,
    WidgetRef ref,
    DashboardEntity dashboard,
  ) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => _EditProfileSheet(dashboard: dashboard),
    );
    invalidateUserScopedProviders(ref);
  }
}

class _EditProfileSheet extends ConsumerStatefulWidget {
  final DashboardEntity dashboard;

  const _EditProfileSheet({required this.dashboard});

  @override
  ConsumerState<_EditProfileSheet> createState() => _EditProfileSheetState();
}

class _EditProfileSheetState extends ConsumerState<_EditProfileSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _fullName;
  late final TextEditingController _email;
  late final TextEditingController _phone;
  late final TextEditingController _gender;
  late final TextEditingController _birthYear;
  late final TextEditingController _occupation;
  late final TextEditingController _height;
  late final TextEditingController _weight;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final dashboard = widget.dashboard;
    _fullName = TextEditingController(text: dashboard.fullName);
    _email = TextEditingController(text: dashboard.email);
    _phone = TextEditingController(text: dashboard.phone);
    _gender = TextEditingController(text: dashboard.gender);
    _birthYear = TextEditingController(
      text: dashboard.birthYear > 0 ? dashboard.birthYear.toString() : '',
    );
    _occupation = TextEditingController(text: dashboard.occupation);
    _height = TextEditingController(
      text: dashboard.heightCm > 0 ? dashboard.heightCm.toString() : '',
    );
    _weight = TextEditingController(
      text: dashboard.weightKg > 0 ? dashboard.weightKg.toString() : '',
    );
  }

  @override
  void dispose() {
    _fullName.dispose();
    _email.dispose();
    _phone.dispose();
    _gender.dispose();
    _birthYear.dispose();
    _occupation.dispose();
    _height.dispose();
    _weight.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.lg,
        bottomInset + AppSpacing.lg,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Chỉnh sửa hồ sơ', style: AppTextStyles.heading3),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Email được quản lý bởi Supabase Auth nên Nabichỉ cập nhật hồ sơ sức khỏe và thông tin hiển thị ở đây.',
                style: AppTextStyles.bodyMedium,
              ),
              const SizedBox(height: AppSpacing.lg),
              _ProfileField(
                controller: _fullName,
                label: 'Họ và tên',
                validator: ProfileValidator.validateFullName,
              ),
              _ProfileField(controller: _email, label: 'Email', enabled: false),
              _ProfileField(
                controller: _phone,
                label: 'Số điện thoại',
                keyboardType: TextInputType.phone,
                validator: ProfileValidator.validatePhone,
              ),
              _ProfileField(controller: _gender, label: 'Giới tính'),
              _ProfileField(
                controller: _birthYear,
                label: 'Năm sinh',
                keyboardType: TextInputType.number,
                validator: (value) => ProfileValidator.validateBirthYear(
                  int.tryParse((value ?? '').trim()),
                ),
              ),
              _ProfileField(controller: _occupation, label: 'Nghề nghiệp'),
              Row(
                children: [
                  Expanded(
                    child: _ProfileField(
                      controller: _height,
                      label: 'Chiều cao (cm)',
                      keyboardType: TextInputType.number,
                      validator: (value) => ProfileValidator.validateHeight(
                        double.tryParse((value ?? '').trim()),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: _ProfileField(
                      controller: _weight,
                      label: 'Cân nặng (kg)',
                      keyboardType: TextInputType.number,
                      validator: (value) => ProfileValidator.validateWeight(
                        double.tryParse((value ?? '').trim()),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _saving ? null : _save,
                  child: _saving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Lưu hồ sơ'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final authUserId = currentSupabaseUserIdOrNull();
    if (authUserId == null) {
      _showMessage(
        'Phiên đăng nhập chưa sẵn sàng. Bạn đăng nhập lại rồi thử cập nhật hồ sơ nhé.',
      );
      return;
    }

    setState(() => _saving = true);
    try {
      final birthYear = int.parse(_birthYear.text.trim());
      final height = double.parse(_height.text.trim());
      final weight = double.parse(_weight.text.trim());
      final bmi = _calculateBmi(height, weight);
      final localProfile = <String, dynamic>{
        'full_name': _fullName.text.trim(),
        'phone': _phone.text.trim(),
        'gender': _gender.text.trim(),
        'birth_year': birthYear,
        'occupation': _occupation.text.trim(),
        'height_cm': height,
        'weight_kg': weight,
        'bmi': bmi,
      };

      // Local data is durable first. SQLite v12 triggers enqueue both user and
      // health-profile changes in the same transaction; the outbox pushes a
      // complete authenticated snapshot and retries without discarding the
      // user's edit when the device is offline.
      await const SettingsLocalDatasource().updateUserProfile(
        authUserId,
        localProfile,
      );
      invalidateUserScopedProviders(ref);

      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nabiđã cập nhật hồ sơ của bạn.')),
      );
    } catch (_) {
      _showMessage(
        'Nabichưa thể cập nhật hồ sơ lúc này. Bạn thử lại sau một chút nhé.',
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  double _calculateBmi(double heightCm, double weightKg) {
    if (heightCm <= 0 || weightKg <= 0) return 0;
    final heightM = heightCm / 100;
    return double.parse((weightKg / (heightM * heightM)).toStringAsFixed(2));
  }
}

class _ProfileField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final bool enabled;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;

  const _ProfileField({
    required this.controller,
    required this.label,
    this.enabled = true,
    this.keyboardType,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: TextFormField(
        controller: controller,
        enabled: enabled,
        keyboardType: keyboardType,
        validator: validator,
        decoration: InputDecoration(labelText: label),
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
                  'Nabisẽ dùng những thông tin này để chăm sóc bạn gần gũi hơn mỗi ngày.',
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
