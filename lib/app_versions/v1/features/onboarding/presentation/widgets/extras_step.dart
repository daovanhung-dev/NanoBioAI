import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:nano_app/core/theme/theme.dart';
import '../../providers/onboarding_provider.dart';
import 'onboarding_step_shell.dart';
import 'onboarding_text_field.dart';

class ExtrasStep extends ConsumerStatefulWidget {
  const ExtrasStep({super.key});

  @override
  ConsumerState<ExtrasStep> createState() => _ExtrasStepState();
}

class _ExtrasStepState extends ConsumerState<ExtrasStep> {
  static const List<_OptionItem> _allergyOptions = [
    _OptionItem(
      icon: AppIcons.success,
      title: 'Không có gì đặc biệt',
      subtitle: 'Hiện tại bạn chưa cần tránh món nào rõ ràng.',
      value: 'Không có gì đặc biệt',
      isExclusive: true,
    ),
    _OptionItem(
      icon: AppIcons.warning,
      title: 'Hải sản',
      subtitle: 'Tôm, cua, cá biển hoặc các món liên quan.',
      value: 'Hải sản',
    ),
    _OptionItem(
      icon: AppIcons.nutrition,
      title: 'Sữa / lactose',
      subtitle: 'Sữa, phô mai, kem hoặc sản phẩm từ sữa.',
      value: 'Sữa / lactose',
    ),
    _OptionItem(
      icon: AppIcons.food,
      title: 'Đậu phộng / các loại hạt',
      subtitle: 'Đậu phộng, hạnh nhân, óc chó...',
      value: 'Đậu phộng / các loại hạt',
    ),
    _OptionItem(
      icon: AppIcons.restaurant,
      title: 'Gluten / bột mì',
      subtitle: 'Bánh mì, mì sợi, thực phẩm chứa gluten.',
      value: 'Gluten / bột mì',
    ),
    _OptionItem(
      icon: AppIcons.meal,
      title: 'Trứng',
      subtitle: 'Trứng gà, trứng vịt hoặc món có trứng.',
      value: 'Trứng',
    ),
    _OptionItem(
      icon: AppIcons.fruits,
      title: 'Đậu nành',
      subtitle: 'Sữa đậu nành, đậu phụ, nước tương...',
      value: 'Đậu nành',
    ),
    _OptionItem(
      icon: AppIcons.warning,
      title: 'Món cay / nhiều dầu',
      subtitle: 'Các món dễ làm bạn khó chịu hoặc đầy bụng.',
      value: 'Món cay / nhiều dầu',
    ),
  ];

  static const List<_OptionItem> _treatmentOptions = [
    _OptionItem(
      icon: AppIcons.success,
      title: 'Không điều trị hiện tại',
      subtitle: 'Bạn chưa có phác đồ hoặc theo dõi y tế cố định.',
      value: 'Không điều trị hiện tại',
      isExclusive: true,
    ),
    _OptionItem(
      icon: AppIcons.heartRate,
      title: 'Theo dõi huyết áp',
      subtitle: 'Cần chú ý muối, nhịp sinh hoạt và vận động.',
      value: 'Theo dõi huyết áp',
    ),
    _OptionItem(
      icon: AppIcons.blood,
      title: 'Theo dõi đường huyết',
      subtitle: 'Cần cân bằng tinh bột, bữa ăn và giờ ăn.',
      value: 'Theo dõi đường huyết',
    ),
    _OptionItem(
      icon: AppIcons.nutrition,
      title: 'Dạ dày / tiêu hóa',
      subtitle: 'Dễ đầy bụng, đau dạ dày hoặc khó tiêu.',
      value: 'Dạ dày / tiêu hóa',
    ),
    _OptionItem(
      icon: AppIcons.health,
      title: 'Tim mạch',
      subtitle: 'Cần chăm sóc bền bỉ và theo dõi đều đặn.',
      value: 'Tim mạch',
    ),
    _OptionItem(
      icon: AppIcons.sleep,
      title: 'Giấc ngủ',
      subtitle: 'Mất ngủ, ngủ không sâu hoặc hay mệt mỏi.',
      value: 'Giấc ngủ',
    ),
    _OptionItem(
      icon: AppIcons.fitness,
      title: 'Cơ xương khớp',
      subtitle: 'Đau lưng, đau gối hoặc hạn chế vận động.',
      value: 'Cơ xương khớp',
    ),
  ];

