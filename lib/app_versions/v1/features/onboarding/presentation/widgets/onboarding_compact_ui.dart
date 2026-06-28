import 'package:flutter/material.dart';

import 'package:nano_app/core/constants/onboarding_constants.dart';
import 'package:nano_app/core/theme/theme.dart';

import 'nabi_onboarding_experience.dart';

/// Shared onboarding primitives.
///
/// Selection behavior remains consistent across all views:
/// - multi-select questions use the inline choice grid;
/// - one-choice questions use the same grid in a modal sheet;
/// - the visual system uses blue as the primary state and animated feedback.
class OnboardingSectionCard extends StatelessWidget {
  final String? title;
  final String? subtitle;
  final int? selectedCount;
  final Widget child;
  final EdgeInsetsGeometry? padding;

  const OnboardingSectionCard({
    super.key,
    this.title,
    this.subtitle,
    this.selectedCount,
    required this.child,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return NabiGlassPanel(
      padding: padding ?? const EdgeInsets.all(13),
      borderRadius: BorderRadius.circular(AppRadius.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title != null) ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 4,
                  height: 30,
                  margin: const EdgeInsets.only(top: 1),
                  decoration: BoxDecoration(
                    gradient: NabiPalette.button,
                    borderRadius: BorderRadius.circular(AppRadius.circular),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title!,
                    style: AppTextStyles.heading5.copyWith(
                      color: NabiPalette.ink,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.1,
                    ),
                  ),
                ),
                if (selectedCount != null) _CountBadge(count: selectedCount!),
              ],
            ),
            if (subtitle != null && subtitle!.trim().isNotEmpty) ...[
              const SizedBox(height: 5),
              Text(
                subtitle!,
                style: AppTextStyles.bodySmall.copyWith(
                  color: NabiPalette.mutedInk,
                  height: 1.36,
                ),
              ),
            ],
            const SizedBox(height: 11),
          ],
          child,
        ],
      ),
    );
  }
}

class OnboardingChoiceGrid extends StatelessWidget {
  final List<OnboardingChoiceOption> options;
  final Iterable<String> selectedCodes;
  final ValueChanged<String> onSelected;
  final bool multiSelect;
  final bool dense;
  final int? maxSelections;

  const OnboardingChoiceGrid({
    super.key,
    required this.options,
    required this.selectedCodes,
    required this.onSelected,
    required this.multiSelect,
    this.dense = true,
    this.maxSelections,
  });

  @override
  Widget build(BuildContext context) {
    final selected = selectedCodes.toSet();

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final crossAxisCount = width >= 760
            ? 4
            : width >= 520
            ? 3
            : 2;

        return GridView.builder(
          itemCount: options.length,
          shrinkWrap: true,
          primary: false,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            mainAxisExtent: dense ? 58 : 66,
          ),
          itemBuilder: (context, index) {
            final option = options[index];
            final isSelected = selected.contains(option.code);
            final selectionLimitReached =
                maxSelections != null &&
                selected.length >= maxSelections! &&
                !isSelected;

            return OnboardingChoiceTile(
              option: option,
              selected: isSelected,
              enabled: !selectionLimitReached,
              onTap: () => onSelected(option.code),
            );
          },
        );
      },
    );
  }
}

class OnboardingChoiceTile extends StatefulWidget {
  final OnboardingChoiceOption option;
  final bool selected;
  final bool enabled;
  final VoidCallback onTap;

  const OnboardingChoiceTile({
    super.key,
    required this.option,
    required this.selected,
    required this.enabled,
    required this.onTap,
  });

  @override
  State<OnboardingChoiceTile> createState() => _OnboardingChoiceTileState();
}

