import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nano_app/app_versions/v1/features/notification_care/providers/notification_care_providers.dart';
import 'package:nano_app/core/constants/onboarding_constants.dart';
import 'package:nano_app/core/theme/theme.dart';
import 'package:nano_app/features/nabi/domain/health_review/nabi_health_review_models.dart';

class ProfileReviewPage extends ConsumerStatefulWidget {
  const ProfileReviewPage({super.key});

  @override
  ConsumerState<ProfileReviewPage> createState() => _ProfileReviewPageState();
}

class _ProfileReviewPageState extends ConsumerState<ProfileReviewPage> {
  final _formKey = GlobalKey<FormState>();
  String? _initializedActor;
  String _occupation = '';
  String _height = '';
  String _weight = '';
  String _sleepQuality = '';
  String _activityLevel = '';
  String _waterPerDay = '';

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(profileReviewControllerProvider);
    return MedicalPageScaffold(
      backgroundColor: context.semanticColors.background,
      appBar: AppBar(title: const Text('Cập nhật thông tin sức khỏe')),
      body: SafeArea(
        top: false,
        child: state.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, __) => Center(
            child: OutlinedButton.icon(
              onPressed: () => ref.invalidate(profileReviewControllerProvider),
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Thử lại'),
            ),
          ),
          data: (data) {
            if (_initializedActor != data.actorKey) {
              _initializedActor = data.actorKey;
              _occupation = data.profile.occupation;
              _height = data.profile.heightCm?.toStringAsFixed(1) ?? '';
              _weight = data.profile.weightKg?.toStringAsFixed(1) ?? '';
              _sleepQuality = data.profile.sleepQuality;
              _activityLevel = data.profile.activityLevel;
              _waterPerDay = data.profile.waterPerDay;
            }
            return Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.pagePadding,
                  AppSpacing.md,
                  AppSpacing.pagePadding,
                  AppSpacing.xxxl,
                ),
                children: [
                  Text('Có gì đã thay đổi không?', style: AppTextStyles.heading2),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    'Nabi chỉ hỏi lại những thông tin thường thay đổi theo thời gian để gợi ý phù hợp hơn.',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: context.semanticColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  DropdownButtonFormField<String>(
                    initialValue: _catalogValue(
                      OnboardingCatalog.occupations.map((item) => item.code),
                      _occupation,
                    ),
                    decoration: const InputDecoration(
                      labelText: 'Nghề nghiệp hiện tại',
                      border: OutlineInputBorder(),
                    ),
                    items: [
                      for (final item in OnboardingCatalog.occupations)
                        DropdownMenuItem(
                          value: item.code,
                          child: Text('${item.emoji} ${item.label}'),
                        ),
                    ],
                    onChanged: (value) => _occupation = value ?? '',
                  ),
                  const SizedBox(height: AppSpacing.md),
                  TextFormField(
                    initialValue: _height,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                    ],
                    decoration: const InputDecoration(
                      labelText: 'Chiều cao (cm)',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) => _numberValidation(value, 80, 250, 'chiều cao'),
                    onChanged: (value) => _height = value,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  TextFormField(
                    initialValue: _weight,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                    ],
                    decoration: const InputDecoration(
                      labelText: 'Cân nặng (kg)',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) => _numberValidation(value, 20, 350, 'cân nặng'),
                    onChanged: (value) => _weight = value,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _StringDropdown(
                    label: 'Chất lượng giấc ngủ',
                    value: _listValue(OnboardingCatalog.sleepQualities, _sleepQuality),
                    values: OnboardingCatalog.sleepQualities,
                    onChanged: (value) => _sleepQuality = value,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _StringDropdown(
                    label: 'Mức vận động',
                    value: _listValue(OnboardingCatalog.activityLevels, _activityLevel),
                    values: OnboardingCatalog.activityLevels,
                    onChanged: (value) => _activityLevel = value,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _StringDropdown(
                    label: 'Lượng nước thường uống',
                    value: _listValue(OnboardingCatalog.waterIntakeOptions, _waterPerDay),
                    values: OnboardingCatalog.waterIntakeOptions,
                    onChanged: (value) => _waterPerDay = value,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  FilledButton.icon(
                    onPressed: _submit,
                    icon: const Icon(Icons.save_rounded),
                    label: const Text('Lưu thông tin mới'),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (_formKey.currentState?.validate() != true) return;
    if (_occupation.isEmpty ||
        _sleepQuality.isEmpty ||
        _activityLevel.isEmpty ||
        _waterPerDay.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bạn giúp Nabi chọn đủ các thông tin nhé.')),
      );
      return;
    }
    final profile = NabiMutableProfileSnapshot(
      occupation: _occupation,
      heightCm: double.tryParse(_height),
      weightKg: double.tryParse(_weight),
      sleepQuality: _sleepQuality,
      activityLevel: _activityLevel,
      waterPerDay: _waterPerDay,
    );
    await ref.read(profileReviewControllerProvider.notifier).submit(profile);
    if (!mounted) return;
    final result = ref.read(profileReviewControllerProvider);
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            result.hasError
                ? 'Nabi chưa lưu được thông tin. Bạn thử lại nhé.'
                : 'Thông tin sức khỏe đã được cập nhật.',
          ),
        ),
      );
  }

  String? _numberValidation(
    String? value,
    double min,
    double max,
    String label,
  ) {
    final number = double.tryParse(value?.trim() ?? '');
    if (number == null || number < min || number > max) {
      return 'Bạn kiểm tra lại $label nhé.';
    }
    return null;
  }

  String? _catalogValue(Iterable<String> values, String value) {
    return values.contains(value) ? value : null;
  }

  String? _listValue(List<String> values, String value) {
    return values.contains(value) ? value : null;
  }
}

class _StringDropdown extends StatelessWidget {
  const _StringDropdown({
    required this.label,
    required this.value,
    required this.values,
    required this.onChanged,
  });

  final String label;
  final String? value;
  final List<String> values;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      initialValue: value,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
      items: [
        for (final item in values)
          DropdownMenuItem(value: item, child: Text(item)),
      ],
      onChanged: (value) {
        if (value != null) onChanged(value);
      },
    );
  }
}
