import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nano_app/app_versions/v1/features/onboarding/presentation/widgets/nabi_onboarding_experience.dart';

import 'package:nano_app/core/constants/onboarding_constants.dart';
import 'package:nano_app/core/theme/theme.dart';

import '../../providers/onboarding_provider.dart';
import 'onboarding_compact_ui.dart';
import 'onboarding_step_shell.dart';
import 'onboarding_text_field.dart';

class ConditionsStep extends ConsumerWidget {
  const ConditionsStep({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(onboardingProvider);
    final controller = ref.read(onboardingProvider.notifier);

    return OnboardingStepShell(
      stepIndex: 3,
      title: 'Cơ thể bạn đang cần lưu ý gì?',
      subtitle:
          'Chọn gần đúng để NaBi thận trọng hơn khi gợi ý. Đây không phải chẩn đoán y khoa.',
      onBack: controller.previousStep,
      onNext: controller.nextStep,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final layout = _ConditionsLayout.fromWidth(constraints.maxWidth);

          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 880),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _SelectionOverviewBanner(
                    selectedCount: state.conditions.length,
                    compact: layout.isCompact,
                  ),
                  SizedBox(height: layout.sectionGap),

                  _PremiumConditionsCard(
                    accentColor: NabiPalette.rose,
                    icon: Icons.health_and_safety_outlined,
                    eyebrow: 'TÌNH TRẠNG CẦN LƯU Ý',
                    title: 'Triệu chứng hoặc tình trạng hiện tại',
                    subtitle: 'Chọn điều NaBi cần cân nhắc khi gợi ý.',
                    compact: layout.isCompact,
                    trailing: _SelectedCountBadge(
                      count: state.conditions.length,
                    ),
                    child: Column(
                      children: [
                        const _ChoiceGuidance(),
                        SizedBox(height: layout.innerGap),
                        Container(
                          width: double.infinity,
                          padding: EdgeInsets.all(layout.isCompact ? 10 : 12),
                          decoration: BoxDecoration(
                            color: NabiPalette.rose.withValues(alpha: 0.035),
                            borderRadius: BorderRadius.circular(
                              layout.isCompact ? 16 : 18,
                            ),
                            border: Border.all(
                              color: NabiPalette.rose.withValues(alpha: 0.10),
                            ),
                          ),
                          child: OnboardingChoiceGrid(
                            options: OnboardingCatalog.conditions,
                            selectedCodes: state.conditions,
                            multiSelect: true,
                            onSelected: controller.toggleCondition,
                          ),
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: layout.sectionGap),

                  _PremiumConditionsCard(
                    accentColor: NabiPalette.violet,
                    icon: Icons.edit_note_rounded,
                    eyebrow: 'GHI CHÚ BỔ SUNG',
                    title: 'Có điều gì bạn muốn NaBi biết thêm?',
                    subtitle:
                        'Bạn có thể bỏ qua phần này và bổ sung sau bất cứ lúc nào.',
                    compact: layout.isCompact,
                    child: Column(
                      children: [
                        OnboardingTextField(
                          label: 'Ghi thêm nếu cần',
                          hint: 'Ví dụ: bác sĩ dặn hạn chế đồ mặn',
                          initialValue: state.otherCondition,
                          onChanged: controller.updateOtherCondition,
                          maxLines: layout.isCompact ? 2 : 3,
                          textInputAction: TextInputAction.done,
                          prefixIcon: const Icon(Icons.edit_note_rounded),
                        ),
                        SizedBox(height: layout.innerGap),
                        const _OtherNoteHint(),
                      ],
                    ),
                  ),

                  SizedBox(height: layout.sectionGap),

                  const _MedicalBoundaryInfoCard(),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _ConditionsLayout {
  final bool isCompact;
  final double sectionGap;
  final double innerGap;

  const _ConditionsLayout({
    required this.isCompact,
    required this.sectionGap,
    required this.innerGap,
  });

  factory _ConditionsLayout.fromWidth(double width) {
    final isCompact = width < 380;

    return _ConditionsLayout(
      isCompact: isCompact,
      sectionGap: isCompact ? 12 : 16,
      innerGap: isCompact ? 12 : 14,
    );
  }
}

class _SelectionOverviewBanner extends StatelessWidget {
  final int selectedCount;
  final bool compact;

  const _SelectionOverviewBanner({
    required this.selectedCount,
    required this.compact,
  });

  @override
  Widget build(BuildContext context) {
    final hasSelection = selectedCount > 0;

    return Container(
      padding: EdgeInsets.all(compact ? 14 : 17),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(compact ? 22 : 26),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [NabiPalette.violet, NabiPalette.royalBlue],
        ),
        boxShadow: [
          BoxShadow(
            color: NabiPalette.violet.withValues(alpha: 0.22),
            blurRadius: 26,
            offset: const Offset(0, 13),
          ),
        ],
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            top: -48,
            right: -34,
            child: Container(
              width: 135,
              height: 135,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.08),
              ),
            ),
          ),
          Positioned(
            bottom: -74,
            left: 50,
            child: Container(
              width: 150,
              height: 150,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: NabiPalette.cyan.withValues(alpha: 0.15),
              ),
            ),
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _HealthStatusOrb(hasSelection: hasSelection, compact: compact),
              SizedBox(width: compact ? 12 : 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      hasSelection
                          ? 'NaBi đã ghi nhận điều bạn chia sẻ'
                          : 'Mỗi cơ thể đều có câu chuyện riêng',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: compact ? 15 : 17,
                        height: 1.15,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.2,
                      ),
                    ),
                    SizedBox(height: compact ? 4 : 6),
                    Text(
                      hasSelection
                          ? 'Đã chọn $selectedCount mục cần lưu ý.'
                          : 'Chọn điều NaBi cần cân nhắc.',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.84),
                        fontSize: compact ? 11.5 : 12.5,
                        height: 1.38,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HealthStatusOrb extends StatelessWidget {
  final bool hasSelection;
  final bool compact;

  const _HealthStatusOrb({required this.hasSelection, required this.compact});

  @override
  Widget build(BuildContext context) {
    final size = compact ? 52.0 : 60.0;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withValues(alpha: 0.14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.28)),
      ),
      child: Icon(
        hasSelection
            ? Icons.favorite_rounded
            : Icons.health_and_safety_outlined,
        color: Colors.white,
        size: compact ? 23 : 27,
      ),
    );
  }
}

class _PremiumConditionsCard extends StatelessWidget {
  final Color accentColor;
  final IconData icon;
  final String eyebrow;
  final String title;
  final String subtitle;
  final Widget child;
  final Widget? trailing;
  final bool compact;

