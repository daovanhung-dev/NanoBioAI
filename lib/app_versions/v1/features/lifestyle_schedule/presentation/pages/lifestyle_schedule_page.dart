import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nano_app/core/theme/design_system.dart';
import 'package:nano_app/core/theme/medical_ui.dart';

import '../../domain/entities/lifestyle_schedule_item_entity.dart';
import '../../providers/lifestyle_schedule_provider.dart';
import '../controllers/lifestyle_schedule_state.dart';

class LifestyleSchedulePage extends ConsumerWidget {
  const LifestyleSchedulePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheduleAsync = ref.watch(lifestyleScheduleControllerProvider);

    return MedicalPageScaffold(
      ambientBackground: false,
      backgroundColor: _SchedulePalette.background(context),
      body: scheduleAsync.when(
        loading: () => const _SchedulePageFrame(child: _ScheduleLoadingState()),
        error: (error, _) => _SchedulePageFrame(
          child: _ScheduleErrorState(
            message:
                'Nabi chưa mở được lịch trình. Bạn thử tải lại giúp Nabi nhé.',
            onRetry: () => ref
                .read(lifestyleScheduleControllerProvider.notifier)
                .refresh(),
          ),
        ),
        data: (state) => _SchedulePageFrame(
          child: RefreshIndicator(
            onRefresh: () => ref
                .read(lifestyleScheduleControllerProvider.notifier)
                .refresh(),
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(
                parent: BouncingScrollPhysics(),
              ),
              slivers: [
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacingTokens.pagePadding,
                    AppSpacingTokens.sectionSpacing,
                    AppSpacingTokens.pagePadding,
                    _ScheduleUi.bottomSafeSpace,
                  ),
                  sliver: SliverToBoxAdapter(
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(
                          maxWidth: _ScheduleUi.maxContentWidth,
                        ),
                        child: _ScheduleContent(state: state),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ScheduleContent extends StatelessWidget {
  final LifestyleScheduleState state;

  const _ScheduleContent({required this.state});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _NamiHero(state: state),
        const SizedBox(height: AppSpacingTokens.sectionSpacing),
        _ProgressCard(state: state),
        if (state.lastEncouragement != null) ...[
          const SizedBox(height: AppSpacingTokens.itemSpacingLarge),
          _EncouragementBanner(message: state.lastEncouragement!),
        ],
        const SizedBox(height: AppSpacingTokens.sectionSpacing),
        _DateSection(state: state),
        const SizedBox(height: AppSpacingTokens.sectionSpacing),
        _Timeline(items: state.selectedItems),
      ],
    );
  }
}

class _SchedulePageFrame extends StatelessWidget {
  final Widget child;

  const _SchedulePageFrame({required this.child});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        const Positioned.fill(child: _DecorativeBackground()),
        SafeArea(child: child),
      ],
    );
  }
}

class _DecorativeBackground extends StatelessWidget {
  const _DecorativeBackground();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            _SchedulePalette.background(context),
            isDark
                ? AppColorTokens.darkSurfaceElevated
                : AppColorTokens.primaryLight,
            _SchedulePalette.background(context),
          ],
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            top: -_ScheduleUi.orbLargeOffset,
            right: -_ScheduleUi.orbMediumOffset,
            child: _SoftOrb(
              size: _ScheduleUi.orbLargeSize,
              color: AppColorTokens.primary,
            ),
          ),
          Positioned(
            top: _ScheduleUi.orbTopOffset,
            left: -_ScheduleUi.orbSmallOffset,
            child: _SoftOrb(
              size: _ScheduleUi.orbMediumSize,
              color: AppColorTokens.secondary,
            ),
          ),
          Positioned(
            bottom: _ScheduleUi.orbBottomOffset,
            right: -_ScheduleUi.orbSmallOffset,
            child: _SoftOrb(
              size: _ScheduleUi.orbMediumSize,
              color: AppColorTokens.tertiary,
            ),
          ),
        ],
      ),
    );
  }
}

class _SoftOrb extends StatelessWidget {
  final double size;
  final Color color;

  const _SoftOrb({required this.size, required this.color});

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color.withValues(alpha: _ScheduleUi.orbOpacity),
        ),
        child: BackdropFilter(
          filter: ImageFilter.blur(
            sigmaX: _ScheduleUi.orbBlur,
            sigmaY: _ScheduleUi.orbBlur,
          ),
          child: const SizedBox.expand(),
        ),
      ),
    );
  }
}

class _NamiHero extends StatelessWidget {
  final LifestyleScheduleState state;

  const _NamiHero({required this.state});

