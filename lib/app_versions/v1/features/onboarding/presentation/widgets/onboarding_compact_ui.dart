import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:nano_app/core/constants/onboarding_constants.dart';
import 'package:nano_app/core/theme/theme.dart';

import 'nabi_onboarding_experience.dart';

class OnboardingSectionCard extends StatelessWidget {
  final String? title;
  final String? subtitle;
  final int? selectedCount;
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final Widget? trailing;
  final IconData? icon;
  final Color? accent;

  const OnboardingSectionCard({
    super.key,
    this.title,
    this.subtitle,
    this.selectedCount,
    required this.child,
    this.padding,
    this.trailing,
    this.icon,
    this.accent,
  });

  @override
  Widget build(BuildContext context) {
    final color = accent ?? NabiPalette.greenPrimary;
    return NabiGlassPanel(
      padding: padding ?? const EdgeInsets.all(AppSpacing.cardPadding),
      borderRadius: BorderRadius.circular(AppRadius.xl),
      shadowColor: color,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title != null) ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (icon != null) ...[
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                    child: Icon(icon, color: color, size: 20),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                ],
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title!,
                        style: AppTextStyles.heading5.copyWith(
                          color: NabiPalette.ink,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.1,
                        ),
                      ),
                      if (subtitle != null && subtitle!.trim().isNotEmpty) ...[
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          subtitle!,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.bodySmall.copyWith(
                            color: NabiPalette.mutedInk,
                            height: 1.35,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (selectedCount != null) ...[
                  const SizedBox(width: AppSpacing.sm),
                  _CountBadge(count: selectedCount!, accent: color),
                ],
                if (trailing != null) ...[
                  const SizedBox(width: AppSpacing.tiny),
                  trailing!,
                ],
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
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
        final columns = width >= 680 ? 3 : width >= 340 ? 2 : 1;
        final itemWidth = (width - (columns - 1) * 8) / columns;
        return Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (var index = 0; index < options.length; index++)
              SizedBox(
                width: itemWidth,
                child: OnboardingChoiceTile(
                  key: ValueKey(options[index].code),
                  option: options[index],
                  selected: selected.contains(options[index].code),
                  enabled: maxSelections == null ||
                      selected.contains(options[index].code) ||
                      selected.length < maxSelections!,
                  accent: _accentForIndex(index),
                  onTap: () {
                    HapticFeedback.selectionClick();
                    onSelected(options[index].code);
                  },
                ),
              ),
          ],
        );
      },
    );
  }

  Color _accentForIndex(int index) {
    const colors = [
      NabiPalette.greenPrimary,
      NabiPalette.calmBlue,
      NabiPalette.personalPurple,
      NabiPalette.careCoral,
      NabiPalette.warning,
    ];
    return colors[index % colors.length];
  }
}

class OnboardingChoiceTile extends StatefulWidget {
  final OnboardingChoiceOption option;
  final bool selected;
  final bool enabled;
  final VoidCallback onTap;
  final Color accent;

  const OnboardingChoiceTile({
    super.key,
    required this.option,
    required this.selected,
    required this.enabled,
    required this.onTap,
    this.accent = NabiPalette.greenPrimary,
  });

  @override
  State<OnboardingChoiceTile> createState() => _OnboardingChoiceTileState();
}

