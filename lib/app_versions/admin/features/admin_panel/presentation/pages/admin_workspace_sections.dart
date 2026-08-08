part of 'admin_workspace_page.dart';

class _AdminContentHost extends StatelessWidget {
  final AdminPanelState state;
  final bool busy;
  final String? runningTargetId;
  final void Function(
    AdminPanelSection section,
    AdminActionPresentation action,
    AdminWorkItem item,
  )
  onAction;
  final ValueChanged<AdminPanelSection> onGoToSection;
  final VoidCallback onClearSearch;

  const _AdminContentHost({
    required this.state,
    required this.busy,
    required this.runningTargetId,
    required this.onAction,
    required this.onGoToSection,
    required this.onClearSearch,
  });

  @override
  Widget build(BuildContext context) {
    final child = state.isPermissionDenied
        ? _PermissionDeniedView(
            section: state.section,
            permission: state.deniedPermission ?? '',
          )
        : switch (state.section) {
            AdminPanelSection.dashboard => _DashboardSection(
              state: state,
              onOpenSection: onGoToSection,
            ),
            AdminPanelSection.audit => _AuditSection(
              events: state.auditEvents,
              query: state.query,
            ),
            AdminPanelSection.wellnessRewards => AdminWellnessRewardsPanel(
              canWrite: state.session.hasPermission(
                AdminPermissions.wellnessRewardsWrite,
              ),
            ),
            _ => _WorkQueueSection(
              state: state,
              runningTargetId: runningTargetId,
              onAction: onAction,
              onClearSearch: onClearSearch,
            ),
          };

    return Stack(
      children: [
        Positioned.fill(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(18, 20, 18, 44),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: AdminWorkspaceTheme.contentMaxWidth,
                ),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 180),
                  switchInCurve: Curves.easeOutCubic,
                  switchOutCurve: Curves.easeInCubic,
                  child: KeyedSubtree(
                    key: ValueKey(
                      '${state.section.value}-${state.isPermissionDenied}',
                    ),
                    child: child,
                  ),
                ),
              ),
            ),
          ),
        ),
        if (busy) Positioned(top: 10, right: 18, child: const _BusyPill()),
      ],
    );
  }
}

class _BusyPill extends StatelessWidget {
  const _BusyPill();