  @override
  Widget build(BuildContext context) {
    final progress = _progressValue(state);
    final title = state.isSelectedToday
        ? 'Nabi ở đây, mình cùng chăm sóc hôm nay nhé'
        : 'Nabi đã chuẩn bị lịch trình cho ngày này';

    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadiusTokens.dialog),
      child: BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: _ScheduleUi.glassBlur,
          sigmaY: _ScheduleUi.glassBlur,
        ),
        child: Container(
          padding: const EdgeInsets.all(AppSpacingTokens.cardPadding),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadiusTokens.dialog),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColorTokens.primary,
                AppColorTokens.secondary,
                AppColorTokens.tertiary,
              ],
            ),
            boxShadow: AppShadowTokens.cardElevated,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _NamiAvatar(progress: progress),
                  const SizedBox(width: AppSpacingTokens.itemSpacingLarge),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: AppTextStyles.heading1.copyWith(
                            color: AppColorTokens.textInverse,
                          ),
                        ),
                        const SizedBox(height: AppSpacingTokens.itemSpacing),
                        Text(
                          '${state.summary.fullName} • ${_formatDate(state.selectedDate)}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: AppColorTokens.textInverse.withValues(
                              alpha: _ScheduleUi.strongTextOpacity,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacingTokens.cardPadding),
              _NamiMessage(score: state.score, completed: state.completedItems),
              const SizedBox(height: AppSpacingTokens.cardPadding),
              Wrap(
                spacing: AppSpacingTokens.itemSpacing,
                runSpacing: AppSpacingTokens.itemSpacing,
                children: [
                  _HeroPill(
                    icon: Icons.auto_awesome_rounded,
                    label: 'Nabi đồng hành',
                    value: '${state.score.round()} điểm',
                  ),
                  _HeroPill(
                    icon: Icons.task_alt_rounded,
                    label: 'Đã xong',
                    value: '${state.completedItems}/${state.totalItems}',
                  ),
                  _HeroPill(
                    icon: Icons.favorite_rounded,
                    label: 'Nhịp chăm sóc',
                    value: state.isSelectedToday ? 'Hôm nay' : 'Cá nhân',
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NamiAvatar extends StatelessWidget {
  final double progress;

  const _NamiAvatar({required this.progress});

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        SizedBox(
          width: _ScheduleUi.namiAvatarOuterSize,
          height: _ScheduleUi.namiAvatarOuterSize,
          child: CircularProgressIndicator(
            value: progress,
            strokeWidth: _ScheduleUi.progressStroke,
            backgroundColor: AppColorTokens.textInverse.withValues(
              alpha: _ScheduleUi.softTextOpacity,
            ),
            valueColor: AlwaysStoppedAnimation<Color>(
              AppColorTokens.textInverse,
            ),
          ),
        ),
        Container(
          width: _ScheduleUi.namiAvatarInnerSize,
          height: _ScheduleUi.namiAvatarInnerSize,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColorTokens.textInverse.withValues(
              alpha: _ScheduleUi.glassSurfaceOpacity,
            ),
            border: Border.all(
              color: AppColorTokens.textInverse.withValues(
                alpha: _ScheduleUi.glassBorderOpacity,
              ),
            ),
          ),
          child: Icon(
            Icons.spa_rounded,
            color: AppColorTokens.textInverse,
            size: _ScheduleUi.heroIconSize,
          ),
        ),
      ],
    );
  }
}

class _NamiMessage extends StatelessWidget {
  final num score;
  final int completed;

  const _NamiMessage({required this.score, required this.completed});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacingTokens.cardPadding),
      decoration: BoxDecoration(
        color: AppColorTokens.textInverse.withValues(
          alpha: _ScheduleUi.glassSurfaceOpacity,
        ),
        borderRadius: BorderRadius.circular(AppRadiusTokens.card),
        border: Border.all(
          color: AppColorTokens.textInverse.withValues(
            alpha: _ScheduleUi.glassBorderOpacity,
          ),
        ),
      ),
      child: Text(
        _namiCopy(score: score, completed: completed),
        style: AppTextStyles.bodyMedium.copyWith(
          color: AppColorTokens.textInverse,
          height: _ScheduleUi.relaxedLineHeight,
        ),
      ),
    );
  }
}

class _HeroPill extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _HeroPill({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacingTokens.itemSpacingLarge,
        vertical: AppSpacingTokens.itemSpacing,
      ),
      decoration: BoxDecoration(
        color: AppColorTokens.textInverse.withValues(
          alpha: _ScheduleUi.glassSurfaceOpacity,
        ),
        borderRadius: BorderRadius.circular(AppRadiusTokens.badge),
        border: Border.all(
          color: AppColorTokens.textInverse.withValues(
            alpha: _ScheduleUi.glassBorderOpacity,
          ),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: AppColorTokens.textInverse,
            size: _ScheduleUi.pillIconSize,
          ),
          const SizedBox(width: AppSpacingTokens.itemSpacing),
          Text(
            '$label • $value',
            style: AppTextStyles.labelMedium.copyWith(
              color: AppColorTokens.textInverse,
            ),
          ),
        ],
      ),
    );
  }
}