class _OnboardingChoiceTileState extends State<OnboardingChoiceTile> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final foreground = widget.selected ? AppColors.surface : NabiPalette.ink;
    final border = widget.selected
        ? NabiPalette.greenPrimary
        : widget.accent.withValues(alpha: 0.16);
    return Semantics(
      button: true,
      selected: widget.selected,
      enabled: widget.enabled,
      label: widget.option.label,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.enabled ? widget.onTap : null,
        onTapDown: widget.enabled ? (_) => setState(() => _pressed = true) : null,
        onTapUp: widget.enabled ? (_) => setState(() => _pressed = false) : null,
        onTapCancel:
            widget.enabled ? () => setState(() => _pressed = false) : null,
        child: AnimatedScale(
          scale: _pressed && !nabiReducedMotion(context) ? 0.975 : 1,
          duration: AppDuration.tap,
          curve: Curves.easeOutCubic,
          child: AnimatedContainer(
            duration: nabiReducedMotion(context)
                ? Duration.zero
                : AppDuration.ripple,
            curve: Curves.easeOutBack,
            constraints: const BoxConstraints(minHeight: 56),
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 6),
            decoration: BoxDecoration(
              gradient: widget.selected
                  ? NabiPalette.selection
                  : LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        widget.accent.withValues(alpha: 0.09),
                        AppColors.surface,
                      ],
                    ),
              borderRadius: BorderRadius.circular(AppRadius.lg),
              border: Border.all(
                color: border,
                width: widget.selected ? 1.8 : 1,
              ),
              boxShadow: widget.selected
                  ? [
                      BoxShadow(
                        color: NabiPalette.greenPrimary.withValues(alpha: 0.22),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ]
                  : const [],
            ),
            child: Opacity(
              opacity: widget.enabled ? 1 : 0.42,
              child: Row(
                children: [
                  AnimatedContainer(
                    duration: AppDuration.fast,
                    width: 34,
                    height: 34,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: widget.selected
                          ? AppColors.surface.withValues(alpha: 0.16)
                          : widget.accent.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                    child: Text(
                      widget.option.emoji,
                      style: const TextStyle(fontSize: 18),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      widget.option.label,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.labelMedium.copyWith(
                        color: foreground,
                        fontWeight: FontWeight.w800,
                        height: 1.18,
                        letterSpacing: 0,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.tiny),
                  AnimatedSwitcher(
                    duration: AppDuration.button,
                    transitionBuilder: (child, animation) => ScaleTransition(
                      scale: animation,
                      child: child,
                    ),
                    child: widget.selected
                        ? const Icon(
                            Icons.check_circle_rounded,
                            key: ValueKey('selected'),
                            size: 22,
                            color: AppColors.surface,
                          )
                        : Icon(
                            Icons.add_circle_outline_rounded,
                            key: const ValueKey('unselected'),
                            size: 21,
                            color: widget.accent,
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
    return _PickerSurface(
      label: label,
      value: selectedLabel,
      icon: icon,
      hasValue: hasValue,
      onTap: () => _openPicker(context),
    );
  }

  Future<void> _openPicker(BuildContext context) async {
    final result = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ChoiceSheet(
        title: label,
        options: options,
        selectedCode: selectedCode,
      ),
    );
    if (result != null) onSelected(result);
  }
}

class OnboardingMultiChoicePickerField extends StatelessWidget {
  final String label;
  final String hint;
  final IconData icon;
  final List<OnboardingChoiceOption> options;
  final List<String> selectedLabels;
  final ValueChanged<List<String>> onChanged;
  final Set<String> exclusiveCodes;
  final Set<String> emptyCodes;

  const OnboardingMultiChoicePickerField({
    super.key,
    required this.label,
    required this.hint,
    required this.icon,
    required this.options,
    required this.selectedLabels,
    required this.onChanged,
    this.exclusiveCodes = const {'none', 'unknown'},
    this.emptyCodes = const {'none'},
  });

  @override
  Widget build(BuildContext context) {
    final cleanLabels = selectedLabels
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toList(growable: false);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _PickerSurface(
          label: label,
          value: cleanLabels.isEmpty ? hint : '${cleanLabels.length} đã chọn',
          icon: icon,
          hasValue: cleanLabels.isNotEmpty,
          onTap: () => _openPicker(context, cleanLabels),
        ),
        if (cleanLabels.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.sm),
          OnboardingSelectedChips(
            values: cleanLabels,
            onRemove: (value) => onChanged(
              cleanLabels.where((item) => item != value).toList(growable: false),
            ),
            onClear: () => onChanged(const []),
          ),
        ],
      ],
    );
  }

  Future<void> _openPicker(
    BuildContext context,
    List<String> currentLabels,
  ) async {
    final initialCodes = options
        .where((option) => currentLabels.contains(option.label))
        .map((option) => option.code)
        .toSet();
    final result = await showModalBottomSheet<Set<String>>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _MultiChoiceSheet(
        title: label,
        options: options,
        initialCodes: initialCodes,
        exclusiveCodes: exclusiveCodes,
      ),
    );
    if (result == null) return;
    final labels = options
        .where((option) => result.contains(option.code))
        .where((option) => !emptyCodes.contains(option.code))
        .map((option) => option.label)
        .toList(growable: false);
    onChanged(labels);
  }
}

class OnboardingSelectedChips extends StatelessWidget {
  final List<String> values;
  final ValueChanged<String>? onRemove;
  final VoidCallback? onClear;

  const OnboardingSelectedChips({
    super.key,
    required this.values,
    this.onRemove,
    this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 7,
          runSpacing: 7,
          children: [
            for (var index = 0; index < values.length; index++)
              InputChip(
                label: Text(values[index]),
                onDeleted:
                    onRemove == null ? null : () => onRemove!(values[index]),
                deleteIcon: const Icon(Icons.close_rounded, size: 17),
                deleteIconColor: NabiPalette.greenDeep,
                side: BorderSide(
                  color: NabiPalette.greenPrimary.withValues(alpha: 0.18),
                ),
                backgroundColor: index.isEven
                    ? NabiPalette.greenSoft
                    : NabiPalette.mintSurface,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
                labelStyle: AppTextStyles.labelSmall.copyWith(
                  color: NabiPalette.ink,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0,
                ),
              ),
          ],
        ),
        if (onClear != null && values.length > 1)
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: onClear,
              icon: const Icon(Icons.clear_all_rounded, size: 18),
              label: const Text('Bỏ chọn tất cả'),
              style: TextButton.styleFrom(
                foregroundColor: NabiPalette.greenDeep,
                visualDensity: VisualDensity.compact,
              ),
            ),
          ),
      ],
    );
  }
}