  static const List<_OptionItem> _medicationOptions = [
    _OptionItem(
      icon: AppIcons.success,
      title: 'Không dùng thuốc thường xuyên',
      subtitle: 'Hiện tại bạn chưa có thuốc dùng cố định.',
      value: 'Không dùng thuốc thường xuyên',
      isExclusive: true,
    ),
    _OptionItem(
      icon: AppIcons.heartRate,
      title: 'Thuốc huyết áp',
      subtitle: 'Nami sẽ lưu ý hơn khi gợi ý thói quen hằng ngày.',
      value: 'Thuốc huyết áp',
    ),
    _OptionItem(
      icon: AppIcons.blood,
      title: 'Thuốc đường huyết',
      subtitle: 'Thông tin này giúp bữa ăn được cân nhắc kỹ hơn.',
      value: 'Thuốc đường huyết',
    ),
    _OptionItem(
      icon: AppIcons.nutrition,
      title: 'Thuốc dạ dày',
      subtitle: 'Cần chú ý món cay, chua hoặc quá nhiều dầu.',
      value: 'Thuốc dạ dày',
    ),
    _OptionItem(
      icon: AppIcons.favorite,
      title: 'Vitamin / khoáng chất',
      subtitle: 'Các sản phẩm bổ sung đang dùng hằng ngày.',
      value: 'Vitamin / khoáng chất',
    ),
    _OptionItem(
      icon: AppIcons.warning,
      title: 'Thuốc dị ứng',
      subtitle: 'Thông tin này giúp Nami thận trọng hơn.',
      value: 'Thuốc dị ứng',
    ),
    _OptionItem(
      icon: AppIcons.health,
      title: 'Thuốc giảm đau',
      subtitle: 'Dùng định kỳ hoặc khi có triệu chứng.',
      value: 'Thuốc giảm đau',
    ),
    _OptionItem(
      icon: AppIcons.sleep,
      title: 'Thuốc hỗ trợ ngủ',
      subtitle: 'Nami sẽ lưu ý hơn về lịch nghỉ ngơi.',
      value: 'Thuốc hỗ trợ ngủ',
    ),
  ];