class _ProgressCard extends StatelessWidget {
  final LifestyleScheduleState state;

  const _ProgressCard({required this.state});

  @override
  Widget build(BuildContext context) {
    final progress = _progressValue(state);

    return AppCard(
      variant: CardVariant.elevated,
      padding: const EdgeInsets.all(AppSpacingTokens.cardPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _SoftIconBadge(
                icon: Icons.insights_rounded,
                color: AppColorTokens.primary,
              ),
              const SizedBox(width: AppSpacingTokens.itemSpacingLarge),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Nhịp chăm sóc trong ngày',
                      style: AppTextStyles.heading2.copyWith(
                        color: _SchedulePalette.textPrimary(context),
                      ),
                    ),
                    const SizedBox(height: AppSpacingTokens.itemSpacing),
                    Text(
                      'Nabi sẽ nhẹ nhàng nhắc bạn từng bước, không vội vàng.',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: _SchedulePalette.textSecondary(context),
                      ),
                    ),
                  ],
                ),
              ),
              _ScoreBadge(score: state.score),
            ],
          ),
          const SizedBox(height: AppSpacingTokens.cardPadding),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadiusTokens.badge),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: _ScheduleUi.progressBarHeight,
              backgroundColor: AppColorTokens.primaryLight,
              valueColor: AlwaysStoppedAnimation<Color>(
                progress >= _ScheduleUi.completeProgress
                    ? AppColorTokens.success
                    : AppColorTokens.primary,
              ),
            ),
          ),
          const SizedBox(height: AppSpacingTokens.itemSpacingLarge),
          Row(
            children: [
              Expanded(
                child: _MiniMetric(
                  icon: Icons.check_circle_rounded,
                  color: AppColorTokens.success,
                  label: 'Hoàn thành',
                  value: '${state.completedItems}',
                ),
              ),
              const SizedBox(width: AppSpacingTokens.itemSpacing),
              Expanded(
                child: _MiniMetric(
                  icon: Icons.pending_actions_rounded,
                  color: AppColorTokens.warning,
                  label: 'Còn lại',
                  value: '${_remainingItems(state)}',
                ),
              ),
              const SizedBox(width: AppSpacingTokens.itemSpacing),
              Expanded(
                child: _MiniMetric(
                  icon: Icons.calendar_month_rounded,
                  color: AppColorTokens.info,
                  label: 'Tổng mục',
                  value: '${state.totalItems}',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ScoreBadge extends StatelessWidget {
  final num score;

  const _ScoreBadge({required this.score});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacingTokens.itemSpacingLarge,
        vertical: AppSpacingTokens.itemSpacing,
      ),
      decoration: BoxDecoration(
        color: AppColorTokens.primaryLight,
        borderRadius: BorderRadius.circular(AppRadiusTokens.badge),
      ),
      child: Text(
        '${score.round()}%',
        style: AppTextStyles.labelLarge.copyWith(color: AppColorTokens.primary),
      ),
    );
  }
}

class _MiniMetric extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final String value;

  const _MiniMetric({
    required this.icon,
    required this.color,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacingTokens.cardPadding),
      decoration: BoxDecoration(
        color: color.withValues(alpha: _ScheduleUi.softSurfaceOpacity),
        borderRadius: BorderRadius.circular(AppRadiusTokens.card),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: _ScheduleUi.metricIconSize),
          const SizedBox(height: AppSpacingTokens.itemSpacing),
          Text(
            value,
            style: AppTextStyles.heading2.copyWith(
              color: _SchedulePalette.textPrimary(context),
            ),
          ),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.caption.copyWith(
              color: _SchedulePalette.textMuted(context),
            ),
          ),
        ],
      ),
    );
  }
}

class _EncouragementBanner extends ConsumerWidget {
  final String message;

  const _EncouragementBanner({required this.message});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AnimatedContainer(
      duration: AppMotionTokens.card,
      curve: AppMotionTokens.defaultCurve,
      padding: const EdgeInsets.all(AppSpacingTokens.cardPadding),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColorTokens.successLight, AppColorTokens.infoLight],
        ),
        borderRadius: BorderRadius.circular(AppRadiusTokens.card),
        border: Border.all(
          color: AppColorTokens.success.withValues(
            alpha: _ScheduleUi.borderOpacity,
          ),
        ),
      ),
      child: Row(
        children: [
          _SoftIconBadge(
            icon: Icons.favorite_rounded,
            color: AppColorTokens.success,
          ),
          const SizedBox(width: AppSpacingTokens.itemSpacingLarge),
          Expanded(
            child: Text(
              'Nabi: $message',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColorTokens.textPrimary,
                height: _ScheduleUi.normalLineHeight,
              ),
            ),
          ),
          Semantics(
            label: 'Đóng lời nhắn của Nabi',
            button: true,
            child: IconButton(
              onPressed: () => ref
                  .read(lifestyleScheduleControllerProvider.notifier)
                  .dismissEncouragement(),
              icon: Icon(
                Icons.close_rounded,
                color: AppColorTokens.textSecondary,
              ),
              tooltip: 'Đóng',
            ),
          ),
        ],
      ),
    );
  }
}

