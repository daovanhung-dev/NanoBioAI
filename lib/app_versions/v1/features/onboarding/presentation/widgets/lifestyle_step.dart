import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nano_app/core/theme/theme.dart';

import '../../providers/onboarding_provider.dart';
import 'package:nano_app/core/constants/onboarding_constants.dart';
import '../constants/onboarding_options.dart';
import 'nabi_onboarding_experience.dart';
import 'onboarding_compact_ui.dart';
import 'onboarding_step_shell.dart';
import 'onboarding_stitch_components.dart';

class LifestyleStep extends ConsumerWidget {
  const LifestyleStep({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(onboardingProvider);
    final controller = ref.read(onboardingProvider.notifier);

    return OnboardingStepShell(
      stepIndex: 4,
      title: 'Nhịp sống của bạn',
      subtitle: 'Chia sẻ thói quen gần với một ngày thường của bạn.',
      mood: NabiOnboardingMood.lifestyle,
      onBack: controller.previousStep,
      onNext: controller.nextStep,
      child: OnboardingRevealColumn(
        children: [
          const OnboardingNabiNote(
            mood: NabiOnboardingMood.lifestyle,
            eyebrow: 'NABI ĐỒNG HÀNH',
            message:
                'Nhịp sinh học mỗi người là một câu chuyện riêng. Cứ chia sẻ theo thói quen thực tế của bạn nhé.',
          ),
          const SizedBox(height: AppSpacing.lg),
          const OnboardingScreenHeading(
            title: 'Nhịp sống của bạn',
            subtitle:
                'Những lựa chọn này giúp Nabi điều chỉnh gợi ý theo lịch sinh hoạt hằng ngày.',
            bottomSpacing: AppSpacing.md,
          ),
          _LifestyleCard(
            number: '01',
            category: 'GIẤC NGỦ',
            title: 'Chất lượng giấc ngủ',
            caption: 'Phục hồi năng lượng',
            icon: Icons.nights_stay_rounded,
            scene: const _LifestyleScene(kind: _SceneKind.sleep),
            child: OnboardingChoicePickerField(
              label: 'Chọn mức độ ngủ',
              hint: 'Chọn mức độ ngủ',
              icon: Icons.bedtime_rounded,
              options: OnboardingOptions.sleepQualityChoices,
              selectedCode: OnboardingOptions.codeForLabel(
                OnboardingOptions.sleepQualityChoices,
                state.sleepQuality,
              ),
              onSelected: (code) => controller.updateSleepQuality(
                OnboardingCatalog.labelOf(
                  OnboardingOptions.sleepQualityChoices,
                  code,
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          _LifestyleCard(
            number: '02',
            category: 'VẬN ĐỘNG',
            title: 'Mức độ vận động',
            caption: 'Lưu thông và dẻo dai',
            icon: Icons.energy_savings_leaf_rounded,
            scene: const _LifestyleScene(kind: _SceneKind.movement),
            child: OnboardingChoicePickerField(
              label: 'Chọn mức độ vận động',
              hint: 'Chọn mức độ vận động',
              icon: Icons.directions_walk_rounded,
              options: OnboardingOptions.activityChoices,
              selectedCode: OnboardingOptions.codeForLabel(
                OnboardingOptions.activityChoices,
                state.activityLevel,
              ),
              onSelected: (code) => controller.updateActivityLevel(
                OnboardingCatalog.labelOf(
                  OnboardingOptions.activityChoices,
                  code,
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          _LifestyleCard(
            number: '03',
            category: 'NƯỚC UỐNG',
            title: 'Lượng nước mỗi ngày',
            caption: 'Dịu dàng tiếp sức cơ thể',
            icon: Icons.water_drop_rounded,
            scene: const _LifestyleScene(kind: _SceneKind.water),
            child: OnboardingChoicePickerField(
              label: 'Chọn lượng nước',
              hint: 'Chọn lượng nước',
              icon: Icons.local_drink_rounded,
              options: OnboardingOptions.waterChoices,
              selectedCode: OnboardingOptions.codeForLabel(
                OnboardingOptions.waterChoices,
                state.waterPerDay,
              ),
              onSelected: (code) => controller.updateWaterPerDay(
                OnboardingCatalog.labelOf(OnboardingOptions.waterChoices, code),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Thông tin chỉ giúp Nabi điều chỉnh gợi ý cho gần với nhịp sống của bạn.',
            style: AppTextStyles.bodySmall.copyWith(
              color: context.semanticColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _LifestyleCard extends StatelessWidget {
  const _LifestyleCard({
    required this.number,
    required this.category,
    required this.title,
    required this.caption,
    required this.icon,
    required this.scene,
    required this.child,
  });

  final String number;
  final String category;
  final String title;
  final String caption;
  final IconData icon;
  final Widget scene;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colors = context.semanticColors;
    return OnboardingStitchCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: colors.secondarySoft,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: Icon(icon, color: colors.secondaryDark, size: 23),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$number. $category',
                      style: AppTextStyles.labelSmall.copyWith(
                        color: colors.secondaryDark,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.4,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      title,
                      style: AppTextStyles.heading5.copyWith(
                        color: colors.textPrimary,
                        fontWeight: FontWeight.w700,
                        height: 1.24,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          SizedBox(height: 82, width: double.infinity, child: scene),
          const SizedBox(height: AppSpacing.sm),
          child,
          const SizedBox(height: AppSpacing.xs),
          Text(
            caption,
            style: AppTextStyles.labelSmall.copyWith(
              color: colors.textMuted,
              letterSpacing: 0,
            ),
          ),
        ],
      ),
    );
  }
}

enum _SceneKind { sleep, movement, water }

class _LifestyleScene extends StatelessWidget {
  const _LifestyleScene({required this.kind});

  final _SceneKind kind;

  @override
  Widget build(BuildContext context) {
    final colors = context.semanticColors;
    final sceneColors = switch (kind) {
      _SceneKind.sleep => [colors.primaryDark, colors.info],
      _SceneKind.movement => [colors.secondaryDark, colors.secondary],
      _SceneKind.water => [colors.info, colors.primaryLight],
    };
    final icon = switch (kind) {
      _SceneKind.sleep => Icons.bedtime_rounded,
      _SceneKind.movement => Icons.directions_walk_rounded,
      _SceneKind.water => Icons.water_drop_rounded,
    };
    final label = switch (kind) {
      _SceneKind.sleep => 'Một khoảng nghỉ êm',
      _SceneKind.movement => 'Chuyển động vừa sức',
      _SceneKind.water => 'Từng ngụm nước mát',
    };

    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: Stack(
        fit: StackFit.expand,
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: sceneColors,
              ),
            ),
          ),
          Positioned.fill(
            child: CustomPaint(
              painter: _LifestyleScenePainter(
                kind: kind,
                accent: colors.onBrand.withValues(alpha: 0.24),
                foreground: colors.onBrand.withValues(alpha: 0.72),
                backdrop: sceneColors.first,
              ),
            ),
          ),
          Positioned(
            left: 12,
            top: 0,
            bottom: 0,
            child: Center(
              child: Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.22),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.28),
                  ),
                ),
                child: Icon(icon, color: Colors.white, size: 23),
              ),
            ),
          ),
          Positioned(
            left: 68,
            bottom: 10,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: colors.card.withValues(alpha: 0.92),
                borderRadius: BorderRadius.circular(AppRadius.pill),
              ),
              child: Text(
                label,
                style: AppTextStyles.labelSmall.copyWith(
                  color: colors.textPrimary,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LifestyleScenePainter extends CustomPainter {
  const _LifestyleScenePainter({
    required this.kind,
    required this.accent,
    required this.foreground,
    required this.backdrop,
  });

  final _SceneKind kind;
  final Color accent;
  final Color foreground;
  final Color backdrop;

  @override
  void paint(Canvas canvas, Size size) {
    final fill = Paint()..color = accent;
    final line = Paint()
      ..color = foreground
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(Offset(size.width * .83, size.height * .22), 27, fill);

    switch (kind) {
      case _SceneKind.sleep:
        canvas.drawCircle(
          Offset(size.width * .83, size.height * .24),
          12,
          line,
        );
        canvas.drawCircle(
          Offset(size.width * .87, size.height * .19),
          12,
          Paint()..color = backdrop,
        );
        final hill = Path()
          ..moveTo(size.width * .28, size.height)
          ..quadraticBezierTo(
            size.width * .58,
            size.height * .45,
            size.width,
            size.height * .88,
          )
          ..lineTo(size.width, size.height)
          ..close();
        canvas.drawPath(hill, fill);
        for (var index = 0; index < 3; index++) {
          final x = size.width * (.65 + index * .10);
          canvas.drawCircle(Offset(x, 14 + (index % 2) * 10), 1.4, line);
        }
      case _SceneKind.movement:
        final hills = Path()
          ..moveTo(size.width * .28, size.height)
          ..cubicTo(
            size.width * .42,
            size.height * .50,
            size.width * .65,
            size.height * .64,
            size.width,
            size.height * .38,
          )
          ..lineTo(size.width, size.height)
          ..close();
        canvas.drawPath(hills, fill);
        canvas.drawPath(
          Path()
            ..moveTo(size.width * .47, size.height * .95)
            ..cubicTo(
              size.width * .58,
              size.height * .75,
              size.width * .7,
              size.height * .76,
              size.width * .83,
              size.height * .58,
            ),
          line,
        );
        for (var index = 0; index < 3; index++) {
          final x = size.width * (.72 + index * .07);
          canvas.drawOval(
            Rect.fromCenter(
              center: Offset(x, 48 - index * 9),
              width: 11,
              height: 5,
            ),
            line,
          );
        }
      case _SceneKind.water:
        for (var index = 0; index < 3; index++) {
          final y = size.height * (.54 + index * .19);
          final wave = Path()
            ..moveTo(size.width * .28, y)
            ..cubicTo(
              size.width * .47,
              y - 9,
              size.width * .58,
              y + 9,
              size.width * .75,
              y,
            )
            ..cubicTo(
              size.width * .85,
              y - 7,
              size.width * .91,
              y + 7,
              size.width,
              y,
            );
          canvas.drawPath(wave, line);
        }
        final drop = Path()
          ..moveTo(size.width * .82, 16)
          ..cubicTo(
            size.width * .75,
            25,
            size.width * .74,
            31,
            size.width * .82,
            36,
          )
          ..cubicTo(
            size.width * .90,
            31,
            size.width * .89,
            25,
            size.width * .82,
            16,
          )
          ..close();
        canvas.drawPath(drop, fill);
    }
  }

  @override
  bool shouldRepaint(covariant _LifestyleScenePainter oldDelegate) =>
      oldDelegate.kind != kind ||
      oldDelegate.accent != accent ||
      oldDelegate.foreground != foreground ||
      oldDelegate.backdrop != backdrop;
}