  static const List<_OptionItem> _concernOptions = [
    _OptionItem(
      icon: AppIcons.stress,
      title: 'Căng thẳng',
      subtitle: 'Bạn đang thấy áp lực hoặc khó thả lỏng.',
      value: 'Căng thẳng',
    ),
    _OptionItem(
      icon: AppIcons.sleep,
      title: 'Ngủ chưa sâu',
      subtitle: 'Khó ngủ, thức giấc hoặc dậy vẫn mệt.',
      value: 'Ngủ chưa sâu',
    ),
    _OptionItem(
      icon: AppIcons.health,
      title: 'Thiếu năng lượng',
      subtitle: 'Dễ uể oải, khó tập trung hoặc nhanh mệt.',
      value: 'Thiếu năng lượng',
    ),
    _OptionItem(
      icon: AppIcons.nutrition,
      title: 'Ăn uống thất thường',
      subtitle: 'Bỏ bữa, ăn muộn hoặc khó duy trì bữa đều.',
      value: 'Ăn uống thất thường',
    ),
    _OptionItem(
      icon: AppIcons.weight,
      title: 'Kiểm soát cân nặng',
      subtitle: 'Bạn muốn giảm, tăng hoặc giữ cân lành mạnh.',
      value: 'Kiểm soát cân nặng',
    ),
    _OptionItem(
      icon: AppIcons.fitness,
      title: 'Ít vận động',
      subtitle: 'Bạn muốn bắt đầu nhẹ nhàng, không ép sức.',
      value: 'Ít vận động',
    ),
    _OptionItem(
      icon: AppIcons.water,
      title: 'Hay quên uống nước',
      subtitle: 'Nami có thể nhắc bạn chăm cơ thể đều hơn.',
      value: 'Hay quên uống nước',
    ),
    _OptionItem(
      icon: AppIcons.monitoring,
      title: 'Lo lắng chỉ số sức khỏe',
      subtitle: 'Bạn muốn theo dõi cơ thể kỹ hơn mỗi ngày.',
      value: 'Lo lắng chỉ số sức khỏe',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(onboardingProvider);
    final controller = ref.read(onboardingProvider.notifier);
    final completedFields = _calculateCompletedFields(state);

    return Stack(
      children: [
        const Positioned.fill(child: _SoftBackground()),
        Positioned.fill(
          child: OnboardingStepShell(
            stepIndex: 5,
            title: '',
            subtitle: '',
            isScrollable: false,
            onBack: controller.previousStep,
            onNext: controller.nextStep,
            child: LayoutBuilder(
              builder: (context, constraints) {
                final maxContentWidth = constraints.maxWidth >= 900
                    ? 820.0
                    : constraints.maxWidth;

                return SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: EdgeInsets.fromLTRB(
                    constraints.maxWidth >= 720
                        ? AppSpacing.pagePaddingLarge
                        : AppSpacing.pagePadding,
                    AppSpacing.sm,
                    constraints.maxWidth >= 720
                        ? AppSpacing.pagePaddingLarge
                        : AppSpacing.pagePadding,
                    AppSpacing.xxxl,
                  ),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(maxWidth: maxContentWidth),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _HeroSection(completedFields: completedFields),
                          const SizedBox(height: AppSpacing.xl),
                          _NamiStatusCard(completedFields: completedFields),
                          const SizedBox(height: AppSpacing.xl),
                          const _SectionHeader(
                            icon: AppIcons.warning,
                            title: 'Có món nào bạn muốn Nami lưu ý không?',
                            subtitle:
                                'Bạn có thể chọn nhanh trước. Nếu có điều gì rất riêng, cứ ghi thêm, Nami sẽ tôn trọng điều đó.',
                          ),
                          const SizedBox(height: AppSpacing.md),
                          _SurfaceCard(
                            child: Column(
                              children: [
                                _NamiChoiceField(
                                  icon: AppIcons.warning,
                                  label: 'Thực phẩm cần tránh',
                                  hint: 'Chọn dị ứng hoặc món bạn muốn hạn chế',
                                  value: state.allergyName,
                                  options: _allergyOptions,
                                  sheetTitle: 'Món nào Nami nên tránh cho bạn?',
                                  sheetSubtitle:
                                      'Chọn những mục phù hợp. Bạn vẫn có thể tự nhập nếu danh sách chưa đủ.',
                                  onChanged: controller.updateAllergyName,
                                ),
                                const SizedBox(height: AppSpacing.lg),
                                _FieldTile(
                                  icon: AppIcons.document,
                                  title: 'Nói thêm với Nami',
                                  subtitle:
                                      'Ví dụ mức độ dị ứng, món ăn từng làm bạn khó chịu, hoặc cách bạn muốn được nhắc.',
                                  child: OnboardingTextField(
                                    label: 'Ghi chú riêng',
                                    hint:
                                        'Ví dụ: Dị ứng nhẹ với tôm, vẫn ăn được cá; không hợp đồ quá cay...',
                                    maxLines: 3,
                                    initialValue: state.allergyNote,
                                    onChanged: controller.updateAllergyNote,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: AppSpacing.xl),
                          const _SectionHeader(
                            icon: AppIcons.health,
                            title: 'Hiện tại cơ thể bạn cần được chăm sóc gì?',
                            subtitle:
                                'Nami hỏi phần này để gợi ý nhẹ nhàng và an toàn hơn, không để bạn phải tự xoay xở một mình.',
                          ),
                          const SizedBox(height: AppSpacing.md),
                          _SurfaceCard(
                            child: Column(
                              children: [
                                _NamiChoiceField(
                                  icon: AppIcons.health,
                                  label: 'Tình trạng đang theo dõi',
                                  hint:
                                      'Chọn điều bạn đang điều trị hoặc quan tâm',
                                  value: state.treatmentName,
                                  options: _treatmentOptions,
                                  sheetTitle:
                                      'Bạn đang theo dõi điều gì gần đây?',
                                  sheetSubtitle:
                                      'Không cần chia sẻ quá nhiều nếu bạn chưa sẵn sàng. Chọn nhanh là đủ để Nami hiểu hơn.',
                                  onChanged: controller.updateTreatmentName,
                                ),
                                const SizedBox(height: AppSpacing.lg),
                                _NamiChoiceField(
                                  icon: AppIcons.nutrition,
                                  label: 'Thuốc / sản phẩm đang dùng',
                                  hint:
                                      'Chọn nhóm thuốc hoặc sản phẩm bổ sung nếu có',
                                  value: state.medicationName,
                                  options: _medicationOptions,
                                  sheetTitle:
                                      'Bạn đang dùng thuốc hoặc sản phẩm nào?',
                                  sheetSubtitle:
                                      'Thông tin này chỉ để Nami thận trọng hơn khi cá nhân hóa gợi ý chăm sóc.',
                                  onChanged: controller.updateMedicationName,
                                ),
                                const SizedBox(height: AppSpacing.lg),
                                _FieldTile(
                                  icon: AppIcons.edit,
                                  title: 'Ghi chú điều trị',
                                  subtitle:
                                      'Nếu bác sĩ có dặn gì quan trọng, bạn có thể ghi lại ở đây để Nami nhớ giúp.',
                                  child: OnboardingTextField(
                                    label: 'Thông tin bổ sung',
                                    hint:
                                        'Ví dụ: Tái khám định kỳ, hạn chế muối, không vận động quá sức...',
                                    maxLines: 4,
                                    initialValue: state.treatmentNote,
                                    onChanged: controller.updateTreatmentNote,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: AppSpacing.xl),
                          const _SectionHeader(
                            icon: AppIcons.stress,
                            title:
                                'Gần đây bạn muốn Nami quan tâm điều gì trước?',
                            subtitle:
                                'Không cần hoàn hảo ngay từ đầu. Mình sẽ cùng bạn điều chỉnh dần từng chút một.',
                          ),
                          const SizedBox(height: AppSpacing.md),
                          _SurfaceCard(
                            child: _NamiChoiceField(
                              icon: AppIcons.stress,
                              label: 'Mối quan tâm hiện tại',
                              hint: 'Chọn một vài điều đang làm bạn bận tâm',
                              value: state.concernText,
                              options: _concernOptions,
                              sheetTitle: 'Điều gì đang làm bạn bận tâm nhất?',
                              sheetSubtitle:
                                  'Bạn có thể chọn nhiều mục. Nếu muốn nói bằng lời của mình, hãy dùng phần tự nhập.',
                              onChanged: controller.updateConcernText,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.xl),
                          _CareNoteCard(completedFields: completedFields),
                          const SizedBox(height: AppSpacing.xl),
                          _SummaryCard(completedFields: completedFields),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  int _calculateCompletedFields(dynamic state) {
    int count = 0;

    if (state.allergyName.toString().trim().isNotEmpty) count++;
    if (state.allergyNote.toString().trim().isNotEmpty) count++;
    if (state.treatmentName.toString().trim().isNotEmpty) count++;
    if (state.medicationName.toString().trim().isNotEmpty) count++;
    if (state.treatmentNote.toString().trim().isNotEmpty) count++;
    if (state.concernText.toString().trim().isNotEmpty) count++;

    return count;
  }
}

class _SoftBackground extends StatelessWidget {
  const _SoftBackground();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(gradient: AppGradients.onboarding),
      child: Stack(
        children: [
          Positioned(
            top: -96,
            right: -72,
            child: _GlowCircle(size: 240, color: AppColors.primarySoft),
          ),
          Positioned(
            bottom: -120,
            left: -88,
            child: _GlowCircle(size: 300, color: AppColors.secondarySoft),
          ),
          Positioned(
            top: 220,
            left: -120,
            child: _GlowCircle(size: 220, color: AppColors.infoSoft),
          ),
        ],
      ),
    );
  }
}

class _GlowCircle extends StatelessWidget {
  const _GlowCircle({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: AppDecoration.circle(color: color.withOpacity(0.72)),
      ),
    );
  }
}

class _HeroSection extends StatelessWidget {
  const _HeroSection({required this.completedFields});

  final int completedFields;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: AppDecoration.premiumGradient(radius: AppRadius.xxl),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 420;

          final avatar = Container(
            width: compact ? 58 : 70,
            height: compact ? 58 : 70,
            decoration: AppDecoration.glass(
              radius: AppRadius.circular,
              opacity: 0.16,
            ),
            child: Icon(
              AppIcons.aiHealth,
              color: AppColors.textWhite,
              size: compact ? 28 : 34,
            ),
          );

          final badge = _HeroBadge(
            icon: AppIcons.shield,
            label: 'Riêng tư & tôn trọng',
          );

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: AppSpacing.md,
                runSpacing: AppSpacing.md,
                crossAxisAlignment: WrapCrossAlignment.center,
                alignment: WrapAlignment.spaceBetween,
                children: [avatar, badge],
              ),
              const SizedBox(height: AppSpacing.xl),
              Text(
                'Nami muốn hiểu bạn hơn một chút',
                style: AppTextStyles.displaySmall.copyWith(
                  color: AppColors.textWhite,
                  fontWeight: FontWeight.w800,
                  height: 1.08,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                'Những chia sẻ ở bước này giúp Nami chăm sóc bữa ăn, thói quen và lời nhắc của bạn tinh tế hơn. Bạn có thể chọn nhanh, bỏ qua điều chưa chắc, rồi chỉnh lại sau.',
                style: AppTextStyles.bodyLarge.copyWith(
                  color: AppColors.textWhite.withOpacity(0.92),
                  height: 1.65,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              _HeroInfoWrap(completedFields: completedFields),
            ],
          );
        },
      ),
    );
  }
}

class _HeroBadge extends StatelessWidget {
  const _HeroBadge({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: AppDecoration.glass(
        radius: AppRadius.circular,
        opacity: 0.14,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: AppColors.textWhite, size: 18),
          const SizedBox(width: AppSpacing.xs),
          Text(
            label,
            style: AppTextStyles.labelLarge.copyWith(
              color: AppColors.textWhite,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroInfoWrap extends StatelessWidget {
  const _HeroInfoWrap({required this.completedFields});

  final int completedFields;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const spacing = AppSpacing.md;
        final columns = constraints.maxWidth >= 520 ? 2 : 1;
        final itemWidth =
            ((constraints.maxWidth - spacing * (columns - 1)) / columns)
                .clamp(150.0, 360.0)
                .toDouble();

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: [
            SizedBox(
              width: itemWidth,
              child: _HeroInfo(
                icon: AppIcons.checkIn,
                title: 'Nami đã hiểu',
                value: '$completedFields nhóm thông tin',
              ),
            ),
            SizedBox(
              width: itemWidth,
              child: const _HeroInfo(
                icon: AppIcons.favorite,
                title: 'Nhịp độ',
                value: 'Nhẹ nhàng, không ép buộc',
              ),
            ),
          ],
        );
      },
    );
  }
}

class _HeroInfo extends StatelessWidget {
  const _HeroInfo({
    required this.icon,
    required this.title,
    required this.value,
  });

  final IconData icon;
  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: AppDecoration.glass(radius: AppRadius.lg, opacity: 0.12),
      child: Row(
        children: [
          Icon(icon, color: AppColors.textWhite, size: 22),
          const SizedBox(width: AppSpacing.sm),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textWhite.withOpacity(0.78),
                  ),
                ),
                const SizedBox(height: AppSpacing.xxs),
                Text(
                  value,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.labelLarge.copyWith(
                    color: AppColors.textWhite,
                    fontWeight: FontWeight.w800,
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

class _NamiStatusCard extends StatelessWidget {
  const _NamiStatusCard({required this.completedFields});

  final int completedFields;

  @override
  Widget build(BuildContext context) {
    final hasData = completedFields > 0;

    return _SurfaceCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: AppDecoration.primaryGradient(radius: AppRadius.lg),
            child: const Icon(
              AppIcons.ai,
              color: AppColors.textWhite,
              size: 28,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  hasData
                      ? 'Nami đã bắt đầu ghi nhớ điều quan trọng'
                      : 'Mình bắt đầu thật nhẹ thôi nhé',
                  style: AppTextStyles.heading4.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  hasData
                      ? 'Bạn đã chia sẻ $completedFields nhóm thông tin. Nami sẽ dùng chúng để gợi ý chăm sóc cá nhân hơn, không máy móc.'
                      : 'Bạn có thể chọn nhanh bằng các thẻ gợi ý bên dưới. Điều nào chưa chắc thì mình để sau cũng được.',
                  style: AppTextStyles.bodyMedium.copyWith(height: 1.6),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: AppSpacing.touchTargetMin,
          height: AppSpacing.touchTargetMin,
          decoration: AppDecoration.card(
            radius: AppRadius.lg,
            border: Border.all(color: AppColors.border.withOpacity(0.72)),
            shadows: AppShadows.xs,
            gradient: AppGradients.surface,
          ),
          child: Icon(icon, color: AppColors.primary, size: 24),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: AppTextStyles.heading3.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                subtitle,
                style: AppTextStyles.bodyMedium.copyWith(height: 1.6),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SurfaceCard extends StatelessWidget {
  const _SurfaceCard({required this.child, this.padding});

  final Widget child;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding ?? const EdgeInsets.all(AppSpacing.md),
      decoration: AppDecoration.card(
        radius: AppRadius.xl,
        border: Border.all(color: AppColors.border.withOpacity(0.72)),
        shadows: AppShadows.soft,
        gradient: AppGradients.surface,
      ),
      child: child,
    );
  }
}

class _FieldTile extends StatelessWidget {
  const _FieldTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.child,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 420;

        final iconBox = Container(
          width: compact ? 48 : 54,
          height: compact ? 48 : 54,
          decoration: AppDecoration.primaryGradient(radius: AppRadius.lg),
          child: Icon(
            icon,
            color: AppColors.textWhite,
            size: compact ? 22 : 24,
          ),
        );

        final content = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: AppTextStyles.labelLarge.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              subtitle,
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textSecondary,
                height: 1.5,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            child,
          ],
        );

        if (compact) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              iconBox,
              const SizedBox(height: AppSpacing.md),
              content,
            ],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            iconBox,
            const SizedBox(width: AppSpacing.md),
            Expanded(child: content),
          ],
        );
      },
    );
  }
}

class _NamiChoiceField extends StatelessWidget {
  const _NamiChoiceField({
    required this.icon,
    required this.label,
    required this.hint,
    required this.value,
    required this.options,
    required this.sheetTitle,
    required this.sheetSubtitle,
    required this.onChanged,
  });

  final IconData icon;
  final String label;
  final String hint;
  final String value;
  final List<_OptionItem> options;
  final String sheetTitle;
  final String sheetSubtitle;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final selectedValues = _parseValues(value);
    final hasValue = selectedValues.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTextStyles.labelLarge.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: AppSpacing.sm),
        Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(AppRadius.xl),
          child: InkWell(
            borderRadius: BorderRadius.circular(AppRadius.xl),
            onTap: () => _openPicker(context),
            child: AnimatedContainer(
              duration: AppDuration.normal,
              curve: AppAnimations.smoothCurve,
              width: double.infinity,
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.sm,
              ),
              decoration: AppDecoration.card(
                color: hasValue ? AppColors.primarySoft : AppColors.card,
                radius: AppRadius.xl,
                border: Border.all(
                  color: hasValue
                      ? AppColors.primary.withOpacity(0.42)
                      : AppColors.border,
                ),
                shadows: hasValue ? AppShadows.primary : AppShadows.xs,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _ChoiceFieldHeader(
                    icon: icon,
                    title: hasValue ? 'Nami đã ghi nhớ' : 'Chạm để chọn nhanh',
                    subtitle: hasValue
                        ? 'Bạn có thể sửa lại bất cứ lúc nào'
                        : hint,
                    selected: hasValue,
                  ),
                  if (hasValue) ...[
                    const SizedBox(height: AppSpacing.sm),
                    Wrap(
                      spacing: AppSpacing.sm,
                      runSpacing: AppSpacing.sm,
                      children: selectedValues.map((item) {
                        return _SelectedPill(
                          label: item,
                          onDeleted: () {
                            final nextValues = List<String>.from(selectedValues)
                              ..remove(item);
                            onChanged(nextValues.join(', '));
                          },
                        );
                      }).toList(),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _openPicker(BuildContext context) async {
    final result = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return _ChoiceBottomSheet(
          title: sheetTitle,
          subtitle: sheetSubtitle,
          currentValue: value,
          options: options,
        );
      },
    );

    if (result != null) {
      onChanged(result);
    }
  }
}

class _ChoiceFieldHeader extends StatelessWidget {
  const _ChoiceFieldHeader({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.selected,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        AnimatedContainer(
          duration: AppDuration.fast,
          curve: AppAnimations.smoothCurve,
          width: 40,
          height: 40,
          decoration: selected
              ? AppDecoration.primaryGradient(radius: AppRadius.lg)
              : AppDecoration.input(
                  color: AppColors.inputBackground,
                  radius: AppRadius.lg,
                  borderColor: AppColors.border,
                ),
          child: Icon(
            icon,
            color: selected ? AppColors.textWhite : AppColors.primary,
            size: 20,
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: AppTextStyles.labelLarge.copyWith(
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: AppSpacing.xxs),
              Text(
                subtitle,
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                  height: 1.45,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Icon(
          AppIcons.expand,
          color: selected ? AppColors.primary : AppColors.textHint,
        ),
      ],
    );
  }
}

class _ChoiceBottomSheet extends StatefulWidget {
  const _ChoiceBottomSheet({
    required this.title,
    required this.subtitle,
    required this.currentValue,
    required this.options,
  });

  final String title;
  final String subtitle;
  final String currentValue;
  final List<_OptionItem> options;

  @override
  State<_ChoiceBottomSheet> createState() => _ChoiceBottomSheetState();
}

class _ChoiceBottomSheetState extends State<_ChoiceBottomSheet> {
  late final TextEditingController _customController;
  late final Set<String> _selectedValues;

  @override
  void initState() {
    super.initState();

    final currentValues = _parseValues(widget.currentValue);
    final optionValues = widget.options.map((item) => item.value).toSet();

    _selectedValues = currentValues
        .where((item) => optionValues.contains(item))
        .toSet();

    final customValues = currentValues
        .where((item) => !optionValues.contains(item))
        .join(', ');

    _customController = TextEditingController(text: customValues);
  }

  @override
  void dispose() {
    _customController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return FractionallySizedBox(
      heightFactor: 0.9,
      child: AnimatedPadding(
        duration: AppDuration.fast,
        curve: AppAnimations.smoothCurve,
        padding: EdgeInsets.only(bottom: bottomInset),
        child: Container(
          decoration: AppDecoration.bottomSheet(),
          child: Column(
            children: [
              const SizedBox(height: AppSpacing.sm),
              Container(
                width: 48,
                height: 5,
                decoration: AppDecoration.container(
                  color: AppColors.border,
                  radius: AppRadius.circular,
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  AppSpacing.lg,
                  AppSpacing.lg,
                  AppSpacing.md,
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: AppDecoration.primaryGradient(
                        radius: AppRadius.lg,
                      ),
                      child: const Icon(
                        AppIcons.ai,
                        color: AppColors.textWhite,
                        size: 26,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.title,
                            style: AppTextStyles.heading3.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            widget.subtitle,
                            style: AppTextStyles.bodyMedium.copyWith(
                              height: 1.55,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(AppIcons.close),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.lg,
                    AppSpacing.sm,
                    AppSpacing.lg,
                    AppSpacing.lg,
                  ),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final columns = constraints.maxWidth >= 720
                          ? 3
                          : constraints.maxWidth >= 460
                          ? 2
                          : 1;
                      const spacing = AppSpacing.sm;
                      final itemWidth =
                          ((constraints.maxWidth - spacing * (columns - 1)) /
                                  columns)
                              .clamp(150.0, 280.0)
                              .toDouble();

                      return Wrap(
                        spacing: spacing,
                        runSpacing: spacing,
                        children: [
                          for (final option in widget.options)
                            SizedBox(
                              width: itemWidth,
                              child: _BottomSheetOptionTile(
                                option: option,
                                selected: _selectedValues.contains(
                                  option.value,
                                ),
                                onTap: () => _toggleOption(option),
                              ),
                            ),
                          SizedBox(
                            width: constraints.maxWidth,
                            child: _CustomInputBox(
                              controller: _customController,
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ),
              _BottomSheetActions(
                hasSelection:
                    _selectedValues.isNotEmpty ||
                    _customController.text.trim().isNotEmpty,
                onClear: () {
                  setState(() {
                    _selectedValues.clear();
                    _customController.clear();
                  });
                },
                onDone: () {
                  Navigator.of(context).pop(_composeValue());
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _toggleOption(_OptionItem option) {
    setState(() {
      if (option.isExclusive) {
        _selectedValues
          ..clear()
          ..add(option.value);
        return;
      }

      final exclusiveValues = widget.options
          .where((item) => item.isExclusive)
          .map((item) => item.value)
          .toSet();

      _selectedValues.removeWhere(exclusiveValues.contains);

      if (_selectedValues.contains(option.value)) {
        _selectedValues.remove(option.value);
      } else {
        _selectedValues.add(option.value);
      }
    });
  }

  String _composeValue() {
    final values = <String>[..._selectedValues];
    final customText = _customController.text.trim();

    if (customText.isNotEmpty) {
      values.addAll(_parseValues(customText));
    }

    return values
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toSet()
        .join(', ');
  }
}

class _BottomSheetOptionTile extends StatelessWidget {
  const _BottomSheetOptionTile({
    required this.option,
    required this.selected,
    required this.onTap,
  });

  final _OptionItem option;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AnimatedScale(
      scale: selected ? 0.98 : 1,
      duration: AppDuration.tap,
      curve: AppAnimations.smoothCurve,
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          child: AnimatedContainer(
            duration: AppDuration.fast,
            curve: AppAnimations.smoothCurve,
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            decoration: selected
                ? AppDecoration.card(
                    color: AppColors.primarySoft,
                    radius: AppRadius.lg,
                    border: Border.all(
                      color: AppColors.primary.withOpacity(0.5),
                      width: 1.4,
                    ),
                    shadows: AppShadows.primary,
                  )
                : AppDecoration.card(
                    color: AppColors.card,
                    radius: AppRadius.lg,
                    border: Border.all(color: AppColors.border),
                    shadows: AppShadows.xs,
                  ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: selected
                      ? AppDecoration.primaryGradient(radius: AppRadius.md)
                      : AppDecoration.input(
                          color: AppColors.inputBackground,
                          radius: AppRadius.md,
                          borderColor: AppColors.border,
                        ),
                  child: Icon(
                    option.icon,
                    color: selected ? AppColors.textWhite : AppColors.primary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        option.title,
                        style: AppTextStyles.labelLarge.copyWith(
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        option.subtitle,
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.textSecondary,
                          height: 1.45,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Icon(
                  selected ? AppIcons.success : AppIcons.add,
                  color: selected ? AppColors.primary : AppColors.textHint,
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CustomInputBox extends StatelessWidget {
  const _CustomInputBox({required this.controller});

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: AppSpacing.md),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: AppDecoration.card(
        color: AppColors.cardAlt,
        radius: AppRadius.lg,
        border: Border.all(color: AppColors.border),
        shadows: AppShadows.xs,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(AppIcons.edit, color: AppColors.primary, size: 20),
              const SizedBox(width: AppSpacing.xs),
              Text(
                'Khác / Tự nhập',
                style: AppTextStyles.labelLarge.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          TextField(
            controller: controller,
            minLines: 1,
            maxLines: 3,
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textPrimary,
            ),
            decoration: InputDecoration(
              hintText:
                  'Viết thêm điều Nami chưa liệt kê, cách nhau bằng dấu phẩy nếu có nhiều mục...',
              prefixIcon: const Icon(AppIcons.edit),
              filled: true,
              fillColor: AppColors.card,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.md,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadius.input),
                borderSide: const BorderSide(color: AppColors.border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadius.input),
                borderSide: const BorderSide(color: AppColors.border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadius.input),
                borderSide: const BorderSide(
                  color: AppColors.primary,
                  width: 1.5,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BottomSheetActions extends StatelessWidget {
  const _BottomSheetActions({
    required this.hasSelection,
    required this.onClear,
    required this.onDone,
  });

  final bool hasSelection;
  final VoidCallback onClear;
  final VoidCallback onDone;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.md,
        AppSpacing.lg,
        AppSpacing.lg,
      ),
      decoration: BoxDecoration(
        color: AppColors.card,
        border: Border(
          top: BorderSide(color: AppColors.border.withOpacity(0.72)),
        ),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 420;

          final clearButton = TextButton.icon(
            onPressed: hasSelection ? onClear : null,
            icon: const Icon(AppIcons.close),
            label: const Text('Bỏ chọn'),
          );

          final doneButton = ElevatedButton.icon(
            onPressed: onDone,
            icon: const Icon(AppIcons.success),
            label: const Text('Nami ghi nhớ'),
          );

          if (compact) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                doneButton,
                const SizedBox(height: AppSpacing.sm),
                clearButton,
              ],
            );
          }

          return Row(
            children: [
              clearButton,
              const Spacer(),
              ConstrainedBox(
                constraints: const BoxConstraints(minWidth: 180),
                child: doneButton,
              ),
            ],
          );
        },
      ),
    );
  }
}

class _SelectedPill extends StatelessWidget {
  const _SelectedPill({required this.label, this.onDeleted});

  final String label;
  final VoidCallback? onDeleted;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: AppDecoration.container(
        color: AppColors.card,
        radius: AppRadius.circular,
        border: Border.all(color: AppColors.primary.withOpacity(0.28)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(AppIcons.success, size: 16, color: AppColors.primary),
          const SizedBox(width: AppSpacing.xs),
          Flexible(
            child: Text(
              label,
              style: AppTextStyles.labelMedium.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          if (onDeleted != null) ...[
            const SizedBox(width: AppSpacing.xs),
            GestureDetector(
              onTap: onDeleted,
              child: const Icon(
                AppIcons.close,
                size: 16,
                color: AppColors.textHint,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _CareNoteCard extends StatelessWidget {
  const _CareNoteCard({required this.completedFields});

  final int completedFields;

  @override
  Widget build(BuildContext context) {
    final message = completedFields == 0
        ? 'Bạn chưa cần điền hết ngay. Chỉ cần chia sẻ điều quan trọng nhất, Nami sẽ cùng bạn hoàn thiện dần.'
        : 'Nami sẽ dùng những thông tin này để cá nhân hóa gợi ý. Khi có dấu hiệu bất thường, bạn vẫn nên ưu tiên lời khuyên từ bác sĩ.';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: AppDecoration.card(
        color: AppColors.infoSoft,
        radius: AppRadius.xl,
        border: Border.all(color: AppColors.info.withOpacity(0.22)),
        shadows: AppShadows.xs,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: AppSpacing.touchTargetMin,
            height: AppSpacing.touchTargetMin,
            decoration: AppDecoration.circle(
              color: AppColors.card.withOpacity(0.82),
            ),
            child: const Icon(AppIcons.info, color: AppColors.info),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Một lời nhắc nhỏ từ Nami',
                  style: AppTextStyles.labelLarge.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  message,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                    height: 1.6,
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

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.completedFields});

  final int completedFields;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: AppDecoration.premiumGradient(radius: AppRadius.xxl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 58,
                height: 58,
                decoration: AppDecoration.glass(
                  radius: AppRadius.lg,
                  opacity: 0.14,
                ),
                child: const Icon(
                  AppIcons.favorite,
                  color: AppColors.textWhite,
                  size: 28,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Nami đã gần hiểu đủ để bắt đầu',
                      style: AppTextStyles.heading3.copyWith(
                        color: AppColors.textWhite,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xxs),
                    Text(
                      'Bước tiếp theo sẽ nhẹ nhàng hơn vì mình đã có ngữ cảnh về bạn.',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.textWhite.withOpacity(0.84),
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          _SummaryRows(completedFields: completedFields),
        ],
      ),
    );
  }
}

class _SummaryRows extends StatelessWidget {
  const _SummaryRows({required this.completedFields});

  final int completedFields;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const spacing = AppSpacing.sm;
        final columns = constraints.maxWidth >= 620 ? 2 : 1;
        final itemWidth =
            ((constraints.maxWidth - spacing * (columns - 1)) / columns)
                .clamp(150.0, 280.0)
                .toDouble();

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: [
            SizedBox(
              width: itemWidth,
              child: _SummaryItem(
                icon: AppIcons.checkIn,
                title: 'Đã chia sẻ',
                value: '$completedFields mục',
              ),
            ),
            SizedBox(
              width: itemWidth,
              child: const _SummaryItem(
                icon: AppIcons.aiChat,
                title: 'Trợ lý',
                value: 'Nami sẵn sàng',
              ),
            ),
          ],
        );
      },
    );
  }
}

class _SummaryItem extends StatelessWidget {
  const _SummaryItem({
    required this.icon,
    required this.title,
    required this.value,
  });

  final IconData icon;
  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: AppDecoration.glass(radius: AppRadius.lg, opacity: 0.1),
      child: Row(
        children: [
          Icon(icon, color: AppColors.textWhite, size: 20),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textWhite.withOpacity(0.74),
                  ),
                ),
                const SizedBox(height: AppSpacing.xxs),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.labelLarge.copyWith(
                    color: AppColors.textWhite,
                    fontWeight: FontWeight.w800,
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

class _OptionItem {
  const _OptionItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    this.isExclusive = false,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String value;
  final bool isExclusive;
}

List<String> _parseValues(String value) {
  return value
      .split(RegExp(r'[,;]'))
      .map((item) => item.trim())
      .where((item) => item.isNotEmpty)
      .toList();
}
