import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nano_app/app_versions/v1/features/body_metrics/domain/entities/basic_health_calculator_models.dart';
import 'package:nano_app/app_versions/v1/services/ai/personal_schedule_quota_gateway.dart';
import 'package:nano_app/core/theme/theme.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../application/fitness_training_controller.dart';
import '../../domain/entities/fitness_training_catalog.dart';
import '../../domain/entities/fitness_schedule_conflict.dart';
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
  static const _workoutTimes = fitnessWorkoutTimeOptions;

  late Future<FitnessTrainingLoadedContext> _loadFuture;
  int _step = 0;
  bool _profileReviewed = false;
  bool _aiConsent = false;
  bool _busy = false;
  String? _error;
  String? _pendingRequestId;
  FitnessTrainingProgram? _preview;
  bool _filtersSeeded = false;
  FitnessTrainingProgram? _replanProgram;
  FitnessWeeklyCheckIn? _replanCheckIn;

  String _goal = 'general_fitness';
  String _experience = 'beginner';
  String _venue = 'gym';
  final Set<String> _equipmentIds = {};
  final Set<int> _weekdays = {1, 3, 5};
  final Set<String> _excludedMoves = {};
  int _sessionMinutes = 45;
  String _workoutTime = '17:30';

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
  Widget build(BuildContext context) => MedicalPageScaffold(
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
                    if (RegExp(
                      r'^\d{2}:\d{2}$',
                    ).hasMatch(data.profile.workoutTime)) {
                      _workoutTime = data.profile.workoutTime;
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
              'Bản thử nghiệm: nội dung bài tập và minh họa đang chờ rà soát chuyên môn. Đây là gợi ý wellness, không thay thế tư vấn y tế hoặc huấn luyện viên.',
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
            'Chiều cao / cân nặng',
            '${_displayNumber(profile.heightCm)} cm / ${_displayNumber(profile.weightKg)} kg',
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
                  borderRadius: BorderRadius.circular(AppRadius.control),
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
          Text('Lịch tập', style: Theme.of(context).textTheme.titleMedium),
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
          _timeDropdown('Giờ tập', _workoutTime, _workoutTimes, (v) {
            setState(() {
              _workoutTime = v;
              _error = null;
            });
          }),
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

  Widget _aiConsentTile(BasicHealthReport? metrics) => Card(
    child: CheckboxListTile(
      value: _aiConsent,
      onChanged: (value) => setState(() => _aiConsent = value ?? false),
      controlAffinity: ListTileControlAffinity.leading,
      title: const Text('Đồng ý tạo gợi ý bằng AI'),
      subtitle: Text(
        'Gemini nhận mục tiêu, nơi tập, thiết bị, lịch tập và giới hạn vận động đã chọn${metrics == null ? '' : ', cùng BMI/BMR/TDEE tham khảo'}. Không gửi ngày sinh, tên, ghi chú hồ sơ, dị ứng, thực đơn hoặc giờ ngủ.',
      ),
    ),
  );

  bool _canGenerate(FitnessTrainingLoadedContext data, bool adult) {
    if (_busy || !adult || !_aiConsent || _weekdays.isEmpty) {
      return false;
    }
    if (_venue == 'gym' && _equipmentIds.isEmpty) return false;
    final exercises = data.catalog.eligibleExercises(
      venue: _venue,
      equipmentIds: _equipmentIds,
      excludedMovementGroups: _excludedMoves,
    );
    return exercises.isNotEmpty;
  }

  Future<void> _generate(
    FitnessTrainingLoadedContext data, {
    String? workoutTimeOverride,
  }) async {
    final controller = ref.read(fitnessTrainingControllerProvider);
    final intake = controller.makeIntake(
      profile: data.profile,
      goal: _goal,
      experience: _experience,
      venue: _venue,
      equipmentIds: _equipmentIds,
      trainingWeekdays: _weekdays.toList(),
      sessionMinutes: _sessionMinutes,
      workoutTime: workoutTimeOverride ?? _workoutTime,
      excludedMovementGroups: _excludedMoves.toList(),
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
      if (error is FitnessWorkoutTimeResolutionRequired) {
        setState(() => _busy = false);
        if (error.resolution.suggestedTime == null) {
          setState(
            () => _error = _noAvailableWorkoutTimeMessage(error.resolution),
          );
          return;
        }
        final acceptedTime = await _confirmWorkoutTimeChange(error.resolution);
        if (!mounted) return;
        if (acceptedTime != null) {
          setState(() => _workoutTime = acceptedTime);
          await _generate(data, workoutTimeOverride: acceptedTime);
          return;
        }
        setState(
          () => _error = _conflictMessage(
            FitnessScheduleConflictException(error.resolution.conflicts),
          ),
        );
        return;
      }
      setState(() {
        _busy = false;
        _error = _friendlyError(error);
      });
    }
  }

  String _friendlyError(Object error) {
    if (error is FitnessWorkoutTimeResolutionRequired) {
      return _noAvailableWorkoutTimeMessage(error.resolution);
    }
    if (error is FitnessScheduleConflictException) {
      return _conflictMessage(error);
    }
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
        'workout_time' => 'Giờ tập chưa hợp lệ. Hãy chọn giờ khác.',
        _ =>
          'AI chưa tạo được lịch hợp lệ. Chương trình hiện tại vẫn được giữ nguyên; bạn có thể thử lại.',
      };
    }
    return 'Kết nối đang bận hoặc phản hồi chưa phù hợp. Chương trình hiện tại vẫn được giữ nguyên; bạn có thể thử lại.';
  }

  String _noAvailableWorkoutTimeMessage(
    FitnessWorkoutTimeResolution resolution,
  ) =>
      'Chưa tìm thấy giờ trống trong các khung giờ gợi ý. Hãy điều chỉnh ngày '
      'tập, thời lượng hoặc giờ tập rồi thử lại.\n'
      '${_conflictMessage(FitnessScheduleConflictException(resolution.conflicts))}';

  Future<String?> _confirmWorkoutTimeChange(
    FitnessWorkoutTimeResolution resolution,
  ) {
    final suggestedTime = resolution.suggestedTime;
    if (suggestedTime == null) return Future.value(null);
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Giờ tập đang bị trùng'),
        content: Text(
          'Giờ ${resolution.requestedTime} có '
          '${resolution.conflicts.length} xung đột lịch trong tuần sắp áp dụng. '
          'Cho phép đổi giờ tập của chương trình M32 này sang $suggestedTime? '
          'Chỉ giờ tập của chương trình này thay đổi; hồ sơ cá nhân và lịch '
          'hiện có được giữ nguyên.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Giữ giờ đã chọn'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, suggestedTime),
            child: const Text('Đồng ý đổi giờ'),
          ),
        ],
      ),
    );
  }

  String _conflictMessage(FitnessScheduleConflictException error) {
    final lines = error.conflicts
        .take(3)
        .map((conflict) {
          final workout =
              '${_formatTime(conflict.workoutStartAt)}–'
              '${_formatTime(conflict.workoutEndAt)}';
          final itemStartsOnDifferentDay =
              conflict.itemStartAt.year != conflict.workoutStartAt.year ||
              conflict.itemStartAt.month != conflict.workoutStartAt.month ||
              conflict.itemStartAt.day != conflict.workoutStartAt.day;
          final itemStartDate = itemStartsOnDifferentDay
              ? '${_formatDate(conflict.itemStartAt)} '
              : '';
          final itemEndsOnDifferentDay =
              conflict.itemEndAt != null &&
              (conflict.itemEndAt!.year != conflict.itemStartAt.year ||
                  conflict.itemEndAt!.month != conflict.itemStartAt.month ||
                  conflict.itemEndAt!.day != conflict.itemStartAt.day);
          final itemEndDate = itemEndsOnDifferentDay
              ? '${_formatDate(conflict.itemEndAt!)} '
              : '';
          final existing = conflict.itemEndAt == null
              ? '$itemStartDate${_formatTime(conflict.itemStartAt)}'
              : '$itemStartDate${_formatTime(conflict.itemStartAt)}–'
                    '$itemEndDate${_formatTime(conflict.itemEndAt!)}';
          return '• ${_formatDate(conflict.workoutStartAt)} $workout trùng với '
              '${conflict.itemTitle} ($existing).';
        })
        .join('\n');
    final extra = error.conflicts.length > 3
        ? '\nCòn ${error.conflicts.length - 3} xung đột khác.'
        : '';
    return 'Giờ tập bị trùng với lịch hiện có. Hãy chọn giờ khác; lịch cũ sẽ được giữ nguyên.\n$lines$extra';
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
        'Tuần ${program.activeWeek} trong kế hoạch 4 tuần · Giờ tập $_workoutTime · Lịch khác chưa được thay đổi.',
      ),
      const SizedBox(height: 10),
      _timeDropdown('Giờ tập áp dụng', _workoutTime, _workoutTimes, (value) {
        setState(() {
          _workoutTime = value;
          _error = null;
        });
      }),
      const SizedBox(height: 10),
      _programWeek(program.weekDays, data.catalog),
      const SizedBox(height: 8),
      const Text(
        'Khi xác nhận, chỉ các buổi tập M32 tương lai chưa hoàn thành được thay. Mục ăn, ngủ, sức khỏe, lịch đã hoàn thành và lịch quá khứ được giữ nguyên.',
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
          if (_replanProgram?.id == program.id && _replanCheckIn != null) ...[
            const SizedBox(height: 8),
            if (_error != null) _errorCard(_error!),
            _timeDropdown('Giờ tập đề xuất mới', _workoutTime, _workoutTimes, (
              value,
            ) {
              setState(() {
                _workoutTime = value;
                _error = null;
              });
            }),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: _busy ? null : () => _retryReplan(data),
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Kiểm tra giờ mới và thử lại'),
            ),
          ],
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
              _workoutTime = program.intake.workoutTime;
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
      subtitle: Text('${day.exercises.length} bài tập'),
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
      ],
    ),
  );

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
          'Chỉ các buổi tập M32 tương lai chưa hoàn thành được thay. Mục ăn, ngủ và các lịch khác được giữ nguyên. Nếu giờ tập trùng lịch, bản xem trước vẫn được giữ để bạn chọn giờ khác.',
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
          .apply(
            context: data,
            program: program,
            week: program.activeWeek,
            workoutTimeOverride: _workoutTime == program.intake.workoutTime
                ? null
                : _workoutTime,
          );
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
    } catch (error) {
      if (!mounted) return;
      if (error is FitnessScheduleConflictException) {
        try {
          final resolution = await ref
              .read(fitnessTrainingControllerProvider)
              .resolveWorkoutTimeForProgramWeek(
                context: data,
                program: program,
                week: program.activeWeek,
                requestedTime: _workoutTime,
              );
          if (!mounted) return;
          if (resolution.suggestedTime != null) {
            setState(() => _busy = false);
            final acceptedTime = await _confirmWorkoutTimeChange(resolution);
            if (!mounted) return;
            if (acceptedTime != null) {
              setState(() {
                _workoutTime = acceptedTime;
                _error =
                    'Đã đổi giờ trong bản xem trước. Hãy xác nhận lại để áp dụng; lịch hiện có vẫn được giữ nguyên.';
              });
              return;
            }
            setState(() {
              _busy = false;
              _error = _conflictMessage(
                FitnessScheduleConflictException(resolution.conflicts),
              );
            });
            return;
          }
          setState(() {
            _busy = false;
            _error = resolution.hasConflicts
                ? _noAvailableWorkoutTimeMessage(resolution)
                : 'Lịch đã thay đổi. Hãy xác nhận áp dụng lại; bản xem trước vẫn được giữ nguyên.';
          });
          return;
        } catch (resolutionError) {
          if (!mounted) return;
          setState(() {
            _busy = false;
            _error = _friendlyError(resolutionError);
          });
          return;
        }
      }
      setState(() {
        _busy = false;
        _error =
            'Chưa áp dụng được lịch. Chương trình xem trước vẫn còn nguyên.';
      });
    }
  }

  Future<void> _weeklyCheckIn(
    FitnessTrainingProgram active,
    FitnessTrainingLoadedContext data,
  ) async {
    var effort = 3;
    var soreness = 2;
    var workoutTime = active.intake.workoutTime;
    final answers = await showDialog<(int, int, String)>(
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
              _timeDropdown('Giờ tập', workoutTime, _workoutTimes, (value) {
                setDialogState(() => workoutTime = value);
              }),
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
              onPressed: () =>
                  Navigator.pop(context, (effort, soreness, workoutTime)),
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
    final intake = _intakeFromProgram(active).copyWith(workoutTime: answers.$3);
    setState(() {
      _busy = true;
      _error = null;
      _workoutTime = answers.$3;
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
        _replanProgram = null;
        _replanCheckIn = null;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _replanProgram = active;
        _replanCheckIn = checkIn;
        _error = _friendlyError(error);
      });
      if (error is FitnessWorkoutTimeResolutionRequired &&
          error.resolution.suggestedTime != null) {
        final acceptedTime = await _confirmWorkoutTimeChange(error.resolution);
        if (!mounted) return;
        if (acceptedTime != null) {
          setState(() => _workoutTime = acceptedTime);
          await _retryReplan(data);
        } else {
          setState(
            () => _error = _conflictMessage(
              FitnessScheduleConflictException(error.resolution.conflicts),
            ),
          );
        }
      } else if (error is FitnessWorkoutTimeResolutionRequired) {
        setState(
          () => _error = _noAvailableWorkoutTimeMessage(error.resolution),
        );
      }
    }
  }

  Future<void> _retryReplan(FitnessTrainingLoadedContext data) async {
    final active = _replanProgram;
    final checkIn = _replanCheckIn;
    final requestId = _pendingRequestId;
    if (active == null || checkIn == null || requestId == null) return;
    final controller = ref.read(fitnessTrainingControllerProvider);
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final preview = await controller.replan(
        context: data,
        activeProgram: active,
        intake: _intakeFromProgram(active).copyWith(workoutTime: _workoutTime),
        checkIn: checkIn,
        requestId: requestId,
      );
      if (!mounted) return;
      setState(() {
        _busy = false;
        _preview = preview;
        _step = 2;
        _pendingRequestId = null;
        _replanProgram = null;
        _replanCheckIn = null;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = _friendlyError(error);
      });
      if (error is FitnessWorkoutTimeResolutionRequired &&
          error.resolution.suggestedTime != null) {
        final acceptedTime = await _confirmWorkoutTimeChange(error.resolution);
        if (!mounted) return;
        if (acceptedTime != null) {
          setState(() => _workoutTime = acceptedTime);
          await _retryReplan(data);
        } else {
          setState(
            () => _error = _conflictMessage(
              FitnessScheduleConflictException(error.resolution.conflicts),
            ),
          );
        }
      } else if (error is FitnessWorkoutTimeResolutionRequired) {
        setState(
          () => _error = _noAvailableWorkoutTimeMessage(error.resolution),
        );
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

  String _formatTime(DateTime value) =>
      '${value.hour.toString().padLeft(2, '0')}:${value.minute.toString().padLeft(2, '0')}';

  String _displayNumber(double? value) =>
      value == null ? '—' : value.toStringAsFixed(1);

  bool get _supportedPlatform =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);
}