class _DateSection extends StatelessWidget {
  final LifestyleScheduleState state;

  const _DateSection({required this.state});

  @override
  Widget build(BuildContext context) {
    if (state.availableDates.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          title: 'Chọn ngày đồng hành',
          subtitle:
              'Nabi gom các nhịp ăn uống, vận động và nghỉ ngơi theo từng ngày.',
        ),
        const SizedBox(height: AppSpacingTokens.itemSpacingLarge),
        _DateSelector(state: state),
      ],
    );
  }
}

class _DateSelector extends ConsumerWidget {
  final LifestyleScheduleState state;

  const _DateSelector({required this.state});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SizedBox(
      height: _ScheduleUi.dateSelectorHeight,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: state.availableDates.length,
        separatorBuilder: (_, __) =>
            const SizedBox(width: AppSpacingTokens.itemSpacing),
        itemBuilder: (context, index) {
          final date = state.availableDates[index];
          final selected = DateUtils.isSameDay(date, state.selectedDate);
          final isToday = DateUtils.isSameDay(date, DateTime.now());

          return _DateChip(
            date: date,
            selected: selected,
            isToday: isToday,
            onTap: () => ref
                .read(lifestyleScheduleControllerProvider.notifier)
                .selectDate(date),
          );
        },
      ),
    );
  }
}

class _DateChip extends StatelessWidget {
  final DateTime date;
  final bool selected;
  final bool isToday;
  final VoidCallback onTap;

  const _DateChip({
    required this.date,
    required this.selected,
    required this.isToday,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final foreground = selected
        ? AppColorTokens.textInverse
        : _SchedulePalette.textPrimary(context);

    return Semantics(
      label: 'Chọn ${_formatDate(date)}',
      selected: selected,
      button: true,
      child: AnimatedScale(
        scale: selected ? _ScheduleUi.selectedScale : _ScheduleUi.normalScale,
        duration: AppMotionTokens.button,
        curve: AppMotionTokens.defaultCurve,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(AppRadiusTokens.card),
            child: AnimatedContainer(
              duration: AppMotionTokens.card,
              curve: AppMotionTokens.defaultCurve,
              width: _ScheduleUi.dateChipWidth,
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacingTokens.itemSpacing,
                vertical: AppSpacingTokens.itemSpacingLarge,
              ),
              decoration: BoxDecoration(
                gradient: selected
                    ? LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          AppColorTokens.primary,
                          AppColorTokens.tertiary,
                        ],
                      )
                    : null,
                color: selected ? null : _SchedulePalette.surface(context),
                borderRadius: BorderRadius.circular(AppRadiusTokens.card),
                border: Border.all(
                  color: selected
                      ? AppColorTokens.primary
                      : _SchedulePalette.border(context),
                ),
                boxShadow: selected
                    ? AppShadowTokens.cardElevated
                    : AppShadowTokens.card,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _weekday(date),
                    style: AppTextStyles.labelMedium.copyWith(
                      color: selected
                          ? AppColorTokens.textInverse.withValues(
                              alpha: _ScheduleUi.strongTextOpacity,
                            )
                          : _SchedulePalette.textMuted(context),
                    ),
                  ),
                  const SizedBox(height: AppSpacingTokens.itemSpacing),
                  Text(
                    '${date.day}',
                    style: AppTextStyles.heading2.copyWith(color: foreground),
                  ),
                  const SizedBox(height: AppSpacingTokens.itemSpacing),
                  AnimatedContainer(
                    duration: AppMotionTokens.button,
                    width: _ScheduleUi.todayDotSize,
                    height: _ScheduleUi.todayDotSize,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isToday
                          ? (selected
                                ? AppColorTokens.textInverse
                                : AppColorTokens.success)
                          : Colors.transparent,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Timeline extends StatelessWidget {
  final List<LifestyleScheduleItemEntity> items;

  const _Timeline({required this.items});

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return EmptyState(
        icon: Icons.hourglass_empty_rounded,
        title: 'Ngày này đang thật nhẹ nhàng',
        description:
            'Nabi chưa thấy lịch trình nào. Bạn có thể kéo xuống để làm mới dữ liệu.',
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          title: 'Dòng chảy trong ngày',
          subtitle:
              'Mỗi thẻ là một nhịp nhỏ Nabi đã sắp sẵn để bạn chăm sóc cơ thể dễ hơn.',
        ),
        const SizedBox(height: AppSpacingTokens.itemSpacingLarge),
        ...List.generate(items.length, (index) {
          final item = items[index];
          final meta = _ScheduleMeta.from(item.category, item.sourceType);

          return Padding(
            padding: EdgeInsets.only(
              bottom: index == items.length - 1
                  ? 0
                  : AppSpacingTokens.itemSpacingLarge,
            ),
            child: _TimelineRow(
              item: item,
              meta: meta,
              isLast: index == items.length - 1,
            ),
          );
        }),
      ],
    );
  }
}

class _TimelineRow extends ConsumerWidget {
  final LifestyleScheduleItemEntity item;
  final _ScheduleMeta meta;
  final bool isLast;

