import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:nano_app/app/app_surface_controller.dart';
import 'package:nano_app/app_versions/admin/features/admin_panel/domain/entities/admin_models.dart';
import 'package:nano_app/app_versions/admin/features/admin_panel/presentation/controllers/admin_controller.dart';
import 'package:nano_app/app_versions/admin/features/admin_panel/providers/admin_providers.dart';
import 'package:nano_app/app_versions/admin/features/wellness_rewards/wellness_rewards_admin.dart';
import 'package:nano_app/app_versions/admin/router/admin_route_paths.dart';
import 'package:nano_app/core/theme/theme.dart';
import 'package:nano_app/core/localization/vietnam_time.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

const _desktopBreakpoint = 920.0;
const _wideBreakpoint = 1180.0;
const _contentMaxWidth = 1280.0;

const _sidebarCompactWidth = 96.0;
const _sidebarWideWidth = 288.0;
const _contentBottomPadding = 72.0;
const _cardHoverOffset = -4.0;
const _ambientOrbLarge = 360.0;
const _ambientOrbMedium = 260.0;
const _ambientOrbSmall = 180.0;
const _ambientMotionDuration = Duration(seconds: 12);

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

      final messenger = ScaffoldMessenger.of(context);
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(AppSpacing.md),
            backgroundColor: AppColors.textPrimary,
            content: Row(
              children: [
                const Icon(
                  Icons.verified_rounded,
                  color: AppColors.textInverse,
                  size: 18,
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(child: Text(message)),
              ],
            ),
          ),
        );
    });

    final state = ref.watch(adminControllerProvider);

    return state.when(
      loading: _LoadingScaffold.new,
      error: (_, __) => _AdminStateScaffold(
        child: _BlockingState(
          icon: Icons.cloud_off_rounded,
          title: 'Chưa tải được khu quản trị',
          message:
              'Nabi chưa lấy được phiên quản trị. Hãy thử lại sau ít phút.',
          actionLabel: 'Thử lại',
          onAction: () => ref.read(adminControllerProvider.notifier).refresh(),
        ),
      ),
      data: (data) {
        if (!data.session.isAdmin) {
          return _AdminStateScaffold(
            child: _BlockingState(
              icon: Icons.lock_person_rounded,
              title: 'Tài khoản chưa có quyền quản trị',
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

            return MedicalPageScaffold(
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
              body: Stack(
                children: [
                  const Positioned.fill(
                    child: RepaintBoundary(child: _AdminAmbientBackdrop()),
                  ),
                  Builder(
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
                                  onShowUserApp: data.session.canUseUserApp
                                      ? _showUserApp
                                      : null,
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
                ],
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

  void _showUserApp() {
    ref.read(appSurfaceControllerProvider.notifier).showUser();
  }

  Future<void> _signOut() async {
    await ref.read(adminAccessControllerProvider.notifier).signOut();
    ref.read(appSurfaceControllerProvider.notifier).reset();
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
            behavior: SnackBarBehavior.floating,
            content: Text(
              'Chưa tải được ảnh minh chứng. Bạn vẫn có thể xác nhận nếu quy trình vận hành cho phép.',
            ),
          ),
        );
      }
      return null;
    }
  }
}

class _AdminAmbientBackdrop extends StatefulWidget {
  const _AdminAmbientBackdrop();

  @override
  State<_AdminAmbientBackdrop> createState() => _AdminAmbientBackdropState();
}

class _AdminAmbientBackdropState extends State<_AdminAmbientBackdrop>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: _ambientMotionDuration,
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          final shift = Curves.easeInOutCubic.transform(_controller.value);

          return DecoratedBox(
            decoration: const BoxDecoration(gradient: AppGradients.surfaceAlt),
            child: Stack(
              fit: StackFit.expand,
              children: [
                Positioned(
                  top: -_ambientOrbLarge * .38 + shift * 28,
                  right: -_ambientOrbLarge * .28,
                  child: _AmbientOrb(
                    size: _ambientOrbLarge,
                    color: AppColors.primary,
                    opacity: .10,
                  ),
                ),
                Positioned(
                  top: 148 - shift * 34,
                  left: -_ambientOrbMedium * .45,
                  child: _AmbientOrb(
                    size: _ambientOrbMedium,
                    color: AppColors.secondary,
                    opacity: .08,
                  ),
                ),
                Positioned(
                  right: 64 + shift * 20,
                  bottom: -_ambientOrbSmall * .48,
                  child: _AmbientOrb(
                    size: _ambientOrbSmall,
                    color: AppColors.tertiary,
                    opacity: .07,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _AmbientOrb extends StatelessWidget {
  final double size;
  final Color color;
  final double opacity;

  const _AmbientOrb({
    required this.size,
    required this.color,
    required this.opacity,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withValues(alpha: opacity),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: opacity * .52),
            blurRadius: size * .30,
            spreadRadius: size * .04,
          ),
        ],
      ),
    );
  }
}

class _LoadingScaffold extends StatelessWidget {
  const _LoadingScaffold();

  @override
  Widget build(BuildContext context) {
    return const _AdminStateScaffold(child: Center(child: _LoadingPanel()));
  }
}

class _LoadingPanel extends StatelessWidget {
  const _LoadingPanel();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 284,
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: _panelDecoration(),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 82,
                height: 82,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.primarySoft,
                  border: Border.all(
                    color: AppColors.primary.withValues(alpha: .20),
                  ),
                ),
              ),
              const SizedBox.square(
                dimension: 52,
                child: CircularProgressIndicator(strokeWidth: 3),
              ),
              const Icon(
                Icons.admin_panel_settings_rounded,
                color: AppColors.primary,
                size: 22,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            'Đang chuẩn bị khu quản trị',
            textAlign: TextAlign.center,
            style: AppTextStyles.labelLarge,
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Nabi đang kiểm tra quyền truy cập và tải dữ liệu vận hành.',
            textAlign: TextAlign.center,
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textSecondary,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }
}

class _AdminStateScaffold extends StatelessWidget {
  final Widget child;

  const _AdminStateScaffold({required this.child});

  @override
  Widget build(BuildContext context) {
    return MedicalPageScaffold(
      backgroundColor: AppColors.scaffold,
      body: Stack(
        children: [
          const Positioned.fill(
            child: RepaintBoundary(child: _AdminAmbientBackdrop()),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: child,
            ),
          ),
        ],
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
    final width = extended ? _sidebarWideWidth : _sidebarCompactWidth;

    return AnimatedContainer(
      duration: AppDuration.navigation,
      curve: Curves.easeOutCubic,
      width: width,
      margin: const EdgeInsets.only(right: AppSpacing.xs),
      padding: EdgeInsets.fromLTRB(
        extended ? AppSpacing.md : AppSpacing.sm,
        AppSpacing.lg,
        extended ? AppSpacing.md : AppSpacing.sm,
        AppSpacing.lg,
      ),
      decoration: BoxDecoration(
        gradient: AppGradients.dashboard,
        borderRadius: const BorderRadius.only(
          topRight: Radius.circular(AppRadius.xl),
          bottomRight: Radius.circular(AppRadius.xl),
        ),
        border: Border(
          right: BorderSide(
            color: AppColors.textInverse.withValues(alpha: .11),
          ),
        ),
        boxShadow: AppShadows.lg,
      ),
      child: Column(
        children: [
          _AdminBrand(extended: extended),
          const SizedBox(height: AppSpacing.lg),
          if (extended) ...[
            const _SideRailLabel('BẢNG ĐIỀU KHIỂN'),
            const SizedBox(height: AppSpacing.sm),
          ],
          Expanded(
            child: ListView.separated(
              padding: EdgeInsets.zero,
              itemCount: sections.length,
              separatorBuilder: (_, __) =>
                  const SizedBox(height: AppSpacing.xs),
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
          if (extended) ...[
            const SizedBox(height: AppSpacing.md),
            const _SideRailProtectionNotice(),
            const SizedBox(height: AppSpacing.md),
          ],
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

class _SideRailLabel extends StatelessWidget {
  final String text;

  const _SideRailLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        text,
        style: AppTextStyles.bodySmall.copyWith(
          color: AppColors.darkTextSecondary,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.1,
        ),
      ),
    );
  }
}

class _SideRailProtectionNotice extends StatelessWidget {
  const _SideRailProtectionNotice();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.textInverse.withValues(alpha: .07),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.textInverse.withValues(alpha: .12)),
      ),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.success,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              'Khu vực có kiểm soát quyền và nhật ký kiểm tra',
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textInverse,
                height: 1.3,
              ),
            ),
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
      child: DecoratedBox(
        decoration: const BoxDecoration(gradient: AppGradients.surfaceAlt),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              children: [
                const _DrawerBrand(),
                const SizedBox(height: AppSpacing.lg),
                Expanded(
                  child: ListView.separated(
                    padding: EdgeInsets.zero,
                    itemCount: sections.length,
                    separatorBuilder: (_, __) =>
                        const SizedBox(height: AppSpacing.xs),
                    itemBuilder: (context, index) {
                      final section = sections[index];
                      final isSelected = section == selected;

                      return Material(
                        color: Colors.transparent,
                        child: Ink(
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppColors.primarySoft
                                : AppColors.surface.withValues(alpha: .76),
                            borderRadius: BorderRadius.circular(AppRadius.md),
                            border: Border.all(
                              color: isSelected
                                  ? AppColors.primary.withValues(alpha: .26)
                                  : AppColors.borderLight,
                            ),
                          ),
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.md,
                            ),
                            minVerticalPadding: AppSpacing.sm,
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
                              style: AppTextStyles.labelLarge.copyWith(
                                color: isSelected
                                    ? AppColors.primaryDark
                                    : AppColors.textPrimary,
                              ),
                            ),
                            trailing: isSelected
                                ? const Icon(
                                    Icons.arrow_forward_rounded,
                                    size: 18,
                                    color: AppColors.primary,
                                  )
                                : null,
                            onTap: () {
                              Navigator.of(context).pop();
                              onSelected(section);
                            },
                          ),
                        ),
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
                    label: const Text('Hướng dẫn vận hành'),
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
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        gradient: AppGradients.futuristic,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.textInverse.withValues(alpha: .18)),
        boxShadow: AppShadows.primary,
      ),
      child: const Icon(
        Icons.admin_panel_settings_rounded,
        color: AppColors.textInverse,
        size: 27,
      ),
    );

    if (!extended) {
      return Tooltip(message: 'NanoBio Quản trị', child: mark);
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
              const SizedBox(height: AppSpacing.xxs),
              Text(
                'Vận hành quản trị',
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.darkTextSecondary,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 7,
                    height: 7,
                    decoration: const BoxDecoration(
                      color: AppColors.success,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Text(
                    'PHIÊN ĐƯỢC KIỂM SOÁT',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textInverse.withValues(alpha: .82),
                      fontWeight: FontWeight.w700,
                      letterSpacing: .75,
                    ),
                  ),
                ],
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
        boxShadow: AppShadows.card,
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              gradient: AppGradients.futuristic,
              borderRadius: BorderRadius.circular(AppRadius.md),
              boxShadow: AppShadows.primary,
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
                Text('NanoBio Quản trị', style: AppTextStyles.heading4),
                const SizedBox(height: AppSpacing.xxs),
                Text(
                  'Vận hành theo quyền và nhật ký kiểm tra',
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
  var _pressed = false;

  @override
  Widget build(BuildContext context) {
    final isActive = widget.selected;
    final foreground = isActive || _hovered
        ? AppColors.textInverse
        : AppColors.darkTextSecondary;
    final background = isActive
        ? AppColors.primary.withValues(alpha: .96)
        : _hovered
        ? AppColors.textInverse.withValues(alpha: .08)
        : Colors.transparent;

    final button = AnimatedScale(
      duration: AppDuration.hover,
      curve: Curves.easeOutCubic,
      scale: _pressed ? .985 : 1,
      child: AnimatedContainer(
        duration: AppDuration.hover,
        curve: Curves.easeOutCubic,
        transform: Matrix4.translationValues(
          widget.extended && _hovered && !isActive ? 2 : 0,
          0,
          0,
        ),
        padding: EdgeInsets.symmetric(
          horizontal: widget.extended ? AppSpacing.md : AppSpacing.sm,
          vertical: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: isActive ? null : background,
          gradient: isActive ? AppGradients.futuristic : null,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(
            color: isActive
                ? AppColors.textInverse.withValues(alpha: .18)
                : _hovered
                ? AppColors.textInverse.withValues(alpha: .14)
                : Colors.transparent,
          ),
          boxShadow: isActive ? AppShadows.primary : const [],
        ),
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            minHeight: AppSpacing.touchTargetMin,
          ),
          child: Row(
            mainAxisAlignment: widget.extended
                ? MainAxisAlignment.start
                : MainAxisAlignment.center,
            children: [
              Icon(
                isActive ? widget.section.selectedIcon : widget.section.icon,
                color: foreground,
              ),
              if (widget.extended) ...[
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    widget.section.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.labelLarge.copyWith(color: foreground),
                  ),
                ),
                AnimatedOpacity(
                  duration: AppDuration.hover,
                  opacity: isActive ? 1 : 0,
                  child: const Icon(
                    Icons.chevron_right_rounded,
                    color: AppColors.textInverse,
                    size: 19,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );

    final interactive = MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) {
        if (mounted) {
          setState(() {
            _hovered = false;
            _pressed = false;
          });
        }
      },
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadius.md),
          onHighlightChanged: (pressed) => setState(() => _pressed = pressed),
          onTap: widget.onTap,
          child: button,
        ),
      ),
    );

    if (widget.extended) return interactive;
    return Tooltip(message: widget.section.label, child: interactive);
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
          style: IconButton.styleFrom(
            backgroundColor: AppColors.textInverse.withValues(alpha: .06),
            side: BorderSide(
              color: AppColors.textInverse.withValues(alpha: .10),
            ),
          ),
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
          side: BorderSide(color: AppColors.textInverse.withValues(alpha: .16)),
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
  final VoidCallback? onShowUserApp;
  final VoidCallback onSignOut;

  const _TopBar({
    required this.state,
    required this.search,
    required this.isCompact,
    required this.onMenuPressed,
    required this.onSearch,
    required this.onRefresh,
    required this.onShowGuide,
    required this.onShowUserApp,
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
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: .94),
        border: const Border(bottom: BorderSide(color: AppColors.borderLight)),
        boxShadow: AppShadows.appBar,
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final narrow = constraints.maxWidth < 720;
          final spacious = constraints.maxWidth >= 1040;
          final title = _TopBarTitle(
            state: state,
            onMenuPressed: onMenuPressed,
          );
          final actions = _TopBarActions(
            compact: narrow,
            onRefresh: onRefresh,
            onShowGuide: onShowGuide,
            onShowUserApp: onShowUserApp,
            onSignOut: onSignOut,
          );

          if (narrow) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(child: title),
                    const SizedBox(width: AppSpacing.xs),
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
              if (spacious) ...[
                const SizedBox(width: AppSpacing.md),
                const _SecurityPill(),
              ],
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

class _SecurityPill extends StatelessWidget {
  final bool inverse;

  const _SecurityPill({this.inverse = false});

  @override
  Widget build(BuildContext context) {
    final foreground = inverse
        ? AppColors.textInverse
        : AppColors.textSecondary;
    final dot = inverse ? AppColors.secondaryLight : AppColors.success;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: inverse
            ? AppColors.textInverse.withValues(alpha: .10)
            : AppColors.successSoft,
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(
          color: inverse
              ? AppColors.textInverse.withValues(alpha: .16)
              : AppColors.success.withValues(alpha: .22),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(color: dot, shape: BoxShape.circle),
          ),
          const SizedBox(width: AppSpacing.xs),
          Text(
            'Nhật ký kiểm tra đang hoạt động',
            style: AppTextStyles.bodySmall.copyWith(
              color: foreground,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
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
            style: IconButton.styleFrom(
              backgroundColor: AppColors.primarySoft,
              foregroundColor: AppColors.primary,
            ),
            onPressed: onMenuPressed,
            icon: const Icon(Icons.menu_rounded),
          ),
          const SizedBox(width: AppSpacing.sm),
        ],
        Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            gradient: AppGradients.primarySoft,
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(color: AppColors.primary.withValues(alpha: .18)),
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
                'Thao tác theo quyền, mọi thay đổi quan trọng đều cần lý do.',
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
    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: controller,
      builder: (context, value, child) {
        final hasQuery = value.text.trim().isNotEmpty;

        return TextField(
          controller: controller,
          textInputAction: TextInputAction.search,
          onSubmitted: onSearch,
          decoration: InputDecoration(
            hintText: 'Tìm trong $sectionLabel',
            prefixIcon: const Icon(Icons.search_rounded),
            suffixIcon: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (hasQuery)
                  IconButton(
                    tooltip: 'Xóa tìm kiếm',
                    onPressed: () {
                      controller.clear();
                      onSearch('');
                    },
                    icon: const Icon(Icons.close_rounded),
                  ),
                IconButton(
                  tooltip: 'Tìm kiếm',
                  onPressed: () => onSearch(controller.text),
                  icon: const Icon(Icons.arrow_forward_rounded),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _TopBarActions extends StatelessWidget {
  final bool compact;
  final VoidCallback onRefresh;
  final VoidCallback onShowGuide;
  final VoidCallback? onShowUserApp;
  final VoidCallback onSignOut;

  const _TopBarActions({
    required this.compact,
    required this.onRefresh,
    required this.onShowGuide,
    required this.onShowUserApp,
    required this.onSignOut,
  });

  @override
  Widget build(BuildContext context) {
    if (compact) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _TopBarIconAction(
            tooltip: 'Hướng dẫn',
            icon: Icons.menu_book_rounded,
            onPressed: onShowGuide,
          ),
          const SizedBox(width: AppSpacing.xs),
          _TopBarIconAction(
            tooltip: 'Làm mới',
            icon: Icons.refresh_rounded,
            onPressed: onRefresh,
          ),
          if (onShowUserApp != null) ...[
            const SizedBox(width: AppSpacing.xs),
            _TopBarIconAction(
              tooltip: 'Giao diện người dùng',
              icon: Icons.health_and_safety_rounded,
              onPressed: onShowUserApp!,
            ),
          ],
          const SizedBox(width: AppSpacing.xs),
          _TopBarIconAction(
            tooltip: 'Đăng xuất',
            icon: Icons.logout_rounded,
            foreground: AppColors.error,
            onPressed: onSignOut,
          ),
        ],
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        OutlinedButton.icon(
          onPressed: onShowGuide,
          icon: const Icon(Icons.menu_book_rounded),
          label: const Text('Hướng dẫn'),
        ),
        if (onShowUserApp != null) ...[
          const SizedBox(width: AppSpacing.sm),
          OutlinedButton.icon(
            onPressed: onShowUserApp,
            icon: const Icon(Icons.health_and_safety_rounded),
            label: const Text('Giao diện người dùng'),
          ),
        ],
        const SizedBox(width: AppSpacing.sm),
        _TopBarIconAction(
          tooltip: 'Làm mới',
          icon: Icons.refresh_rounded,
          onPressed: onRefresh,
        ),
        const SizedBox(width: AppSpacing.sm),
        _TopBarIconAction(
          tooltip: 'Đăng xuất',
          icon: Icons.logout_rounded,
          foreground: AppColors.error,
          onPressed: onSignOut,
        ),
      ],
    );
  }
}

class _TopBarIconAction extends StatelessWidget {
  final String tooltip;
  final IconData icon;
  final Color? foreground;
  final VoidCallback onPressed;

  const _TopBarIconAction({
    required this.tooltip,
    required this.icon,
    required this.onPressed,
    this.foreground,
  });

  @override
  Widget build(BuildContext context) {
    final color = foreground ?? AppColors.textSecondary;

    return Tooltip(
      message: tooltip,
      child: IconButton(
        onPressed: onPressed,
        color: color,
        style: IconButton.styleFrom(
          backgroundColor: color.withValues(alpha: .08),
          side: BorderSide(color: color.withValues(alpha: .14)),
        ),
        icon: Icon(icon),
      ),
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
            AdminPanelSection.wellnessRewards => AdminWellnessRewardsPanel(
              canWrite: state.session.hasPermission(
                AdminPermissions.wellnessRewardsWrite,
              ),
            ),
            _ => _WorkQueueView(state: state, onAction: onAction),
          };

    final horizontalPadding =
        MediaQuery.sizeOf(context).width < _desktopBreakpoint
        ? AppSpacing.md
        : AppSpacing.xl;

    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
        horizontalPadding,
        AppSpacing.lg,
        horizontalPadding,
        _contentBottomPadding,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: _contentMaxWidth),
          child: AnimatedSwitcher(
            duration: AppDuration.switcher,
            switchInCurve: Curves.easeOutCubic,
            switchOutCurve: Curves.easeInCubic,
            transitionBuilder: (child, animation) {
              final offset = Tween<Offset>(
                begin: const Offset(0, .025),
                end: Offset.zero,
              ).animate(animation);

              return FadeTransition(
                opacity: animation,
                child: SlideTransition(position: offset, child: child),
              );
            },
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
                'Khi dữ liệu quản trị sẵn sàng, Nabi sẽ hiển thị các chỉ số vận hành tại đây.',
          )
        else
          _ResponsiveGrid(
            minItemWidth: 220,
            itemHeight: 176,
            children: state.metrics.map(_MetricCard.new).toList(),
          ),
        const SizedBox(height: AppSpacing.xl),
        const _SectionTitle(
          title: 'Lối tắt vận hành',
          subtitle: 'Mở nhanh các khu vực bạn được phân quyền xử lý.',
        ),
        const SizedBox(height: AppSpacing.md),
        _ResponsiveGrid(
          minItemWidth: 236,
          itemHeight: 116,
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
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.xl),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: AppGradients.dashboard,
          boxShadow: AppShadows.md,
        ),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned(
              top: -92,
              right: -48,
              child: _HeroGlow(
                size: 246,
                color: AppColors.secondaryLight,
                opacity: .14,
              ),
            ),
            Positioned(
              bottom: -94,
              right: 182,
              child: _HeroGlow(
                size: 184,
                color: AppColors.primaryLight,
                opacity: .12,
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.xl),
              child: Wrap(
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.end,
                spacing: AppSpacing.lg,
                runSpacing: AppSpacing.lg,
                children: [
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 680),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.sm,
                            vertical: AppSpacing.xs,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.textInverse.withValues(alpha: .10),
                            borderRadius: BorderRadius.circular(AppRadius.pill),
                            border: Border.all(
                              color: AppColors.textInverse.withValues(
                                alpha: .16,
                              ),
                            ),
                          ),
                          child: Text(
                            'NANOBIO • VẬN HÀNH QUẢN TRỊ',
                            style: AppTextStyles.bodySmall.copyWith(
                              color: AppColors.textInverse,
                              fontWeight: FontWeight.w700,
                              letterSpacing: .8,
                            ),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        Text(
                          'Trung tâm vận hành',
                          style: AppTextStyles.heading1.copyWith(
                            color: AppColors.textInverse,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          'Theo dõi chỉ số, xử lý yêu cầu và xem lịch sử.',
                          style: AppTextStyles.bodyLarge.copyWith(
                            color: AppColors.darkTextSecondary,
                            height: 1.52,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const _SecurityPill(inverse: true),
                      const SizedBox(height: AppSpacing.sm),
                      _OverviewBadge(metricCount: metricCount),
                    ],
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

class _HeroGlow extends StatelessWidget {
  final double size;
  final Color color;
  final double opacity;

  const _HeroGlow({
    required this.size,
    required this.color,
    required this.opacity,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withValues(alpha: opacity),
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
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: AppColors.textInverse.withValues(alpha: .12),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.insights_rounded,
              size: 16,
              color: AppColors.textInverse,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
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
        final spacing = AppSpacing.md;
        final columns = ((width + spacing) / (minItemWidth + spacing))
            .floor()
            .clamp(1, 4)
            .toInt();
        final itemWidth = columns == 1
            ? width
            : (width - spacing * (columns - 1)) / columns;

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: [
            for (final child in children)
              SizedBox(width: itemWidth, height: itemHeight, child: child),
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
    final color = _statusColor(metric.status);

    return _InteractivePanel(
      accent: color,
      onTap: target == null ? null : () => context.go(target.routePath),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            top: -28,
            right: -18,
            child: Container(
              width: 98,
              height: 98,
              decoration: BoxDecoration(
                color: color.withValues(alpha: .08),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _IconBadge(icon: _statusIcon(metric.status), color: color),
                    const Spacer(),
                    _StatusChip(status: metric.status),
                  ],
                ),
                const Spacer(),
                AnimatedSwitcher(
                  duration: AppDuration.switcher,
                  child: Text(
                    metric.value.toString(),
                    key: ValueKey('${metric.key}-${metric.value}'),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.heading1,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        _metricLabel(metric),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                    if (target != null) ...[
                      const SizedBox(width: AppSpacing.sm),
                      Icon(Icons.arrow_forward_rounded, size: 18, color: color),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
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
      accent: AppColors.primary,
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
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: AppColors.primarySoft,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.arrow_forward_rounded,
                size: 17,
                color: AppColors.primary,
              ),
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
        _QueueSummaryBanner(
          sectionLabel: state.section.label,
          itemCount: state.items.length,
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

class _QueueSummaryBanner extends StatelessWidget {
  final String sectionLabel;
  final int itemCount;

  const _QueueSummaryBanner({
    required this.sectionLabel,
    required this.itemCount,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.infoSoft,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.info.withValues(alpha: .18)),
      ),
      child: Wrap(
        spacing: AppSpacing.md,
        runSpacing: AppSpacing.sm,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          const _IconBadge(
            icon: Icons.auto_awesome_rounded,
            color: AppColors.info,
          ),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 680),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$itemCount mục đang chờ trong $sectionLabel',
                  style: AppTextStyles.labelLarge.copyWith(
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: AppSpacing.xxs),
                Text(
                  'Kiểm tra kỹ và nhập lý do trước khi xác nhận.',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textSecondary,
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
    final statusColor = _statusColor(item.status);

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: _InteractivePanel(
        accent: statusColor,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final narrow = constraints.maxWidth < 720;
              final header = Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _IconBadge(icon: section.icon, color: statusColor),
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
                      const SizedBox(height: AppSpacing.lg),
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
                        const SizedBox(width: AppSpacing.lg),
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
        _metadataString(metadata, 'payment_content') ??
        'Cộng tác viên $shortId';
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

    return LayoutBuilder(
      builder: (context, constraints) {
        final detailWidth = constraints.maxWidth >= 480
            ? 420.0
            : constraints.maxWidth;

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: AppColors.cardAlt,
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(color: AppColors.borderLight),
          ),
          child: Wrap(
            spacing: AppSpacing.lg,
            runSpacing: AppSpacing.md,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              if (qrPayload != null)
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 132,
                      height: 132,
                      padding: const EdgeInsets.all(AppSpacing.xs),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(AppRadius.sm),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: QrImageView(
                        data: qrPayload,
                        version: QrVersions.auto,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      'Mã thanh toán',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              SizedBox(
                width: detailWidth,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.account_balance_rounded,
                          size: 18,
                          color: AppColors.primary,
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        Text(
                          'Thông tin chi trả',
                          style: AppTextStyles.labelLarge,
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    _PayoutLine(label: 'Ngân hàng', value: bankName ?? bankBin),
                    _PayoutLine(label: 'BIN', value: bankBin),
                    _PayoutLine(label: 'Số tài khoản', value: accountNumber),
                    _PayoutLine(label: 'Chủ tài khoản', value: accountName),
                    _PayoutLine(
                      label: 'Số tiền',
                      value: _formatMoney(amount, currency),
                    ),
                    _PayoutLine(label: 'Nội dung', value: content),
                    if (proofPath != null)
                      _PayoutLine(label: 'Minh chứng', value: proofPath),
                  ],
                ),
              ),
            ],
          ),
        );
      },
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
      padding: const EdgeInsets.only(top: AppSpacing.xs),
      child: Text.rich(
        TextSpan(
          children: [
            TextSpan(
              text: '$label: ',
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w700,
              ),
            ),
            TextSpan(
              text: value,
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
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
              height: 1.35,
            ),
          ),
        ],
        if (item.createdAt != null) ...[
          const SizedBox(height: AppSpacing.sm),
          _MetaPill(
            icon: Icons.schedule_rounded,
            text: 'Tạo lúc ${_formatDateTime(item.createdAt)}',
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
        for (var index = 0; index < actions.length; index++)
          _AdminActionButton(
            action: actions[index],
            primary: index == 0 && !actions[index].isDanger,
            onPressed: () => onAction(
              section,
              actions[index].key,
              item,
              actions[index].label,
            ),
          ),
      ],
    );
  }
}

class _AdminActionButton extends StatelessWidget {
  final _AdminAction action;
  final bool primary;
  final VoidCallback onPressed;

  const _AdminActionButton({
    required this.action,
    required this.primary,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final foreground = action.isDanger ? AppColors.error : AppColors.primary;

    final button = primary
        ? FilledButton.icon(
            onPressed: onPressed,
            icon: Icon(action.icon, size: 18),
            label: Text(action.label),
          )
        : OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              foregroundColor: foreground,
              side: BorderSide(
                color: action.isDanger
                    ? AppColors.error.withValues(alpha: .42)
                    : AppColors.primary.withValues(alpha: .28),
              ),
            ),
            onPressed: onPressed,
            icon: Icon(action.icon, size: 18),
            label: Text(action.label),
          );

    return Tooltip(
      message: action.isDanger
          ? 'Thao tác này sẽ được ghi vào nhật ký kiểm tra'
          : 'Xác nhận thao tác và ghi vào nhật ký kiểm tra',
      child: button,
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
        title: 'Chưa có nhật ký kiểm tra phù hợp',
        message:
            'Nhật ký kiểm tra sẽ hiển thị khi có thao tác quản trị được ghi nhận.',
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionTitle(
          title: 'Lịch sử kiểm tra',
          subtitle: '${events.length} thao tác gần nhất theo bộ lọc hiện tại.',
        ),
        const SizedBox(height: AppSpacing.md),
        const _AuditNoticeBanner(),
        const SizedBox(height: AppSpacing.md),
        for (final event in events) _AuditRow(event: event),
      ],
    );
  }
}

class _AuditNoticeBanner extends StatelessWidget {
  const _AuditNoticeBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.infoSoft,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.info.withValues(alpha: .18)),
      ),
      child: Row(
        children: [
          const _IconBadge(
            icon: Icons.verified_user_rounded,
            color: AppColors.info,
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              'Nhật ký chỉ dùng trong phạm vi được phân quyền.',
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textSecondary,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
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
        accent: AppColors.info,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Wrap(
            spacing: AppSpacing.md,
            runSpacing: AppSpacing.sm,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              const _IconBadge(
                icon: Icons.history_rounded,
                color: AppColors.info,
              ),
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
                      '${_auditTargetLabel(event.target)} · ${_auditReasonLabel(event.reason)}',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                        height: 1.35,
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
    final canConfirm = _reason.text.trim().isNotEmpty;

    return AlertDialog(
      icon: const _IconBadge(
        icon: Icons.shield_rounded,
        color: AppColors.primary,
      ),
      title: Text('Xác nhận ${widget.actionLabel}'),
      content: SizedBox(
        width: 460,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Nhập lý do ngắn gọn để lưu vào nhật ký.',
              style: AppTextStyles.bodyMedium.copyWith(height: 1.45),
            ),
            const SizedBox(height: AppSpacing.md),
            TextField(
              controller: _reason,
              autofocus: true,
              minLines: 3,
              maxLines: 5,
              maxLength: 300,
              onChanged: (_) => setState(() {}),
              decoration: const InputDecoration(
                labelText: 'Lý do bắt buộc',
                hintText:
                    'Ví dụ: Đã đối chiếu thông tin theo quy trình vận hành.',
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
          onPressed: canConfirm
              ? () => Navigator.of(context).pop(_reason.text.trim())
              : null,
          icon: const Icon(Icons.verified_rounded),
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
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppRadius.xl),
          child: DecoratedBox(
            decoration: const BoxDecoration(gradient: AppGradients.surfaceAlt),
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                children: [
                  Row(
                    children: [
                      const _IconBadge(
                        icon: Icons.menu_book_rounded,
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Hướng dẫn vận hành',
                              style: AppTextStyles.heading3,
                            ),
                            const SizedBox(height: AppSpacing.xxs),
                            Text(
                              'Các bước thao tác an toàn, rõ ràng và có nhật ký kiểm tra.',
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
                              'Xem các chỉ số vận hành chính trong bảng điều khiển.',
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
                              'Các thay đổi quan trọng sẽ được ghi lại trong nhật ký kiểm tra.',
                            ],
                          ),
                          _GuideSection(
                            icon: Icons.badge_rounded,
                            title: 'Cộng tác viên và quy đổi điểm',
                            items: [
                              'Duyệt, tạm dừng hoặc đóng hồ sơ cộng tác viên theo trạng thái hiện tại.',
                              'Với quy đổi điểm, kiểm tra số điểm và trạng thái trước khi đánh dấu đã chi trả.',
                              'Nếu cần điều chỉnh điểm, ghi lý do ngắn gọn và có thể kiểm chứng.',
                            ],
                          ),
                          _GuideSection(
                            icon: Icons.fact_check_rounded,
                            title: 'Đối soát',
                            items: [
                              'Dùng trạng thái Cần theo dõi khi dữ liệu chưa đủ chắc chắn.',
                              'Chỉ chọn Đã đối soát khi thanh toán, gói dịch vụ và điểm đã khớp.',
                              'Các quyết định đối soát nên có lý do đủ để người khác đọc lại.',
                            ],
                          ),
                          _GuideSection(
                            icon: Icons.summarize_rounded,
                            title: 'Báo cáo và cấu hình',
                            items: [
                              'Tạo yêu cầu xuất báo cáo theo phạm vi được phân quyền.',
                              'Khi lưu cấu hình, mô tả rõ mục tiêu thay đổi.',
                              'Không dùng giao diện quản trị để lưu bí mật hoặc khóa truy cập.',
                            ],
                          ),
                          _GuideSection(
                            icon: Icons.history_rounded,
                            title: 'Nhật ký kiểm tra',
                            items: [
                              'Dùng nhật ký kiểm tra để xem ai đã thao tác, thao tác gì và lý do là gì.',
                              'Khi có sai lệch, đối chiếu nhật ký kiểm tra trước khi xử lý tiếp.',
                              'Không chia sẻ dữ liệu nhật ký kiểm tra ra ngoài nhóm vận hành được phép.',
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
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: .82),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.borderLight),
      ),
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
                            color: AppColors.primary,
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
  final Color? accent;

  const _InteractivePanel({required this.child, this.onTap, this.accent});

  @override
  State<_InteractivePanel> createState() => _InteractivePanelState();
}

class _InteractivePanelState extends State<_InteractivePanel> {
  var _hovered = false;
  var _pressed = false;

  @override
  Widget build(BuildContext context) {
    final canInteract = widget.onTap != null;
    final accent = widget.accent ?? AppColors.primary;
    final active = canInteract && (_hovered || _pressed);

    return MouseRegion(
      cursor: canInteract ? SystemMouseCursors.click : MouseCursor.defer,
      onEnter: canInteract ? (_) => setState(() => _hovered = true) : null,
      onExit: canInteract
          ? (_) => setState(() {
              _hovered = false;
              _pressed = false;
            })
          : null,
      child: AnimatedScale(
        duration: AppDuration.card,
        curve: Curves.easeOutCubic,
        scale: _pressed ? .992 : 1,
        child: AnimatedContainer(
          duration: AppDuration.card,
          curve: Curves.easeOutCubic,
          transform: Matrix4.translationValues(
            0,
            active ? _cardHoverOffset : 0,
            0,
          ),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(
              color: active
                  ? accent.withValues(alpha: .38)
                  : AppColors.borderLight,
            ),
            boxShadow: active ? AppShadows.floating : AppShadows.card,
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.lg),
            child: Stack(
              fit: StackFit.passthrough,
              children: [
                Positioned(
                  top: 0,
                  bottom: 0,
                  left: 0,
                  child: AnimatedContainer(
                    duration: AppDuration.card,
                    width: active ? 4 : 3,
                    color: accent.withValues(alpha: active ? .88 : .42),
                  ),
                ),
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                    onHighlightChanged: canInteract
                        ? (pressed) => setState(() => _pressed = pressed)
                        : null,
                    onTap: widget.onTap,
                    child: widget.child,
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

class _IconBadge extends StatelessWidget {
  final IconData icon;
  final Color color;

  const _IconBadge({required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: color.withValues(alpha: .11),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: color.withValues(alpha: .18)),
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
        color: color.withValues(alpha: .11),
        borderRadius: BorderRadius.circular(AppRadius.badge),
        border: Border.all(color: color.withValues(alpha: .20)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: 6,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 7,
              height: 7,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: AppSpacing.xs),
            Text(
              _statusLabel(status),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.bodySmall.copyWith(
                color: color,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
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
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: AppColors.textSecondary),
          const SizedBox(width: AppSpacing.xs),
          Flexible(
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.bodySmall,
            ),
          ),
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
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 4,
          height: 42,
          decoration: BoxDecoration(
            gradient: AppGradients.futuristic,
            borderRadius: BorderRadius.circular(AppRadius.pill),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: AppTextStyles.heading3),
              const SizedBox(height: AppSpacing.xxs),
              Text(
                subtitle,
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                  height: 1.35,
                ),
              ),
            ],
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
        child: _InteractivePanel(
          accent: AppColors.info,
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const _IconBadge(
                  icon: Icons.inbox_rounded,
                  color: AppColors.info,
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
        child: _InteractivePanel(
          accent: AppColors.warning,
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.xl),
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
                  'Tài khoản quản trị hiện tại cần quyền ${_permissionLabel(permission)} để mở mục này.',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.bodyMedium.copyWith(height: 1.45),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

String _permissionLabel(String permission) {
  switch (permission.trim().toLowerCase()) {
    case 'view_dashboard':
    case 'dashboard.read':
      return 'xem bảng điều khiển';
    case 'manage_users':
    case 'users.write':
      return 'quản lý người dùng';
    case 'manage_payments':
    case 'payments.write':
      return 'quản lý thanh toán';
    case 'manage_sales':
    case 'sales.write':
      return 'quản lý cộng tác viên';
    case 'manage_sale_conversions':
      return 'quản lý quy đổi điểm';
    case 'wellness_rewards.read':
      return 'xem Điểm chăm sóc và ưu đãi';
    case 'wellness_rewards.write':
      return 'quản lý Điểm chăm sóc và ưu đãi';
    case 'manage_reconciliation':
    case 'reconciliation.write':
      return 'quản lý đối soát';
    case 'manage_plans':
    case 'plans.write':
      return 'quản lý gói dịch vụ';
    case 'export_reports':
    case 'reports.write':
      return 'xuất báo cáo';
    case 'view_audit':
    case 'audit.read':
      return 'xem nhật ký kiểm tra';
    case 'manage_config':
    case 'config.write':
      return 'quản lý cấu hình';
    default:
      return 'phù hợp';
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
        child: _InteractivePanel(
          accent: AppColors.primary,
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.xl),
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
      AdminPanelSection.dashboard => 'Bảng điều khiển',
      AdminPanelSection.users => 'Người dùng',
      AdminPanelSection.payments => 'Thanh toán',
      AdminPanelSection.sales => 'Cộng tác viên',
      AdminPanelSection.saleConversions => 'Quy đổi điểm cộng tác viên',
      AdminPanelSection.wellnessRewards => 'Điểm chăm sóc',
      AdminPanelSection.reconciliation => 'Đối soát',
      AdminPanelSection.plans => 'Gói dịch vụ',
      AdminPanelSection.reports => 'Báo cáo',
      AdminPanelSection.audit => 'Nhật ký kiểm tra',
      AdminPanelSection.config => 'Cấu hình',
    };
  }

  String get guideSummary {
    return switch (this) {
      AdminPanelSection.dashboard => 'Theo dõi số liệu chính',
      AdminPanelSection.users => 'Quản lý trạng thái tài khoản',
      AdminPanelSection.payments => 'Duyệt và kiểm tra thanh toán',
      AdminPanelSection.sales => 'Duyệt hồ sơ cộng tác viên',
      AdminPanelSection.saleConversions => 'Xử lý quy đổi điểm',
      AdminPanelSection.wellnessRewards =>
        'Quản lý ưu đãi và kho mã dùng một lần',
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
      AdminPanelSection.wellnessRewards => AdminRoutePaths.wellnessRewards,
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
      AdminPanelSection.wellnessRewards => Icons.redeem_outlined,
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
      AdminPanelSection.wellnessRewards => Icons.redeem_rounded,
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
        _AdminAction('close', 'Đóng cộng tác viên', Icons.cancel_rounded),
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
      AdminPanelSection.wellnessRewards => const [],
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
    border: Border.all(color: AppColors.borderLight),
    boxShadow: elevated ? AppShadows.card : const [],
  );
}

String _metricLabel(AdminDashboardMetric metric) {
  return switch (metric.key) {
    'users_total' => 'Người dùng',
    'payments_pending' => 'Thanh toán chờ duyệt',
    'sales_active' => 'Cộng tác viên đang hoạt động',
    'commission_available' => 'Điểm cộng tác viên khả dụng',
    _ => 'Chỉ số vận hành',
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
  return 'Đang cập nhật';
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
  final local = VietnamTime.wallClock(dateTime);
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
    'admin_review_sale_profile' => 'Duyệt hồ sơ cộng tác viên',
    'admin_upsert_config_version' => 'Lưu cấu hình',
    'admin_request_report_export' => 'Yêu cầu xuất báo cáo',
    'admin_adjust_sale_points' => 'Điều chỉnh điểm cộng tác viên',
    'admin_create_reconciliation_run' => 'Tạo phiên đối soát',
    'admin_update_reconciliation_discrepancy_status' => 'Cập nhật đối soát',
    'admin_review_sale_point_conversion' => 'Duyệt quy đổi điểm',
    'admin_upsert_reward_offer' => 'Cập nhật ưu đãi Điểm chăm sóc',
    'admin_import_reward_codes' => 'Nhập kho mã voucher',
    'admin_cancel_reward_redemption' => 'Hủy giao dịch voucher',
    _ => 'Hoạt động quản trị',
  };
}

String _auditTargetLabel(String target) {
  final normalized = target.trim().toLowerCase();
  if (normalized.isEmpty) return 'Đối tượng quản trị';
  if (normalized.contains('reward_offer')) return 'Ưu đãi Điểm chăm sóc';
  if (normalized.contains('reward_code')) return 'Kho mã voucher';
  if (normalized.contains('redemption')) return 'Giao dịch voucher';
  if (normalized.contains('payment')) return 'Giao dịch thanh toán';
  if (normalized.contains('sale')) return 'Hồ sơ cộng tác viên';
  if (normalized.contains('user') || normalized.contains('profile')) {
    return 'Tài khoản người dùng';
  }
  if (normalized.contains('config') || normalized.contains('plan')) {
    return 'Cấu hình hệ thống';
  }
  return 'Đối tượng quản trị';
}

String _auditReasonLabel(String reason) {
  final value = reason.trim();
  if (value.isEmpty) return 'Không có mô tả';
  return switch (value.toLowerCase()) {
    'system' => 'Do hệ thống thực hiện',
    'manual review' => 'Đã kiểm tra thủ công',
    'user request' => 'Theo yêu cầu của người dùng',
    _ => value,
  };
}
