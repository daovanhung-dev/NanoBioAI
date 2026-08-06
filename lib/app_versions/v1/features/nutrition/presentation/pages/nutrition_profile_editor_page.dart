import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:nano_app/app_versions/v1/features/nutrition/domain/entities/nutrition_profile_entity.dart';
import 'package:nano_app/app_versions/v1/features/nutrition/providers/nutrition_profile_providers.dart';
import 'package:nano_app/core/theme/theme.dart';

class NutritionProfileEditorPage extends ConsumerWidget {
  const NutritionProfileEditorPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(nutritionProfileControllerProvider);

    return MedicalPageScaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Hồ sơ dinh dưỡng')),
      body: AppStateSwitcher(
        alignment: Alignment.topCenter,
        child: profileAsync.when(
          loading: () => const Center(
            key: ValueKey('nutrition-profile-loading'),
            child: CircularProgressIndicator(),
          ),
          error: (error, _) => _ProfileLoadError(
            key: const ValueKey('nutrition-profile-error'),
            onRetry: () {
              AppFeedbackService.instance.emit(AppFeedbackType.primaryAction);
              ref
                  .read(nutritionProfileControllerProvider.notifier)
                  .refresh();
            },
          ),
          data: (profile) => _NutritionProfileForm(
            key: ValueKey('nutrition-profile-${profile.id}-${profile.updatedAt}'),
            initialProfile: profile,
          ),
        ),
      ),
    );
  }
}

class _NutritionProfileForm extends ConsumerStatefulWidget {
  const _NutritionProfileForm({
    super.key,
    required this.initialProfile,
  });

  final NutritionProfileEntity initialProfile;

  @override
  ConsumerState<_NutritionProfileForm> createState() =>
      _NutritionProfileFormState();
}

