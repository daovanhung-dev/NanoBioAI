part of 'admin_workspace_page.dart';

class _AdminSidebar extends StatelessWidget {
  const _AdminSidebar({
    required this.selected,
    required this.sections,
    required this.extended,
    required this.onSelected,
    required this.onShowGuide,
    required this.onShowUserApp,
    required this.onSignOut,
  });

  final AdminPanelSection selected;
  final List<AdminPanelSection> sections;
  final bool extended;
  final ValueChanged<AdminPanelSection> onSelected;
  final VoidCallback onShowGuide;
  final VoidCallback? onShowUserApp;
  final VoidCallback onSignOut;

  @override
  Widget build(BuildContext context) {
    final colors = context.adminColors;
    final width = extended
        ? AdminWorkspaceTheme.sidebarWidth
        : AdminWorkspaceTheme.compactSidebarWidth;
    return Container(
      width: width,
      decoration: BoxDecoration(
        color: colors.sidebar,
        border: Border(right: BorderSide(color: colors.divider)),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(10, 14, 10, 12),
          child: Column(
            children: [
              _AdminBrand(extended: extended),
              const SizedBox(height: 16),
              Expanded(
                child: ListView(
                  padding: EdgeInsets.zero,
                  children: [
                    for (final group in _navigationGroups(sections)) ...[
                      if (extended)
                        Padding(
                          padding: const EdgeInsets.fromLTRB(10, 14, 10, 6),
                          child: Text(
                            group.label,
                            style: AppTextStyles.labelSmall.copyWith(
                              color: colors.textMuted,
                              fontWeight: FontWeight.w700,
                              letterSpacing: .45,
                            ),
                          ),
                        ),
                      for (final section in group.sections)
                        _SidebarDestination(
                          section: section,
                          selected: section == selected,
                          extended: extended,
                          onTap: () => onSelected(section),
                        ),
                    ],
                  ],
                ),
              ),
              const Divider(height: 20),
              _SidebarUtility(
                icon: Icons.help_outline_rounded,
                label: 'Hướng dẫn',
                extended: extended,
                onPressed: onShowGuide,
              ),
              if (onShowUserApp != null)
                _SidebarUtility(
                  icon: Icons.open_in_new_rounded,
                  label: 'Ứng dụng người dùng',
                  extended: extended,
                  onPressed: onShowUserApp!,
                ),
              _SidebarUtility(
                icon: Icons.logout_rounded,
                label: 'Đăng xuất',
                extended: extended,
                danger: true,
                onPressed: onSignOut,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AdminNavigationDrawer extends StatelessWidget {
  const _AdminNavigationDrawer({
    required this.selected,
    required this.sections,
    required this.onSelected,
    required this.onShowGuide,
    required this.onShowUserApp,
    required this.onSignOut,
  });

  final AdminPanelSection selected;
  final List<AdminPanelSection> sections;
  final ValueChanged<AdminPanelSection> onSelected;
  final VoidCallback onShowGuide;
  final VoidCallback? onShowUserApp;
  final VoidCallback onSignOut;

  @override
  Widget build(BuildContext context) {
    final colors = context.adminColors;
    return Drawer(
      child: SafeArea(
        child: Column(
          children: [
            const Padding(
              padding: EdgeInsets.all(16),
              child: _AdminBrand(extended: true),
            ),
            const Divider(height: 1),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(10),
                children: [
                  for (final group in _navigationGroups(sections)) ...[
                    Padding(
                      padding: const EdgeInsets.fromLTRB(10, 14, 10, 6),
                      child: Text(
                        group.label,
                        style: AppTextStyles.labelSmall.copyWith(
                          color: colors.textMuted,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    for (final section in group.sections)
                      _SidebarDestination(
                        section: section,
                        selected: section == selected,
                        extended: true,
                        onTap: () {
                          Navigator.of(context).pop();
                          onSelected(section);
                        },
                      ),
                  ],
                ],
              ),
            ),
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                children: [
                  _SidebarUtility(
                    icon: Icons.help_outline_rounded,
                    label: 'Hướng dẫn',
                    extended: true,
                    onPressed: () {
                      Navigator.of(context).pop();
                      onShowGuide();
                    },
                  ),
                  if (onShowUserApp != null)
                    _SidebarUtility(
                      icon: Icons.open_in_new_rounded,
                      label: 'Ứng dụng người dùng',
                      extended: true,
                      onPressed: onShowUserApp!,
                    ),
                  _SidebarUtility(
                    icon: Icons.logout_rounded,
                    label: 'Đăng xuất',
                    extended: true,
                    danger: true,
                    onPressed: onSignOut,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AdminBrand extends StatelessWidget {
  const _AdminBrand({required this.extended});

  final bool extended;

  @override
  Widget build(BuildContext context) {
    final colors = context.adminColors;
    final icon = Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        color: colors.brandSurface,
        borderRadius: BorderRadius.circular(11),
      ),
      child: const Icon(
        Icons.admin_panel_settings_rounded,
        color: Colors.white,
        size: 23,
      ),
    );
    if (!extended) {
      return Tooltip(message: 'NanoBio Quản trị', child: icon);
    }
    return Row(
      children: [
        icon,
        const SizedBox(width: 11),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'NanoBio',
                style: AppTextStyles.labelLarge.copyWith(
                  color: colors.text,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Text(
                'Không gian quản trị',
                style: AppTextStyles.bodySmall.copyWith(
                  color: colors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SidebarDestination extends StatelessWidget {
  const _SidebarDestination({
    required this.section,
    required this.selected,
    required this.extended,
    required this.onTap,
  });

  final AdminPanelSection section;
  final bool selected;
  final bool extended;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.adminColors;
    final foreground = selected ? colors.blueStrong : colors.textSecondary;
    final tile = Padding(
      padding: const EdgeInsets.only(bottom: 3),
      child: Material(
        color: selected ? colors.selected : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          onTap: selected ? null : onTap,
          borderRadius: BorderRadius.circular(10),
          hoverColor: colors.hover,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 48),
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: extended ? 11 : 8,
                vertical: 8,
              ),
              child: Row(
                mainAxisAlignment:
                    extended ? MainAxisAlignment.start : MainAxisAlignment.center,
                children: [
                  Icon(
                    _iconForSection(section, selected),
                    size: 21,
                    color: foreground,
                  ),
                  if (extended) ...[
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        AdminUiCopy.sectionLabel(section),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.labelMedium.copyWith(
                          color: foreground,
                          fontWeight:
                              selected ? FontWeight.w700 : FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
    if (extended) return tile;
    return Tooltip(message: AdminUiCopy.sectionLabel(section), child: tile);
  }
}

class _SidebarUtility extends StatelessWidget {
  const _SidebarUtility({
    required this.icon,
    required this.label,
    required this.extended,
    required this.onPressed,
    this.danger = false,
  });

  final IconData icon;
  final String label;
  final bool extended;
  final bool danger;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final colors = context.adminColors;
    final color = danger ? colors.danger : colors.textSecondary;
    final child = Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(10),
        hoverColor: colors.hover,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 48),
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: extended ? 11 : 8,
              vertical: 8,
            ),
            child: Row(
              mainAxisAlignment:
                  extended ? MainAxisAlignment.start : MainAxisAlignment.center,
              children: [
                Icon(icon, size: 20, color: color),
                if (extended) ...[
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      label,
                      style: AppTextStyles.labelMedium.copyWith(color: color),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
    if (extended) return child;
    return Tooltip(message: label, child: child);
  }
}

class _AdminToolbar extends StatelessWidget {
  const _AdminToolbar({
    required this.state,
    required this.compact,
    required this.busy,
    required this.searchController,
    required this.onMenuPressed,
    required this.onSearchChanged,
    required this.onClearSearch,
    required this.onRefresh,
    required this.onShowGuide,
    required this.onShowUserApp,
    required this.onSignOut,
  });

  final AdminPanelState state;
  final bool compact;
  final bool busy;
  final TextEditingController searchController;
  final VoidCallback? onMenuPressed;
  final ValueChanged<String> onSearchChanged;
  final VoidCallback onClearSearch;
  final VoidCallback onRefresh;
  final VoidCallback onShowGuide;
  final VoidCallback? onShowUserApp;
  final VoidCallback onSignOut;

  @override
  Widget build(BuildContext context) {
    final colors = context.adminColors;
    final searchable =
        state.section != AdminPanelSection.dashboard && !state.isPermissionDenied;

    return Container(
      color: colors.toolbar,
      padding: EdgeInsets.fromLTRB(
        compact ? 12 : 20,
        10,
        compact ? 10 : 16,
        10,
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final narrow = constraints.maxWidth < 700;
          final header = Row(
            children: [
              if (onMenuPressed != null) ...[
                IconButton(
                  tooltip: 'Mở danh mục',
                  onPressed: onMenuPressed,
                  icon: const Icon(Icons.menu_rounded),
                ),
                const SizedBox(width: 4),
              ],
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: colors.selected,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  _iconForSection(state.section, true),
                  color: colors.blueStrong,
                  size: 21,
                ),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AdminUiCopy.sectionLabel(state.section),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.heading4.copyWith(color: colors.text),
                    ),
                    if (!narrow)
                      Text(
                        AdminUiCopy.sectionDescription(state.section),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.bodySmall.copyWith(
                          color: colors.textSecondary,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          );
          final actions = _ToolbarMenu(
            busy: busy,
            onRefresh: onRefresh,
            onShowGuide: onShowGuide,
            onShowUserApp: onShowUserApp,
            onSignOut: onSignOut,
          );

          if (narrow) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(children: [Expanded(child: header), actions]),
                if (searchable) ...[
                  const SizedBox(height: 10),
                  _AdminSearchField(
                    controller: searchController,
                    section: state.section,
                    onChanged: onSearchChanged,
                    onClear: onClearSearch,
                  ),
                ],
              ],
            );
          }

          return Row(
            children: [
              Expanded(child: header),
              if (searchable) ...[
                const SizedBox(width: 14),
                SizedBox(
                  width: constraints.maxWidth > 1000 ? 340 : 260,
                  child: _AdminSearchField(
                    controller: searchController,
                    section: state.section,
                    onChanged: onSearchChanged,
                    onClear: onClearSearch,
                  ),
                ),
              ],
              const SizedBox(width: 8),
              actions,
            ],
          );
        },
      ),
    );
  }
}

class _AdminSearchField extends StatelessWidget {
  const _AdminSearchField({
    required this.controller,
    required this.section,
    required this.onChanged,
    required this.onClear,
  });

  final TextEditingController controller;
  final AdminPanelSection section;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: controller,
      builder: (context, value, child) {
        return TextField(
          controller: controller,
          onChanged: onChanged,
          textInputAction: TextInputAction.search,
          decoration: InputDecoration(
            hintText: 'Tìm trong ${AdminUiCopy.sectionLabel(section)}',
            prefixIcon: const Icon(Icons.search_rounded, size: 20),
            suffixIcon: value.text.trim().isEmpty
                ? null
                : IconButton(
                    tooltip: 'Xóa nội dung tìm kiếm',
                    onPressed: onClear,
                    icon: const Icon(Icons.close_rounded, size: 19),
                  ),
          ),
        );
      },
    );
  }
}

class _ToolbarMenu extends StatelessWidget {
  const _ToolbarMenu({
    required this.busy,
    required this.onRefresh,
    required this.onShowGuide,
    required this.onShowUserApp,
    required this.onSignOut,
  });

  final bool busy;
  final VoidCallback onRefresh;
  final VoidCallback onShowGuide;
  final VoidCallback? onShowUserApp;
  final VoidCallback onSignOut;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          tooltip: 'Làm mới dữ liệu',
          onPressed: busy ? null : onRefresh,
          icon: const Icon(Icons.refresh_rounded),
        ),
        PopupMenuButton<_ToolbarAction>(
          tooltip: 'Thêm lựa chọn',
          icon: const Icon(Icons.more_horiz_rounded),
          onSelected: (value) {
            switch (value) {
              case _ToolbarAction.guide:
                onShowGuide();
                return;
              case _ToolbarAction.userApp:
                onShowUserApp?.call();
                return;
              case _ToolbarAction.signOut:
                onSignOut();
                return;
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: _ToolbarAction.guide,
              child: _MenuItem(
                icon: Icons.help_outline_rounded,
                label: 'Hướng dẫn',
              ),
            ),
            if (onShowUserApp != null)
              const PopupMenuItem(
                value: _ToolbarAction.userApp,
                child: _MenuItem(
                  icon: Icons.open_in_new_rounded,
                  label: 'Ứng dụng người dùng',
                ),
              ),
            const PopupMenuDivider(),
            const PopupMenuItem(
              value: _ToolbarAction.signOut,
              child: _MenuItem(
                icon: Icons.logout_rounded,
                label: 'Đăng xuất',
                danger: true,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

enum _ToolbarAction { guide, userApp, signOut }

class _MenuItem extends StatelessWidget {
  const _MenuItem({required this.icon, required this.label, this.danger = false});

  final IconData icon;
  final String label;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final colors = context.adminColors;
    final color = danger ? colors.danger : colors.textSecondary;
    return Row(
      children: [
        Icon(icon, size: 19, color: color),
        const SizedBox(width: 10),
        Text(label, style: TextStyle(color: color)),
      ],
    );
  }
}

class _PaymentReviewNotice extends StatelessWidget {
  const _PaymentReviewNotice({required this.count, required this.onOpen});

  final int count;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final colors = context.adminColors;
    return Material(
      color: colors.warningContainer,
      child: InkWell(
        onTap: onOpen,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 48),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 9),
            child: Row(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: colors.warning,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    '$count',
                    style: AppTextStyles.labelSmall.copyWith(
                      color: colors.onAccent,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    '$count thanh toán đang chờ bạn kiểm tra.',
                    style: AppTextStyles.labelMedium.copyWith(
                      color: colors.onWarningContainer,
                    ),
                  ),
                ),
                TextButton(onPressed: onOpen, child: const Text('Mở danh sách')),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
