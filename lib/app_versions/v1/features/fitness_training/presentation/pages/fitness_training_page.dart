import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nano_app/app_versions/v1/features/body_metrics/domain/entities/basic_health_calculator_models.dart';
import 'package:nano_app/app_versions/v1/services/ai/personal_schedule_quota_gateway.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../application/fitness_training_controller.dart';
import '../../domain/entities/fitness_training_catalog.dart';
import '../../domain/entities/fitness_training_profile.dart';
import '../../domain/entities/fitness_training_program.dart';
import '../../domain/repositories/fitness_training_repository.dart';
import '../../domain/services/fitness_program_validator.dart';
import '../../providers/fitness_training_providers.dart';
import '../widgets/fitness_catalog_image.dart';
import '../widgets/fitness_training_youtube_player.dart';

class FitnessTrainingPage extends ConsumerStatefulWidget {
  const FitnessTrainingPage({super.key});

  @override
  ConsumerState<FitnessTrainingPage> createState() =>
      _FitnessTrainingPageState();
}

class _FitnessTrainingPageState extends ConsumerState<FitnessTrainingPage> {
  late Future<FitnessTrainingLoadedContext> _loadFuture;
  int _step = 0;
  bool _profileReviewed = false;
  bool _aiConsent = false;
  bool _busy = false;
  String? _error;
  String? _pendingRequestId;
  FitnessTrainingProgram? _preview;
  bool _filtersSeeded = false;

  String _goal = 'general_fitness';
  String _experience = 'beginner';
  String _venue = 'gym';
  final Set<String> _equipmentIds = {};
  final Set<int> _weekdays = {1, 3, 5};
  final Set<String> _excludedMoves = {};
  final Set<String> _excludedAllergens = {};
  final Set<String> _foodGroups = {};
  int _sessionMinutes = 45;
  String _workoutTime = '17:30';
  String _sleepTime = '22:30';
  String _wakeTime = '06:30';

  @override
  void initState() {
    super.initState();
    _loadFuture = ref.read(fitnessTrainingControllerProvider).load();
  }