class _NutritionProfileFormState
    extends ConsumerState<_NutritionProfileForm> {
  final _formKey = GlobalKey<FormState>();
  int _step = 0;
  bool _saving = false;

  late final TextEditingController _birthDate;
  late final TextEditingController _waist;
  late final TextEditingController _sleep;
  late final TextEditingController _currentStatus;
  late final TextEditingController _targetWeight;
  late final TextEditingController _allergies;
  late final TextEditingController _intolerances;
  late final TextEditingController _avoidFoods;
  late final TextEditingController _symptoms;
  late final TextEditingController _medications;
  late final TextEditingController _labs;
  late final TextEditingController _goals;
  late final TextEditingController _likedFoods;
  late final TextEditingController _dislikedFoods;
  late final TextEditingController _waterRestrictionNote;

  String _smokingStatus = 'not_provided';
  String _alcoholFrequency = 'not_provided';
  String _coffeeFrequency = 'not_provided';
  String _nocturiaLevel = 'not_provided';
  bool _waterRestriction = false;

  @override
  void initState() {
    super.initState();
    final profile = widget.initialProfile;
    _birthDate = TextEditingController(
      text: profile.birthDate == null
          ? ''
          : profile.birthDate!.toIso8601String().split('T').first,
    );
    _waist = TextEditingController(text: _numberText(profile.waistCm));
    _sleep = TextEditingController(
      text: _numberText(profile.averageSleepHours),
    );
    _currentStatus = TextEditingController(text: profile.currentStatus);
    _targetWeight = TextEditingController(
      text: _numberText(profile.targetWeightKg),
    );
    _allergies = TextEditingController(
      text: _joinRestrictions(profile, 'allergy'),
    );
    _intolerances = TextEditingController(
      text: _joinRestrictions(profile, 'intolerance'),
    );
    _avoidFoods = TextEditingController(
      text: _joinRestrictions(profile, 'avoid'),
    );
    _symptoms = TextEditingController(
      text: profile.symptoms.map((item) => item.symptomType).join(', '),
    );
    _medications = TextEditingController(
      text: profile.medications.map((item) => item.name).join(', '),
    );
    _labs = TextEditingController(
      text: profile.labResults
          .map((item) => '${item.testName}=${item.valueText}${item.unit.isEmpty ? '' : ' ${item.unit}'}')
          .join('\n'),
    );
    _goals = TextEditingController(
      text: profile.goals.map((item) => item.name).join(', '),
    );
    _likedFoods = TextEditingController(
      text: _joinPreference(profile, 'like'),
    );
    _dislikedFoods = TextEditingController(
      text: _joinPreference(profile, 'dislike'),
    );
    _waterRestrictionNote = TextEditingController(
      text: profile.waterRestrictionNote,
    );
    _smokingStatus = profile.smokingStatus;
    _alcoholFrequency = profile.alcoholFrequency;
    _coffeeFrequency = profile.coffeeFrequency;
    _nocturiaLevel = profile.nocturiaLevel;
    _waterRestriction = profile.waterRestriction;
  }

  @override
  void dispose() {
    for (final controller in [
      _birthDate,
      _waist,
      _sleep,
      _currentStatus,
      _targetWeight,
      _allergies,
      _intolerances,
      _avoidFoods,
      _symptoms,
      _medications,
      _labs,
      _goals,
      _likedFoods,
      _dislikedFoods,
      _waterRestrictionNote,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          _StepHeader(step: _step),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.md,
                AppSpacing.md,
                AppSpacing.md,
                120,
              ),
              child: AppDirectionalSwitcher(
                index: _step,
                child: KeyedSubtree(
                  key: ValueKey('nutrition-profile-step-$_step'),
                  child: _buildStep(),
                ),
              ),
            ),
          ),
          _NavigationBar(
            step: _step,
            saving: _saving,
            onBack: _step == 0
                ? null
                : () {
                    AppFeedbackService.instance.emit(AppFeedbackType.selection);
                    setState(() => _step--);
                  },
            onNext: _saving ? null : _next,
          ),
        ],
      ),
    );
  }

  Widget _buildStep() {
    switch (_step) {
      case 0:
        return _StepCard(
          title: 'Thông tin nền',
          subtitle: 'Chỉ nhập những gì bạn biết. Các trường đều có thể cập nhật sau.',
          children: [
            _TextField(
              controller: _birthDate,
              label: 'Ngày sinh (YYYY-MM-DD)',
              keyboardType: TextInputType.datetime,
              validator: _optionalDateValidator,
            ),
            _TextField(
              controller: _waist,
              label: 'Vòng eo (cm)',
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              validator: (value) => _optionalNumberValidator(
                value,
                min: 20,
                max: 300,
                label: 'Vòng eo',
              ),
            ),
            _TextField(
              controller: _sleep,
              label: 'Số giờ ngủ trung bình',
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              validator: (value) => _optionalNumberValidator(
                value,
                min: 0,
                max: 24,
                label: 'Thời gian ngủ',
              ),
            ),
            _TextField(
              controller: _currentStatus,
              label: 'Tình trạng hiện tại',
              hint: 'Ví dụ: thường mệt buổi chiều',
              maxLines: 3,
            ),
            _TextField(
              controller: _targetWeight,
              label: 'Cân nặng mục tiêu (kg)',
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              validator: (value) => _optionalNumberValidator(
                value,
                min: 20,
                max: 400,
                label: 'Cân nặng mục tiêu',
              ),
            ),
          ],
        );
      case 1:
        return _StepCard(
          title: 'Thực phẩm cần tránh',
          subtitle: 'Tách nhiều mục bằng dấu phẩy. Nabi sẽ không tự suy diễn mức độ dị ứng.',
          children: [
            _TextField(
              controller: _allergies,
              label: 'Dị ứng đã biết',
              hint: 'Tôm, đậu phộng...',
              maxLines: 2,
            ),
            _TextField(
              controller: _intolerances,
              label: 'Không dung nạp',
              hint: 'Sữa bò, gluten...',
              maxLines: 2,
            ),
            _TextField(
              controller: _avoidFoods,
              label: 'Thực phẩm chủ động tránh',
              hint: 'Đồ chiên, nội tạng...',
              maxLines: 2,
            ),
            SwitchListTile.adaptive(
              contentPadding: EdgeInsets.zero,
              title: const Text('Có hạn chế lượng nước uống'),
              subtitle: const Text('Chỉ bật khi đã có hướng dẫn phù hợp.'),
              value: _waterRestriction,
              onChanged: (value) => setState(() => _waterRestriction = value),
            ),
            if (_waterRestriction)
              _TextField(
                controller: _waterRestrictionNote,
                label: 'Ghi chú hạn chế nước',
                maxLines: 2,
              ),
            _ChoiceField(
              label: 'Tiểu đêm',
              value: _nocturiaLevel,
              options: const {
                'not_provided': 'Chưa cung cấp',
                'none': 'Không',
                'mild': '1 lần/đêm',
                'moderate': '2 lần/đêm',
                'high': 'Từ 3 lần/đêm',
              },
              onChanged: (value) => setState(() => _nocturiaLevel = value),
            ),
          ],
        );
      case 2:
        return _StepCard(
          title: 'Triệu chứng và thuốc',
          subtitle: 'Thông tin này hỗ trợ sàng lọc thực đơn, không thay thế tư vấn y tế.',
          children: [
            _TextField(
              controller: _symptoms,
              label: 'Triệu chứng đang theo dõi',
              hint: 'Đầy bụng, khó ngủ...',
              maxLines: 3,
            ),
            _TextField(
              controller: _medications,
              label: 'Thuốc hoặc sản phẩm đang dùng',
              hint: 'Tên thuốc, vitamin...',
              maxLines: 3,
            ),
            _TextField(
              controller: _labs,
              label: 'Chỉ số xét nghiệm (mỗi dòng một chỉ số)',
              hint: 'Đường huyết=5.6 mmol/L',
              maxLines: 5,
            ),
            _ChoiceField(
              label: 'Hút thuốc',
              value: _smokingStatus,
              options: const {
                'not_provided': 'Chưa cung cấp',
                'never': 'Không hút',
                'former': 'Đã bỏ',
                'current': 'Đang hút',
              },
              onChanged: (value) => setState(() => _smokingStatus = value),
            ),
            _ChoiceField(
              label: 'Đồ uống có cồn',
              value: _alcoholFrequency,
              options: const {
                'not_provided': 'Chưa cung cấp',
                'never': 'Không dùng',
                'rare': 'Hiếm khi',
                'weekly': 'Hàng tuần',
                'daily': 'Hàng ngày',
              },
              onChanged: (value) => setState(() => _alcoholFrequency = value),
            ),
            _ChoiceField(
              label: 'Cà phê',
              value: _coffeeFrequency,
              options: const {
                'not_provided': 'Chưa cung cấp',
                'never': 'Không dùng',
                'rare': 'Hiếm khi',
                'daily_1': 'Khoảng 1 ly/ngày',
                'daily_2_plus': 'Từ 2 ly/ngày',
              },
              onChanged: (value) => setState(() => _coffeeFrequency = value),
            ),
          ],
        );
      case 3:
        return _StepCard(
          title: 'Mục tiêu và sở thích',
          subtitle: 'Tối đa 3 mục tiêu ưu tiên. Sở thích chỉ được dùng sau các ràng buộc an toàn.',
          children: [
            _TextField(
              controller: _goals,
              label: 'Mục tiêu ưu tiên',
              hint: 'Giảm cân, ăn đủ rau, ổn định bữa ăn',
              maxLines: 3,
              validator: (value) {
                if (_items(value).length > 3) {
                  return 'Chọn tối đa 3 mục tiêu ưu tiên.';
                }
                return null;
              },
            ),
            _TextField(
              controller: _likedFoods,
              label: 'Món hoặc nguyên liệu yêu thích',
              maxLines: 3,
            ),
            _TextField(
              controller: _dislikedFoods,
              label: 'Món hoặc nguyên liệu không thích',
              maxLines: 3,
            ),
            const _SafetyNote(),
          ],
        );
      default:
        return _ReviewCard(profile: _buildProfile());
    }
  }

  Future<void> _next() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      AppFeedbackService.instance.emit(AppFeedbackType.warning);
      return;
    }
    if (_step < 4) {
      AppFeedbackService.instance.emit(AppFeedbackType.selection);
      setState(() => _step++);
      return;
    }

    AppFeedbackService.instance.emit(AppFeedbackType.primaryAction);
    setState(() => _saving = true);
    await ref
        .read(nutritionProfileControllerProvider.notifier)
        .save(_buildProfile());
    if (!mounted) return;
    final result = ref.read(nutritionProfileControllerProvider);
    setState(() => _saving = false);
    if (result.hasError) {
      AppFeedbackService.instance.emit(AppFeedbackType.error);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nabi chưa lưu được hồ sơ. Hãy thử lại.')),
      );
      return;
    }
    AppFeedbackService.instance.emit(AppFeedbackType.success);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Đã lưu hồ sơ dinh dưỡng.')),
    );
    Navigator.of(context).pop(true);
  }

  NutritionProfileEntity _buildProfile() {
    final base = widget.initialProfile;
    return base.copyWith(
      birthDate: DateTime.tryParse(_birthDate.text.trim()),
      clearBirthDate: _birthDate.text.trim().isEmpty,
      waistCm: double.tryParse(_waist.text.trim()),
      clearWaistCm: _waist.text.trim().isEmpty,
      averageSleepHours: double.tryParse(_sleep.text.trim()),
      clearAverageSleepHours: _sleep.text.trim().isEmpty,
      currentStatus: _currentStatus.text.trim(),
      targetWeightKg: double.tryParse(_targetWeight.text.trim()),
      clearTargetWeightKg: _targetWeight.text.trim().isEmpty,
      targetWeightSource: _targetWeight.text.trim().isEmpty ? '' : 'user',
      smokingStatus: _smokingStatus,
      alcoholFrequency: _alcoholFrequency,
      coffeeFrequency: _coffeeFrequency,
      waterRestriction: _waterRestriction,
      waterRestrictionNote: _waterRestriction
          ? _waterRestrictionNote.text.trim()
          : '',
      nocturiaLevel: _nocturiaLevel,
      restrictions: [
        ..._restrictionEntities(_allergies.text, 'allergy'),
        ..._restrictionEntities(_intolerances.text, 'intolerance'),
        ..._restrictionEntities(_avoidFoods.text, 'avoid'),
      ],
      symptoms: _items(_symptoms.text)
          .map((name) => HealthSymptomEntity(symptomType: name))
          .toList(growable: false),
      medications: _items(_medications.text)
          .map((name) => MedicationRecordEntity(name: name))
          .toList(growable: false),
      labResults: _parseLabs(_labs.text),
      goals: _items(_goals.text)
          .take(3)
          .toList(growable: false)
          .asMap()
          .entries
          .map(
            (entry) => NutritionGoalEntity(
              code: _slug(entry.value),
              name: entry.value,
              priority: entry.key + 1,
            ),
          )
          .toList(growable: false),
      preferenceRules: [
        ..._preferenceEntities(_likedFoods.text, 'like', 'preferred'),
        ..._preferenceEntities(_dislikedFoods.text, 'dislike', 'avoid_if_possible'),
      ],
    );
  }

  static List<FoodRestrictionEntity> _restrictionEntities(
    String text,
    String type,
  ) {
    return _items(text)
        .map((name) => FoodRestrictionEntity(type: type, itemName: name))
        .toList(growable: false);
  }

  static List<NutritionPreferenceRuleEntity> _preferenceEntities(
    String text,
    String type,
    String level,
  ) {
    return _items(text)
        .map(
          (name) => NutritionPreferenceRuleEntity(
            ruleType: type,
            itemName: name,
            preferenceLevel: level,
          ),
        )
        .toList(growable: false);
  }

  static List<LabResultEntity> _parseLabs(String text) {
    final results = <LabResultEntity>[];
    for (final line in text.split(RegExp(r'[\n;]+'))) {
      final trimmed = line.trim();
      if (trimmed.isEmpty) continue;
      final separator = trimmed.indexOf('=');
      if (separator <= 0 || separator >= trimmed.length - 1) continue;
      results.add(
        LabResultEntity(
          testName: trimmed.substring(0, separator).trim(),
          valueText: trimmed.substring(separator + 1).trim(),
        ),
      );
    }
    return results;
  }

  static String? _optionalDateValidator(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return null;
    final parsed = DateTime.tryParse(text);
    if (parsed == null || !RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(text)) {
      return 'Nhập ngày theo dạng YYYY-MM-DD.';
    }
    if (parsed.isAfter(DateTime.now())) return 'Ngày sinh không hợp lệ.';
    return null;
  }

  static String? _optionalNumberValidator(
    String? value, {
    required double min,
    required double max,
    required String label,
  }) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return null;
    final number = double.tryParse(text);
    if (number == null || number < min || number > max) {
      return '$label phải nằm trong khoảng $min–$max.';
    }
    return null;
  }

  static String _joinRestrictions(
    NutritionProfileEntity profile,
    String type,
  ) {
    return profile.restrictions
        .where((item) => item.type == type && item.isActive)
        .map((item) => item.itemName)
        .join(', ');
  }

  static String _joinPreference(
    NutritionProfileEntity profile,
    String type,
  ) {
    return profile.preferenceRules
        .where((item) => item.ruleType == type && item.isActive)
        .map((item) => item.itemName)
        .join(', ');
  }

  static List<String> _items(String? value) {
    return (value ?? '')
        .split(RegExp(r'[,;\n]+'))
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toSet()
        .toList(growable: false);
  }

  static String _slug(String value) {
    return value
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
        .replaceAll(RegExp(r'^_+|_+$'), '');
  }

  static String _numberText(double? value) {
    if (value == null) return '';
    if (value == value.roundToDouble()) return value.toInt().toString();
    return value.toStringAsFixed(1);
  }
}

