import 'dart:async';

import 'package:flutter/material.dart';
import 'package:nano_app/app_versions/v1/features/features_hub/presentation/widgets/nami_care_page.dart';
import 'package:nano_app/core/theme/theme.dart';

class QuickCarePage extends StatefulWidget {
  const QuickCarePage({super.key});

  @override
  State<QuickCarePage> createState() => _QuickCarePageState();
}

class _QuickCarePageState extends State<QuickCarePage> {
  static const _actions = <_QuickCareAction>[
    _QuickCareAction(
      icon: Icons.air_rounded,
      color: AppColors.secondary,
      title: 'Thở chậm 1 phút',
      subtitle: 'Hít vào thật nhẹ, thở ra chậm hơn một chút.',
      duration: Duration(minutes: 1),
    ),
    _QuickCareAction(
      icon: Icons.water_drop_rounded,
      color: AppColors.info,
      title: 'Uống một cốc nước',
      subtitle: 'Uống chậm từng ngụm và để cơ thể có một khoảng nghỉ ngắn.',
      duration: Duration(minutes: 1),
    ),
    _QuickCareAction(
      icon: Icons.accessibility_new_rounded,
      color: AppColors.success,
      title: 'Giãn vai',
      subtitle: 'Thả lỏng cổ và vai sau một lúc tập trung.',
      duration: Duration(minutes: 2),
    ),
    _QuickCareAction(
      icon: Icons.visibility_rounded,
      color: AppColors.primary,
      title: 'Nghỉ mắt 30 giây',
      subtitle: 'Nhìn ra xa một chút để mắt được nghỉ.',
      duration: Duration(seconds: 30),
    ),
    _QuickCareAction(
      icon: Icons.edit_note_rounded,
      color: AppColors.warning,
      title: 'Viết ra điều đang bận tâm',
      subtitle: 'Đặt suy nghĩ xuống giấy để lòng nhẹ hơn.',
      duration: Duration(minutes: 3),
    ),
  ];

  int? _selectedIndex;
  Timer? _timer;
  Duration _remaining = Duration.zero;
  bool _running = false;
  bool _completed = false;

  _QuickCareAction? get _selectedAction =>
      _selectedIndex == null ? null : _actions[_selectedIndex!];

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final selected = _selectedAction;
    return NamiCareScaffold(
      title: 'Chăm mình 5 phút',
      subtitle: 'Một khoảng nghỉ nhỏ cũng có thể làm bạn dễ chịu hơn.',
      badge: 'Dễ chịu ngay lúc này',
      icon: Icons.spa_rounded,
      gradient: AppGradients.meditation,
      children: [
        NamiCareEmptyState(
          icon: _completed ? Icons.check_circle_rounded : Icons.favorite_rounded,
          color: _completed ? AppColors.success : AppColors.secondary,
          title: _completed
              ? 'Bạn vừa dành một khoảng nghỉ cho mình'
              : 'Mình dành vài phút cho bản thân nhé',
          message: _completed
              ? 'Bài chăm sóc ngắn đã kết thúc. Kết quả này chỉ là một khoảng nghỉ tại chỗ và không thay đổi lịch sức khỏe của bạn.'
              : 'Chọn một gợi ý, sau đó bấm Bắt đầu. Bạn có thể dừng bất cứ lúc nào.',
        ),
        const SizedBox(height: AppSpacing.sectionSpacing),
        const NamiCareSectionTitle(
          title: 'Gợi ý nhanh từ Nabi',
          subtitle: 'Chọn một việc nhỏ phù hợp với bạn lúc này.',
        ),
        const SizedBox(height: AppSpacing.md),
        ...List.generate(_actions.length, (index) {
          final action = _actions[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: NamiCareInfoTile(
              icon: action.icon,
              color: action.color,
              title: action.title,
              subtitle: action.subtitle,
              trailing: _formatDuration(action.duration),
              selected: _selectedIndex == index,
              onTap: _running ? null : () => _select(index),
            ),
          );
        }),
        if (selected != null) ...[
          const SizedBox(height: AppSpacing.md),
          NamiCareSurfaceCard(
            borderColor: selected.color.withValues(alpha: .22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  _running ? 'Đang thực hiện' : 'Sẵn sàng bắt đầu',
                  style: AppTextStyles.labelLarge,
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  selected.title,
                  style: AppTextStyles.heading4,
                ),
                const SizedBox(height: AppSpacing.sm),
                if (_running) ...[
                  LinearProgressIndicator(
                    value: _progressFor(selected),
                    minHeight: 7,
                    borderRadius: BorderRadius.circular(AppRadius.circular),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    'Còn ${_formatClock(_remaining)}',
                    style: AppTextStyles.bodyMedium,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  OutlinedButton.icon(
                    onPressed: _stop,
                    icon: const Icon(Icons.stop_circle_outlined),
                    label: const Text('Dừng bài'),
                  ),
                ] else
                  FilledButton.icon(
                    onPressed: _start,
                    icon: const Icon(Icons.play_arrow_rounded),
                    label: Text('Bắt đầu · ${_formatDuration(selected.duration)}'),
                  ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  void _select(int index) {
    _timer?.cancel();
    setState(() {
      _selectedIndex = index;
      _remaining = _actions[index].duration;
      _running = false;
      _completed = false;
    });
  }

  void _start() {
    final action = _selectedAction;
    if (action == null || _running) return;

    AppFeedbackService.instance.emit(AppFeedbackType.primaryAction);
    _timer?.cancel();
    setState(() {
      _remaining = action.duration;
      _running = true;
      _completed = false;
    });
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      final next = _remaining - const Duration(seconds: 1);
      if (next <= Duration.zero) {
        timer.cancel();
        setState(() {
          _remaining = Duration.zero;
          _running = false;
          _completed = true;
        });
        AppFeedbackService.instance.emit(AppFeedbackType.success);
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            const SnackBar(
              content: Text('Xong rồi. Bạn có thể quay lại khi cần nghỉ thêm.'),
            ),
          );
        return;
      }
      setState(() => _remaining = next);
    });
  }

  void _stop() {
    if (!_running) return;
    _timer?.cancel();
    AppFeedbackService.instance.emit(AppFeedbackType.selection);
    setState(() {
      _running = false;
      _completed = false;
      _remaining = _selectedAction?.duration ?? Duration.zero;
    });
  }

  double _progressFor(_QuickCareAction action) {
    if (action.duration.inSeconds <= 0) return 0;
    final elapsed = action.duration.inSeconds - _remaining.inSeconds;
    return (elapsed / action.duration.inSeconds).clamp(0.0, 1.0).toDouble();
  }

  static String _formatDuration(Duration value) {
    if (value.inSeconds < 60) return '${value.inSeconds} giây';
    return '${value.inMinutes} phút';
  }

  static String _formatClock(Duration value) {
    final minutes = value.inMinutes.toString().padLeft(2, '0');
    final seconds = (value.inSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }
}

class _QuickCareAction {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final Duration duration;

  const _QuickCareAction({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.duration,
  });
}
