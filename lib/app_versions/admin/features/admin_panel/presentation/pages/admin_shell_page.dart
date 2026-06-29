import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:nano_app/app_versions/admin/features/admin_panel/domain/entities/admin_models.dart';
import 'package:nano_app/app_versions/admin/features/admin_panel/presentation/controllers/admin_controller.dart';
import 'package:nano_app/app_versions/admin/features/admin_panel/providers/admin_providers.dart';
import 'package:nano_app/app_versions/admin/router/admin_route_paths.dart';
import 'package:nano_app/core/theme/theme.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

const _desktopBreakpoint = 920.0;
const _wideBreakpoint = 1180.0;
const _contentMaxWidth = 1280.0;

class AdminShellPage extends ConsumerStatefulWidget {
  final AdminPanelSection initialSection;

  const AdminShellPage({required this.initialSection, super.key});

  @override
  ConsumerState<AdminShellPage> createState() => _AdminShellPageState();
}

class _AdminShellPageState extends ConsumerState<AdminShellPage> {
  final _search = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref
          .read(adminControllerProvider.notifier)
          .selectSection(widget.initialSection);
    });
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AsyncValue<AdminPanelState>>(adminControllerProvider, (
      previous,
      next,
    ) {
      final message = next.asData?.value.lastMessage;
      if (message == null || message.isEmpty) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(behavior: SnackBarBehavior.floating, content: Text(message)),
      );
    });

    final state = ref.watch(adminControllerProvider);

    return state.when(
      loading: _LoadingScaffold.new,
      error: (_, __) => _AdminStateScaffold(
        child: _BlockingState(
          icon: Icons.cloud_off_rounded,
          title: 'Chưa tải được khu quản trị',
          message: 'Nabi chưa lấy được phiên Admin. Hãy thử lại sau ít phút.',
          actionLabel: 'Thử lại',
          onAction: () => ref.read(adminControllerProvider.notifier).refresh(),
        ),
      ),
      data: (data) {
        if (!data.session.isAdmin) {
          return _AdminStateScaffold(
            child: _BlockingState(
              icon: Icons.lock_person_rounded,
              title: 'Tài khoản chưa có quyền Admin',
              message:
                  'Nabi đã đăng nhập, nhưng tài khoản này chưa có vai trò quản trị đang hoạt động.',
              actionLabel: 'Đăng xuất',
              onAction: _signOut,
            ),
          );
        }

        final sections = AdminPanelSection.values
            .where(data.session.canAccessSection)
            .toList(growable: false);

        return LayoutBuilder(
          builder: (context, constraints) {
            final isCompact = constraints.maxWidth < _desktopBreakpoint;
            final isWide = constraints.maxWidth >= _wideBreakpoint;

            return Scaffold(
              backgroundColor: AppColors.scaffold,
              drawer: isCompact
                  ? _AdminDrawer(
                      selected: data.section,
                      sections: sections,
                      onSelected: _goToSection,
                      onShowGuide: _showGuide,
                      onSignOut: _signOut,
                    )
                  : null,
              body: Builder(
                builder: (scaffoldContext) {
                  return Row(
                    children: [
                      if (!isCompact)
                        _AdminSideBar(
                          selected: data.section,
                          sections: sections,
                          extended: isWide,
                          onSelected: _goToSection,
                          onShowGuide: _showGuide,
                          onSignOut: _signOut,
                        ),
                      Expanded(
                        child: Column(
                          children: [
                            _TopBar(
                              state: data,
                              search: _search,
                              isCompact: isCompact,
                              onMenuPressed: isCompact
                                  ? () => Scaffold.of(
                                      scaffoldContext,
                                    ).openDrawer()
                                  : null,
                              onSearch: (value) {
                                ref
                                    .read(adminControllerProvider.notifier)
                                    .search(value);
                              },
                              onRefresh: () {
                                ref
                                    .read(adminControllerProvider.notifier)
                                    .refresh();
                              },
                              onShowGuide: _showGuide,
                              onSignOut: _signOut,
                            ),
                            Expanded(
                              child: _AdminContent(
                                state: data,
                                onAction: _runAction,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              ),
            );
          },
        );
      },
    );
  }

  void _goToSection(AdminPanelSection section) {
    context.go(section.routePath);
  }

  void _showGuide() {
    showDialog<void>(
      context: context,
      builder: (context) => const _AdminGuideDialog(),
    );
  }

  Future<void> _signOut() async {
    await ref.read(adminControllerProvider.notifier).signOut();
    if (mounted) context.go(AdminRoutePaths.login);
  }

  Future<void> _runAction(
    AdminPanelSection section,
    String action,
    AdminWorkItem item,
    String actionLabel,
  ) async {
    final reason = await showDialog<String>(
      context: context,
      builder: (context) => _ReasonDialog(actionLabel: actionLabel),
    );
    if (reason == null || reason.trim().isEmpty) return;

    final payload = <String, Object?>{};
    if (section == AdminPanelSection.saleConversions && action == 'mark_paid') {
      final proofPath = await _pickAndUploadSalePayoutProof(item.id);
      if (proofPath != null) payload['payment_proof_path'] = proofPath;
    }

    await ref
        .read(adminControllerProvider.notifier)
        .runMutation(
          section: section,
          action: action,
          targetId: item.id,
          reason: reason,
          payload: payload,
        );
  }

  Future<String?> _pickAndUploadSalePayoutProof(String conversionId) async {
    try {
      final image = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );
      if (image == null) return null;

      final bytes = await image.readAsBytes();
      final safeName = image.name.replaceAll(RegExp(r'[^a-zA-Z0-9._-]'), '_');
      final path =
          'sale-point-conversions/$conversionId/${DateTime.now().millisecondsSinceEpoch}-$safeName';
      final contentType = image.mimeType ?? 'image/jpeg';

      await Supabase.instance.client.storage
          .from('sale-payout-proofs')
          .uploadBinary(
            path,
            bytes,
            fileOptions: FileOptions(contentType: contentType, upsert: true),
          );

      return path;
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Chua upload duoc anh minh chung. Admin co the confirm khong anh.',
            ),
          ),
        );
      }
      return null;
    }
  }
}

class _LoadingScaffold extends StatelessWidget {
  const _LoadingScaffold();

  @override
  Widget build(BuildContext context) {
    return const _AdminStateScaffold(
      child: Center(
        child: SizedBox.square(
          dimension: 36,
          child: CircularProgressIndicator(strokeWidth: 3),
        ),
      ),
    );
  }
}

class _AdminStateScaffold extends StatelessWidget {
  final Widget child;

  const _AdminStateScaffold({required this.child});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffold,
      body: Container(
        decoration: const BoxDecoration(gradient: AppGradients.surfaceAlt),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: child,
          ),
        ),
      ),
    );
  }
}

class _AdminSideBar extends StatelessWidget {
  final AdminPanelSection selected;
  final List<AdminPanelSection> sections;
  final bool extended;
  final ValueChanged<AdminPanelSection> onSelected;
  final VoidCallback onShowGuide;
  final VoidCallback onSignOut;

  const _AdminSideBar({
    required this.selected,
    required this.sections,
    required this.extended,
    required this.onSelected,
    required this.onShowGuide,
    required this.onSignOut,
  });