class _StepHeader extends StatelessWidget {
  const _StepHeader({required this.step});

  final int step;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.surface,
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.sm,
        AppSpacing.md,
        AppSpacing.md,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Bước ${step + 1}/5',
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textSecondary,
              fontWeight: AppTypography.semiBold,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          LinearProgressIndicator(
            value: (step + 1) / 5,
            minHeight: 7,
            borderRadius: BorderRadius.circular(AppRadius.circular),
          ),
        ],
      ),
    );
  }
}

class _StepCard extends StatelessWidget {
  const _StepCard({
    required this.title,
    required this.subtitle,
    required this.children,
  });

  final String title;
  final String subtitle;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.pagePaddingLarge),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        boxShadow: AppShadows.sm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppTextStyles.heading3),
          const SizedBox(height: AppSpacing.xs),
          Text(
            subtitle,
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textSecondary,
              height: 1.45,
            ),
          ),
          const SizedBox(height: AppSpacing.sectionSpacing),
          ...children.expand(
            (child) => [child, const SizedBox(height: AppSpacing.md)],
          ),
        ],
      ),
    );
  }
}

class _TextField extends StatelessWidget {
  const _TextField({
    required this.controller,
    required this.label,
    this.hint,
    this.keyboardType,
    this.maxLines = 1,
    this.validator,
  });

