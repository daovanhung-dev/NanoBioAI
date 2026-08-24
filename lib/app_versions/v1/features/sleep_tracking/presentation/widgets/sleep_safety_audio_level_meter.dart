import 'package:flutter/material.dart';

/// Live, transient visualization of the on-device microphone signal.
///
/// Values come from native PCM feature extraction. This widget never invents
/// movement and never receives raw audio bytes.
class SleepSafetyAudioLevelMeter extends StatefulWidget {
  const SleepSafetyAudioLevelMeter({
    super.key,
    required this.signalLevel,
    required this.peakLevel,
    required this.baselineLevel,
    required this.relativeEnergy,
    required this.phase,
    required this.sensitivity,
    required this.hasSignal,
    required this.signalStale,
  });

  final double signalLevel;
  final double peakLevel;
  final double baselineLevel;
  final double relativeEnergy;
  final String phase;
  final String sensitivity;
  final bool hasSignal;
  final bool signalStale;

  @override
  State<SleepSafetyAudioLevelMeter> createState() =>
      _SleepSafetyAudioLevelMeterState();
}

class _SleepSafetyAudioLevelMeterState
    extends State<SleepSafetyAudioLevelMeter> {
  bool _isRising = true;

  @override
  void didUpdateWidget(covariant SleepSafetyAudioLevelMeter oldWidget) {
    super.didUpdateWidget(oldWidget);
    _isRising = widget.signalLevel >= oldWidget.signalLevel;
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final reduceMotion = MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    final level = widget.signalLevel.clamp(0.0, 1.0).toDouble();
    final peak = widget.peakLevel.clamp(0.0, 1.0).toDouble();
    final baseline = widget.baselineLevel.clamp(0.0, 1.0).toDouble();
    final status = _statusText();
    final isLoud = widget.phase == 'candidate' ||
        widget.phase == 'alerting' ||
        level >= 0.82;
    final foreground = isLoud ? colors.error : colors.primary;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.graphic_eq_rounded, color: foreground),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Âm thanh môi trường',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                      Text(
                        status,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: widget.signalStale ? colors.error : null,
                            ),
                      ),
                    ],
                  ),
                ),
                Text(
                  '${(level * 100).round()}%',
                  style: Theme.of(context).textTheme.labelLarge,
                ),
              ],
            ),
            const SizedBox(height: 14),
            Semantics(
              label: 'Mức tín hiệu âm thanh ${(level * 100).round()} phần trăm. $status',
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final width = constraints.maxWidth;
                  return SizedBox(
                    height: 22,
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Positioned.fill(
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              color: colors.surfaceContainerHighest,
                              borderRadius: BorderRadius.circular(999),
                            ),
                          ),
                        ),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: AnimatedContainer(
                            key: const Key('sleep-safety-live-level-fill'),
                            duration: reduceMotion
                                ? Duration.zero
                                : Duration(milliseconds: _isRising ? 90 : 260),
                            curve: Curves.easeOut,
                            width: widget.hasSignal ? width * level : 0,
                            decoration: BoxDecoration(
                              color: foreground,
                              borderRadius: BorderRadius.circular(999),
                            ),
                          ),
                        ),
                        if (widget.hasSignal)
                          Positioned(
                            left: (width * baseline).clamp(0.0, width - 2),
                            top: 2,
                            bottom: 2,
                            child: Container(
                              key: const Key('sleep-safety-baseline-marker'),
                              width: 2,
                              color: colors.onSurfaceVariant,
                            ),
                          ),
                        if (widget.hasSignal)
                          Positioned(
                            left: (width * peak).clamp(0.0, width - 3),
                            top: -2,
                            bottom: -2,
                            child: Container(
                              key: const Key('sleep-safety-peak-marker'),
                              width: 3,
                              decoration: BoxDecoration(
                                color: colors.onSurface,
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                          ),
                      ],
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Độ nhạy: ${widget.sensitivity}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
                Text(
                  widget.hasSignal
                      ? 'Năng lượng tương đối ${widget.relativeEnergy.toStringAsFixed(1)}×'
                      : 'Chưa có dữ liệu tín hiệu',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              'Mức hiển thị là tín hiệu tương đối từ micro, không phải phép đo dB SPL và không được lưu thành bản ghi âm.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
            ),
          ],
        ),
      ),
    );
  }

  String _statusText() {
    if (widget.signalStale) return 'Không nhận được tín hiệu micro';
    if (!widget.hasSignal) return 'Đang chờ tín hiệu micro';
    return switch (widget.phase) {
      'calibrating' => 'Đang hiệu chỉnh âm thanh phòng',
      'candidate' => 'Phát hiện âm thanh lớn — đang kiểm tra',
      'alerting' => 'Phát hiện âm thanh cần chú ý',
      _ => 'Mic đang nghe',
    };
  }
}