  @override
  Widget build(BuildContext context) {
    final width = extended ? 276.0 : 96.0;

    return AnimatedContainer(
      duration: AppDuration.navigation,
      curve: Curves.easeOutCubic,
      width: width,
      padding: EdgeInsets.symmetric(
        horizontal: extended ? AppSpacing.md : AppSpacing.sm,
        vertical: AppSpacing.lg,
      ),
      decoration: const BoxDecoration(
        gradient: AppGradients.dashboard,
        boxShadow: AppShadows.lg,
      ),
      child: Column(
        children: [
          _AdminBrand(extended: extended),
          const SizedBox(height: AppSpacing.lg),
          Expanded(
            child: ListView.separated(
              itemCount: sections.length,
              separatorBuilder: (_, __) =>
                  const SizedBox(height: AppSpacing.sm),
              itemBuilder: (context, index) {
                final section = sections[index];
                return _AdminNavButton(
                  section: section,
                  selected: section == selected,
                  extended: extended,
                  onTap: () => onSelected(section),
                );
              },
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          _SideActionButton(
            icon: Icons.menu_book_rounded,
            label: 'Hướng dẫn',
            extended: extended,
            onPressed: onShowGuide,
          ),
          const SizedBox(height: AppSpacing.sm),
          _SideActionButton(
            icon: Icons.logout_rounded,
            label: 'Đăng xuất',
            extended: extended,
            onPressed: onSignOut,
          ),
        ],
      ),
    );
  }
}

class _AdminDrawer extends StatelessWidget {
  final AdminPanelSection selected;
  final List<AdminPanelSection> sections;
  final ValueChanged<AdminPanelSection> onSelected;
  final VoidCallback onShowGuide;
  final VoidCallback onSignOut;

  const _AdminDrawer({
    required this.selected,
    required this.sections,
    required this.onSelected,
    required this.onShowGuide,
    required this.onSignOut,
  });

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: AppColors.surface,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            children: [
              const _DrawerBrand(),
              const SizedBox(height: AppSpacing.md),
              Expanded(
                child: ListView.separated(
                  itemCount: sections.length,
                  separatorBuilder: (_, __) =>
                      const SizedBox(height: AppSpacing.xs),
                  itemBuilder: (context, index) {
                    final section = sections[index];
                    final isSelected = section == selected;
                    return ListTile(
                      selected: isSelected,
                      selectedTileColor: AppColors.primarySoft,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadius.md),
                      ),
                      leading: Icon(
                        isSelected ? section.selectedIcon : section.icon,
                        color: isSelected
                            ? AppColors.primary
                            : AppColors.textSecondary,
                      ),
                      title: Text(
                        section.label,
                        style: AppTextStyles.labelLarge,
                      ),
                      onTap: () {
                        Navigator.of(context).pop();
                        onSelected(section);
                      },
                    );
                  },
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.of(context).pop();
                    onShowGuide();
                  },
                  icon: const Icon(Icons.menu_book_rounded),
                  label: const Text('Hướng dẫn'),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              SizedBox(
                width: double.infinity,
                child: TextButton.icon(
                  onPressed: onSignOut,
                  icon: const Icon(Icons.logout_rounded),
                  label: const Text('Đăng xuất'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AdminBrand extends StatelessWidget {
  final bool extended;

  const _AdminBrand({required this.extended});

  @override
  Widget build(BuildContext context) {
    final mark = Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        gradient: AppGradients.futuristic,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: AppShadows.primary,
      ),
      child: const Icon(
        Icons.admin_panel_settings_rounded,
        color: AppColors.textInverse,
      ),
    );

    if (!extended) {
      return Tooltip(message: 'NanoBio Admin', child: mark);
    }

    return Row(
      children: [
        mark,
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'NanoBio',
                style: AppTextStyles.heading4.copyWith(
                  color: AppColors.textInverse,
                ),
              ),
              Text(
                'Admin Console',
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.darkTextSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _DrawerBrand extends StatelessWidget {
  const _DrawerBrand();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        gradient: AppGradients.primarySoft,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              gradient: AppGradients.futuristic,
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: const Icon(
              Icons.admin_panel_settings_rounded,
              color: AppColors.textInverse,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('NanoBio Admin', style: AppTextStyles.heading4),
                Text(
                  'Vận hành an toàn',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textSecondary,
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

class _AdminNavButton extends StatefulWidget {
  final AdminPanelSection section;
  final bool selected;
  final bool extended;
  final VoidCallback onTap;

  const _AdminNavButton({
    required this.section,
    required this.selected,
    required this.extended,
    required this.onTap,
  });

  @override
  State<_AdminNavButton> createState() => _AdminNavButtonState();
}

class _AdminNavButtonState extends State<_AdminNavButton> {
  var _hovered = false;

  @override
  Widget build(BuildContext context) {
    final color = widget.selected || _hovered
        ? AppColors.textInverse
        : AppColors.darkTextSecondary;
    final background = widget.selected
        ? AppColors.primary.withValues(alpha: .96)
        : _hovered
        ? AppColors.textInverse.withValues(alpha: .08)
        : Colors.transparent;

    final child = AnimatedContainer(
      duration: AppDuration.hover,
      curve: Curves.easeOut,
      padding: EdgeInsets.symmetric(
        horizontal: widget.extended ? AppSpacing.md : AppSpacing.sm,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: AppSpacing.touchTargetMin),
        child: widget.extended
            ? Row(
                children: [
                  Icon(
                    widget.selected
                        ? widget.section.selectedIcon
                        : widget.section.icon,
                    color: color,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      widget.section.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.labelLarge.copyWith(color: color),
                    ),
                  ),
                ],
              )
            : Center(
                child: Icon(
                  widget.selected
                      ? widget.section.selectedIcon
                      : widget.section.icon,
                  color: color,
                ),
              ),
      ),
    );

    return Tooltip(
      message: widget.extended ? '' : widget.section.label,
      child: MouseRegion(
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(AppRadius.md),
            onTap: widget.onTap,
            child: child,
          ),
        ),
      ),
    );
  }
}

class _SideActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool extended;
  final VoidCallback onPressed;

  const _SideActionButton({
    required this.icon,
    required this.label,
    required this.extended,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final foreground = AppColors.darkTextSecondary;
    if (!extended) {
      return Tooltip(
        message: label,
        child: IconButton(
          color: foreground,
          onPressed: onPressed,
          icon: Icon(icon),
        ),
      );
    }

    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        style: OutlinedButton.styleFrom(
          foregroundColor: foreground,
          side: BorderSide(color: AppColors.textInverse.withValues(alpha: .18)),
          alignment: Alignment.centerLeft,
        ),
        onPressed: onPressed,
        icon: Icon(icon),
        label: Text(label),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  final AdminPanelState state;
  final TextEditingController search;
  final bool isCompact;
  final VoidCallback? onMenuPressed;
  final ValueChanged<String> onSearch;
  final VoidCallback onRefresh;
  final VoidCallback onShowGuide;
  final VoidCallback onSignOut;

  const _TopBar({
    required this.state,
    required this.search,
    required this.isCompact,
    required this.onMenuPressed,
    required this.onSearch,
    required this.onRefresh,
    required this.onShowGuide,
    required this.onSignOut,
  });

  @override
  Widget build(BuildContext context) {
    final showSearch =
        state.section != AdminPanelSection.dashboard &&
        !state.isPermissionDenied;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: isCompact ? AppSpacing.md : AppSpacing.xl,
        vertical: AppSpacing.md,
      ),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(bottom: BorderSide(color: AppColors.border)),
        boxShadow: AppShadows.appBar,
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final narrow = constraints.maxWidth < 720;
          final title = _TopBarTitle(
            state: state,
            onMenuPressed: onMenuPressed,
          );
          final actions = _TopBarActions(
            compact: narrow,
            onRefresh: onRefresh,
            onShowGuide: onShowGuide,
            onSignOut: onSignOut,
          );

          if (narrow) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(child: title),
                    actions,
                  ],
                ),
                if (showSearch) ...[
                  const SizedBox(height: AppSpacing.md),
                  _SearchField(
                    controller: search,
                    sectionLabel: state.section.label,
                    onSearch: onSearch,
                  ),
                ],
              ],
            );
          }

          return Row(
            children: [
              Expanded(child: title),
              if (showSearch) ...[
                const SizedBox(width: AppSpacing.md),
                ConstrainedBox(
                  constraints: const BoxConstraints(
                    minWidth: 240,
                    maxWidth: 380,
                  ),
                  child: _SearchField(
                    controller: search,
                    sectionLabel: state.section.label,
                    onSearch: onSearch,
                  ),
                ),
              ],
              const SizedBox(width: AppSpacing.md),
              actions,
            ],
          );
        },
      ),
    );
  }
}