class _PickerSurface extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final bool hasValue;
  final VoidCallback onTap;

  const _PickerSurface({
    required this.label,
    required this.value,
    required this.icon,
    required this.hasValue,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: '$label: $value',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            HapticFeedback.selectionClick();
            onTap();
          },
          borderRadius: BorderRadius.circular(AppRadius.lg),
          child: AnimatedContainer(
            duration: AppDuration.button,
            constraints: const BoxConstraints(minHeight: 56),
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
            decoration: BoxDecoration(
              color: hasValue ? NabiPalette.greenSoft : AppColors.surface,
              borderRadius: BorderRadius.circular(AppRadius.lg),
              border: Border.all(
                color: hasValue
                    ? NabiPalette.greenPrimary.withValues(alpha: 0.32)
                    : NabiPalette.line,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: NabiPalette.greenPrimary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                  child: Icon(icon, size: 21, color: NabiPalette.greenPrimary),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        style: AppTextStyles.labelSmall.copyWith(
                          color: NabiPalette.mutedInk,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xxs),
                      Text(
                        value,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.labelLarge.copyWith(
                          color: hasValue
                              ? NabiPalette.greenDeep
                              : NabiPalette.ink,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Icon(
                  Icons.keyboard_arrow_down_rounded,
                  color: NabiPalette.greenPrimary,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ChoiceSheet extends StatefulWidget {
  final String title;
  final List<OnboardingChoiceOption> options;
  final String selectedCode;

  const _ChoiceSheet({
    required this.title,
    required this.options,
    required this.selectedCode,
  });

  @override
  State<_ChoiceSheet> createState() => _ChoiceSheetState();
}

class _ChoiceSheetState extends State<_ChoiceSheet> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final normalized = _query.trim().toLowerCase();
    final filtered = widget.options
        .where(
          (option) =>
              normalized.isEmpty || option.label.toLowerCase().contains(normalized),
        )
        .toList(growable: false);
    return _SheetFrame(
      title: widget.title,
      count: widget.selectedCode.isEmpty ? 0 : 1,
      search: _SearchField(onChanged: (value) => setState(() => _query = value)),
      child: filtered.isEmpty
          ? const _EmptySearch()
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
              itemCount: filtered.length,
              separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
              itemBuilder: (context, index) {
                final option = filtered[index];
                return OnboardingChoiceTile(
                  option: option,
                  selected: widget.selectedCode == option.code,
                  enabled: true,
                  accent: _sheetAccent(index),
                  onTap: () => Navigator.of(context).pop(option.code),
                );
              },
            ),
    );
  }
}

class _MultiChoiceSheet extends StatefulWidget {
  final String title;
  final List<OnboardingChoiceOption> options;
  final Set<String> initialCodes;
  final Set<String> exclusiveCodes;

  const _MultiChoiceSheet({
    required this.title,
    required this.options,
    required this.initialCodes,
    required this.exclusiveCodes,
  });

  @override
  State<_MultiChoiceSheet> createState() => _MultiChoiceSheetState();
}

class _MultiChoiceSheetState extends State<_MultiChoiceSheet> {
  late Set<String> _selected;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _selected = {...widget.initialCodes};
  }

  void _toggle(String code) {
    HapticFeedback.selectionClick();
    setState(() {
      if (_selected.contains(code)) {
        _selected.remove(code);
        return;
      }
      if (widget.exclusiveCodes.contains(code)) {
        _selected
          ..clear()
          ..add(code);
        return;
      }
      _selected.removeWhere(widget.exclusiveCodes.contains);
      _selected.add(code);
    });
  }

  @override
  Widget build(BuildContext context) {
    final normalized = _query.trim().toLowerCase();
    final filtered = widget.options
        .where(
          (option) =>
              normalized.isEmpty || option.label.toLowerCase().contains(normalized),
        )
        .toList(growable: false);
    final selectedOptions = widget.options
        .where((option) => _selected.contains(option.code))
        .toList(growable: false);

    return _SheetFrame(
      title: widget.title,
      count: _selected.length,
      onClear: _selected.isEmpty ? null : () => setState(_selected.clear),
      search: _SearchField(onChanged: (value) => setState(() => _query = value)),
      selected: selectedOptions.isEmpty
          ? null
          : SizedBox(
              height: 48,
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                scrollDirection: Axis.horizontal,
                itemCount: selectedOptions.length,
                separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.sm),
                itemBuilder: (context, index) => InputChip(
                  label: Text(selectedOptions[index].label),
                  onDeleted: () => _toggle(selectedOptions[index].code),
                  backgroundColor: NabiPalette.greenSoft,
                  side: BorderSide(
                    color: NabiPalette.greenPrimary.withValues(alpha: 0.18),
                  ),
                ),
              ),
            ),
      footer: Padding(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
        child: NabiPrimaryButton(
          onPressed: () => Navigator.of(context).pop({..._selected}),
          label: _selected.isEmpty ? 'Xong' : 'Xong · ${_selected.length}',
          icon: Icons.check_rounded,
        ),
      ),
      child: filtered.isEmpty
          ? const _EmptySearch()
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
              itemCount: filtered.length,
              separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
              itemBuilder: (context, index) {
                final option = filtered[index];
                return OnboardingChoiceTile(
                  option: option,
                  selected: _selected.contains(option.code),
                  enabled: true,
                  accent: _sheetAccent(index),
                  onTap: () => _toggle(option.code),
                );
              },
            ),
    );
  }
}

