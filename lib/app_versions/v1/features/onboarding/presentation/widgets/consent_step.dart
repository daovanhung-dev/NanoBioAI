import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nano_app/core/theme/theme.dart';

import '../../providers/onboarding_provider.dart';
import 'nabi_onboarding_experience.dart';
import 'onboarding_step_shell.dart';

class ConsentStep extends ConsumerWidget {
  const ConsentStep({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.semanticColors;
    final state = ref.watch(onboardingProvider);
    final controller = ref.read(onboardingProvider.notifier);
    return OnboardingStepShell(
      stepIndex: 7,
      title: 'Bạn luôn có quyền chọn',
      subtitle: 'Xác nhận trước khi tạo lộ trình.',
      mood: NabiOnboardingMood.consent,
      onBack: controller.previousStep,
      nextLabel: 'Tiếp tục',
      onNext: state.agreed ? controller.nextStep : null,
      child: Column(
        children: [
          const _ConsentCard(
            icon: Icons.lock_rounded,
            title: 'Dữ liệu của bạn',
            text: 'Chỉ dùng để cá nhân hóa trải nghiệm.',
            color: NabiPalette.greenPrimary,
          ),
          const SizedBox(height: AppSpacing.sm),
          const _ConsentCard(
            icon: Icons.medical_information_rounded,
            title: 'Lưu ý sức khỏe',
            text: 'Nabi không thay thế bác sĩ hoặc chuyên gia.',
            color: NabiPalette.warning,
          ),
          const SizedBox(height: AppSpacing.md),
          const _TeamStorySection(),
          const SizedBox(height: AppSpacing.md),
          Semantics(
            checked: state.agreed,
            label: 'Đồng ý sử dụng thông tin để tạo lộ trình',
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  AppFeedbackService.instance.emit(AppFeedbackType.selection);
                  controller.setAgreed(!state.agreed);
                },
                borderRadius: BorderRadius.circular(AppRadius.xl),
                child: AnimatedContainer(
                  duration: nabiReducedMotion(context)
                      ? Duration.zero
                      : const Duration(milliseconds: 230),
                  curve: Curves.easeOutBack,
                  padding: const EdgeInsets.all(AppSpacing.cardPadding),
                  decoration: BoxDecoration(
                    gradient: state.agreed
                        ? NabiPalette.selection
                        : LinearGradient(colors: [colors.card, colors.cardAlt]),
                    borderRadius: BorderRadius.circular(AppRadius.xl),
                    border: Border.all(
                      color: state.agreed
                          ? NabiPalette.greenPrimary
                          : colors.border,
                      width: state.agreed ? 1.8 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      AnimatedContainer(
                        duration: AppDuration.fast,
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: state.agreed
                              ? AppColors.textInverse.withValues(alpha: 0.16)
                              : colors.primarySoft,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          state.agreed
                              ? Icons.check_rounded
                              : Icons.touch_app_rounded,
                          color: state.agreed
                              ? AppColors.textInverse
                              : NabiPalette.greenPrimary,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Text(
                          'Tôi đồng ý dùng thông tin đã nhập để tạo lộ trình.',
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: state.agreed
                                ? AppColors.textInverse
                                : colors.textPrimary,
                            fontWeight: FontWeight.w800,
                            height: 1.35,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          NabiAssistantMessage(
            message: state.agreed
                ? 'Cảm ơn bạn đã xác nhận'
                : 'Chạm để xác nhận',
            icon: state.agreed
                ? Icons.favorite_rounded
                : Icons.touch_app_rounded,
            accent: state.agreed
                ? NabiPalette.greenPrimary
                : NabiPalette.calmBlue,
          ),
        ],
      ),
    );
  }
}

class _TeamStorySection extends StatelessWidget {
  const _TeamStorySection();

  static const _members = <_TeamMember>[
    _TeamMember(
      name: 'Lưu Hải Minh',
      role: 'Nhà sáng chế',
      assetPath: 'docs/note/19-08-2026/image_char/Lưu Hải Minh.jpg',
      story:
          'Đồng hành cùng dự án với niềm tin rằng sức khỏe cần một hệ sinh thái biết lắng nghe, nhắc nhở và cùng người dùng vun đắp những thói quen nhỏ mỗi ngày.',
    ),
    _TeamMember(
      name: 'Lê Quang Thành',
      role: 'Nhà sáng chế',
      assetPath: 'docs/note/19-08-2026/image_char/Lê Quang Thành.jpg',
      story:
          'Mang khát vọng đưa tri thức và công nghệ ứng dụng vào đời sống, góp phần giúp mỗi người chủ động chăm sóc sức khỏe hằng ngày thay vì chỉ quan tâm khi cơ thể đã lên tiếng.',
    ),
    _TeamMember(
      name: 'Thủy Tiên',
      role: 'Huấn luyện viên',
      assetPath: 'docs/note/19-08-2026/image_char/Thủy tiên.jpg',
      story:
          'Đồng hành từ kinh nghiệm chia sẻ về dinh dưỡng và chăm sóc sức khỏe chủ động, với mong muốn người dùng bớt hoang mang trước những lựa chọn chăm sóc cơ thể mỗi ngày.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final colors = context.semanticColors;
    return NabiGlassPanel(
      padding: const EdgeInsets.all(AppSpacing.cardPadding),
      elevated: false,
      borderColor: NabiPalette.calmBlue.withValues(alpha: 0.18),
      gradient: LinearGradient(
        colors: [
          NabiPalette.calmBlue.withValues(alpha: 0.08),
          colors.card,
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: NabiPalette.calmBlue.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: const Icon(
                  Icons.groups_2_rounded,
                  color: NabiPalette.calmBlue,
                  size: 22,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Những người đồng hành cùng NanoBio',
                      style: AppTextStyles.labelLarge.copyWith(
                        color: colors.textPrimary,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xxs),
                    Text(
                      'Ứng dụng không chỉ được xây dựng bởi công nghệ, mà bởi những con người cùng chung khát vọng giúp người Việt sống khỏe chủ động hơn mỗi ngày.',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: colors.textSecondary,
                        height: 1.45,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          for (var index = 0; index < _members.length; index++) ...[
            _TeamMemberCard(member: _members[index]),
            if (index != _members.length - 1)
              const SizedBox(height: AppSpacing.sm),
          ],
        ],
      ),
    );
  }
}

class _TeamMemberCard extends StatelessWidget {
  const _TeamMemberCard({required this.member});

  final _TeamMember member;

  @override
  Widget build(BuildContext context) {
    final colors = context.semanticColors;
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 380;
        final portrait = Semantics(
          image: true,
          label: 'Ảnh ${member.role} ${member.name}',
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.lg),
            child: Image.asset(
              member.assetPath,
              width: compact ? 74 : 84,
              height: compact ? 88 : 100,
              fit: BoxFit.cover,
              alignment: Alignment.topCenter,
              errorBuilder: (context, error, stackTrace) => Container(
                width: compact ? 74 : 84,
                height: compact ? 88 : 100,
                color: colors.primarySubtle,
                alignment: Alignment.center,
                child: const Icon(
                  Icons.person_rounded,
                  color: NabiPalette.calmBlue,
                  size: 34,
                ),
              ),
            ),
          ),
        );

        final details = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              member.name,
              style: AppTextStyles.labelLarge.copyWith(
                color: colors.textPrimary,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: AppSpacing.xxs),
            Text(
              member.role,
              style: AppTextStyles.labelSmall.copyWith(
                color: NabiPalette.calmBlue,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              member.story,
              style: AppTextStyles.bodySmall.copyWith(
                color: colors.textSecondary,
                height: 1.42,
              ),
            ),
          ],
        );

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(AppSpacing.sm),
          decoration: BoxDecoration(
            color: colors.surface.withValues(alpha: 0.72),
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(color: colors.border),
          ),
          child: compact
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    portrait,
                    const SizedBox(height: AppSpacing.sm),
                    details,
                  ],
                )
              : Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    portrait,
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(child: details),
                  ],
                ),
        );
      },
    );
  }
}

class _TeamMember {
  const _TeamMember({
    required this.name,
    required this.role,
    required this.assetPath,
    required this.story,
  });

  final String name;
  final String role;
  final String assetPath;
  final String story;
}

class _ConsentCard extends StatelessWidget {
  const _ConsentCard({
    required this.icon,
    required this.title,
    required this.text,
    required this.color,
  });

  final IconData icon;
  final String title;
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final colors = context.semanticColors;
    return NabiGlassPanel(
      padding: const EdgeInsets.all(AppSpacing.cardPadding),
      elevated: false,
      borderColor: color.withValues(alpha: 0.16),
      gradient: LinearGradient(
        colors: [color.withValues(alpha: 0.10), colors.card],
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTextStyles.labelLarge.copyWith(
                    color: colors.textPrimary,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: AppSpacing.xxs),
                Text(
                  text,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: colors.textSecondary,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
