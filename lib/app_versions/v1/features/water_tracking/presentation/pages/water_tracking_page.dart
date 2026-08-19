import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:nano_app/app_versions/v1/features/features_hub/presentation/widgets/nami_care_page.dart';
import 'package:nano_app/app_versions/v1/features/water_tracking/data/water_tracking_local_store.dart';
import 'package:nano_app/app_versions/v2/features/auth/providers/auth_providers.dart';
import 'package:nano_app/core/theme/theme.dart';

class WaterTrackingPage extends ConsumerStatefulWidget {
  const WaterTrackingPage({
    super.key,
    this.localStore = const SharedPreferencesWaterTrackingLocalStore(),
    DateTime Function()? now,
  }) : now = now ?? DateTime.now;

  final WaterTrackingLocalStore localStore;
  final DateTime Function() now;

  @override
  ConsumerState<WaterTrackingPage> createState() => _WaterTrackingPageState();
}

class _WaterTrackingPageState extends ConsumerState<WaterTrackingPage> {
  int? _targetMl;
  int _currentMl = 0;
  bool _isLoading = true;
  bool _isSaving = false;
  Object? _loadError;
  DateTime? _loadedLocalDay;
  late String _stateActorScope;
  int _loadGeneration = 0;

  @override
  void initState() {
    super.initState();
    _stateActorScope = _actorScope(ref.read(currentAuthUserIdProvider));
    _load(actorScope: _stateActorScope);
  }

  Future<void> _load({String? actorScope}) async {
    final requestedActorScope =
        actorScope ?? _actorScope(ref.read(currentAuthUserIdProvider));
    final loadGeneration = ++_loadGeneration;
    if (mounted) {
      setState(() {
        _stateActorScope = requestedActorScope;
        _targetMl = null;
        _currentMl = 0;
        _loadedLocalDay = null;
        _isLoading = true;
        _isSaving = false;
        _loadError = null;
      });
    }
    try {
      final localDay = widget.now();
      final snapshot = await widget.localStore.load(localDay);
      if (!_canApply(loadGeneration, requestedActorScope)) return;
      setState(() {
        _targetMl = snapshot.targetMl;
        _currentMl = snapshot.amountMl;
        _loadedLocalDay = localDay;
        _isLoading = false;
      });
    } catch (error) {
      if (!_canApply(loadGeneration, requestedActorScope)) return;
      setState(() {
        _loadError = error;
        _isLoading = false;
      });
    }
  }

