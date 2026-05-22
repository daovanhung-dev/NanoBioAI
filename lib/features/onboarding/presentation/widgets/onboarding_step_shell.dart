import 'package:flutter/material.dart';

class OnboardingStepShell extends StatelessWidget {
  final int stepIndex;
  final int totalSteps;
  final String title;
  final String subtitle;
  final Widget child;
  final Widget? footer;
  final VoidCallback? onBack;
  final VoidCallback? onNext;
  final String? nextLabel;
  final bool showBack;
  final bool isScrollable;

  const OnboardingStepShell({
    super.key,
    required this.stepIndex,
    required this.title,
    required this.subtitle,
    required this.child,
    this.totalSteps = 7,
    this.footer,
    this.onBack,
    this.onNext,
    this.nextLabel,
    this.showBack = true,
    this.isScrollable = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final progress = (stepIndex + 1) / totalSteps;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _TopBar(
            progress: progress,
            onBack: showBack ? onBack : null,
          ),
          const SizedBox(height: 18),
          Text(
            title,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.textTheme.bodySmall?.color?.withOpacity(0.75),
              height: 1.35,
            ),
          ),
          const SizedBox(height: 18),
          Expanded(
            child: isScrollable
                ? SingleChildScrollView(
                    child: child,
                  )
                : child,
          ),
          if (footer != null) ...[
            const SizedBox(height: 18),
            footer!,
          ],
          if (onNext != null && footer == null) ...[
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: onNext,
                child: Text(nextLabel ?? 'Tiếp tục'),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  final double progress;
  final VoidCallback? onBack;

  const _TopBar({
    required this.progress,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      children: [
        if (onBack != null)
          IconButton(
            onPressed: onBack,
            icon: const Icon(Icons.arrow_back_rounded),
          )
        else
          const SizedBox(width: 48),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 10,
              backgroundColor: theme.colorScheme.surfaceContainerHighest,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Text(
          '${(progress * 100).round()}%',
          style: theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700),
        ),
      ],
    );
  }
}