class _OnboardingChoiceTileState extends State<OnboardingChoiceTile> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final foreground = widget.selected ? Colors.white : NabiPalette.ink;
    final iconBackground = widget.selected
        ? Colors.white.withValues(alpha: 0.18)
        : NabiPalette.royalBlue.withValues(alpha: 0.10);

    return Semantics(
      button: true,
      selected: widget.selected,
      enabled: widget.enabled,
      label: widget.option.label,
      child: AnimatedScale(
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        scale: _pressed ? 0.975 : 1,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutCubic,
          decoration: BoxDecoration(
            gradient: widget.selected
                ? NabiPalette.selection
                : NabiPalette.card,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(
              color: widget.selected ? NabiPalette.royalBlue : NabiPalette.line,
              width: widget.selected ? 1.5 : 1,
            ),
            boxShadow: widget.selected
                ? [
                    BoxShadow(
                      color: NabiPalette.royalBlue.withValues(alpha: 0.24),
                      blurRadius: 14,
                      offset: const Offset(0, 5),
                    ),
                  ]
                : const [],
          ),
          child: Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            child: InkWell(
              onTap: widget.enabled ? widget.onTap : null,
              onHighlightChanged: (value) => setState(() => _pressed = value),
              borderRadius: BorderRadius.circular(AppRadius.lg),
              splashColor: Colors.white.withValues(alpha: 0.20),
              child: Opacity(
                opacity: widget.enabled ? 1 : 0.42,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 7,
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 29,
                        height: 29,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: iconBackground,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          widget.option.emoji,
                          style: const TextStyle(fontSize: 16),
                        ),
                      ),
                      const SizedBox(width: 7),
                      Expanded(
                        child: Text(
                          widget.option.label,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.labelMedium.copyWith(
                            color: foreground,
                            fontWeight: FontWeight.w800,
                            height: 1.12,
                            letterSpacing: 0,
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 160),
                        width: 18,
                        height: 18,
                        decoration: BoxDecoration(
                          color: widget.selected
                              ? Colors.white
                              : NabiPalette.royalBlue.withValues(alpha: 0.09),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          widget.selected
                              ? Icons.check_rounded
                              : Icons.add_rounded,
                          size: 13,
                          color: widget.selected
                              ? NabiPalette.royalBlue
                              : NabiPalette.royalBlue,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class OnboardingChoicePickerField extends StatelessWidget {
  final String label;
  final String hint;
  final IconData icon;
  final List<OnboardingChoiceOption> options;
  final String selectedCode;
  final ValueChanged<String> onSelected;

  const OnboardingChoicePickerField({
    super.key,
    required this.label,
    required this.hint,
    required this.icon,
    required this.options,
    required this.selectedCode,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final selectedLabel = OnboardingCatalog.labelOf(
      options,
      selectedCode,
      fallback: hint,
    );
    final hasValue = selectedCode.trim().isNotEmpty;

    return Semantics(
      button: true,
      label: label,
      value: hasValue ? selectedLabel : hint,
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          onTap: () => _openPicker(context),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            constraints: const BoxConstraints(minHeight: 58),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              gradient: hasValue ? NabiPalette.softBlue : NabiPalette.card,
              borderRadius: BorderRadius.circular(AppRadius.lg),
              border: Border.all(
                color: hasValue ? NabiPalette.skyBlue : NabiPalette.line,
                width: hasValue ? 1.3 : 1,
              ),
              boxShadow: hasValue
                  ? [
                      BoxShadow(
                        color: NabiPalette.royalBlue.withValues(alpha: 0.08),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ]
                  : const [],
            ),
            child: Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    gradient: hasValue
                        ? NabiPalette.selection
                        : NabiPalette.softBlue,
                    borderRadius: BorderRadius.circular(11),
                  ),
                  child: Icon(
                    icon,
                    size: 18,
                    color: hasValue ? Colors.white : NabiPalette.royalBlue,
                  ),
                ),
                const SizedBox(width: 9),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        style: AppTextStyles.labelSmall.copyWith(
                          color: NabiPalette.mutedInk,
                          letterSpacing: 0,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        selectedLabel,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.labelLarge.copyWith(
                          color: hasValue
                              ? NabiPalette.ink
                              : AppColors.textHint,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 6),
                Icon(
                  Icons.keyboard_arrow_down_rounded,
                  color: hasValue ? NabiPalette.royalBlue : AppColors.icon,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _openPicker(BuildContext context) async {
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: false,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFFFAFDFF), Color(0xFFF2F8FF)],
            ),
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: SafeArea(
            top: false,
            child: DraggableScrollableSheet(
              expand: false,
              initialChildSize: 0.68,
              minChildSize: 0.42,
              maxChildSize: 0.92,
              builder: (context, scrollController) {
                return SingleChildScrollView(
                  controller: scrollController,
                  padding: const EdgeInsets.fromLTRB(18, 2, 18, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 46,
                        height: 5,
                        margin: const EdgeInsets.only(bottom: 15),
                        decoration: BoxDecoration(
                          color: NabiPalette.royalBlue.withValues(alpha: 0.20),
                          borderRadius: BorderRadius.circular(
                            AppRadius.circular,
                          ),
                        ),
                      ),
                      Row(
                        children: [
                          Container(
                            width: 39,
                            height: 39,
                            decoration: const BoxDecoration(
                              gradient: NabiPalette.selection,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(icon, color: Colors.white, size: 19),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  label,
                                  style: AppTextStyles.heading4.copyWith(
                                    color: NabiPalette.ink,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                                Text(
                                  'Chọn điều gần đúng nhất với bạn.',
                                  style: AppTextStyles.bodySmall.copyWith(
                                    color: NabiPalette.mutedInk,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      OnboardingChoiceGrid(
                        options: options,
                        selectedCodes: [selectedCode],
                        multiSelect: false,
                        onSelected: (code) {
                          onSelected(code);
                          Navigator.of(sheetContext).pop();
                        },
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }
}

class OnboardingInlineInfo extends StatelessWidget {
  final IconData icon;
  final String text;

  const OnboardingInlineInfo({
    super.key,
    required this.icon,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(10, 10, 11, 10),
      decoration: BoxDecoration(
        gradient: NabiPalette.softBlue,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: NabiPalette.line),
      ),
      child: Row(
        children: [
          Container(
            width: 31,
            height: 31,
            decoration: BoxDecoration(
              color: NabiPalette.cyan.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 17, color: NabiPalette.royalBlue),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
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

class OnboardingLabelValue extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const OnboardingLabelValue({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        gradient: NabiPalette.card,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: NabiPalette.line),
      ),
      child: Row(
        children: [
          Container(
            width: 31,
            height: 31,
            decoration: BoxDecoration(
              color: NabiPalette.royalBlue.withValues(alpha: 0.09),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 17, color: NabiPalette.royalBlue),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: AppTextStyles.labelSmall.copyWith(
                    color: NabiPalette.mutedInk,
                    letterSpacing: 0,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.labelLarge.copyWith(
                    color: NabiPalette.ink,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0,
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

class _CountBadge extends StatelessWidget {
  final int count;

  const _CountBadge({required this.count});

  @override
  Widget build(BuildContext context) {
    final hasSelection = count > 0;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        gradient: hasSelection ? NabiPalette.selection : NabiPalette.card,
        borderRadius: BorderRadius.circular(AppRadius.circular),
        border: Border.all(color: NabiPalette.line),
      ),
      child: Text(
        '$count đã chọn',
        style: AppTextStyles.labelSmall.copyWith(
          color: hasSelection ? Colors.white : NabiPalette.mutedInk,
          fontWeight: FontWeight.w900,
          letterSpacing: 0,
        ),
      ),
    );
  }
}