  Future<void> _chooseTarget() async {
    final actorScope = _actorScope(ref.read(currentAuthUserIdProvider));
    if (actorScope != _stateActorScope || _isLoading) {
      await _load(actorScope: actorScope);
      if (!mounted || actorScope != _stateActorScope || _isLoading) return;
    }
    final target = await showModalBottomSheet<int>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) => _WaterTargetSheet(initialValue: _targetMl),
    );
    if (target == null || !mounted || !_isCurrentActor(actorScope)) return;

    setState(() => _isSaving = true);
    try {
      await widget.localStore.saveTargetMl(target);
      if (!mounted || !_isCurrentActor(actorScope)) return;
      setState(() {
        _targetMl = target;
        _isSaving = false;
      });
      AppFeedbackService.instance.emit(AppFeedbackType.selection);
    } catch (_) {
      if (!mounted || !_isCurrentActor(actorScope)) return;
      setState(() => _isSaving = false);
      _showSaveError();
    }
  }

  Future<void> _addWater(int amount) async {
    if (_isSaving) return;
    final actorScope = _actorScope(ref.read(currentAuthUserIdProvider));
    if (actorScope != _stateActorScope || _isLoading) {
      await _load(actorScope: actorScope);
      if (!mounted || actorScope != _stateActorScope || _isLoading) return;
    }
    final localDay = widget.now();
    setState(() => _isSaving = true);
    try {
      var target = _targetMl;
      var previous = _currentMl;
      if (!_isSameLocalDay(_loadedLocalDay, localDay)) {
        final snapshot = await widget.localStore.load(localDay);
        if (!mounted || !_isCurrentActor(actorScope)) return;
        target = snapshot.targetMl;
        previous = snapshot.amountMl;
      }
      final next = (previous + amount).clamp(0, 100000);
      await widget.localStore.saveAmountMl(localDay, next);
      if (!mounted || !_isCurrentActor(actorScope)) return;
      setState(() {
        _targetMl = target;
        _currentMl = next;
        _loadedLocalDay = localDay;
        _isSaving = false;
      });
      if (target != null && previous < target && next >= target) {
        AppFeedbackService.instance.emit(AppFeedbackType.milestone);
      } else {
        AppFeedbackService.instance.emit(AppFeedbackType.selection);
      }
    } catch (_) {
      if (!mounted || !_isCurrentActor(actorScope)) return;
      setState(() => _isSaving = false);
      _showSaveError();
    }
  }

  bool _canApply(int loadGeneration, String actorScope) =>
      mounted &&
      loadGeneration == _loadGeneration &&
      _isCurrentActor(actorScope);

  bool _isCurrentActor(String actorScope) =>
      actorScope == _stateActorScope &&
      actorScope == _actorScope(ref.read(currentAuthUserIdProvider));

  static String _actorScope(String? userId) {
    final normalizedUserId = userId?.trim();
    return normalizedUserId == null || normalizedUserId.isEmpty
        ? 'guest:install'
        : 'member:$normalizedUserId';
  }

  static bool _isSameLocalDay(DateTime? first, DateTime second) =>
      first != null &&
      first.year == second.year &&
      first.month == second.month &&
      first.day == second.day;

  void _showSaveError() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Chưa thể lưu ghi nhận. Bạn thử lại nhé.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentActorScope = _actorScope(ref.watch(currentAuthUserIdProvider));
    ref.listen<String?>(currentAuthUserIdProvider, (previous, next) {
      final nextActorScope = _actorScope(next);
      if (nextActorScope != _stateActorScope) {
        _load(actorScope: nextActorScope);
      }
    });

    return NamiCareScaffold(
      title: 'Uống nước hôm nay',
      subtitle: 'Từng ngụm nhỏ cũng là cách bạn chăm cơ thể rồi.',
      badge: 'Nhẹ nhàng từng chút',
      icon: Icons.water_drop_rounded,
      gradient: AppGradients.info,
      children: _buildContent(
        hideStaleActorState: currentActorScope != _stateActorScope,
      ),
    );
  }

  List<Widget> _buildContent({bool hideStaleActorState = false}) {
    final colors = context.semanticColors;
    if (hideStaleActorState || _isLoading) {
      return const [
        NamiCareSurfaceCard(
          child: Center(
            child: Padding(
              padding: EdgeInsets.all(AppSpacing.lg),
              child: CircularProgressIndicator(),
            ),
          ),
        ),
      ];
    }

    if (_loadError != null) {
      return [
        const NamiCareEmptyState(
          icon: Icons.sync_problem_rounded,
          color: AppColors.error,
          title: 'Chưa mở được ghi nhận hôm nay',
          message:
              'Thông tin của bạn vẫn được giữ trên thiết bị. Hãy thử tải lại màn này.',
        ),
        const SizedBox(height: AppSpacing.md),
        FilledButton.icon(
          onPressed: _load,
          icon: const Icon(Icons.refresh_rounded),
          label: const Text('Thử lại'),
        ),
      ];
    }

    final target = _targetMl;
    final progress = target == null
        ? null
        : (_currentMl / target).clamp(0.0, 1.0).toDouble();

    return [
      NamiCareSurfaceCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Hôm nay mình đã uống',
              style: AppTextStyles.bodyMedium.copyWith(
                color: colors.textSecondary,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            AppStateSwitcher(
              alignment: Alignment.centerLeft,
              child: Text(
                '$_currentMl ml',
                key: ValueKey('water-$_currentMl'),
                style: AppTextStyles.displaySmall.copyWith(
                  color: colors.info,
                  fontWeight: AppTypography.bold,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            if (progress != null) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(AppRadius.circular),
                child: TweenAnimationBuilder<double>(
                  tween: Tween<double>(end: progress),
                  duration: AppMotionScope.duration(
                    context,
                    AppDuration.progress,
                  ),
                  curve: AppAnimations.emphasizedCurve,
                  builder: (context, value, _) => LinearProgressIndicator(
                    value: value,
                    minHeight: 10,
                    backgroundColor: colors.info.withValues(alpha: .1),
                    valueColor: AlwaysStoppedAnimation<Color>(colors.info),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
            ],
            Row(
              children: [
                Expanded(
                  child: Text(
                    target == null
                        ? 'Bạn chưa chọn mục tiêu.'
                        : 'Mục tiêu bạn đã chọn: $target ml',
                    key: const Key('water-target-label'),
                    style: AppTextStyles.caption.copyWith(
                      color: colors.textSecondary,
                      fontWeight: AppTypography.medium,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                TextButton(
                  key: const Key('water-goal-button'),
                  onPressed: _isSaving ? null : _chooseTarget,
                  child: Text(target == null ? 'Chọn mục tiêu' : 'Thay đổi'),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Mục tiêu này do bạn tự chọn, không phải khuyến nghị y tế.',
              style: AppTextStyles.caption.copyWith(
                color: colors.textSecondary,
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: AppSpacing.sectionSpacing),
      const NamiCareSectionTitle(
        title: 'Thêm một ly nhỏ',
        subtitle:
            'Chọn nhanh lượng nước vừa uống. Ghi nhận hôm nay được lưu trên thiết bị.',
      ),
      const SizedBox(height: AppSpacing.md),
      IgnorePointer(
        ignoring: _isSaving,
        child: Opacity(
          opacity: _isSaving ? .56 : 1,
          child: Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              NamiCareActionChip(
                key: const Key('water-add-100'),
                label: '+100 ml',
                icon: Icons.add_rounded,
                color: AppColors.info,
                onTap: () => _addWater(100),
              ),
              NamiCareActionChip(
                key: const Key('water-add-250'),
                label: '+250 ml',
                icon: Icons.add_rounded,
                color: AppColors.info,
                onTap: () => _addWater(250),
              ),
              NamiCareActionChip(
                key: const Key('water-add-500'),
                label: '+500 ml',
                icon: Icons.add_rounded,
                color: AppColors.info,
                onTap: () => _addWater(500),
              ),
            ],
          ),
        ),
      ),
      const SizedBox(height: AppSpacing.sectionSpacing),
      AppStateSwitcher(
        child: NamiCareEmptyState(
          key: ValueKey(
            'water-message-${_currentMl == 0
                ? 'empty'
                : target != null && _currentMl >= target
                ? 'goal'
                : 'progress'}',
          ),
          icon: Icons.notifications_active_rounded,
          color: AppColors.info,
          title: 'Nabi nhắc mình uống nước',
          message: _currentMl == 0
              ? 'Nabi chưa ghi nhận ly nước nào hôm nay. Mình bắt đầu bằng một ngụm nhỏ nhé.'
              : target != null && _currentMl >= target
              ? 'Bạn đã chạm mục tiêu do mình chọn hôm nay.'
              : 'Ghi nhận hôm nay đã được lưu trên thiết bị.',
        ),
      ),
    ];
  }
}

class _WaterTargetSheet extends StatefulWidget {
  const _WaterTargetSheet({required this.initialValue});

  final int? initialValue;

  @override
  State<_WaterTargetSheet> createState() => _WaterTargetSheetState();
}

class _WaterTargetSheetState extends State<_WaterTargetSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
      text: widget.initialValue?.toString() ?? '',
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.semanticColors;
    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.lg,
        AppSpacing.md,
        MediaQuery.viewInsetsOf(context).bottom + AppSpacing.lg,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Mục tiêu uống nước', style: AppTextStyles.heading3),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Nhập giá trị phù hợp với bạn. NanoBio không tự đưa ra mục tiêu hay khuyến nghị y tế.',
              style: AppTextStyles.bodySmall.copyWith(
                color: colors.textSecondary,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            TextFormField(
              key: const Key('water-target-field'),
              controller: _controller,
              autofocus: true,
              keyboardType: TextInputType.number,
              textInputAction: TextInputAction.done,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: const InputDecoration(
                labelText: 'Mục tiêu do bạn chọn',
                suffixText: 'ml',
              ),
              validator: (value) {
                final amount = int.tryParse(value ?? '');
                if (amount == null || amount <= 0) {
                  return 'Nhập một giá trị lớn hơn 0.';
                }
                if (amount > 100000) {
                  return 'Giá trị quá lớn. Hãy nhập dưới 100000 ml.';
                }
                return null;
              },
              onFieldSubmitted: (_) => _submit(),
            ),
            const SizedBox(height: AppSpacing.lg),
            FilledButton(
              key: const Key('water-save-target'),
              onPressed: _submit,
              child: const Text('Lưu mục tiêu'),
            ),
          ],
        ),
      ),
    );
  }

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    Navigator.of(context).pop(int.parse(_controller.text));
  }
}