  const _TimelineRow({
    required this.item,
    required this.meta,
    required this.isLast,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final now = DateTime.now();
    final status = item.completionStatusAt(now);
    final canToggle = item.isWithinCompletionWindow(now);

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _TimelineRail(
            meta: meta,
            isCompleted: item.isCompleted,
            isLast: isLast,
          ),
          const SizedBox(width: AppSpacingTokens.itemSpacingLarge),
          Expanded(
            child: _ScheduleItemCard(
              item: item,
              meta: meta,
              status: status,
              canToggle: canToggle,
              onToggle: canToggle
                  ? () => ref
                        .read(lifestyleScheduleControllerProvider.notifier)
                        .toggleItem(item)
                  : null,
            ),
          ),
        ],
      ),
    );
  }
}

class _TimelineRail extends StatelessWidget {
  final _ScheduleMeta meta;
  final bool isCompleted;
  final bool isLast;

  const _TimelineRail({
    required this.meta,
    required this.isCompleted,
    required this.isLast,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: _ScheduleUi.railWidth,
      child: Column(
        children: [
          AnimatedContainer(
            duration: AppMotionTokens.button,
            curve: AppMotionTokens.defaultCurve,
            width: _ScheduleUi.railDotSize,
            height: _ScheduleUi.railDotSize,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isCompleted ? AppColorTokens.success : meta.color,
              boxShadow: [
                BoxShadow(
                  color: meta.color.withValues(
                    alpha: _ScheduleUi.shadowOpacity,
                  ),
                  blurRadius: _ScheduleUi.railGlowBlur,
                  offset: const Offset(0, AppSpacingTokens.itemSpacing),
                ),
              ],
            ),
            child: Icon(
              isCompleted ? Icons.check_rounded : meta.icon,
              color: AppColorTokens.textInverse,
              size: _ScheduleUi.railIconSize,
            ),
          ),
          if (!isLast)
            Expanded(
              child: Container(
                width: _ScheduleUi.railLineWidth,
                margin: const EdgeInsets.symmetric(
                  vertical: AppSpacingTokens.itemSpacing,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(AppRadiusTokens.badge),
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      meta.color.withValues(alpha: _ScheduleUi.borderOpacity),
                      meta.color.withValues(
                        alpha: _ScheduleUi.softSurfaceOpacity,
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _ScheduleItemCard extends StatelessWidget {
  final LifestyleScheduleItemEntity item;
  final _ScheduleMeta meta;
  final CompletionWindowStatus status;
  final bool canToggle;
  final VoidCallback? onToggle;

  const _ScheduleItemCard({
    required this.item,
    required this.meta,
    required this.status,
    required this.canToggle,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final titleColor = item.isCompleted
        ? _SchedulePalette.textMuted(context)
        : _SchedulePalette.textPrimary(context);

    return AppCard(
      variant: item.isCompleted
          ? CardVariant.outlined
          : CardVariant.defaultCard,
      padding: EdgeInsets.zero,
      onTap: onToggle,
      child: AnimatedContainer(
        duration: AppMotionTokens.card,
        curve: AppMotionTokens.defaultCurve,
        padding: const EdgeInsets.all(AppSpacingTokens.cardPadding),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppRadiusTokens.card),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              meta.color.withValues(
                alpha: item.isCompleted
                    ? _ScheduleUi.completedTintOpacity
                    : _ScheduleUi.softSurfaceOpacity,
              ),
              _SchedulePalette.surface(context),
            ],
          ),
          border: Border.all(
            color: item.isCompleted
                ? AppColorTokens.success.withValues(
                    alpha: _ScheduleUi.borderOpacity,
                  )
                : meta.color.withValues(alpha: _ScheduleUi.softBorderOpacity),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _TimeBlock(item: item, color: meta.color),
                const SizedBox(width: AppSpacingTokens.itemSpacingLarge),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        spacing: AppSpacingTokens.itemSpacing,
                        runSpacing: AppSpacingTokens.itemSpacing,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          _CategoryPill(meta: meta),
                          if (status == CompletionWindowStatus.waiting)
                            const _WaitingPill(),
                          if (status == CompletionWindowStatus.open)
                            const _OpenPill(),
                          if (status == CompletionWindowStatus.locked)
                            const _LockedPill(),
                          if (status == CompletionWindowStatus.completed)
                            const _DonePill(),
                        ],
                      ),
                      const SizedBox(height: AppSpacingTokens.itemSpacing),
                      Text(
                        item.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.labelLarge.copyWith(
                          color: titleColor,
                          decoration: item.isCompleted
                              ? TextDecoration.lineThrough
                              : null,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacingTokens.itemSpacing),
                _CompletionButton(
                  color: meta.color,
                  checked: item.isCompleted,
                  enabled: canToggle,
                  onTap: onToggle,
                ),
              ],
            ),
            if (item.description.isNotEmpty) ...[
              const SizedBox(height: AppSpacingTokens.itemSpacingLarge),
              Text(
                item.description,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: _SchedulePalette.textSecondary(context),
                  height: _ScheduleUi.relaxedLineHeight,
                ),
              ),
            ],
            if (!canToggle && !item.isCompleted) ...[
              const SizedBox(height: AppSpacingTokens.itemSpacingLarge),
              _NamiHint(
                icon: Icons.schedule_rounded,
                color: AppColorTokens.warning,
                text:
                    'Nabi để mục này chờ đúng giờ rồi mình đánh dấu nhé, bạn không cần vội.',
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _TimeBlock extends StatelessWidget {
  final LifestyleScheduleItemEntity item;
  final Color color;

  const _TimeBlock({required this.item, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: _ScheduleUi.timeBlockWidth,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacingTokens.itemSpacing,
        vertical: AppSpacingTokens.itemSpacing,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: _ScheduleUi.softSurfaceOpacity),
        borderRadius: BorderRadius.circular(AppRadiusTokens.input),
      ),
      child: Column(
        children: [
          Text(
            item.startTime,
            textAlign: TextAlign.center,
            style: AppTextStyles.labelLarge.copyWith(color: color),
          ),
          if (item.endTime.isNotEmpty) ...[
            const SizedBox(height: AppSpacingTokens.itemSpacing),
            Text(
              item.endTime,
              textAlign: TextAlign.center,
              style: AppTextStyles.caption.copyWith(
                color: _SchedulePalette.textMuted(context),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _CategoryPill extends StatelessWidget {
  final _ScheduleMeta meta;

  const _CategoryPill({required this.meta});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacingTokens.itemSpacing,
        vertical: AppSpacingTokens.itemSpacing,
      ),
      decoration: BoxDecoration(
        color: meta.color.withValues(alpha: _ScheduleUi.softSurfaceOpacity),
        borderRadius: BorderRadius.circular(AppRadiusTokens.badge),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(meta.icon, color: meta.color, size: _ScheduleUi.inlineIconSize),
          const SizedBox(width: AppSpacingTokens.itemSpacing),
          Text(
            meta.label,
            style: AppTextStyles.labelMedium.copyWith(color: meta.color),
          ),
        ],
      ),
    );
  }
}

class _WaitingPill extends StatelessWidget {
  const _WaitingPill();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacingTokens.itemSpacing,
        vertical: AppSpacingTokens.itemSpacing,
      ),
      decoration: BoxDecoration(
        color: AppColorTokens.warningLight,
        borderRadius: BorderRadius.circular(AppRadiusTokens.badge),
      ),
      child: Text(
        'Chờ đúng giờ',
        style: AppTextStyles.labelMedium.copyWith(
          color: AppColorTokens.warning,
        ),
      ),
    );
  }
}

class _OpenPill extends StatelessWidget {
  const _OpenPill();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacingTokens.itemSpacing,
        vertical: AppSpacingTokens.itemSpacing,
      ),
      decoration: BoxDecoration(
        color: AppColorTokens.successLight,
        borderRadius: BorderRadius.circular(AppRadiusTokens.badge),
      ),
      child: Text(
        'Dang mo',
        style: AppTextStyles.labelMedium.copyWith(
          color: AppColorTokens.success,
        ),
      ),
    );
  }
}

class _LockedPill extends StatelessWidget {
  const _LockedPill();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacingTokens.itemSpacing,
        vertical: AppSpacingTokens.itemSpacing,
      ),
      decoration: BoxDecoration(
        color: AppColorTokens.warningLight,
        borderRadius: BorderRadius.circular(AppRadiusTokens.badge),
      ),
      child: Text(
        'Da khoa',
        style: AppTextStyles.labelMedium.copyWith(
          color: AppColorTokens.warning,
        ),
      ),
    );
  }
}

class _DonePill extends StatelessWidget {
  const _DonePill();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacingTokens.itemSpacing,
        vertical: AppSpacingTokens.itemSpacing,
      ),
      decoration: BoxDecoration(
        color: AppColorTokens.successLight,
        borderRadius: BorderRadius.circular(AppRadiusTokens.badge),
      ),
      child: Text(
        'Đã chăm sóc',
        style: AppTextStyles.labelMedium.copyWith(
          color: AppColorTokens.success,
        ),
      ),
    );
  }
}