class _SheetFrame extends StatelessWidget {
  final String title;
  final int count;
  final Widget search;
  final Widget child;
  final Widget? selected;
  final Widget? footer;
  final VoidCallback? onClear;

  const _SheetFrame({
    required this.title,
    required this.count,
    required this.search,
    required this.child,
    this.selected,
    this.footer,
    this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.sizeOf(context).height * 0.88;
    return Container(
      height: height,
      decoration: const BoxDecoration(
        color: NabiPalette.pageBackground,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        children: [
          const SizedBox(height: AppSpacing.sm),
          Container(
            width: 48,
            height: 5,
            decoration: BoxDecoration(
              color: NabiPalette.greenPrimary.withValues(alpha: 0.26),
              borderRadius: BorderRadius.circular(AppRadius.pill),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 13, 10, 10),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    gradient: NabiPalette.button,
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                  child: const Icon(
                    Icons.eco_rounded,
                    color: AppColors.surface,
                    size: 21,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.heading5.copyWith(
                      color: NabiPalette.ink,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                _CountBadge(count: count),
                if (onClear != null)
                  IconButton(
                    tooltip: 'Bỏ chọn tất cả',
                    onPressed: onClear,
                    icon: const Icon(Icons.clear_all_rounded),
                    color: NabiPalette.greenDeep,
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            child: search,
          ),
          if (selected != null) ...[
            const SizedBox(height: AppSpacing.sm),
            selected!,
          ],
          const SizedBox(height: AppSpacing.sm),
          Expanded(child: child),
          if (footer != null) footer!,
        ],
      ),
    );
  }
}

class _SearchField extends StatelessWidget {
  final ValueChanged<String> onChanged;

  const _SearchField({required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return TextField(
      onChanged: onChanged,
      textInputAction: TextInputAction.search,
      decoration: InputDecoration(
        hintText: 'Tìm nhanh',
        prefixIcon: const Icon(Icons.search_rounded),
        filled: true,
        fillColor: AppColors.surface,
        isDense: true,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          borderSide: const BorderSide(color: NabiPalette.line),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          borderSide: const BorderSide(color: NabiPalette.line),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          borderSide: const BorderSide(
            color: NabiPalette.greenPrimary,
            width: 1.5,
          ),
        ),
      ),
    );
  }
}

class _EmptySearch extends StatelessWidget {
  const _EmptySearch();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.pagePaddingLarge),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const NabiCompanionAvatar(
              size: 76,
              mood: NabiOnboardingMood.thinking,
              showStatus: false,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Chưa tìm thấy',
              style: AppTextStyles.heading5.copyWith(
                color: NabiPalette.ink,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Thử từ khóa ngắn hơn nhé.',
              style: AppTextStyles.bodySmall.copyWith(
                color: NabiPalette.mutedInk,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class OnboardingInlineInfo extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color? color;

  const OnboardingInlineInfo({
    super.key,
    required this.icon,
    required this.text,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final accent = color ?? NabiPalette.greenPrimary;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.09),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: accent.withValues(alpha: 0.14)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 19, color: accent),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              text,
              style: AppTextStyles.bodySmall.copyWith(
                color: NabiPalette.ink,
                height: 1.4,
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
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: NabiPalette.line),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: NabiPalette.greenSoft,
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: Icon(icon, size: 18, color: NabiPalette.greenPrimary),
          ),
          const SizedBox(width: AppSpacing.sm),
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
                const SizedBox(height: AppSpacing.xxs),
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
  final Color accent;

  const _CountBadge({
    required this.count,
    this.accent = NabiPalette.greenPrimary,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
      decoration: BoxDecoration(
        color: count > 0
            ? accent.withValues(alpha: 0.12)
            : NabiPalette.mintSurface,
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Text(
        '$count',
        style: AppTextStyles.labelSmall.copyWith(
          color: count > 0 ? accent : NabiPalette.mutedInk,
          fontWeight: FontWeight.w900,
          letterSpacing: 0,
        ),
      ),
    );
  }
}

Color _sheetAccent(int index) {
  const colors = [
    NabiPalette.greenPrimary,
    NabiPalette.calmBlue,
    NabiPalette.personalPurple,
    NabiPalette.careCoral,
    NabiPalette.warning,
  ];
  return colors[index % colors.length];
}