  @override
  Widget build(BuildContext context) {
    final colors = context.adminColors;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
      decoration: BoxDecoration(
        color: colors.panel,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colors.border),
        boxShadow: [
          BoxShadow(color: colors.shadow, blurRadius: 12, offset: Offset(0, 3)),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox.square(
            dimension: 14,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          const SizedBox(width: 8),
          Text(
            'Đang cập nhật',
            style: AppTextStyles.bodySmall.copyWith(
              color: colors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _DashboardSection extends StatelessWidget {
  final AdminPanelState state;
  final ValueChanged<AdminPanelSection> onOpenSection;

  const _DashboardSection({required this.state, required this.onOpenSection});

  @override
  Widget build(BuildContext context) {
    final shortcuts = AdminPanelSection.values
        .where((section) => section != AdminPanelSection.dashboard)
        .where(state.session.canAccessSection)
        .toList(growable: false);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _PageIntro(
          eyebrow: 'TRUNG TÂM VẬN HÀNH',
          title: 'Tổng quan hôm nay',
          description:
              'Theo dõi các chỉ số chính và mở nhanh những khu vực cần xử lý.',
          trailing: _SessionBadge(roleCount: state.session.roles.length),
        ),
        const SizedBox(height: 18),
        if (state.metrics.isEmpty)
          const _EmptyState(
            icon: Icons.insights_outlined,
            title: 'Chưa có số liệu tổng quan',
            message: 'Số liệu sẽ xuất hiện khi nguồn dữ liệu sẵn sàng.',
          )
        else
          _AdaptiveGrid(
            minWidth: 210,
            children: [
              for (final metric in state.metrics)
                _MetricCard(
                  metric: metric,
                  onOpen: () {
                    final section = AdminPanelSection.fromValue(
                      metric.targetSection,
                    );
                    if (section != null) onOpenSection(section);
                  },
                ),
            ],
          ),
        const SizedBox(height: 24),
        const _SectionHeader(
          title: 'Mở nhanh',
          subtitle: 'Các khu vực được cấp quyền trên tài khoản hiện tại.',
        ),
        const SizedBox(height: 12),
        _AdaptiveGrid(
          minWidth: 230,
          children: [
            for (final section in shortcuts)
              _ShortcutCard(
                section: section,
                onOpen: () => onOpenSection(section),
              ),
          ],
        ),
      ],
    );
  }
}

class _PageIntro extends StatelessWidget {
  final String eyebrow;
  final String title;
  final String description;
  final Widget? trailing;

  const _PageIntro({
    required this.eyebrow,
    required this.title,
    required this.description,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.adminColors;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: colors.panel,
        borderRadius: BorderRadius.circular(AdminWorkspaceTheme.panelRadius),
        border: Border.all(color: colors.border),
      ),
      child: Wrap(
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 18,
        runSpacing: 14,
        children: [
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  eyebrow,
                  style: AppTextStyles.labelSmall.copyWith(
                    color: colors.blueStrong,
                    fontWeight: FontWeight.w800,
                    letterSpacing: .7,
                  ),
                ),
                const SizedBox(height: 7),
                Text(
                  title,
                  style: AppTextStyles.heading2.copyWith(color: colors.text),
                ),
                const SizedBox(height: 7),
                Text(
                  description,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: colors.textSecondary,
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

class _SessionBadge extends StatelessWidget {
  final int roleCount;

  const _SessionBadge({required this.roleCount});

  @override
  Widget build(BuildContext context) {
    final colors = context.adminColors;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: colors.successContainer,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: colors.successBorder),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.verified_user_outlined, color: colors.mint, size: 19),
          const SizedBox(width: 8),
          Text(
            roleCount > 1
                ? '$roleCount nhóm quyền đang hoạt động'
                : 'Quyền đã xác nhận',
            style: AppTextStyles.labelMedium.copyWith(
              color: colors.onSuccessContainer,
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  final AdminDashboardMetric metric;
  final VoidCallback onOpen;

  const _MetricCard({required this.metric, required this.onOpen});

  @override
  Widget build(BuildContext context) {
    final colors = context.adminColors;
    final section = AdminPanelSection.fromValue(metric.targetSection);
    final tone = _statusTone(metric.status, colors);

    return _WorkspacePanel(
      onTap: section == null ? null : onOpen,
      child: Padding(
        padding: const EdgeInsets.all(17),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _IconTile(icon: _statusIcon(metric.status), color: tone.color),
                const Spacer(),
                _StatusBadge(status: metric.status),
              ],
            ),
            const SizedBox(height: 20),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 180),
              child: Text(
                '${metric.value}',
                key: ValueKey('${metric.key}-${metric.value}'),
                style: AppTextStyles.heading1.copyWith(color: colors.text),
              ),
            ),
            const SizedBox(height: 5),
            Row(
              children: [
                Expanded(
                  child: Text(
                    AdminUiCopy.metricLabel(metric),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: colors.textSecondary,
                    ),
                  ),
                ),
                if (section != null)
                  Icon(
                    Icons.arrow_forward_rounded,
                    size: 18,
                    color: colors.blue,
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ShortcutCard extends StatelessWidget {
  final AdminPanelSection section;
  final VoidCallback onOpen;

  const _ShortcutCard({required this.section, required this.onOpen});

  @override
  Widget build(BuildContext context) {
    final colors = context.adminColors;
    return _WorkspacePanel(
      onTap: onOpen,
      child: Padding(
        padding: const EdgeInsets.all(15),
        child: Row(
          children: [
            _IconTile(
              icon: _iconForSection(section, false),
              color: colors.blue,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AdminUiCopy.sectionLabel(section),
                    style: AppTextStyles.labelLarge.copyWith(
                      color: colors.text,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    AdminUiCopy.sectionDescription(section),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: colors.textSecondary,
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(Icons.chevron_right_rounded, color: colors.textMuted),
          ],
        ),
      ),
    );
  }
}

class _WorkQueueSection extends StatelessWidget {
  final AdminPanelState state;
  final String? runningTargetId;
  final void Function(
    AdminPanelSection section,
    AdminActionPresentation action,
    AdminWorkItem item,
  )
  onAction;
  final VoidCallback onClearSearch;

  const _WorkQueueSection({
    required this.state,
    required this.runningTargetId,
    required this.onAction,
    required this.onClearSearch,
  });

  @override
  Widget build(BuildContext context) {
    final hasQuery = state.query.trim().isNotEmpty;
    if (state.items.isEmpty) {
      return _EmptyState(
        icon: hasQuery ? Icons.search_off_rounded : Icons.inbox_outlined,
        title: AdminUiCopy.emptyTitle(hasQuery: hasQuery),
        message: AdminUiCopy.emptyMessage(
          section: state.section,
          hasQuery: hasQuery,
        ),
        actionLabel: hasQuery ? 'Xóa tìm kiếm' : null,
        onAction: hasQuery ? onClearSearch : null,
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeader(
          title: AdminUiCopy.sectionLabel(state.section),
          subtitle: hasQuery
              ? '${state.items.length} kết quả phù hợp.'
              : '${state.items.length} mục đang hiển thị.',
          trailing: hasQuery
              ? TextButton.icon(
                  onPressed: onClearSearch,
                  icon: const Icon(Icons.close_rounded, size: 18),
                  label: const Text('Xóa tìm kiếm'),
                )
              : null,
        ),
        const SizedBox(height: 12),
        for (final item in state.items)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _WorkItemCard(
              section: state.section,
              session: state.session,
              item: item,
              busy: runningTargetId == item.id,
              disabled: runningTargetId != null,
              onAction: onAction,
            ),
          ),
      ],
    );
  }
}

class _WorkItemCard extends StatelessWidget {
  final AdminPanelSection section;
  final AdminSession session;
  final AdminWorkItem item;
  final bool busy;
  final bool disabled;
  final void Function(
    AdminPanelSection section,
    AdminActionPresentation action,
    AdminWorkItem item,
  )
  onAction;

  const _WorkItemCard({
    required this.section,
    required this.session,
    required this.item,
    required this.busy,
    required this.disabled,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.adminColors;
    final actions = _actionsFor(section, item.status)
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
    final tone = _statusTone(item.status, colors);

    return _WorkspacePanel(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            LayoutBuilder(
              builder: (context, constraints) {
                final narrow = constraints.maxWidth < 680;
                final information = Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _IconTile(
                      icon: _iconForSection(section, false),
                      color: tone.color,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.labelLarge.copyWith(
                              color: colors.text,
                            ),
                          ),
                          if (item.subtitle.trim().isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(
                              item.subtitle,
                              maxLines: narrow ? 4 : 2,
                              overflow: TextOverflow.ellipsis,
                              style: AppTextStyles.bodySmall.copyWith(
                                color: colors.textSecondary,
                                height: 1.35,
                              ),
                            ),
                          ],
                          if (item.createdAt != null) ...[
                            const SizedBox(height: 8),
                            _MetaText(
                              icon: Icons.schedule_rounded,
                              text:
                                  'Tạo lúc ${_formatDateTime(item.createdAt)}',
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    _StatusBadge(status: item.status),
                  ],
                );

                final actionBar = _ActionBar(
                  section: section,
                  actions: actions,
                  item: item,
                  busy: busy,
                  disabled: disabled,
                  onAction: onAction,
                );

                if (narrow) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      information,
                      if (actions.isNotEmpty) ...[
                        const SizedBox(height: 14),
                        actionBar,
                      ],
                    ],
                  );
                }

                return Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(child: information),
                    if (actions.isNotEmpty) ...[
                      const SizedBox(width: 18),
                      Flexible(child: actionBar),
                    ],
                  ],
                );
              },
            ),
            if (section == AdminPanelSection.payments &&
                item.paymentReconciliation != null) ...[
              const SizedBox(height: 14),
              _PaymentDetails(item: item),
            ],
            if (section == AdminPanelSection.saleConversions &&
                item.metadata.isNotEmpty) ...[
              const SizedBox(height: 14),
              _PayoutDetails(item: item),
            ],
          ],
        ),
      ),
    );
  }
}

class _ActionBar extends StatelessWidget {
  final AdminPanelSection section;
  final List<AdminActionPresentation> actions;
  final AdminWorkItem item;
  final bool busy;
  final bool disabled;
  final void Function(
    AdminPanelSection section,
    AdminActionPresentation action,
    AdminWorkItem item,
  )
  onAction;

  const _ActionBar({
    required this.section,
    required this.actions,
    required this.item,
    required this.busy,
    required this.disabled,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      alignment: WrapAlignment.end,
      spacing: 8,
      runSpacing: 8,
      children: [
        for (var index = 0; index < actions.length; index++)
          if (busy && index == 0)
            const SizedBox(
              width: 96,
              height: 42,
              child: Center(
                child: SizedBox.square(
                  dimension: 18,
                  child: CircularProgressIndicator(strokeWidth: 2.2),
                ),
              ),
            )
          else
            _ActionButton(
              action: actions[index],
              primary: index == 0 && !actions[index].danger,
              enabled: !disabled,
              onPressed: () => onAction(section, actions[index], item),
            ),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  final AdminActionPresentation action;
  final bool primary;
  final bool enabled;
  final VoidCallback onPressed;

  const _ActionButton({
    required this.action,
    required this.primary,
    required this.enabled,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.adminColors;
    if (primary) {
      return FilledButton.icon(
        onPressed: enabled ? onPressed : null,
        icon: Icon(action.icon, size: 18),
        label: Text(action.label),
      );
    }

    return OutlinedButton.icon(
      onPressed: enabled ? onPressed : null,
      style: action.danger
          ? OutlinedButton.styleFrom(
              foregroundColor: colors.danger,
              side: BorderSide(color: colors.dangerBorder),
            )
          : null,
      icon: Icon(action.icon, size: 18),
      label: Text(action.label),
    );
  }
}

class _PaymentDetails extends StatelessWidget {
  final AdminWorkItem item;

  const _PaymentDetails({required this.item});

  @override
  Widget build(BuildContext context) {
    final colors = context.adminColors;
    final details = item.paymentReconciliation;
    if (details == null) return const SizedBox.shrink();

    return _DetailPanel(
      title: 'Thông tin đối chiếu',
      icon: Icons.account_balance_outlined,
      color: colors.warning,
      children: [
        _InfoLine(label: 'Mã giao dịch', value: details.transferReference),
        _InfoLine(label: 'Nội dung chuyển khoản', value: details.transferMemo),
        _InfoLine(label: 'Người chuyển', value: details.payerFullName),
        if (details.amountCents != null)
          _InfoLine(
            label: 'Số tiền',
            value: _formatMoney(
              details.amountCents!,
              details.currency ?? 'VND',
            ),
          ),
        if (details.transferConfirmedAt != null)
          _InfoLine(
            label: 'Khách xác nhận lúc',
            value: _formatDateTime(details.transferConfirmedAt),
          ),
      ],
    );
  }
}

class _PayoutDetails extends StatelessWidget {
  final AdminWorkItem item;

  const _PayoutDetails({required this.item});

  @override
  Widget build(BuildContext context) {
    final colors = context.adminColors;
    final metadata = item.metadata;
    final bankCode = _metadataString(metadata, 'bank_bin');
    final bankName = _metadataString(metadata, 'bank_name');
    final accountNumber = _metadataString(metadata, 'bank_account_number');
    final accountName = _metadataString(metadata, 'bank_account_name');
    final hasProof =
        _metadataString(metadata, 'payment_proof_path')?.isNotEmpty == true;
    final shortId = item.id.length <= 8 ? item.id : item.id.substring(0, 8);
    final transferContent =
        _metadataString(metadata, 'payment_content') ??
        'Cộng tác viên $shortId';
    final currency = _metadataString(metadata, 'currency') ?? 'VND';
    final amount = _metadataInt(metadata, 'money_amount_cents');
    final qrPayload =
        VietQrPayloadBuilder.build(
          bankBin: bankCode,
          accountNumber: accountNumber,
          accountName: accountName,
          amount: amount,
          transferMemo: transferContent,
        ) ??
        _metadataString(metadata, 'vietqr_payload');

    if (bankName == null &&
        accountNumber == null &&
        accountName == null &&
        amount == 0 &&
        !hasProof) {
      return const SizedBox.shrink();
    }

    return _DetailPanel(
      title: 'Thông tin chi trả',
      icon: Icons.payments_outlined,
      color: colors.blue,
      children: [
        Wrap(
          spacing: 18,
          runSpacing: 14,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            if (qrPayload != null)
              Container(
                width: 126,
                height: 126,
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: colors.border),
                ),
                child: QrImageView(data: qrPayload, version: QrVersions.auto),
              ),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _InfoLine(label: 'Ngân hàng', value: bankName ?? bankCode),
                  _InfoLine(label: 'Mã ngân hàng', value: bankCode),
                  _InfoLine(label: 'Số tài khoản', value: accountNumber),
                  _InfoLine(label: 'Chủ tài khoản', value: accountName),
                  _InfoLine(
                    label: 'Số tiền',
                    value: _formatMoney(amount, currency),
                  ),
                  _InfoLine(label: 'Nội dung', value: transferContent),
                  if (hasProof)
                    const _InfoLine(label: 'Ảnh xác nhận', value: 'Đã tải lên'),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _DetailPanel extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final List<Widget> children;

  const _DetailPanel({
    required this.title,
    required this.icon,
    required this.color,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.adminColors;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.panelMuted,
        borderRadius: BorderRadius.circular(11),
        border: Border.all(color: colors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: color),
              const SizedBox(width: 8),
              Text(
                title,
                style: AppTextStyles.labelLarge.copyWith(color: colors.text),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...children,
        ],
      ),
    );
  }
}

class _InfoLine extends StatelessWidget {
  final String label;
  final String? value;

  const _InfoLine({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final colors = context.adminColors;
    final text = value?.trim();
    if (text == null || text.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 5),
      child: Text.rich(
        TextSpan(
          children: [
            TextSpan(
              text: '$label: ',
              style: AppTextStyles.bodySmall.copyWith(
                color: colors.textSecondary,
                fontWeight: FontWeight.w700,
              ),
            ),
            TextSpan(
              text: text,
              style: AppTextStyles.bodySmall.copyWith(color: colors.text),
            ),
          ],
        ),
      ),
    );
  }
}

class _AuditSection extends StatelessWidget {
  final List<AdminAuditEvent> events;
  final String query;

  const _AuditSection({required this.events, required this.query});

  @override
  Widget build(BuildContext context) {
    final colors = context.adminColors;
    if (events.isEmpty) {
      return _EmptyState(
        icon: query.trim().isEmpty
            ? Icons.history_toggle_off_rounded
            : Icons.search_off_rounded,
        title: query.trim().isEmpty
            ? 'Chưa có lịch sử phù hợp'
            : 'Không tìm thấy kết quả',
        message: query.trim().isEmpty
            ? 'Các thao tác quan trọng sẽ được ghi nhận tại đây.'
            : 'Hãy thử một từ khóa khác.',
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeader(
          title: 'Lịch sử thao tác',
          subtitle: '${events.length} mục gần nhất theo nội dung đang tìm.',
        ),
        const SizedBox(height: 12),
        for (final event in events)
          Padding(
            padding: const EdgeInsets.only(bottom: 9),
            child: _WorkspacePanel(
              child: Padding(
                padding: const EdgeInsets.all(15),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _IconTile(icon: Icons.history_rounded, color: colors.cyan),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            AdminUiCopy.auditAction(event.action),
                            style: AppTextStyles.labelLarge.copyWith(
                              color: colors.text,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${AdminUiCopy.auditTarget(event.target)} · '
                            '${AdminUiCopy.auditReason(event.reason)}',
                            style: AppTextStyles.bodySmall.copyWith(
                              color: colors.textSecondary,
                              height: 1.35,
                            ),
                          ),
                          if (event.createdAt != null) ...[
                            const SizedBox(height: 7),
                            _MetaText(
                              icon: Icons.schedule_rounded,
                              text: _formatDateTime(event.createdAt),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _PermissionDeniedView extends StatelessWidget {
  final AdminPanelSection section;
  final String permission;

  const _PermissionDeniedView({
    required this.section,
    required this.permission,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.adminColors;
    return _EmptyState(
      icon: Icons.lock_person_outlined,
      title: 'Bạn chưa được mở khu vực này',
      message:
          'Tài khoản cần quyền '
          '${AdminUiCopy.permissionLabel(permission)}. Hãy liên hệ người '
          'quản lý quyền nếu đây là nhiệm vụ của bạn.',
      tone: colors.warning,
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget? trailing;

  const _SectionHeader({
    required this.title,
    required this.subtitle,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.adminColors;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: AppTextStyles.heading3.copyWith(color: colors.text),
              ),
              const SizedBox(height: 3),
              Text(
                subtitle,
                style: AppTextStyles.bodySmall.copyWith(
                  color: colors.textSecondary,
                ),
              ),
            ],
          ),
        ),
        if (trailing != null) ...[const SizedBox(width: 12), trailing!],
      ],
    );
  }
}

class _AdaptiveGrid extends StatelessWidget {
  final double minWidth;
  final List<Widget> children;

  const _AdaptiveGrid({required this.minWidth, required this.children});

  @override
  Widget build(BuildContext context) {
    if (children.isEmpty) return const SizedBox.shrink();
    return LayoutBuilder(
      builder: (context, constraints) {
        const spacing = 10.0;
        final columns =
            ((constraints.maxWidth + spacing) / (minWidth + spacing))
                .floor()
                .clamp(1, 4)
                .toInt();
        final width = columns == 1
            ? constraints.maxWidth
            : (constraints.maxWidth - spacing * (columns - 1)) / columns;
        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: [
            for (final child in children) SizedBox(width: width, child: child),
          ],
        );
      },
    );
  }
}

class _WorkspacePanel extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;

  const _WorkspacePanel({required this.child, this.onTap});

  @override
  State<_WorkspacePanel> createState() => _WorkspacePanelState();
}

class _WorkspacePanelState extends State<_WorkspacePanel> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final colors = context.adminColors;
    final interactive = widget.onTap != null;
    return MouseRegion(
      cursor: interactive ? SystemMouseCursors.click : MouseCursor.defer,
      onEnter: interactive ? (_) => setState(() => _hovered = true) : null,
      onExit: interactive ? (_) => setState(() => _hovered = false) : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 140),
        decoration: BoxDecoration(
          color: colors.panel,
          borderRadius: BorderRadius.circular(AdminWorkspaceTheme.panelRadius),
          border: Border.all(
            color: _hovered ? colors.borderStrong : colors.border,
          ),
          boxShadow: _hovered
              ? [
                  BoxShadow(
                    color: colors.shadow,
                    blurRadius: 14,
                    offset: Offset(0, 4),
                  ),
                ]
              : const [],
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(AdminWorkspaceTheme.panelRadius),
          child: InkWell(
            onTap: widget.onTap,
            borderRadius: BorderRadius.circular(
              AdminWorkspaceTheme.panelRadius,
            ),
            child: widget.child,
          ),
        ),
      ),
    );
  }
}

class _IconTile extends StatelessWidget {
  final IconData icon;
  final Color color;

  const _IconTile({required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        color: color.withValues(alpha: .10),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(icon, color: color, size: 20),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String status;

  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final tone = _statusTone(status, context.adminColors);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: tone.background,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        AdminUiCopy.statusLabel(status),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: AppTextStyles.labelSmall.copyWith(
          color: tone.color,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _MetaText extends StatelessWidget {
  final IconData icon;
  final String text;

  const _MetaText({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    final colors = context.adminColors;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 15, color: colors.textMuted),
        const SizedBox(width: 5),
        Flexible(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.bodySmall.copyWith(color: colors.textMuted),
          ),
        ),
      ],
    );
  }
}

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;
  final Color? tone;

  const _EmptyState({
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
    this.tone,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.adminColors;
    final effectiveTone = tone ?? colors.blue;
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: _WorkspacePanel(
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _IconTile(icon: icon, color: effectiveTone),
                const SizedBox(height: 14),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: AppTextStyles.heading3.copyWith(color: colors.text),
                ),
                const SizedBox(height: 7),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: colors.textSecondary,
                    height: 1.45,
                  ),
                ),
                if (actionLabel != null && onAction != null) ...[
                  const SizedBox(height: 18),
                  OutlinedButton(
                    onPressed: onAction,
                    child: Text(actionLabel!),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