  final TextEditingController controller;
  final String label;
  final String? hint;
  final TextInputType? keyboardType;
  final int maxLines;
  final String? Function(String?)? validator;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      validator: validator,
      decoration: InputDecoration(labelText: label, hintText: hint),
    );
  }
}

class _ChoiceField extends StatelessWidget {
  const _ChoiceField({
    required this.label,
    required this.value,
    required this.options,
    required this.onChanged,
  });

  final String label;
  final String value;
  final Map<String, String> options;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      initialValue: options.containsKey(value) ? value : options.keys.first,
      decoration: InputDecoration(labelText: label),
      items: options.entries
          .map(
            (entry) => DropdownMenuItem<String>(
              value: entry.key,
              child: Text(entry.value),
            ),
          )
          .toList(growable: false),
      onChanged: (value) {
        if (value != null) onChanged(value);
      },
    );
  }
}

class _ReviewCard extends StatelessWidget {
  const _ReviewCard({required this.profile});

  final NutritionProfileEntity profile;

  @override
  Widget build(BuildContext context) {
    final rows = <MapEntry<String, String>>[
      MapEntry('Ngày sinh', profile.birthDate?.toIso8601String().split('T').first ?? 'Chưa cung cấp'),
      MapEntry('Vòng eo', profile.waistCm == null ? 'Chưa cung cấp' : '${profile.waistCm} cm'),
      MapEntry('Ngủ trung bình', profile.averageSleepHours == null ? 'Chưa cung cấp' : '${profile.averageSleepHours} giờ'),
      MapEntry('Thực phẩm cần tránh', profile.restrictions.isEmpty ? 'Không ghi nhận' : profile.restrictions.map((item) => item.itemName).join(', ')),
      MapEntry('Triệu chứng', profile.symptoms.isEmpty ? 'Không ghi nhận' : profile.symptoms.map((item) => item.symptomType).join(', ')),
      MapEntry('Thuốc/sản phẩm', profile.medications.isEmpty ? 'Không ghi nhận' : profile.medications.map((item) => item.name).join(', ')),
      MapEntry('Mục tiêu', profile.goals.isEmpty ? 'Chưa chọn' : profile.goals.map((item) => item.name).join(', ')),
    ];

    return _StepCard(
      title: 'Kiểm tra trước khi lưu',
      subtitle: 'Bạn có thể quay lại từng bước để chỉnh sửa.',
      children: [
        ...rows.map(
          (row) => ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(row.key),
            subtitle: Text(row.value),
          ),
        ),
        const _SafetyNote(),
      ],
    );
  }
}