class _TopBarTitle extends StatelessWidget {
  final AdminPanelState state;
  final VoidCallback? onMenuPressed;

  const _TopBarTitle({required this.state, required this.onMenuPressed});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        if (onMenuPressed != null) ...[
          IconButton(
            tooltip: 'Mở điều hướng',
            onPressed: onMenuPressed,
            icon: const Icon(Icons.menu_rounded),
          ),
          const SizedBox(width: AppSpacing.sm),
        ],
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: AppColors.primarySoft,
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          child: Icon(state.section.selectedIcon, color: AppColors.primary),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                state.section.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.heading3,
              ),
              const SizedBox(height: AppSpacing.xxs),
              Text(
                'Quản trị theo quyền, mọi thao tác nhạy cảm đều cần lý do.',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SearchField extends StatelessWidget {
  final TextEditingController controller;
  final String sectionLabel;
  final ValueChanged<String> onSearch;

  const _SearchField({
    required this.controller,
    required this.sectionLabel,
    required this.onSearch,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      textInputAction: TextInputAction.search,
      onSubmitted: onSearch,
      decoration: InputDecoration(
        labelText: 'Tìm trong $sectionLabel',
        prefixIcon: const Icon(Icons.search_rounded),
        suffixIcon: IconButton(
          tooltip: 'Tìm kiếm',
          onPressed: () => onSearch(controller.text),
          icon: const Icon(Icons.arrow_forward_rounded),
        ),
      ),
    );
  }
}

class _TopBarActions extends StatelessWidget {
  final bool compact;
  final VoidCallback onRefresh;
  final VoidCallback onShowGuide;
  final VoidCallback onSignOut;

  const _TopBarActions({
    required this.compact,
    required this.onRefresh,
    required this.onShowGuide,
    required this.onSignOut,
  });

  @override
  Widget build(BuildContext context) {
    if (compact) {
      return Wrap(
        spacing: AppSpacing.xs,
        children: [
          IconButton(
            tooltip: 'Hướng dẫn',
            onPressed: onShowGuide,
            icon: const Icon(Icons.menu_book_rounded),
          ),
          IconButton(
            tooltip: 'Làm mới',
            onPressed: onRefresh,
            icon: const Icon(Icons.refresh_rounded),
          ),
          IconButton(
            tooltip: 'Đăng xuất',
            onPressed: onSignOut,
            icon: const Icon(Icons.logout_rounded),
          ),
        ],
      );
    }

    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: [
        OutlinedButton.icon(
          onPressed: onShowGuide,
          icon: const Icon(Icons.menu_book_rounded),
          label: const Text('Hướng dẫn'),
        ),
        IconButton(
          tooltip: 'Làm mới',
          onPressed: onRefresh,
          icon: const Icon(Icons.refresh_rounded),
        ),
        IconButton(
          tooltip: 'Đăng xuất',
          onPressed: onSignOut,
          icon: const Icon(Icons.logout_rounded),
        ),
      ],
    );
  }
}

class _AdminContent extends StatelessWidget {
  final AdminPanelState state;
  final void Function(
    AdminPanelSection section,
    String action,
    AdminWorkItem item,
    String actionLabel,
  )
  onAction;

  const _AdminContent({required this.state, required this.onAction});

  @override
  Widget build(BuildContext context) {
    final content = state.isPermissionDenied
        ? _PermissionDeniedPanel(
            section: state.section,
            permission: state.deniedPermission!,
          )
        : switch (state.section) {
            AdminPanelSection.dashboard => _DashboardView(state: state),
            AdminPanelSection.audit => _AuditView(events: state.auditEvents),
            _ => _WorkQueueView(state: state, onAction: onAction),
          };

    return SingleChildScrollView(
      padding: EdgeInsets.all(
        MediaQuery.sizeOf(context).width < _desktopBreakpoint
            ? AppSpacing.md
            : AppSpacing.xl,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: _contentMaxWidth),
          child: AnimatedSwitcher(
            duration: AppDuration.switcher,
            switchInCurve: Curves.easeOutCubic,
            switchOutCurve: Curves.easeInCubic,
            child: KeyedSubtree(
              key: ValueKey(
                '${state.section.value}-${state.query}-${state.isPermissionDenied}',
              ),
              child: content,
            ),
          ),
        ),
      ),
    );
  }
}

class _DashboardView extends StatelessWidget {
  final AdminPanelState state;

  const _DashboardView({required this.state});

  @override
  Widget build(BuildContext context) {
    final shortcuts = AdminPanelSection.values
        .where((section) => section != AdminPanelSection.dashboard)
        .where(state.session.canAccessSection)
        .toList(growable: false);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _AdminOverviewPanel(metricCount: state.metrics.length),
        const SizedBox(height: AppSpacing.lg),
        if (state.metrics.isEmpty)
          const _EmptyPanel(
            title: 'Chưa có số liệu tổng quan',
            message:
                'Khi dữ liệu Admin sẵn sàng, Nabi sẽ hiển thị các chỉ số vận hành tại đây.',
          )
        else
          _ResponsiveGrid(
            minItemWidth: 220,
            itemHeight: 156,
            children: state.metrics.map(_MetricCard.new).toList(),
          ),
        const SizedBox(height: AppSpacing.xl),
        _SectionTitle(
          title: 'Lối tắt vận hành',
          subtitle: 'Đi nhanh đến các khu vực bạn có quyền xử lý.',
        ),
        const SizedBox(height: AppSpacing.md),
        _ResponsiveGrid(
          minItemWidth: 220,
          itemHeight: 104,
          children: shortcuts
              .map((section) => _ShortcutCard(section: section))
              .toList(),
        ),
      ],
    );
  }
}

class _AdminOverviewPanel extends StatelessWidget {
  final int metricCount;