  void _reload() {
    setState(() {
      _preview = null;
      _error = null;
      _step = 0;
      _loadFuture = ref.read(fitnessTrainingControllerProvider).load();
    });
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Chế độ luyện tập')),
    body: !_supportedPlatform
        ? const Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Text(
                'Bản thử nghiệm chế độ luyện tập hiện hỗ trợ Android và iOS.',
              ),
            ),
          )
        : FutureBuilder<FitnessTrainingLoadedContext>(
            future: _loadFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState != ConnectionState.done) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError || !snapshot.hasData) {
                return _loadError();
              }
              final data = snapshot.requireData;
              if (!_filtersSeeded) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (!mounted || _filtersSeeded) return;
                  setState(() {
                    _filtersSeeded = true;
                    _foodGroups.addAll(data.catalog.foodGroups);
                    if (RegExp(
                      r'^\d{2}:\d{2}$',
                    ).hasMatch(data.profile.workoutTime)) {
                      _workoutTime = data.profile.workoutTime;
                    }
                    if (RegExp(
                      r'^\d{2}:\d{2}$',
                    ).hasMatch(data.profile.sleepTime)) {
                      _sleepTime = data.profile.sleepTime;
                    }
                    if (RegExp(
                      r'^\d{2}:\d{2}$',
                    ).hasMatch(data.profile.wakeTime)) {
                      _wakeTime = data.profile.wakeTime;
                    }
                    for (final restriction in data.profile.foodRestrictions) {
                      _excludedAllergens.addAll(
                        ref
                            .read(fitnessTrainingControllerProvider)
                            .allergenTagsFor(restriction),
                      );
                    }
                  });
                });
              }
              return _pageBody(data);
            },
          ),
  );

  Widget _loadError() => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.cloud_off_rounded, size: 42),
          const SizedBox(height: 12),
          const Text('Chưa mở được chế độ luyện tập.'),
          const SizedBox(height: 12),
          FilledButton(onPressed: _reload, child: const Text('Thử lại')),
        ],
      ),
    ),
  );

  Widget _pageBody(FitnessTrainingLoadedContext data) {
    final controller = ref.read(fitnessTrainingControllerProvider);
    final profile = data.profile;
    final age = controller.age(profile);
    final adult = age != null && age >= 18;
    final metrics = controller.bodyMetrics(profile);
    final active = data.activeProgram;
    final pendingPreview = _preview ?? data.previewProgram;
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 36),
      children: [
        _pilotNotice(),
        if (active != null) ...[
          const SizedBox(height: 14),
          _activeProgramCard(active, data),
        ],
        if (pendingPreview != null && _step != 2) ...[
          const SizedBox(height: 14),
          _pendingPreviewCard(pendingPreview, data),
        ],
        if (_step == 0) ...[
          const SizedBox(height: 18),
          _sectionTitle(
            'Rà soát hồ sơ',
            'Kiểm tra thông tin trước khi tạo lộ trình.',
          ),
          const SizedBox(height: 8),
          _profileReview(profile, age, adult, metrics),
          const SizedBox(height: 14),
          if (!adult)
            _ageGateCard(profile, age)
          else ...[
            CheckboxListTile(
              value: _profileReviewed,
              onChanged: (value) =>
                  setState(() => _profileReviewed = value ?? false),
              contentPadding: EdgeInsets.zero,
              title: const Text('Tôi đã rà soát và xác nhận hồ sơ bên trên.'),
              controlAffinity: ListTileControlAffinity.leading,
            ),
            FilledButton.icon(
              onPressed: _profileReviewed
                  ? () => setState(() => _step = 1)
                  : null,
              icon: const Icon(Icons.arrow_forward_rounded),
              label: const Text('Tiếp tục thiết lập'),
            ),
          ],
        ] else if (_step == 1) ...[
          const SizedBox(height: 18),
          _sectionTitle(
            'Thiết lập chương trình',
            'Nabi chỉ dùng các lựa chọn an toàn bạn đã khai báo.',
          ),
          const SizedBox(height: 12),
          _goalAndExperience(),
          const SizedBox(height: 12),
          _venuePicker(),
          if (_venue == 'gym') ...[
            const SizedBox(height: 12),
            _equipmentPicker(data.catalog),
          ],
          const SizedBox(height: 12),
          _schedulePreferences(),
          const SizedBox(height: 12),
          _movementRestrictions(),
          const SizedBox(height: 12),
          _foodPreferences(data.catalog),
          const SizedBox(height: 12),
          _aiConsentTile(metrics),
          if (_error != null) _errorCard(_error!),
          const SizedBox(height: 10),
          Row(
            children: [
              OutlinedButton(
                onPressed: _busy ? null : () => setState(() => _step = 0),
                child: const Text('Quay lại'),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton.icon(
                  onPressed: _canGenerate(data, adult)
                      ? () => _generate(data)
                      : null,
                  icon: _busy
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.auto_awesome_rounded),
                  label: Text(
                    _busy ? 'Đang tạo...' : 'Tạo bản xem trước 4 tuần',
                  ),
                ),
              ),
            ],
          ),
        ] else if (pendingPreview != null) ...[
          const SizedBox(height: 18),
          _previewProgram(pendingPreview, data),
          if (_error != null) _errorCard(_error!),
          const SizedBox(height: 12),
          Row(
            children: [
              OutlinedButton(
                onPressed: _busy ? null : () => setState(() => _step = 1),
                child: const Text('Chỉnh lựa chọn'),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton.icon(
                  onPressed: _busy
                      ? null
                      : () => _confirmApply(pendingPreview, data),
                  icon: const Icon(Icons.check_circle_outline_rounded),
                  label: Text(
                    'Xác nhận và áp dụng tuần ${pendingPreview.activeWeek}',
                  ),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _pilotNotice() => Card(
    color: Theme.of(context).colorScheme.secondaryContainer,
    child: const Padding(
      padding: EdgeInsets.all(14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.science_outlined),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Bản thử nghiệm: nội dung bài tập, thực đơn và minh họa đang chờ rà soát chuyên môn. Đây là gợi ý wellness, không thay thế tư vấn y tế hoặc huấn luyện viên.',
            ),
          ),
        ],
      ),
    ),
  );

  Widget _sectionTitle(String title, String subtitle) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(title, style: Theme.of(context).textTheme.titleLarge),
      const SizedBox(height: 4),
      Text(subtitle, style: Theme.of(context).textTheme.bodyMedium),
    ],
  );

  Widget _profileReview(
    FitnessTrainingProfileSnapshot profile,
    int? age,
    bool adult,
    BasicHealthReport? metrics,
  ) => Card(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _detailLine(
            'Tên hồ sơ',
            profile.fullName.isEmpty ? 'Chưa cập nhật' : profile.fullName,
          ),
          _detailLine(
            'Ngày sinh',
            profile.birthDate == null
                ? 'Chưa có'
                : _formatDate(profile.birthDate!),
          ),
          _detailLine(
            'Điều kiện tuổi',
            age == null
                ? 'Chưa xác định'
                : adult
                ? 'Đủ 18 tuổi'
                : 'Chưa đủ 18 tuổi',
          ),
          _detailLine(
            'Mục tiêu đã khai báo',
            profile.goals.isEmpty ? 'Chưa cập nhật' : profile.goals.join(' · '),
          ),
          _detailLine(
            'Tình trạng đã khai báo',
            profile.conditions.isEmpty
                ? 'Chưa ghi nhận'
                : profile.conditions.join(' · '),
          ),
          _detailLine(
            'Hạn chế/dị ứng thực phẩm',
            profile.foodRestrictions.isEmpty
                ? 'Chưa ghi nhận'
                : profile.foodRestrictions.join(' · '),
          ),
          _detailLine(
            'Chiều cao / cân nặng',
            '${_displayNumber(profile.heightCm)} cm / ${_displayNumber(profile.weightKg)} kg',
          ),
          _detailLine(
            'Lịch ngủ hiện tại',
            '${profile.sleepTime} – ${profile.wakeTime}',
          ),
          const Divider(height: 22),
          if (metrics == null)
            const Text('Chưa đủ thông tin để tính chỉ số tham khảo bằng M04.')
          else ...[
            Text(
              'Chỉ số tham khảo (M04)',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _metricChip('BMI', metrics.bmi.toStringAsFixed(1)),
                _metricChip('BMR', '${metrics.bmrKcal} kcal/ngày'),
                _metricChip('TDEE', '${metrics.tdeeKcal} kcal/ngày'),
              ],
            ),
            const SizedBox(height: 5),
            const Text('Ước tính tham khảo, không dùng để chẩn đoán.'),
          ],
        ],
      ),
    ),
  );

  Widget _ageGateCard(FitnessTrainingProfileSnapshot profile, int? age) => Card(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            age != null && age < 18
                ? 'Chế độ này hiện dành cho người từ 18 tuổi.'
                : 'Cần ngày sinh đầy đủ để kiểm tra điều kiện sử dụng.',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 6),
          const Text(
            'Ngày sinh tự khai được lưu trong hồ sơ và kiểm tra trên thiết bị. Cách này có thể bị sửa hoặc vượt qua.',
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: _busy ? null : () => _chooseBirthDate(profile),
            icon: const Icon(Icons.cake_outlined),
            label: Text(
              profile.birthDate == null
                  ? 'Nhập ngày sinh'
                  : 'Cập nhật ngày sinh',
            ),
          ),
        ],
      ),
    ),
  );

  Widget _detailLine(String label, String value) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 146,
          child: Text(label, style: Theme.of(context).textTheme.labelLarge),
        ),
        Expanded(child: Text(value)),
      ],
    ),
  );

  Widget _metricChip(String label, String value) => Chip(
    avatar: const Icon(Icons.monitor_weight_outlined, size: 18),
    label: Text('$label · $value'),
  );

  Future<void> _chooseBirthDate(FitnessTrainingProfileSnapshot profile) async {
    final today = DateTime.now();
    final selected = await showDatePicker(
      context: context,
      initialDate:
          profile.birthDate ??
          DateTime(today.year - 25, today.month, today.day),
      firstDate: DateTime(1900),
      lastDate: today,
      helpText: 'Chọn ngày sinh đầy đủ',
    );
    if (selected == null || !mounted) return;
    setState(() => _busy = true);
    try {
      final refreshed = await ref
          .read(fitnessTrainingControllerProvider)
          .saveBirthDate(selected);
      if (!mounted) return;
      setState(() {
        _loadFuture = Future.value(refreshed);
        _busy = false;
        _profileReviewed = false;
      });
    } catch (_) {
      if (mounted) {
        setState(() {
          _busy = false;
          _error = 'Chưa lưu được ngày sinh. Bạn thử lại nhé.';
        });
      }
    }
  }

  Widget _goalAndExperience() => Card(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          DropdownButtonFormField<String>(
            key: ValueKey('fitness-goal-$_goal'),
            initialValue: _goal,
            decoration: const InputDecoration(labelText: 'Mục tiêu cá nhân'),
            items: const [
              DropdownMenuItem(
                value: 'general_fitness',
                child: Text('Khỏe và vận động đều'),
              ),
              DropdownMenuItem(value: 'strength', child: Text('Tăng sức mạnh')),
              DropdownMenuItem(
                value: 'muscle_building',
                child: Text('Phát triển cơ bắp'),
              ),
              DropdownMenuItem(
                value: 'weight_management',
                child: Text('Quản lý cân nặng'),
              ),
            ],
            onChanged: (value) => setState(() => _goal = value ?? _goal),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            key: ValueKey('fitness-experience-$_experience'),
            initialValue: _experience,
            decoration: const InputDecoration(
              labelText: 'Kinh nghiệm luyện tập',
            ),
            items: const [
              DropdownMenuItem(value: 'beginner', child: Text('Mới bắt đầu')),
              DropdownMenuItem(
                value: 'intermediate',
                child: Text('Đã tập một thời gian'),
              ),
              DropdownMenuItem(
                value: 'experienced',
                child: Text('Có kinh nghiệm'),
              ),
            ],
            onChanged: (value) =>
                setState(() => _experience = value ?? _experience),
          ),
        ],
      ),
    ),
  );

  Widget _venuePicker() => Card(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Bạn thường tập ở đâu?',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          SegmentedButton<String>(
            segments: const [
              ButtonSegment(
                value: 'gym',
                label: Text('Phòng gym'),
                icon: Icon(Icons.fitness_center_rounded),
              ),
              ButtonSegment(
                value: 'home',
                label: Text('Tại nhà'),
                icon: Icon(Icons.home_outlined),
              ),
            ],
            selected: {_venue},
            onSelectionChanged: (value) => setState(() {
              _venue = value.first;
              _equipmentIds.clear();
            }),
          ),
        ],
      ),
    ),
  );

  Widget _equipmentPicker(FitnessTrainingCatalog catalog) => Card(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Chọn thiết bị bạn có thể dùng',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 5),
          const Text('Bài tập chỉ dùng thiết bị đã chọn.'),
          const SizedBox(height: 12),
          GridView.builder(
            itemCount: catalog.equipment.length,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 178,
              mainAxisExtent: 170,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
            ),
            itemBuilder: (context, index) {
              final item = catalog.equipment[index];
              final selected = _equipmentIds.contains(item.id);
              return Semantics(
                button: true,
                selected: selected,
                label: '${item.name}. ${item.description}',
                child: InkWell(
                  borderRadius: BorderRadius.circular(14),
                  onTap: () => setState(
                    () => selected
                        ? _equipmentIds.remove(item.id)
                        : _equipmentIds.add(item.id),
                  ),
                  child: Card(
                    margin: EdgeInsets.zero,
                    color: selected
                        ? Theme.of(context).colorScheme.secondaryContainer
                        : null,
                    clipBehavior: Clip.antiAlias,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: SizedBox(
                            width: double.infinity,
                            child: FitnessCatalogImage(
                              catalog: catalog,
                              illustration: item.illustration,
                              width: double.infinity,
                              height: 105,
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(9, 6, 9, 8),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  item.name,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: Theme.of(context).textTheme.labelLarge,
                                ),
                              ),
                              Icon(
                                selected
                                    ? Icons.check_circle
                                    : Icons.circle_outlined,
                                size: 18,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    ),
  );

  Widget _schedulePreferences() => Card(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Lịch tập và nghỉ ngơi',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            children: [
              for (var day = 1; day <= 7; day++)
                FilterChip(
                  label: Text(_weekdayLabel(day)),
                  selected: _weekdays.contains(day),
                  onSelected: (selected) => setState(
                    () => selected ? _weekdays.add(day) : _weekdays.remove(day),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<int>(
            key: ValueKey('fitness-duration-$_sessionMinutes'),
            initialValue: _sessionMinutes,
            decoration: const InputDecoration(labelText: 'Thời lượng mỗi buổi'),
            items: const [30, 45, 60, 75]
                .map(
                  (value) => DropdownMenuItem(
                    value: value,
                    child: Text('$value phút'),
                  ),
                )
                .toList(),
            onChanged: (value) =>
                setState(() => _sessionMinutes = value ?? _sessionMinutes),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _timeDropdown('Giờ tập', _workoutTime, const [
                  '06:00',
                  '07:00',
                  '08:00',
                  '12:00',
                  '16:30',
                  '17:30',
                  '18:30',
                  '19:30',
                ], (v) => setState(() => _workoutTime = v)),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _timeDropdown('Giờ ngủ', _sleepTime, const [
                  '21:00',
                  '21:30',
                  '22:00',
                  '22:30',
                  '23:00',
                  '23:30',
                ], (v) => setState(() => _sleepTime = v)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _timeDropdown('Giờ thức dậy', _wakeTime, const [
            '05:00',
            '05:30',
            '06:00',
            '06:30',
            '07:00',
            '07:30',
            '08:00',
          ], (v) => setState(() => _wakeTime = v)),
        ],
      ),
    ),
  );

  Widget _timeDropdown(
    String label,
    String value,
    List<String> options,
    ValueChanged<String> onChanged,
  ) {
    final choices = {...options, value}.toList()..sort();
    return DropdownButtonFormField<String>(
      key: ValueKey('$label-$value'),
      initialValue: value,
      decoration: InputDecoration(labelText: label),
      items: [
        for (final option in choices)
          DropdownMenuItem(value: option, child: Text(option)),
      ],
      onChanged: (next) {
        if (next != null) onChanged(next);
      },
    );
  }

  Widget _movementRestrictions() => Card(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Vùng vận động cần tránh',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 4),
          const Text('Chọn những vùng không muốn đưa vào bài tập.'),
          Wrap(
            spacing: 6,
            children: [
              for (final item in const {
                'upper_body': 'Thân trên',
                'back': 'Lưng',
                'lower_body': 'Thân dưới',
                'core': 'Bụng',
                'cardio': 'Cardio',
              }.entries)
                FilterChip(
                  label: Text(item.value),
                  selected: _excludedMoves.contains(item.key),
                  onSelected: (selected) => setState(
                    () => selected
                        ? _excludedMoves.add(item.key)
                        : _excludedMoves.remove(item.key),
                  ),
                ),
            ],
          ),
        ],
      ),
    ),
  );

  Widget _foodPreferences(FitnessTrainingCatalog catalog) {
    const foodNames = {
      'protein': 'Đạm',
      'carbohydrate': 'Tinh bột',
      'fruit_vegetable': 'Rau và trái cây',
      'fat_source': 'Chất béo',
    };
    const allergenNames = {
      'milk': 'Sữa',
      'egg': 'Trứng',
      'fish': 'Cá',
      'crustacean_shellfish': 'Tôm cua',
      'soy': 'Đậu nành',
      'peanut': 'Đậu phộng',
      'tree_nuts': 'Các loại hạt',
      'wheat_gluten': 'Lúa mì/gluten',
      'sesame': 'Mè/vừng',
    };
    final unknown = _excludedAllergens
        .where((item) => item.startsWith('unknown:'))
        .toList();
    final unsupported = _excludedAllergens
        .where(
          (tag) =>
              !catalog.allergenTags.contains(tag) &&
              !tag.startsWith('unknown:'),
        )
        .toList();
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Nguồn thực phẩm phù hợp',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            Wrap(
              spacing: 6,
              children: [
                for (final group in catalog.foodGroups)
                  FilterChip(
                    label: Text(foodNames[group] ?? group),
                    selected: _foodGroups.contains(group),
                    onSelected: (selected) => setState(
                      () => selected
                          ? _foodGroups.add(group)
                          : _foodGroups.remove(group),
                    ),
                  ),
              ],
            ),
            const Divider(height: 24),
            Text(
              'Dị ứng cần loại trừ',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            Wrap(
              spacing: 6,
              children: [
                for (final entry in allergenNames.entries)
                  FilterChip(
                    label: Text(entry.value),
                    selected: _excludedAllergens.contains(entry.key),
                    onSelected: (selected) => setState(
                      () => selected
                          ? _excludedAllergens.add(entry.key)
                          : _excludedAllergens.remove(entry.key),
                    ),
                  ),
              ],
            ),
            if (unknown.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                'Chưa thể lọc chính xác mục hạn chế từ hồ sơ: ${unknown.map((item) => item.substring(8).replaceAll('_', ' ')).join(', ')}. Hãy cập nhật hồ sơ trước khi tạo thực đơn.',
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ],
            if (unsupported.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                'Catalog thử nghiệm chưa có dữ liệu lọc cho: ${unsupported.join(', ')}. Chưa thể tạo thực đơn an toàn với lựa chọn này.',
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ],
            const SizedBox(height: 5),
            const Text(
              'Món ăn và giá trị dinh dưỡng trong bản thử nghiệm chỉ mang tính tham khảo.',
            ),
          ],
        ),
      ),
    );
  }

  Widget _aiConsentTile(BasicHealthReport? metrics) => Card(
    child: CheckboxListTile(
      value: _aiConsent,
      onChanged: (value) => setState(() => _aiConsent = value ?? false),
      controlAffinity: ListTileControlAffinity.leading,
      title: const Text('Đồng ý tạo gợi ý bằng AI'),
      subtitle: Text(
        'Gemini nhận mục tiêu, nơi tập, thiết bị, lịch, nhóm thực phẩm và điều kiện đã chọn${metrics == null ? '' : ', cùng BMI/BMR/TDEE tham khảo'}. Không gửi ngày sinh, tên hoặc ghi chú hồ sơ.',
      ),
    ),
  );

  bool _canGenerate(FitnessTrainingLoadedContext data, bool adult) {
    if (_busy ||
        !adult ||
        !_aiConsent ||
        _weekdays.isEmpty ||
        _foodGroups.isEmpty) {
      return false;
    }
    if (_venue == 'gym' && _equipmentIds.isEmpty) return false;
    if (_excludedAllergens.any(
      (tag) =>
          tag.startsWith('unknown:') ||
          !data.catalog.allergenTags.contains(tag),
    )) {
      return false;
    }
    final exercises = data.catalog.eligibleExercises(
      venue: _venue,
      equipmentIds: _equipmentIds,
      excludedMovementGroups: _excludedMoves,
    );
    final recipes = data.catalog.eligibleRecipes(
      excludedAllergens: _excludedAllergens,
      availableFoodGroups: _foodGroups,
    );
    return exercises.isNotEmpty &&
        FitnessProgramValidator.mealSlots.every(
          (slot) => recipes.any((recipe) => recipe.mealSlot == slot),
        );
  }

  Future<void> _generate(FitnessTrainingLoadedContext data) async {
    final controller = ref.read(fitnessTrainingControllerProvider);
    final intake = controller.makeIntake(
      profile: data.profile,
      goal: _goal,
      experience: _experience,
      venue: _venue,
      equipmentIds: _equipmentIds,
      trainingWeekdays: _weekdays.toList(),
      sessionMinutes: _sessionMinutes,
      workoutTime: _workoutTime,
      excludedMovementGroups: _excludedMoves.toList(),
      excludedAllergens: _excludedAllergens,
      availableFoodGroups: _foodGroups,
      sleepTime: _sleepTime,
      wakeTime: _wakeTime,
    );
    setState(() {
      _busy = true;
      _error = null;
      _pendingRequestId ??= controller.newRequestId();
    });
    try {
      final result = await controller.generate(
        context: data,
        intake: intake,
        requestId: _pendingRequestId!,
      );
      if (!mounted) return;
      setState(() {
        _preview = result;
        _step = 2;
        _busy = false;
        _pendingRequestId = null;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = _friendlyError(error);
      });
    }
  }

  String _friendlyError(Object error) {
    if (error is PersonalScheduleQuotaExceededException) {
      return PersonalScheduleQuotaExceededException.userMessage;
    }
    if (error is PersonalScheduleQuotaUnavailableException) {
      return PersonalScheduleQuotaUnavailableException.userMessage;
    }
    if (error is FitnessTrainingGuestQuotaExceededException) {
      return FitnessTrainingGuestQuotaExceededException.userMessage;
    }
    if (error is FitnessProgramValidationException) {
      return switch (error.code) {
        'adult_gate' => 'Chế độ luyện tập chỉ dành cho người từ 18 tuổi.',
        'no_safe_exercises' =>
          'Chưa có bài phù hợp với thiết bị và giới hạn vận động đã chọn.',
        'no_safe_meals' =>
          'Chưa có đủ món ăn phù hợp với nhóm thực phẩm và dị ứng đã chọn.',
        _ =>
          'AI chưa tạo được lịch hợp lệ. Chương trình hiện tại vẫn được giữ nguyên; bạn có thể thử lại.',
      };
    }
    return 'Kết nối đang bận hoặc phản hồi chưa phù hợp. Chương trình hiện tại vẫn được giữ nguyên; bạn có thể thử lại.';
  }

  Widget _errorCard(String message) => Card(
    color: Theme.of(context).colorScheme.errorContainer,
    child: Padding(padding: const EdgeInsets.all(12), child: Text(message)),
  );

  Widget _previewProgram(
    FitnessTrainingProgram program,
    FitnessTrainingLoadedContext data,
  ) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _sectionTitle(
        'Xem trước chương trình',
        'Tuần ${program.activeWeek} trong kế hoạch 4 tuần · Lịch khác chưa được thay đổi.',
      ),
      const SizedBox(height: 10),
      _programWeek(program.weekDays, data.catalog),
      const SizedBox(height: 8),
      const Text(
        'Khi xác nhận, các mục tập, ăn và ngủ tương lai chưa hoàn thành sẽ được thêm vào lịch. Lịch sử hoàn thành và mục sức khỏe khác được giữ nguyên.',
      ),
    ],
  );

  Widget _activeProgramCard(
    FitnessTrainingProgram program,
    FitnessTrainingLoadedContext data,
  ) => Card(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Chương trình đang áp dụng · Tuần ${program.activeWeek} / 4',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 6),
          Text(
            'Bắt đầu ${_formatDate(program.startDate)} · ${program.intake.venue == 'home' ? 'Tại nhà' : 'Phòng gym'}',
          ),
          const SizedBox(height: 10),
          for (final day in program.weekDays.take(7))
            _daySummary(day, data.catalog),
          if (program.activeWeek < 4 && _checkInDue(program)) ...[
            const SizedBox(height: 8),
            if (ref.read(fitnessTrainingControllerProvider).isGuest)
              const Text(
                'Lượt tạo của khách dùng cho một chương trình. Đăng nhập để tiếp tục tạo đề xuất điều chỉnh.',
              )
            else
              OutlinedButton.icon(
                onPressed: _busy ? null : () => _weeklyCheckIn(program, data),
                icon: const Icon(Icons.tune_rounded),
                label: const Text('Đánh giá tuần và đề xuất điều chỉnh'),
              ),
          ] else if (program.activeWeek < 4) ...[
            const SizedBox(height: 6),
            Text(
              'Bạn có thể đánh giá tuần này từ ${_formatDate(_weekEndDate(program))}.',
            ),
          ],
        ],
      ),
    ),
  );

  Widget _pendingPreviewCard(
    FitnessTrainingProgram program,
    FitnessTrainingLoadedContext data,
  ) => Card(
    child: Padding(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Có bản xem trước cần xác nhận · Tuần ${program.activeWeek}',
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: 6),
          OutlinedButton(
            onPressed: () => setState(() {
              _preview = program;
              _step = 2;
            }),
            child: const Text('Xem lại chương trình'),
          ),
        ],
      ),
    ),
  );

  Widget _programWeek(
    List<FitnessProgramDay> days,
    FitnessTrainingCatalog catalog,
  ) => Column(children: [for (final day in days) _daySummary(day, catalog)]);

  Widget _daySummary(
    FitnessProgramDay day,
    FitnessTrainingCatalog catalog,
  ) => Card(
    margin: const EdgeInsets.only(bottom: 8),
    child: ExpansionTile(
      title: Text(
        '${_weekdayLabel(day.date.weekday)} · ${_formatDate(day.date)}${day.isRestDay ? ' · Nghỉ tập' : ''}',
      ),
      subtitle: Text(
        '${day.exercises.length} bài tập · ${day.meals.length} bữa · Ngủ ${day.sleepTime}',
      ),
      childrenPadding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
      children: [
        for (final planned in day.exercises)
          if (catalog.exercisesById[planned.exerciseId] case final exercise?)
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: FitnessCatalogImage(
                catalog: catalog,
                illustration: exercise.illustration,
                width: 72,
                height: 56,
              ),
              title: Text(exercise.name),
              subtitle: Text(
                planned.durationMinutes != null
                    ? '${planned.durationMinutes} phút'
                    : '${planned.sets} hiệp × ${planned.reps} lần · nghỉ ${planned.restSeconds} giây',
              ),
              trailing: const Icon(Icons.info_outline_rounded),
              onTap: () => _showExerciseDetails(exercise, planned, catalog),
            ),
        for (final meal in _orderedMeals(day.meals))
          if (catalog.recipesById[meal.recipeId] case final recipe?)
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: FitnessCatalogImage(
                catalog: catalog,
                illustration: recipe.illustration,
                width: 72,
                height: 56,
              ),
              title: Text(recipe.name),
              subtitle: Text(
                '${_mealName(meal.mealSlot)} · ${meal.servings.toStringAsFixed(1)} khẩu phần',
              ),
            ),
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.bedtime_outlined),
          title: Text('Ngủ ${day.sleepTime} · Dậy ${day.wakeTime}'),
          subtitle: const Text(
            'Nhắc lịch nghỉ ngơi theo mục tiêu bạn đã chọn.',
          ),
        ),
      ],
    ),
  );

  List<FitnessProgramMeal> _orderedMeals(List<FitnessProgramMeal> meals) {
    final ranks = {
      for (var i = 0; i < FitnessProgramValidator.mealSlots.length; i++)
        FitnessProgramValidator.mealSlots[i]: i,
    };
    return [...meals]
      ..sort((a, b) => ranks[a.mealSlot]!.compareTo(ranks[b.mealSlot]!));
  }

  Future<void> _showExerciseDetails(
    FitnessExercise exercise,
    FitnessWorkoutExercise planned,
    FitnessTrainingCatalog catalog,
  ) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: FitnessCatalogImage(
                  catalog: catalog,
                  illustration: exercise.illustration,
                  width: 260,
                  height: 174,
                  borderRadius: 18,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                exercise.name,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 5),
              Text(
                planned.durationMinutes != null
                    ? '${planned.durationMinutes} phút'
                    : '${planned.sets} hiệp × ${planned.reps} lần · nghỉ ${planned.restSeconds} giây',
              ),
              const SizedBox(height: 12),
              Text(
                'Cách thực hiện',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              for (var i = 0; i < exercise.steps.length; i++)
                Padding(
                  padding: const EdgeInsets.only(top: 7),
                  child: Text('${i + 1}. ${exercise.steps[i]}'),
                ),
              if (exercise.safetyNotes.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text('Lưu ý', style: Theme.of(context).textTheme.titleMedium),
                Text(exercise.safetyNotes),
              ],
              const SizedBox(height: 14),
              if (exercise.hasApprovedVideo) ...[
                FitnessTrainingYoutubePlayer(videoId: exercise.videoId!),
                const SizedBox(height: 8),
              ] else
                const Text(
                  'Video minh họa chưa được duyệt nhúng. Bạn có thể xem hướng dẫn bằng hình và mở YouTube.',
                ),
              OutlinedButton.icon(
                onPressed: () => _openYoutube(exercise.name),
                icon: const Icon(Icons.open_in_new_rounded),
                label: const Text('Mở tìm kiếm bài tập trên YouTube'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _openYoutube(String query) async {
    final uri = Uri.https('www.youtube.com', '/results', {
      'search_query': query,
    });
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  Future<void> _confirmApply(
    FitnessTrainingProgram program,
    FitnessTrainingLoadedContext data,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Áp dụng tuần ${program.activeWeek}?'),
        content: const Text(
          'Các mục luyện tập, bữa ăn và giờ ngủ tương lai chưa hoàn thành sẽ được thay theo chương trình này.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Xem lại'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Xác nhận'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref
          .read(fitnessTrainingControllerProvider)
          .apply(context: data, program: program, week: program.activeWeek);
      if (!mounted) return;
      setState(() {
        _busy = false;
        _preview = null;
        _step = 0;
        _loadFuture = ref.read(fitnessTrainingControllerProvider).load();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã áp dụng lịch luyện tập của bạn.')),
      );
    } catch (_) {
      if (mounted) {
        setState(() {
          _busy = false;
          _error =
              'Chưa áp dụng được lịch. Chương trình xem trước vẫn còn nguyên.';
        });
      }
    }
  }

  Future<void> _weeklyCheckIn(
    FitnessTrainingProgram active,
    FitnessTrainingLoadedContext data,
  ) async {
    var effort = 3;
    var soreness = 2;
    final answers = await showDialog<(int, int)>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text('Đánh giá tuần ${active.activeWeek}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Mức độ nặng của tuần vừa rồi?'),
              Slider(
                value: effort.toDouble(),
                min: 1,
                max: 5,
                divisions: 4,
                label: '$effort',
                onChanged: (value) =>
                    setDialogState(() => effort = value.round()),
              ),
              const Text('Mức độ ê mỏi bạn cảm nhận?'),
              Slider(
                value: soreness.toDouble(),
                min: 1,
                max: 5,
                divisions: 4,
                label: '$soreness',
                onChanged: (value) =>
                    setDialogState(() => soreness = value.round()),
              ),
              const Text(
                'Chỉ gửi điểm đánh giá cho AI điều chỉnh; không gửi ghi chú.',
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Để sau'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, (effort, soreness)),
              child: const Text('Tạo đề xuất'),
            ),
          ],
        ),
      ),
    );
    if (answers == null || !mounted) return;
    final controller = ref.read(fitnessTrainingControllerProvider);
    final checkIn = FitnessWeeklyCheckIn(
      week: active.activeWeek,
      effortScore: answers.$1,
      sorenessScore: answers.$2,
      note: '',
      createdAt: DateTime.now().toUtc(),
    );
    final intake = _intakeFromProgram(active);
    setState(() {
      _busy = true;
      _error = null;
      _pendingRequestId ??= controller.newRequestId();
    });
    try {
      final preview = await controller.replan(
        context: data,
        activeProgram: active,
        intake: intake,
        checkIn: checkIn,
        requestId: _pendingRequestId!,
      );
      if (!mounted) return;
      setState(() {
        _busy = false;
        _preview = preview;
        _step = 2;
        _pendingRequestId = null;
      });
    } catch (error) {
      if (mounted) {
        setState(() {
          _busy = false;
          _error = _friendlyError(error);
        });
      }
    }
  }

  FitnessTrainingIntake _intakeFromProgram(FitnessTrainingProgram program) =>
      FitnessTrainingIntake.fromJson(program.intake.toJson());

  bool _checkInDue(FitnessTrainingProgram program) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return !today.isBefore(_weekEndDate(program));
  }

  DateTime _weekEndDate(FitnessTrainingProgram program) => DateTime(
    program.startDate.year,
    program.startDate.month,
    program.startDate.day,
  ).add(Duration(days: program.activeWeek * 7 - 1));

  String _mealName(String slot) => switch (slot) {
    'breakfast' => 'Bữa sáng',
    'morning_snack' => 'Bữa phụ sáng',
    'lunch' => 'Bữa trưa',
    'afternoon_snack' => 'Bữa phụ chiều',
    _ => 'Bữa tối',
  };

  String _weekdayLabel(int day) => switch (day) {
    1 => 'T2',
    2 => 'T3',
    3 => 'T4',
    4 => 'T5',
    5 => 'T6',
    6 => 'T7',
    _ => 'CN',
  };

  String _formatDate(DateTime value) =>
      '${value.day.toString().padLeft(2, '0')}/${value.month.toString().padLeft(2, '0')}/${value.year}';

  String _displayNumber(double? value) =>
      value == null ? '—' : value.toStringAsFixed(1);

  bool get _supportedPlatform =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);
}