class _SafetyNote extends StatelessWidget {
  const _SafetyNote();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.cardPadding),
      decoration: BoxDecoration(
        color: AppColors.info.withValues(alpha: .08),
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Text(
        'Hồ sơ này giúp cá nhân hóa gợi ý. Ứng dụng không tự kê thuốc, chẩn đoán hoặc thay đổi chỉ định chuyên môn.',
        style: AppTextStyles.bodySmall.copyWith(
          color: AppColors.textSecondary,
          height: 1.45,
        ),
      ),
    );
  }
}

class _NavigationBar extends StatelessWidget {
  const _NavigationBar({
    required this.step,
    required this.saving,
    required this.onBack,
    required this.onNext,
  });

  final int step;
  final bool saving;
  final VoidCallback? onBack;
  final VoidCallback? onNext;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.cardPadding),
        decoration: BoxDecoration(
          color: AppColors.surface,
          boxShadow: AppShadows.md,
        ),
        child: Row(
          children: [
            if (onBack != null)
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onBack,
                  icon: const Icon(Icons.arrow_back_rounded),
                  label: const Text('Quay lại'),
                ),
              ),
            if (onBack != null) const SizedBox(width: AppSpacing.sm),
            Expanded(
              flex: 2,
              child: FilledButton.icon(
                onPressed: onNext,
                icon: saving
                    ? const SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.surface,
                        ),
                      )
                    : Icon(step == 4 ? Icons.save_rounded : Icons.arrow_forward_rounded),
                label: Text(saving ? 'Đang lưu...' : step == 4 ? 'Lưu hồ sơ' : 'Tiếp tục'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileLoadError extends StatelessWidget {
  const _ProfileLoadError({super.key, required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.pagePaddingLarge),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.spa_rounded, size: 48),
            const SizedBox(height: AppSpacing.md),
            const Text('Nabi chưa mở được hồ sơ dinh dưỡng.'),
            const SizedBox(height: AppSpacing.sm),
            FilledButton.icon(
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