  const _AdminOverviewPanel({required this.metricCount});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        gradient: AppGradients.dashboard,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: AppShadows.md,
      ),
      child: Wrap(
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: AppSpacing.lg,
        runSpacing: AppSpacing.md,
        children: [
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 680),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Trung tâm vận hành Admin',
                  style: AppTextStyles.heading2.copyWith(
                    color: AppColors.textInverse,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'Theo dõi số liệu, xử lý yêu cầu và kiểm tra audit trong một giao diện gọn hơn.',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.darkTextSecondary,
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
          _OverviewBadge(metricCount: metricCount),
        ],
      ),
    );
  }
}

class _OverviewBadge extends StatelessWidget {
  final int metricCount;

  const _OverviewBadge({required this.metricCount});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: AppColors.textInverse.withValues(alpha: .12),
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(color: AppColors.textInverse.withValues(alpha: .18)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.insights_rounded,
            size: 18,
            color: AppColors.textInverse,
          ),
          const SizedBox(width: AppSpacing.xs),
          Text(
            '$metricCount chỉ số đang theo dõi',
            style: AppTextStyles.labelMedium.copyWith(
              color: AppColors.textInverse,
            ),
          ),
        ],
      ),
    );
  }
}

class _ResponsiveGrid extends StatelessWidget {
  final double minItemWidth;
  final double itemHeight;
  final List<Widget> children;

  const _ResponsiveGrid({
    required this.minItemWidth,
    required this.itemHeight,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    if (children.isEmpty) return const SizedBox.shrink();

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final columns = width >= 1120
            ? 4
            : width >= 760
            ? 2
            : 1;
        final spacing = AppSpacing.md;
        final itemWidth = columns == 1
            ? width
            : (width - spacing * (columns - 1)) / columns;

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: [
            for (final child in children)
              SizedBox(
                width: itemWidth < minItemWidth ? width : itemWidth,
                height: itemHeight,
                child: child,
              ),
          ],
        );
      },
    );
  }
}

class _MetricCard extends StatelessWidget {
  final AdminDashboardMetric metric;

  const _MetricCard(this.metric);

  @override
  Widget build(BuildContext context) {
    final target = AdminPanelSection.fromValue(metric.targetSection);

    return _InteractivePanel(
      onTap: target == null ? null : () => context.go(target.routePath),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _IconBadge(
                  icon: _statusIcon(metric.status),
                  color: _statusColor(metric.status),
                ),
                const Spacer(),
                _StatusChip(status: metric.status),
              ],
            ),
            const Spacer(),
            Text(
              metric.value.toString(),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.heading1,
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              _metricLabel(metric),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ShortcutCard extends StatelessWidget {
  final AdminPanelSection section;

  const _ShortcutCard({required this.section});

  @override
  Widget build(BuildContext context) {
    return _InteractivePanel(
      onTap: () => context.go(section.routePath),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          children: [
            _IconBadge(icon: section.icon, color: AppColors.primary),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    section.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.labelLarge,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    section.guideSummary,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios_rounded,
              size: 16,
              color: AppColors.textHint,
            ),
          ],
        ),
      ),
    );
  }
}

class _WorkQueueView extends StatelessWidget {
  final AdminPanelState state;
  final void Function(
    AdminPanelSection section,
    String action,
    AdminWorkItem item,
    String actionLabel,
  )
  onAction;

  const _WorkQueueView({required this.state, required this.onAction});

  @override
  Widget build(BuildContext context) {
    if (state.items.isEmpty) {
      return _EmptyPanel(
        title: 'Chưa có dữ liệu phù hợp',
        message:
            'Nabi sẽ hiển thị danh sách ${state.section.label.toLowerCase()} khi có dữ liệu mới.',
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionTitle(
          title: 'Danh sách cần xử lý',
          subtitle: '${state.items.length} mục trong ${state.section.label}.',
        ),
        const SizedBox(height: AppSpacing.md),
        for (final item in state.items)
          _WorkItemRow(
            section: state.section,
            session: state.session,
            item: item,
            onAction: onAction,
          ),
      ],
    );
  }
}

class _WorkItemRow extends StatelessWidget {
  final AdminPanelSection section;
  final AdminSession session;
  final AdminWorkItem item;
  final void Function(
    AdminPanelSection section,
    String action,
    AdminWorkItem item,
    String actionLabel,
  )
  onAction;

  const _WorkItemRow({
    required this.section,
    required this.session,
    required this.item,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final actions = section
        .actionsForStatus(item.status)
        .where((action) {
          return session.canRunMutation(
            AdminMutationCommand(
              section: section,
              action: action.key,
              targetId: item.id,
              reason: 'permission-check',
              idempotencyKey: 'permission-check',
            ),
          );
        })
        .toList(growable: false);

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: _InteractivePanel(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final narrow = constraints.maxWidth < 720;
              final header = Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _IconBadge(icon: section.icon, color: AppColors.primary),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(child: _WorkItemText(item: item)),
                  const SizedBox(width: AppSpacing.sm),
                  _StatusChip(status: item.status),
                ],
              );
              final actionWrap = _ActionWrap(
                actions: actions,
                section: section,
                item: item,
                onAction: onAction,
              );
              final payoutDetail = section == AdminPanelSection.saleConversions
                  ? _SaleConversionPayoutDetail(item: item)
                  : null;

              if (narrow) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    header,
                    if (payoutDetail != null) ...[
                      const SizedBox(height: AppSpacing.md),
                      payoutDetail,
                    ],
                    if (actions.isNotEmpty) ...[
                      const SizedBox(height: AppSpacing.md),
                      actionWrap,
                    ],
                  ],
                );
              }

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(child: header),
                      if (actions.isNotEmpty) ...[
                        const SizedBox(width: AppSpacing.md),
                        Flexible(child: actionWrap),
                      ],
                    ],
                  ),
                  if (payoutDetail != null) ...[
                    const SizedBox(height: AppSpacing.md),
                    payoutDetail,
                  ],
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _SaleConversionPayoutDetail extends StatelessWidget {
  final AdminWorkItem item;

  const _SaleConversionPayoutDetail({required this.item});

  @override
  Widget build(BuildContext context) {
    final metadata = item.metadata;
    if (metadata.isEmpty) return const SizedBox.shrink();

    final bankBin = _metadataString(metadata, 'bank_bin');
    final bankName = _metadataString(metadata, 'bank_name');
    final accountNumber = _metadataString(metadata, 'bank_account_number');
    final accountName = _metadataString(metadata, 'bank_account_name');
    final proofPath = _metadataString(metadata, 'payment_proof_path');
    final shortId = item.id.length <= 8 ? item.id : item.id.substring(0, 8);
    final content =
        _metadataString(metadata, 'payment_content') ?? 'SALE $shortId';
    final currency = _metadataString(metadata, 'currency') ?? 'VND';
    final amount = _metadataInt(metadata, 'money_amount_cents');
    final qrPayload =
        _buildVietQrPayload(
          bankBin: bankBin,
          accountNumber: accountNumber,
          accountName: accountName,
          amount: amount,
          content: content,
        ) ??
        _metadataString(metadata, 'vietqr_payload') ??
        _buildFallbackQrPayload(
          bankBin: bankBin,
          accountNumber: accountNumber,
          accountName: accountName,
          amount: amount,
          currency: currency,
          content: content,
        );

    if (bankBin == null &&
        bankName == null &&
        accountNumber == null &&
        accountName == null &&
        amount == 0 &&
        proofPath == null) {
      return const SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.sm),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Wrap(
        spacing: AppSpacing.md,
        runSpacing: AppSpacing.md,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          if (qrPayload != null)
            Container(
              width: 132,
              height: 132,
              padding: const EdgeInsets.all(AppSpacing.xs),
              color: Colors.white,
              child: QrImageView(data: qrPayload, version: QrVersions.auto),
            ),
          SizedBox(
            width: 420,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Thong tin chi tra', style: AppTextStyles.labelLarge),
                const SizedBox(height: AppSpacing.xs),
                _PayoutLine(label: 'Ngan hang', value: bankName ?? bankBin),
                _PayoutLine(label: 'BIN', value: bankBin),
                _PayoutLine(label: 'So tai khoan', value: accountNumber),
                _PayoutLine(label: 'Chu tai khoan', value: accountName),
                _PayoutLine(
                  label: 'So tien',
                  value: _formatMoney(amount, currency),
                ),
                _PayoutLine(label: 'Noi dung', value: content),
                if (proofPath != null)
                  _PayoutLine(label: 'Minh chung', value: proofPath),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PayoutLine extends StatelessWidget {
  final String label;
  final String? value;

  const _PayoutLine({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    if (value == null || value!.trim().isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Text(
        '$label: $value',
        style: AppTextStyles.bodySmall.copyWith(height: 1.35),
      ),
    );
  }
}

class _WorkItemText extends StatelessWidget {
  final AdminWorkItem item;

  const _WorkItemText({required this.item});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          item.title,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: AppTextStyles.labelLarge,
        ),
        if (item.subtitle.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.xs),
          Text(
            item.subtitle,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
        if (item.createdAt != null) ...[
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Tạo lúc ${_formatDateTime(item.createdAt)}',
            style: AppTextStyles.bodySmall,
          ),
        ],
      ],
    );
  }
}

class _ActionWrap extends StatelessWidget {
  final List<_AdminAction> actions;
  final AdminPanelSection section;
  final AdminWorkItem item;
  final void Function(
    AdminPanelSection section,
    String action,
    AdminWorkItem item,
    String actionLabel,
  )
  onAction;

  const _ActionWrap({
    required this.actions,
    required this.section,
    required this.item,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      alignment: WrapAlignment.end,
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: [
        for (final action in actions)
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              foregroundColor: action.isDanger
                  ? AppColors.error
                  : AppColors.primary,
              side: BorderSide(
                color: action.isDanger
                    ? AppColors.error.withValues(alpha: .45)
                    : AppColors.border,
              ),
            ),
            onPressed: () => onAction(section, action.key, item, action.label),
            icon: Icon(action.icon, size: 18),
            label: Text(action.label),
          ),
      ],
    );
  }
}

