import 'dart:math' as math;
import 'nabi_onboarding_experience.dart' show NabiPalette;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nano_app/app_versions/v1/services/ai/ai_service.dart';
import 'package:nano_app/core/theme/theme.dart';

import '../../providers/onboarding_provider.dart';
import 'onboarding_step_shell.dart';

class WelcomeStep extends ConsumerStatefulWidget {
  const WelcomeStep({super.key});

  @override
  ConsumerState<WelcomeStep> createState() => _WelcomeStepState();
}

class _WelcomeStepState extends ConsumerState<WelcomeStep>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ambientController;

  @override
  void initState() {
    super.initState();
    _ambientController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 11),
    )..repeat();
  }

  @override
  void dispose() {
    _ambientController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = ref.read(onboardingProvider.notifier);
    final enabled = ref.watch(onboardingAiDevCheckEnabledProvider);
    final check = enabled ? ref.watch(onboardingAiDevCheckProvider) : null;

    return OnboardingStepShell(
      stepIndex: 0,
      showBack: false,
      title: 'Hành trình khỏe hơn,\nbắt đầu từ hôm nay.',
      subtitle:
          'NaBi sẽ tạo lộ trình phù hợp với nhịp sống, mục tiêu và những điều bạn thực sự cần.',
      nextLabel: 'Tạo lộ trình của tôi',
      onNext: controller.nextStep,
      child: AnimatedBuilder(
        animation: _ambientController,
        builder: (context, _) {
          return Column(
            children: [
              _PremiumWelcomeHero(progress: _ambientController.value),
              const SizedBox(height: 14),

              const _SignalRow(),
              const SizedBox(height: 14),

              const _FeatureOverviewCard(),
              const SizedBox(height: 12),

              const _StartFlowCard(),
              const SizedBox(height: 12),

              const _CommitmentHint(),

              if (check != null) ...[
                const SizedBox(height: 10),
                _AiCheckCard(
                  key: const Key('onboarding_ai_dev_check_banner'),
                  check: check,
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _PremiumWelcomeHero extends StatelessWidget {
  final double progress;

  const _PremiumWelcomeHero({required this.progress});

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 360;

          return Semantics(
            label: 'Khởi đầu hành trình chăm sóc sức khỏe cùng NaBi',
            child: ClipRRect(
              borderRadius: BorderRadius.circular(28),
              child: Container(
                height: compact ? 214 : 230,
                width: double.infinity,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      NabiPalette.violet,
                      Color.lerp(NabiPalette.violet, NabiPalette.cyan, 0.42)!,
                      NabiPalette.cyan,
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: NabiPalette.violet.withValues(alpha: 0.22),
                      blurRadius: 30,
                      offset: const Offset(0, 16),
                    ),
                  ],
                ),
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Positioned.fill(
                      child: CustomPaint(
                        painter: _AmbientHeroPainter(progress: progress),
                      ),
                    ),
                    Positioned(
                      top: -36,
                      right: -38,
                      child: Container(
                        width: 138,
                        height: 138,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withValues(alpha: 0.07),
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: -74,
                      left: -42,
                      child: Container(
                        width: 168,
                        height: 168,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withValues(alpha: 0.08),
                        ),
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.fromLTRB(
                        compact ? 18 : 21,
                        19,
                        compact ? 96 : 110,
                        18,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _HeroEyebrow(
                            label: 'CHĂM SÓC SỨC KHỎE CÁ NHÂN',
                            progress: progress,
                          ),
                          const SizedBox(height: 13),
                          Expanded(
                            child: Text(
                              'Không cần hoàn hảo.\nChỉ cần đúng với bạn.',
                              maxLines: compact ? 4 : 3,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: compact ? 25 : 29,
                                height: 1.08,
                                fontWeight: FontWeight.w900,
                                letterSpacing: -0.75,
                              ),
                            ),
                          ),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 11,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.14),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.20),
                              ),
                            ),
                            child: const Row(
                              children: [
                                Icon(
                                  Icons.auto_awesome_rounded,
                                  size: 15,
                                  color: Colors.white,
                                ),
                                SizedBox(width: 7),
                                Expanded(
                                  child: Text(
                                    'Lộ trình được thiết kế cho riêng bạn',
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 11.5,
                                      height: 1,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    Positioned(
                      right: compact ? -8 : 2,
                      bottom: compact ? 4 : 8,
                      child: _HealthOrbit(progress: progress),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _HeroEyebrow extends StatelessWidget {
  final String label;
  final double progress;

  const _HeroEyebrow({required this.label, required this.progress});

  @override
  Widget build(BuildContext context) {
    final breathing = 0.7 + math.sin(progress * math.pi * 2) * 0.12;

    return Opacity(
      opacity: breathing.clamp(0.55, 0.9),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.88),
                fontSize: 9.5,
                letterSpacing: 1.12,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HealthOrbit extends StatelessWidget {
  final double progress;

  const _HealthOrbit({required this.progress});

  @override
  Widget build(BuildContext context) {
    final floating = math.sin(progress * math.pi * 2) * 5;
    final orbit = progress * math.pi * 2;

    return SizedBox(
      width: 154,
      height: 154,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Transform.rotate(
            angle: orbit,
            child: CustomPaint(
              size: const Size(146, 146),
              painter: _OrbitPainter(progress: progress),
            ),
          ),
          Transform.translate(
            offset: Offset(0, floating),
            child: Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.18),
                border: Border.all(color: Colors.white.withValues(alpha: 0.45)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: const Icon(
                Icons.favorite_rounded,
                color: Colors.white,
                size: 31,
              ),
            ),
          ),
          Positioned(
            left: 6,
            top: 43 + math.sin(orbit) * 6,
            child: _OrbitBadge(
              icon: Icons.restaurant_rounded,
              color: NabiPalette.amber,
            ),
          ),
          Positioned(
            right: 3,
            top: 24 + math.cos(orbit) * 6,
            child: _OrbitBadge(
              icon: Icons.bolt_rounded,
              color: NabiPalette.cyan,
            ),
          ),
          Positioned(
            bottom: 5,
            right: 40 + math.sin(orbit) * 5,
            child: _OrbitBadge(
              icon: Icons.nightlight_round,
              color: NabiPalette.rose,
            ),
          ),
        ],
      ),
    );
  }
}

class _OrbitBadge extends StatelessWidget {
  final IconData icon;
  final Color color;

  const _OrbitBadge({required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 31,
      height: 31,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withValues(alpha: 0.95),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.10),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Icon(icon, size: 15, color: color),
    );
  }
}

class _AmbientHeroPainter extends CustomPainter {
  final double progress;

  const _AmbientHeroPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final wave = math.sin(progress * math.pi * 2);
    final wave2 = math.cos(progress * math.pi * 2);

    final bloomPaint = Paint()
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 34);

    bloomPaint.color = Colors.white.withValues(alpha: 0.12);
    canvas.drawCircle(
      Offset(size.width * 0.78 + wave * 20, size.height * 0.16),
      44,
      bloomPaint,
    );

    bloomPaint.color = NabiPalette.rose.withValues(alpha: 0.18);
    canvas.drawCircle(
      Offset(size.width * 0.28, size.height * 0.94 + wave2 * 12),
      62,
      bloomPaint,
    );

    bloomPaint.color = NabiPalette.cyan.withValues(alpha: 0.20);
    canvas.drawCircle(
      Offset(size.width * 0.88, size.height * 0.74 + wave * 8),
      38,
      bloomPaint,
    );

    final linePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.13)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    final path = Path()
      ..moveTo(-20, size.height * 0.72)
      ..quadraticBezierTo(
        size.width * 0.35,
        size.height * (0.52 + wave * 0.04),
        size.width + 25,
        size.height * 0.68,
      );

    canvas.drawPath(path, linePaint);
  }

  @override
  bool shouldRepaint(covariant _AmbientHeroPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

class _OrbitPainter extends CustomPainter {
  final double progress;

  const _OrbitPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);

    final rings = [
      (radius: 61.0, color: Colors.white.withValues(alpha: 0.22)),
      (radius: 48.0, color: Colors.white.withValues(alpha: 0.14)),
    ];

    for (final ring in rings) {
      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.25
        ..color = ring.color;

      canvas.drawCircle(center, ring.radius, paint);
    }

    final arcPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.4
      ..strokeCap = StrokeCap.round
      ..color = Colors.white.withValues(alpha: 0.72);

    final rect = Rect.fromCircle(center: center, radius: 61);

    canvas.drawArc(
      rect,
      progress * math.pi * 2,
      math.pi * 0.58,
      false,
      arcPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _OrbitPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

class _SignalRow extends StatelessWidget {
  const _SignalRow();

  @override
  Widget build(BuildContext context) {
    return const Wrap(
      alignment: WrapAlignment.center,
      spacing: 8,
      runSpacing: 8,
      children: [
        _SignalPill(
          icon: Icons.tune_rounded,
          label: 'Theo nhịp sống',
          color: NabiPalette.violet,
        ),
        _SignalPill(
          icon: Icons.auto_awesome_rounded,
          label: 'Cá nhân hoá',
          color: NabiPalette.cyan,
        ),
        _SignalPill(
          icon: Icons.lock_outline_rounded,
          label: 'Riêng tư',
          color: NabiPalette.rose,
        ),
      ],
    );
  }
}

class _SignalPill extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _SignalPill({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.14)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: AppTextStyles.bodySmall.copyWith(
              color: NabiPalette.ink,
              fontSize: 11.5,
              fontWeight: FontWeight.w800,
              height: 1,
            ),
          ),
        ],
      ),
    );
  }
}

class _FeatureOverviewCard extends StatelessWidget {
  const _FeatureOverviewCard();

  @override
  Widget build(BuildContext context) {
    return _GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 39,
                height: 39,
                decoration: BoxDecoration(
                  color: NabiPalette.violet.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: const Icon(
                  Icons.insights_rounded,
                  color: NabiPalette.violet,
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Không chỉ là lời nhắc chung chung',
                  style: AppTextStyles.labelLarge.copyWith(
                    color: NabiPalette.ink,
                    fontWeight: FontWeight.w900,
                    fontSize: 15.5,
                    letterSpacing: -0.15,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Mỗi gợi ý được xây dựng từ mục tiêu, thể trạng và nhịp sống riêng của bạn.',
            style: AppTextStyles.bodySmall.copyWith(
              color: NabiPalette.mutedInk,
              height: 1.42,
            ),
          ),
          const SizedBox(height: 15),
          const _FeatureRow(
            icon: Icons.restaurant_menu_rounded,
            color: NabiPalette.cyan,
            title: 'Ăn uống vừa sức',
            description: 'Gợi ý bữa ăn dễ theo, phù hợp với mục tiêu của bạn.',
          ),
          const _SoftDivider(),
          const _FeatureRow(
            icon: Icons.notifications_active_outlined,
            color: NabiPalette.violet,
            title: 'Đồng hành đúng lúc',
            description:
                'Nhắc bạn vận động, nghỉ ngơi và chăm cơ thể đúng nhịp.',
          ),
          const _SoftDivider(),
          const _FeatureRow(
            icon: Icons.psychology_alt_outlined,
            color: NabiPalette.amber,
            title: 'Linh hoạt khi bạn thay đổi',
            description:
                'Lộ trình được điều chỉnh theo thói quen và tiến độ thực tế.',
          ),
        ],
      ),
    );
  }
}

class _FeatureRow extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String description;

  const _FeatureRow({
    required this.icon,
    required this.color,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 39,
          height: 39,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color, size: 19),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 1),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTextStyles.labelLarge.copyWith(
                    color: NabiPalette.ink,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: NabiPalette.mutedInk,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _SoftDivider extends StatelessWidget {
  const _SoftDivider();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 11),
      child: Divider(
        height: 1,
        thickness: 1,
        color: NabiPalette.ink.withValues(alpha: 0.06),
      ),
    );
  }
}

class _StartFlowCard extends StatelessWidget {
  const _StartFlowCard();

  @override
  Widget build(BuildContext context) {
    return _GlassCard(
      padding: const EdgeInsets.fromLTRB(15, 14, 15, 13),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Chỉ 3 bước để bắt đầu',
            style: AppTextStyles.labelLarge.copyWith(
              color: NabiPalette.ink,
              fontWeight: FontWeight.w900,
              fontSize: 14.5,
            ),
          ),
          const SizedBox(height: 13),
          const Row(
            children: [
              Expanded(
                child: _FlowStage(
                  number: '01',
                  icon: Icons.person_outline_rounded,
                  title: 'Hiểu bạn',
                  color: NabiPalette.violet,
                ),
              ),
              _FlowConnector(),
              Expanded(
                child: _FlowStage(
                  number: '02',
                  icon: Icons.auto_graph_rounded,
                  title: 'Tạo lộ trình',
                  color: NabiPalette.cyan,
                ),
              ),
              _FlowConnector(),
              Expanded(
                child: _FlowStage(
                  number: '03',
                  icon: Icons.favorite_outline_rounded,
                  title: 'Đồng hành',
                  color: NabiPalette.rose,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _FlowStage extends StatelessWidget {
  final String number;
  final IconData icon;
  final String title;
  final Color color;

  const _FlowStage({
    required this.number,
    required this.icon,
    required this.title,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.center,
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color.withValues(alpha: 0.11),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            Positioned(
              top: -5,
              right: -9,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(7),
                ),
                child: Text(
                  number,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 7.5,
                    height: 1,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          title,
          textAlign: TextAlign.center,
          maxLines: 2,
          style: AppTextStyles.bodySmall.copyWith(
            color: NabiPalette.ink,
            height: 1.15,
            fontSize: 10.5,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

class _FlowConnector extends StatelessWidget {
  const _FlowConnector();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 23),
      child: Container(
        width: 13,
        height: 1.5,
        decoration: BoxDecoration(
          color: NabiPalette.ink.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(20),
        ),
      ),
    );
  }
}

class _CommitmentHint extends StatelessWidget {
  const _CommitmentHint();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
      decoration: BoxDecoration(
        color: NabiPalette.cyan.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: NabiPalette.cyan.withValues(alpha: 0.13)),
      ),
      child: Row(
        children: [
          Container(
            width: 31,
            height: 31,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: NabiPalette.cyan.withValues(alpha: 0.14),
            ),
            child: const Icon(
              Icons.timer_outlined,
              size: 17,
              color: NabiPalette.cyan,
            ),
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              'Mất khoảng 2–3 phút. Bạn luôn có thể điều chỉnh hồ sơ và lộ trình sau này.',
              style: AppTextStyles.bodySmall.copyWith(
                color: NabiPalette.mutedInk,
                height: 1.32,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AiCheckCard extends StatelessWidget {
  final AsyncValue<AIConnectionCheckResult?> check;

  const _AiCheckCard({super.key, required this.check});

  @override
  Widget build(BuildContext context) {
    return check.when(
      loading: () => const _StatusCard(
        icon: Icons.sync_rounded,
        color: NabiPalette.violet,
        text: 'Đang kiểm tra để trợ lý sẵn sàng đồng hành cùng bạn...',
      ),
      error: (_, __) => const _StatusCard(
        icon: Icons.warning_amber_rounded,
        color: NabiPalette.amber,
        text: 'Hiện chưa thể kiểm tra kết nối trợ lý. Bạn vẫn có thể tiếp tục.',
      ),
      data: (result) {
        if (result == null) return const SizedBox.shrink();

        return _StatusCard(
          icon: result.success
              ? Icons.check_circle_outline_rounded
              : Icons.warning_amber_rounded,
          color: result.success ? NabiPalette.cyan : NabiPalette.amber,
          text: result.success
              ? 'Trợ lý đã sẵn sàng: ${result.modelName ?? 'đã kết nối'}.'
              : result.message,
        );
      },
    );
  }
}

class _StatusCard extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String text;

  const _StatusCard({
    required this.icon,
    required this.color,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: color.withValues(alpha: 0.14)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: AppTextStyles.bodySmall.copyWith(
                color: NabiPalette.mutedInk,
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;

  const _GlassCard({
    required this.child,
    this.padding = const EdgeInsets.all(16),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.88),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white.withValues(alpha: 0.95)),
        boxShadow: [
          BoxShadow(
            color: NabiPalette.ink.withValues(alpha: 0.055),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: child,
    );
  }
}