class _CompletionButton extends StatelessWidget {
  final Color color;
  final bool checked;
  final bool enabled;
  final VoidCallback? onTap;

  const _CompletionButton({
    required this.color,
    required this.checked,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: checked ? 'Đã hoàn thành' : 'Đánh dấu hoàn thành',
      button: true,
      enabled: enabled,
      child: AnimatedOpacity(
        duration: AppMotionTokens.button,
        opacity: enabled
            ? _ScheduleUi.enabledOpacity
            : _ScheduleUi.disabledOpacity,
        child: InkWell(
          onTap: enabled ? onTap : null,
          borderRadius: BorderRadius.circular(AppRadiusTokens.avatar),
          child: AnimatedContainer(
            duration: AppMotionTokens.card,
            curve: AppMotionTokens.defaultCurve,
            width: AppSpacingTokens.touchTargetMin,
            height: AppSpacingTokens.touchTargetMin,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: checked
                  ? AppColorTokens.success
                  : color.withValues(alpha: _ScheduleUi.softSurfaceOpacity),
              border: Border.all(
                color: checked
                    ? AppColorTokens.success
                    : color.withValues(alpha: _ScheduleUi.borderOpacity),
              ),
            ),
            child: Icon(
              checked
                  ? Icons.check_rounded
                  : Icons.radio_button_unchecked_rounded,
              color: checked ? AppColorTokens.textInverse : color,
              size: _ScheduleUi.checkIconSize,
            ),
          ),
        ),
      ),
    );
  }
}