class _AuditView extends StatelessWidget {
  final List<AdminAuditEvent> events;

  const _AuditView({required this.events});

  @override
  Widget build(BuildContext context) {
    if (events.isEmpty) {
      return const _EmptyPanel(
        title: 'Chưa có audit phù hợp',
        message: 'Audit sẽ hiển thị khi có thao tác Admin được ghi nhận.',
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionTitle(
          title: 'Lịch sử audit',
          subtitle: '${events.length} thao tác gần nhất theo bộ lọc hiện tại.',
        ),
        const SizedBox(height: AppSpacing.md),
        for (final event in events) _AuditRow(event: event),
      ],
    );
  }
}

class _AuditRow extends StatelessWidget {
  final AdminAuditEvent event;

  const _AuditRow({required this.event});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: _InteractivePanel(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Wrap(
            spacing: AppSpacing.md,
            runSpacing: AppSpacing.sm,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              _IconBadge(icon: Icons.history_rounded, color: AppColors.info),
              ConstrainedBox(
                constraints: const BoxConstraints(minWidth: 220, maxWidth: 720),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _auditActionLabel(event.action),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.labelLarge,
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      '${event.target} - ${event.reason}',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              _MetaPill(
                icon: Icons.schedule_rounded,
                text: _formatDateTime(event.createdAt),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ReasonDialog extends StatefulWidget {
  final String actionLabel;

  const _ReasonDialog({required this.actionLabel});

  @override
  State<_ReasonDialog> createState() => _ReasonDialogState();
}

class _ReasonDialogState extends State<_ReasonDialog> {
  final _reason = TextEditingController();

  @override
  void dispose() {
    _reason.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Xác nhận ${widget.actionLabel}'),
      content: SizedBox(
        width: 440,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Vui lòng nhập lý do rõ ràng để hệ thống ghi audit cho thao tác này.',
              style: AppTextStyles.bodyMedium,
            ),
            const SizedBox(height: AppSpacing.md),
            TextField(
              controller: _reason,
              minLines: 3,
              maxLines: 5,
              decoration: const InputDecoration(
                labelText: 'Lý do bắt buộc',
                alignLabelWithHint: true,
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Hủy'),
        ),
        FilledButton.icon(
          onPressed: () => Navigator.of(context).pop(_reason.text),
          icon: const Icon(Icons.check_rounded),
          label: const Text('Xác nhận'),
        ),
      ],
    );
  }
}

class _AdminGuideDialog extends StatelessWidget {
  const _AdminGuideDialog();

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.all(AppSpacing.md),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 760, maxHeight: 720),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            children: [
              Row(
                children: [
                  _IconBadge(
                    icon: Icons.menu_book_rounded,
                    color: AppColors.primary,
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Hướng dẫn sử dụng Admin',
                          style: AppTextStyles.heading3,
                        ),
                        Text(
                          'Các bước thao tác nhanh, an toàn và có audit.',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: 'Đóng',
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              const Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      _GuideSection(
                        icon: Icons.space_dashboard_rounded,
                        title: 'Tổng quan',
                        items: [
                          'Xem các chỉ số vận hành chính trong Dashboard.',
                          'Bấm vào thẻ chỉ số để đi đến khu vực liên quan.',
                          'Dùng nút Làm mới khi cần tải lại dữ liệu mới nhất.',
                        ],
                      ),
                      _GuideSection(
                        icon: Icons.people_rounded,
                        title: 'Người dùng',
                        items: [
                          'Tìm theo email, tên hoặc số điện thoại.',
                          'Tạm khóa hoặc mở lại tài khoản khi có lý do vận hành rõ ràng.',
                          'Không nhập dữ liệu nhạy cảm vào ô lý do.',
                        ],
                      ),
                      _GuideSection(
                        icon: Icons.payments_rounded,
                        title: 'Thanh toán',
                        items: [
                          'Kiểm tra thông tin người thanh toán trước khi duyệt.',
                          'Chọn Duyệt hoặc Từ chối và luôn nhập lý do đầy đủ.',
                          'Các thay đổi quan trọng sẽ được ghi lại trong Audit.',
                        ],
                      ),
                      _GuideSection(
                        icon: Icons.badge_rounded,
                        title: 'Sale và quy đổi điểm',
                        items: [
                          'Duyệt, tạm dừng hoặc đóng hồ sơ Sale theo trạng thái hiện tại.',
                          'Với quy đổi điểm, kiểm tra số điểm và trạng thái trước khi đánh dấu đã chi trả.',
                          'Nếu cần điều chỉnh điểm, ghi lý do ngắn gọn và có thể kiểm chứng.',
                        ],
                      ),
                      _GuideSection(
                        icon: Icons.fact_check_rounded,
                        title: 'Đối soát',
                        items: [
                          'Dùng trạng thái Cần theo dõi khi dữ liệu chưa đủ chắc chắn.',
                          'Chỉ chọn Đã đối soát khi payment, subscription và điểm đã khớp.',
                          'Các quyết định đối soát nên có lý do đủ để người khác đọc lại.',
                        ],
                      ),
                      _GuideSection(
                        icon: Icons.summarize_rounded,
                        title: 'Báo cáo và cấu hình',
                        items: [
                          'Tạo yêu cầu xuất báo cáo theo phạm vi được phân quyền.',
                          'Khi lưu cấu hình, mô tả rõ mục tiêu thay đổi.',
                          'Không dùng giao diện Admin để lưu bí mật hoặc khóa truy cập.',
                        ],
                      ),
                      _GuideSection(
                        icon: Icons.history_rounded,
                        title: 'Audit',
                        items: [
                          'Dùng Audit để kiểm tra ai đã thao tác, thao tác gì và lý do là gì.',
                          'Khi có sai lệch, đối chiếu Audit trước khi xử lý tiếp.',
                          'Không chia sẻ dữ liệu audit ra ngoài nhóm vận hành được phép.',
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Align(
                alignment: Alignment.centerRight,
                child: FilledButton.icon(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.check_rounded),
                  label: const Text('Đã hiểu'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GuideSection extends StatelessWidget {
  final IconData icon;
  final String title;
  final List<String> items;

  const _GuideSection({
    required this.icon,
    required this.title,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: _panelDecoration(elevated: false),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _IconBadge(icon: icon, color: AppColors.primary),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTextStyles.labelLarge),
                const SizedBox(height: AppSpacing.sm),
                for (final item in items)
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Padding(
                          padding: EdgeInsets.only(top: 6),
                          child: Icon(
                            Icons.circle,
                            size: 5,
                            color: AppColors.textHint,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: Text(
                            item,
                            style: AppTextStyles.bodyMedium.copyWith(
                              height: 1.45,
                            ),
                          ),
                        ),
                      ],
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

class _InteractivePanel extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;

  const _InteractivePanel({required this.child, this.onTap});

  @override
  State<_InteractivePanel> createState() => _InteractivePanelState();
}

class _InteractivePanelState extends State<_InteractivePanel> {
  var _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: AppDuration.card,
        curve: Curves.easeOutCubic,
        transform: Matrix4.translationValues(0, _hovered ? -2 : 0, 0),
        decoration: _panelDecoration(
          elevated: _hovered || widget.onTap != null,
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(AppRadius.lg),
            onTap: widget.onTap,
            child: widget.child,
          ),
        ),
      ),
    );
  }
}

class _IconBadge extends StatelessWidget {
  final IconData icon;
  final Color color;

  const _IconBadge({required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        color: color.withValues(alpha: .12),
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Icon(icon, color: color, size: 22),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String status;

  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    final color = _statusColor(status);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: color.withValues(alpha: .12),
        borderRadius: BorderRadius.circular(AppRadius.badge),
        border: Border.all(color: color.withValues(alpha: .18)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: 6,
        ),
        child: Text(
          _statusLabel(status),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppTextStyles.bodySmall.copyWith(
            color: color,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class _MetaPill extends StatelessWidget {
  final IconData icon;
  final String text;

  const _MetaPill({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    if (text.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: AppColors.cardAlt,
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: AppColors.textSecondary),
          const SizedBox(width: AppSpacing.xs),
          Text(text, style: AppTextStyles.bodySmall),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  final String subtitle;

  const _SectionTitle({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: AppTextStyles.heading3),
        const SizedBox(height: AppSpacing.xs),
        Text(
          subtitle,
          style: AppTextStyles.bodySmall.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}

class _EmptyPanel extends StatelessWidget {
  final String title;
  final String message;

  const _EmptyPanel({required this.title, required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(AppSpacing.xl),
          decoration: _panelDecoration(),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const _IconBadge(
                icon: Icons.inbox_rounded,
                color: AppColors.textHint,
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                title,
                textAlign: TextAlign.center,
                style: AppTextStyles.heading3,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                message,
                textAlign: TextAlign.center,
                style: AppTextStyles.bodyMedium.copyWith(height: 1.45),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PermissionDeniedPanel extends StatelessWidget {
  final AdminPanelSection section;
  final String permission;

  const _PermissionDeniedPanel({
    required this.section,
    required this.permission,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(AppSpacing.xl),
          decoration: _panelDecoration(),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const _IconBadge(
                icon: Icons.lock_person_rounded,
                color: AppColors.warning,
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                'Không đủ quyền ${section.label}',
                textAlign: TextAlign.center,
                style: AppTextStyles.heading3,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Tài khoản Admin hiện tại cần quyền $permission để mở mục này.',
                textAlign: TextAlign.center,
                style: AppTextStyles.bodyMedium.copyWith(height: 1.45),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BlockingState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final String actionLabel;
  final VoidCallback onAction;

  const _BlockingState({
    required this.icon,
    required this.title,
    required this.message,
    required this.actionLabel,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(AppSpacing.xl),
          decoration: _panelDecoration(),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _IconBadge(icon: icon, color: AppColors.primary),
              const SizedBox(height: AppSpacing.md),
              Text(
                title,
                textAlign: TextAlign.center,
                style: AppTextStyles.heading3,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                message,
                textAlign: TextAlign.center,
                style: AppTextStyles.bodyMedium.copyWith(height: 1.45),
              ),
              const SizedBox(height: AppSpacing.lg),
              FilledButton.icon(
                onPressed: onAction,
                icon: const Icon(Icons.arrow_forward_rounded),
                label: Text(actionLabel),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AdminAction {
  final String key;
  final String label;
  final IconData icon;

  const _AdminAction(this.key, this.label, this.icon);

  bool get isDanger {
    return key == 'reject' ||
        key == 'suspended' ||
        key == 'suspend' ||
        key == 'close' ||
        key == 'dismissed';
  }
}

extension _AdminPanelSectionUi on AdminPanelSection {
  String get label {
    return switch (this) {
      AdminPanelSection.dashboard => 'Dashboard',
      AdminPanelSection.users => 'Người dùng',
      AdminPanelSection.payments => 'Thanh toán',
      AdminPanelSection.sales => 'Sale',
      AdminPanelSection.saleConversions => 'Quy đổi điểm Sale',
      AdminPanelSection.reconciliation => 'Đối soát',
      AdminPanelSection.plans => 'Gói dịch vụ',
      AdminPanelSection.reports => 'Báo cáo',
      AdminPanelSection.audit => 'Audit',
      AdminPanelSection.config => 'Cấu hình',
    };
  }

  String get guideSummary {
    return switch (this) {
      AdminPanelSection.dashboard => 'Theo dõi số liệu chính',
      AdminPanelSection.users => 'Quản lý trạng thái tài khoản',
      AdminPanelSection.payments => 'Duyệt và kiểm tra thanh toán',
      AdminPanelSection.sales => 'Duyệt hồ sơ Sale',
      AdminPanelSection.saleConversions => 'Xử lý quy đổi điểm',
      AdminPanelSection.reconciliation => 'Kiểm tra sai lệch vận hành',
      AdminPanelSection.plans => 'Cập nhật gói dịch vụ',
      AdminPanelSection.reports => 'Yêu cầu xuất báo cáo',
      AdminPanelSection.audit => 'Xem lịch sử thao tác',
      AdminPanelSection.config => 'Quản lý cấu hình hệ thống',
    };
  }

  String get routePath {
    return switch (this) {
      AdminPanelSection.dashboard => AdminRoutePaths.dashboard,
      AdminPanelSection.users => AdminRoutePaths.users,
      AdminPanelSection.payments => AdminRoutePaths.payments,
      AdminPanelSection.sales => AdminRoutePaths.sales,
      AdminPanelSection.saleConversions => AdminRoutePaths.saleConversions,
      AdminPanelSection.reconciliation => AdminRoutePaths.reconciliation,
      AdminPanelSection.plans => AdminRoutePaths.plans,
      AdminPanelSection.reports => AdminRoutePaths.reports,
      AdminPanelSection.audit => AdminRoutePaths.audit,
      AdminPanelSection.config => AdminRoutePaths.config,
    };
  }

  IconData get icon {
    return switch (this) {
      AdminPanelSection.dashboard => Icons.space_dashboard_outlined,
      AdminPanelSection.users => Icons.people_outline_rounded,
      AdminPanelSection.payments => Icons.payments_outlined,
      AdminPanelSection.sales => Icons.badge_outlined,
      AdminPanelSection.saleConversions =>
        Icons.published_with_changes_outlined,
      AdminPanelSection.reconciliation => Icons.fact_check_outlined,
      AdminPanelSection.plans => Icons.workspace_premium_outlined,
      AdminPanelSection.reports => Icons.summarize_outlined,
      AdminPanelSection.audit => Icons.history_outlined,
      AdminPanelSection.config => Icons.tune_outlined,
    };
  }

  IconData get selectedIcon {
    return switch (this) {
      AdminPanelSection.dashboard => Icons.space_dashboard_rounded,
      AdminPanelSection.users => Icons.people_rounded,
      AdminPanelSection.payments => Icons.payments_rounded,
      AdminPanelSection.sales => Icons.badge_rounded,
      AdminPanelSection.saleConversions => Icons.published_with_changes_rounded,
      AdminPanelSection.reconciliation => Icons.fact_check_rounded,
      AdminPanelSection.plans => Icons.workspace_premium_rounded,
      AdminPanelSection.reports => Icons.summarize_rounded,
      AdminPanelSection.audit => Icons.history_rounded,
      AdminPanelSection.config => Icons.tune_rounded,
    };
  }

  List<_AdminAction> get actions {
    return switch (this) {
      AdminPanelSection.users => const [
        _AdminAction('active', 'Mở lại', Icons.lock_open_rounded),
        _AdminAction('suspended', 'Tạm khóa', Icons.lock_rounded),
      ],
      AdminPanelSection.payments => const [
        _AdminAction('approve', 'Duyệt', Icons.verified_rounded),
        _AdminAction('reject', 'Từ chối', Icons.block_rounded),
      ],
      AdminPanelSection.sales => const [
        _AdminAction('approve', 'Duyệt', Icons.verified_user_rounded),
        _AdminAction('reject', 'Từ chối', Icons.block_rounded),
        _AdminAction('suspend', 'Tạm dừng', Icons.pause_circle_rounded),
        _AdminAction('close', 'Đóng Sale', Icons.cancel_rounded),
      ],
      AdminPanelSection.saleConversions => const [
        _AdminAction('approve', 'Duyệt', Icons.verified_rounded),
        _AdminAction('reject', 'Từ chối', Icons.block_rounded),
        _AdminAction('mark_paid', 'Đã chi trả', Icons.payments_rounded),
      ],
      AdminPanelSection.reconciliation => const [
        _AdminAction('resolved', 'Đã đối soát', Icons.task_alt_rounded),
        _AdminAction(
          'needs_follow_up',
          'Cần theo dõi',
          Icons.manage_search_rounded,
        ),
        _AdminAction('adjusted', 'Điều chỉnh điểm', Icons.tune_rounded),
        _AdminAction('dismissed', 'Bỏ qua', Icons.close_rounded),
      ],
      AdminPanelSection.plans => const [
        _AdminAction('upsert', 'Cập nhật', Icons.save_rounded),
      ],
      AdminPanelSection.reports => const [
        _AdminAction('export', 'Xuất', Icons.download_rounded),
      ],
      AdminPanelSection.config => const [
        _AdminAction('upsert', 'Lưu phiên bản', Icons.save_as_rounded),
      ],
      AdminPanelSection.dashboard => const [],
      AdminPanelSection.audit => const [],
    };
  }

  List<_AdminAction> actionsForStatus(String status) {
    final normalized = status.toLowerCase();
    final all = actions;

    return switch (this) {
      AdminPanelSection.users when normalized.contains('closed') => const [],
      AdminPanelSection.users when normalized.contains('active') =>
        all
            .where((action) => action.key == 'suspended')
            .toList(growable: false),
      AdminPanelSection.users when normalized.contains('suspended') =>
        all.where((action) => action.key == 'active').toList(growable: false),
      AdminPanelSection.payments
          when !normalized.contains('pending') &&
              !normalized.contains('review') =>
        const [],
      AdminPanelSection.sales when normalized.contains('closed') => const [],
      AdminPanelSection.sales when normalized.contains('pending') =>
        all
            .where(
              (action) => action.key == 'approve' || action.key == 'reject',
            )
            .toList(growable: false),
      AdminPanelSection.sales when normalized.contains('active') =>
        all
            .where((action) => action.key == 'suspend' || action.key == 'close')
            .toList(growable: false),
      AdminPanelSection.sales when normalized.contains('suspended') =>
        all
            .where((action) => action.key == 'approve' || action.key == 'close')
            .toList(growable: false),
      AdminPanelSection.saleConversions when normalized.contains('approved') =>
        all
            .where((action) => action.key == 'mark_paid')
            .toList(growable: false),
      AdminPanelSection.saleConversions
          when normalized.contains('paid') || normalized.contains('rejected') =>
        const [],
      AdminPanelSection.reconciliation
          when normalized.contains('resolved') ||
              normalized.contains('dismissed') ||
              normalized.contains('adjusted') =>
        const [],
      _ => all,
    };
  }
}

BoxDecoration _panelDecoration({bool elevated = true}) {
  return BoxDecoration(
    color: AppColors.surface,
    borderRadius: BorderRadius.circular(AppRadius.lg),
    border: Border.all(color: AppColors.border),
    boxShadow: elevated ? AppShadows.card : const [],
  );
}

String _metricLabel(AdminDashboardMetric metric) {
  return switch (metric.key) {
    'users_total' => 'Người dùng',
    'payments_pending' => 'Thanh toán chờ duyệt',
    'sales_active' => 'Sale đang hoạt động',
    'commission_available' => 'Điểm Sale khả dụng',
    _ => metric.label,
  };
}

String _statusLabel(String status) {
  final normalized = status.toLowerCase();
  if (normalized.contains('pending_review')) return 'Đang chờ duyệt';
  if (normalized.contains('needs_follow_up')) return 'Cần theo dõi';
  if (normalized.contains('requested')) return 'Đã yêu cầu';
  if (normalized.contains('pending')) return 'Đang chờ';
  if (normalized.contains('succeeded')) return 'Thành công';
  if (normalized.contains('approved')) return 'Đã duyệt';
  if (normalized.contains('active')) return 'Đang hoạt động';
  if (normalized.contains('suspended')) return 'Tạm khóa';
  if (normalized.contains('closed')) return 'Đã đóng';
  if (normalized.contains('cancelled') || normalized.contains('canceled')) {
    return 'Đã hủy';
  }
  if (normalized.contains('refunded')) return 'Đã hoàn tiền';
  if (normalized.contains('chargeback')) return 'Khiếu nại';
  if (normalized.contains('failed')) return 'Thất bại';
  if (normalized.contains('rejected')) return 'Từ chối';
  if (normalized.contains('paid')) return 'Đã chi trả';
  if (normalized.contains('resolved')) return 'Đã đối soát';
  if (normalized.contains('adjusted')) return 'Đã điều chỉnh';
  if (normalized.contains('dismissed')) return 'Đã bỏ qua';
  if (normalized.contains('ready')) return 'Sẵn sàng';
  if (normalized.contains('draft')) return 'Bản nháp';
  if (normalized.contains('archived')) return 'Lưu trữ';
  if (normalized.contains('open')) return 'Đang mở';
  if (normalized.contains('generating')) return 'Đang tạo';
  return status.replaceAll('_', ' ');
}

Color _statusColor(String status) {
  final normalized = status.toLowerCase();
  if (normalized.contains('fail') ||
      normalized.contains('reject') ||
      normalized.contains('suspend') ||
      normalized.contains('chargeback')) {
    return AppColors.error;
  }
  if (normalized.contains('pending') ||
      normalized.contains('review') ||
      normalized.contains('requested') ||
      normalized.contains('open') ||
      normalized.contains('follow')) {
    return AppColors.warning;
  }
  if (normalized.contains('active') ||
      normalized.contains('approved') ||
      normalized.contains('ready') ||
      normalized.contains('succeeded') ||
      normalized.contains('resolved') ||
      normalized.contains('paid')) {
    return AppColors.success;
  }
  if (normalized.contains('closed') ||
      normalized.contains('cancel') ||
      normalized.contains('archived') ||
      normalized.contains('dismissed')) {
    return AppColors.textMuted;
  }
  return AppColors.info;
}

IconData _statusIcon(String status) {
  final normalized = status.toLowerCase();
  if (normalized.contains('fail') || normalized.contains('reject')) {
    return Icons.error_outline_rounded;
  }
  if (normalized.contains('pending') || normalized.contains('requested')) {
    return Icons.pending_actions_rounded;
  }
  if (normalized.contains('paid') || normalized.contains('succeeded')) {
    return Icons.task_alt_rounded;
  }
  return Icons.insights_rounded;
}

String? _metadataString(Map<String, Object?> metadata, String key) {
  final value = metadata[key]?.toString().trim();
  return value == null || value.isEmpty ? null : value;
}

int _metadataInt(Map<String, Object?> metadata, String key) {
  final value = metadata[key];
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? 0;
}

String? _buildVietQrPayload({
  required String? bankBin,
  required String? accountNumber,
  required String? accountName,
  required int amount,
  required String content,
}) {
  if (bankBin == null ||
      accountNumber == null ||
      accountName == null ||
      amount <= 0) {
    return null;
  }

  final beneficiary = _emv('00', bankBin) + _emv('01', accountNumber);
  final merchantAccount =
      "${_emv('00', 'A000000727')}${_emv('01', beneficiary)}${_emv('02', 'QRIBFTTA')}";
  final additionalData = _emv('08', _qrAscii(content, maxLength: 40));
  final raw =
      "${_emv('00', '01')}${_emv('01', '12')}${_emv('38', merchantAccount)}${_emv('53', '704')}${_emv('54', amount.toString())}${_emv('58', 'VN')}${_emv('59', _qrAscii(accountName, maxLength: 25))}${_emv('62', additionalData)}6304";
  return '$raw${_crc16Ccitt(raw)}';
}

String _emv(String id, String value) {
  final length = value.length.toString().padLeft(2, '0');
  return '$id$length$value';
}

String _qrAscii(String value, {required int maxLength}) {
  final ascii = value
      .toUpperCase()
      .replaceAll(RegExp(r'[^A-Z0-9 ]'), ' ')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
  if (ascii.isEmpty) return 'NANOBIO';
  return ascii.length <= maxLength ? ascii : ascii.substring(0, maxLength);
}

String _crc16Ccitt(String input) {
  var crc = 0xFFFF;
  for (final unit in input.codeUnits) {
    crc ^= unit << 8;
    for (var i = 0; i < 8; i++) {
      crc = (crc & 0x8000) != 0 ? (crc << 1) ^ 0x1021 : crc << 1;
      crc &= 0xFFFF;
    }
  }
  return crc.toRadixString(16).toUpperCase().padLeft(4, '0');
}

String? _buildFallbackQrPayload({
  required String? bankBin,
  required String? accountNumber,
  required String? accountName,
  required int amount,
  required String currency,
  required String content,
}) {
  if (bankBin == null || accountNumber == null || accountName == null) {
    return null;
  }
  return [
    'VIETQR',
    bankBin,
    accountNumber,
    accountName,
    amount.toString(),
    currency,
    content,
  ].join('|');
}

String _formatMoney(int amount, String currency) {
  final sign = amount < 0 ? '-' : '';
  final digits = amount.abs().toString();
  final buffer = StringBuffer();
  for (var i = 0; i < digits.length; i++) {
    final remaining = digits.length - i;
    buffer.write(digits[i]);
    if (remaining > 1 && remaining % 3 == 1) buffer.write(',');
  }
  return '$sign$buffer $currency';
}

String _formatDateTime(DateTime? dateTime) {
  if (dateTime == null) return '';
  final local = dateTime.toLocal();
  final day = local.day.toString().padLeft(2, '0');
  final month = local.month.toString().padLeft(2, '0');
  final hour = local.hour.toString().padLeft(2, '0');
  final minute = local.minute.toString().padLeft(2, '0');
  return '$day/$month/${local.year} $hour:$minute';
}

String _auditActionLabel(String action) {
  return switch (action) {
    'admin_update_user_status' => 'Cập nhật trạng thái người dùng',
    'admin_review_payment' => 'Duyệt thanh toán',
    'admin_refund_or_cancel_payment' => 'Hoàn hủy thanh toán',
    'admin_review_sale_profile' => 'Duyệt hồ sơ Sale',
    'admin_upsert_config_version' => 'Lưu cấu hình',
    'admin_request_report_export' => 'Yêu cầu xuất báo cáo',
    'admin_adjust_sale_points' => 'Điều chỉnh điểm Sale',
    'admin_create_reconciliation_run' => 'Tạo phiên đối soát',
    'admin_update_reconciliation_discrepancy_status' => 'Cập nhật đối soát',
    'admin_review_sale_point_conversion' => 'Duyệt quy đổi điểm',
    _ => action.replaceAll('_', ' '),
  };
}