  const _PremiumConditionsCard({
    required this.accentColor,
    required this.icon,
    required this.eyebrow,
    required this.title,
    required this.subtitle,
    required this.child,
    required this.compact,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final radius = compact ? 20.0 : 24.0;
    final padding = compact ? 14.0 : 18.0;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.white, accentColor.withValues(alpha: 0.028)],
        ),
        border: Border.all(color: accentColor.withValues(alpha: 0.11)),
        boxShadow: [
          BoxShadow(
            color: NabiPalette.ink.withValues(alpha: 0.045),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: Stack(
          children: [
            Positioned(
              top: -52,
              right: -48,
              child: Container(
                width: 142,
                height: 142,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: accentColor.withValues(alpha: 0.045),
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.all(padding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: compact ? 40 : 44,
                        height: compact ? 40 : 44,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(
                            compact ? 13 : 15,
                          ),
                          color: accentColor.withValues(alpha: 0.11),
                        ),
                        child: Icon(
                          icon,
                          color: accentColor,
                          size: compact ? 20 : 22,
                        ),
                      ),
                      SizedBox(width: compact ? 10 : 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Wrap(
                              spacing: 7,
                              runSpacing: 6,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: [
                                Text(
                                  eyebrow,
                                  style: TextStyle(
                                    color: accentColor,
                                    fontSize: compact ? 8.5 : 9.5,
                                    height: 1,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 1.05,
                                  ),
                                ),
                                if (trailing != null) trailing!,
                              ],
                            ),
                            const SizedBox(height: 5),
                            Text(
                              title,
                              style: AppTextStyles.labelLarge.copyWith(
                                color: NabiPalette.ink,
                                fontSize: compact ? 14.5 : 15.5,
                                height: 1.18,
                                fontWeight: FontWeight.w900,
                                letterSpacing: -0.1,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: compact ? 9 : 11),
                  Text(
                    subtitle,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: NabiPalette.mutedInk,
                      fontSize: compact ? 11.5 : null,
                      height: 1.42,
                    ),
                  ),
                  SizedBox(height: compact ? 14 : 17),
                  child,
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SelectedCountBadge extends StatelessWidget {
  final int count;

  const _SelectedCountBadge({required this.count});

  @override
  Widget build(BuildContext context) {
    final hasSelection = count > 0;

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 220),
      child: Container(
        key: ValueKey(count),
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
        decoration: BoxDecoration(
          color: (hasSelection ? NabiPalette.rose : NabiPalette.mutedInk)
              .withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          hasSelection ? '$count ĐÃ CHỌN' : 'CHƯA CHỌN',
          style: TextStyle(
            color: hasSelection ? NabiPalette.rose : NabiPalette.mutedInk,
            fontSize: 7.5,
            height: 1,
            fontWeight: FontWeight.w900,
            letterSpacing: 0.55,
          ),
        ),
      ),
    );
  }
}

class _ChoiceGuidance extends StatelessWidget {
  const _ChoiceGuidance();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
      decoration: BoxDecoration(
        color: NabiPalette.amber.withValues(alpha: 0.075),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline_rounded, size: 18, color: NabiPalette.amber),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Có thể chọn nhiều mục. “Không có vấn đề” sẽ thay các mục khác.',
              style: AppTextStyles.bodySmall.copyWith(
                color: NabiPalette.mutedInk,
                height: 1.34,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _OtherNoteHint extends StatelessWidget {
  const _OtherNoteHint();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
      decoration: BoxDecoration(
        color: NabiPalette.violet.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.tips_and_updates_outlined,
            size: 18,
            color: NabiPalette.violet,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Chỉ ghi điều cần thiết về ăn uống hoặc vận động.',
              style: AppTextStyles.bodySmall.copyWith(
                color: NabiPalette.mutedInk,
                height: 1.34,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MedicalBoundaryInfoCard extends StatelessWidget {
  const _MedicalBoundaryInfoCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: NabiPalette.cyan.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: NabiPalette.cyan.withValues(alpha: 0.13)),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final stacked = constraints.maxWidth < 300;

          final icon = Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: NabiPalette.cyan.withValues(alpha: 0.13),
            ),
            child: const Icon(
              Icons.verified_user_outlined,
              color: NabiPalette.cyan,
              size: 18,
            ),
          );

          final content = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'NaBi không thay thế tư vấn y tế',
                style: AppTextStyles.labelLarge.copyWith(
                  color: NabiPalette.ink,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                'Thông tin chỉ giúp NaBi gợi ý thận trọng hơn.',
                style: AppTextStyles.bodySmall.copyWith(
                  color: NabiPalette.mutedInk,
                  height: 1.35,
                ),
              ),
            ],
          );

          if (stacked) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [icon, const SizedBox(height: 10), content],
            );
          }

          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              icon,
              const SizedBox(width: 10),
              Expanded(child: content),
            ],
          );
        },
      ),
    );
  }
}