class _NamiHint extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String text;

  const _NamiHint({
    required this.icon,
    required this.color,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacingTokens.cardPadding),
      decoration: BoxDecoration(
        color: color.withValues(alpha: _ScheduleUi.softSurfaceOpacity),
        borderRadius: BorderRadius.circular(AppRadiusTokens.input),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: _ScheduleUi.inlineIconSize),
          const SizedBox(width: AppSpacingTokens.itemSpacing),
          Expanded(
            child: Text(
              text,
              style: AppTextStyles.caption.copyWith(
                color: _SchedulePalette.textSecondary(context),
                height: _ScheduleUi.normalLineHeight,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SoftIconBadge extends StatelessWidget {
  final IconData icon;
  final Color color;

  const _SoftIconBadge({required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: AppSpacingTokens.touchTargetMin,
      height: AppSpacingTokens.touchTargetMin,
      decoration: BoxDecoration(
        color: color.withValues(alpha: _ScheduleUi.softSurfaceOpacity),
        borderRadius: BorderRadius.circular(AppRadiusTokens.button),
      ),
      child: Icon(icon, color: color, size: _ScheduleUi.iconSize),
    );
  }
}

class _ScheduleLoadingState extends StatelessWidget {
  const _ScheduleLoadingState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacingTokens.pagePadding),
        child: AppCard(
          variant: CardVariant.elevated,
          padding: const EdgeInsets.all(AppSpacingTokens.cardPadding),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              LoadingState(variant: LoadingVariant.spinner),
              const SizedBox(height: AppSpacingTokens.itemSpacingLarge),
              Text(
                'Nabi đang mở lịch chăm sóc của bạn...',
                textAlign: TextAlign.center,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: _SchedulePalette.textSecondary(context),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ScheduleErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ScheduleErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacingTokens.pagePadding),
        child: AppCard(
          variant: CardVariant.elevated,
          padding: const EdgeInsets.all(AppSpacingTokens.cardPadding),
          child: ErrorState(message: message, onRetry: onRetry),
        ),
      ),
    );
  }
}

class _ScheduleMeta {
  final IconData icon;
  final Color color;
  final String label;

  const _ScheduleMeta({
    required this.icon,
    required this.color,
    required this.label,
  });

  factory _ScheduleMeta.from(String category, String sourceType) {
    if (sourceType == LifestyleScheduleSourceTypes.mealPlan ||
        category == LifestyleScheduleCategories.meal) {
      return const _ScheduleMeta(
        icon: Icons.restaurant_rounded,
        color: AppColorTokens.secondary,
        label: 'Bữa ăn',
      );
    }

    switch (category) {
      case LifestyleScheduleCategories.water:
        return const _ScheduleMeta(
          icon: Icons.water_drop_rounded,
          color: AppColorTokens.info,
          label: 'Uống nước',
        );
      case LifestyleScheduleCategories.body:
        return const _ScheduleMeta(
          icon: Icons.directions_run_rounded,
          color: AppColorTokens.success,
          label: 'Vận động',
        );
      case LifestyleScheduleCategories.mind:
        return const _ScheduleMeta(
          icon: Icons.self_improvement_rounded,
          color: AppColorTokens.tertiary,
          label: 'Tinh thần',
        );
      case LifestyleScheduleCategories.brain:
        return const _ScheduleMeta(
          icon: Icons.psychology_rounded,
          color: AppColorTokens.warning,
          label: 'Trí não',
        );
      case LifestyleScheduleCategories.sleep:
        return const _ScheduleMeta(
          icon: Icons.bedtime_rounded,
          color: AppColorTokens.primaryHover,
          label: 'Giấc ngủ',
        );
      default:
        return const _ScheduleMeta(
          icon: Icons.checklist_rounded,
          color: AppColorTokens.primary,
          label: 'Chăm sóc',
        );
    }
  }
}

class _SchedulePalette {
  const _SchedulePalette._();

  static bool _isDark(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark;

  static Color background(BuildContext context) => _isDark(context)
      ? AppColorTokens.darkBackground
      : AppColorTokens.background;

  static Color surface(BuildContext context) =>
      _isDark(context) ? AppColorTokens.darkSurface : AppColorTokens.surface;

  static Color textPrimary(BuildContext context) => _isDark(context)
      ? AppColorTokens.darkTextPrimary
      : AppColorTokens.textPrimary;

  static Color textSecondary(BuildContext context) => _isDark(context)
      ? AppColorTokens.darkTextSecondary
      : AppColorTokens.textSecondary;

  static Color textMuted(BuildContext context) => _isDark(context)
      ? AppColorTokens.darkTextMuted
      : AppColorTokens.textMuted;

  static Color border(BuildContext context) =>
      _isDark(context) ? AppColorTokens.darkBorder : AppColorTokens.border;
}

class _ScheduleUi {
  const _ScheduleUi._();

  static const double maxContentWidth = 680;
  static const double bottomSafeSpace = 128;

  static const double namiAvatarOuterSize = 72;
  static const double namiAvatarInnerSize = 58;
  static const double heroIconSize = 30;
  static const double pillIconSize = 16;
  static const double metricIconSize = 20;
  static const double iconSize = 22;
  static const double inlineIconSize = 14;
  static const double checkIconSize = 22;

  static const double dateSelectorHeight = 104;
  static const double dateChipWidth = 74;
  static const double todayDotSize = 6;

  static const double railWidth = 48;
  static const double railDotSize = 42;
  static const double railIconSize = 20;
  static const double railLineWidth = 3;
  static const double railGlowBlur = 16;

  static const double timeBlockWidth = 68;
  static const double progressStroke = 4;
  static const double progressBarHeight = 12;
  static const double completeProgress = .96;

  static const double glassBlur = 16;
  static const double orbBlur = 34;
  static const double orbLargeSize = 240;
  static const double orbMediumSize = 180;
  static const double orbLargeOffset = 88;
  static const double orbMediumOffset = 56;
  static const double orbSmallOffset = 64;
  static const double orbTopOffset = 180;
  static const double orbBottomOffset = 96;

  static const double selectedScale = 1.02;
  static const double normalScale = 1;
  static const double enabledOpacity = 1;
  static const double disabledOpacity = .46;

  static const double orbOpacity = .16;
  static const double glassSurfaceOpacity = .18;
  static const double glassBorderOpacity = .24;
  static const double strongTextOpacity = .9;
  static const double softTextOpacity = .28;
  static const double softSurfaceOpacity = .1;
  static const double completedTintOpacity = .07;
  static const double borderOpacity = .24;
  static const double softBorderOpacity = .18;
  static const double shadowOpacity = .28;

  static const double normalLineHeight = 1.45;
  static const double relaxedLineHeight = 1.55;
}

double _progressValue(LifestyleScheduleState state) {
  if (state.totalItems <= 0) return 0;
  return (state.score / 100).clamp(0.0, 1.0).toDouble();
}

int _remainingItems(LifestyleScheduleState state) {
  final remaining = state.totalItems - state.completedItems;
  return remaining < 0 ? 0 : remaining;
}

String _namiCopy({required num score, required int completed}) {
  if (completed == 0) {
    return 'Nabi đã sắp từng việc nhỏ theo nhịp trong ngày. Bạn cứ bắt đầu bằng một mục dễ nhất, mình đi chậm mà đều nhé.';
  }
  if (score >= 90) {
    return 'Bạn đang chăm sóc bản thân rất tốt. Nabi tự hào về nhịp hôm nay của bạn lắm.';
  }
  if (score >= 60) {
    return 'Mọi thứ đang đi đúng hướng rồi. Nabi sẽ ở đây nhắc nhẹ phần còn lại để bạn không bị quá tải.';
  }
  return 'Không cần hoàn hảo đâu. Nabi chỉ mong bạn chọn thêm một việc nhỏ và làm thật dịu dàng với cơ thể mình.';
}

String _formatDate(DateTime date) {
  return '${_weekday(date)}, ${date.day}/${date.month}/${date.year}';
}

String _weekday(DateTime date) {
  const days = ['T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'CN'];
  return days[date.weekday - 1];
}
