import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:nano_app/app/app_surface_controller.dart';
import 'package:nano_app/app_versions/admin/features/admin_panel/domain/entities/admin_models.dart';
import 'package:nano_app/app_versions/admin/features/admin_panel/presentation/controllers/admin_controller.dart';
import 'package:nano_app/app_versions/admin/features/admin_panel/presentation/copy/admin_ui_copy.dart';
import 'package:nano_app/app_versions/admin/features/admin_panel/providers/admin_payout_proof_provider.dart';
import 'package:nano_app/app_versions/admin/features/admin_panel/providers/admin_providers.dart';
import 'package:nano_app/app_versions/admin/features/wellness_rewards/wellness_rewards_admin.dart';
import 'package:nano_app/app_versions/admin/router/admin_route_paths.dart';
import 'package:nano_app/app_versions/admin/theme/admin_workspace_theme.dart';
import 'package:nano_app/core/localization/vietnam_time.dart';
import 'package:nano_app/core/payments/viet_qr_payload_builder.dart';
import 'package:nano_app/core/theme/theme.dart';
import 'package:qr_flutter/qr_flutter.dart';

part 'admin_workspace_shell.dart';
part 'admin_workspace_sections.dart';
part 'admin_workspace_dialogs.dart';
part 'admin_workspace_presentation.dart';

const _desktopBreakpoint = 900.0;
const _wideBreakpoint = 1220.0;
const _searchDebounceDuration = Duration(milliseconds: 320);

class AdminWorkspacePage extends ConsumerStatefulWidget {
  final AdminPanelSection initialSection;

  const AdminWorkspacePage({required this.initialSection, super.key});

  @override
  ConsumerState<AdminWorkspacePage> createState() => _AdminWorkspacePageState();
}

class _AdminWorkspacePageState extends ConsumerState<AdminWorkspacePage>
    with WidgetsBindingObserver {
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  final _searchController = TextEditingController();
  Timer? _searchDebounce;
  Timer? _paymentAlertTimer;
  AdminPanelState? _lastUsableState;
  String? _lastNotice;
  String? _runningTargetId;
  bool _paymentAlertRefreshInFlight = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      unawaited(_activateSection(widget.initialSection));
      unawaited(_refreshPaymentAlert());
    });
    _paymentAlertTimer = Timer.periodic(
      const Duration(seconds: 30),
      (_) => unawaited(_refreshPaymentAlert()),
    );
  }

  @override
  void didUpdateWidget(covariant AdminWorkspacePage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialSection == widget.initialSection) return;
    _searchDebounce?.cancel();
    _searchController.clear();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) unawaited(_activateSection(widget.initialSection));
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(_refreshPaymentAlert());
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _searchDebounce?.cancel();
    _paymentAlertTimer?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AsyncValue<AdminPanelState>>(adminControllerProvider, (
      previous,
      next,
    ) {
      final value = next.asData?.value;
      if (value != null) {
        _lastUsableState = value;
        _showNotice(value);
      }
    });

    final asyncState = ref.watch(adminControllerProvider);
    final candidate = asyncState.asData?.value ?? _lastUsableState;
    final current = candidate?.section == widget.initialSection
        ? candidate
        : null;

    if (current == null) {
      return asyncState.when(
        loading: () => const _AdminBlockingState(
          icon: Icons.admin_panel_settings_rounded,
          title: 'Đang chuẩn bị khu quản trị',
          message: 'Ứng dụng đang kiểm tra quyền và tải dữ liệu cần thiết.',
          loading: true,
        ),
        error: (_, __) => _AdminBlockingState(
          icon: Icons.cloud_off_rounded,
          title: 'Chưa mở được khu quản trị',
          message: 'Kết nối chưa ổn định. Dữ liệu chưa bị thay đổi.',
          actionLabel: 'Thử lại',
          onAction: _refreshCurrentSection,
        ),
        data: (_) => const _AdminBlockingState(
          icon: Icons.admin_panel_settings_rounded,
          title: 'Đang mở khu vực đã chọn',
          message: 'Nội dung phù hợp đang được chuẩn bị.',
          loading: true,
        ),
      );
    }

    if (!current.session.isAdmin) {
      return _AdminBlockingState(
        icon: Icons.lock_person_rounded,
        title: 'Tài khoản chưa có quyền quản trị',
        message:
            'Bạn có thể đăng xuất hoặc trở lại ứng dụng dành cho người dùng.',
        actionLabel: 'Đăng xuất',
        onAction: _signOut,
        secondaryLabel: current.session.canUseUserApp
            ? 'Về ứng dụng người dùng'
            : null,
        onSecondaryAction: current.session.canUseUserApp ? _showUserApp : null,
      );
    }

    final sections = AdminPanelSection.values
        .where(current.session.canAccessSection)
        .toList(growable: false);
    final busy = asyncState.isLoading;

    return PopScope(
      canPop: current.section == AdminPanelSection.dashboard,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop || current.section == AdminPanelSection.dashboard) return;
        context.go(AdminRoutePaths.dashboard);
      },
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < _desktopBreakpoint;
          final wide = constraints.maxWidth >= _wideBreakpoint;

          return Scaffold(
            key: _scaffoldKey,
            backgroundColor: context.adminColors.canvas,
            drawer: compact
                ? _AdminNavigationDrawer(
                    selected: current.section,
                    sections: sections,
                    onSelected: _goToSection,
                    onShowGuide: _showGuide,
                    onShowUserApp: current.session.canUseUserApp
                        ? _showUserApp
                        : null,
                    onSignOut: _signOut,
                  )
                : null,
            body: SafeArea(
              child: Row(
                children: [
                  if (!compact)
                    _AdminSidebar(
                      selected: current.section,
                      sections: sections,
                      extended: wide,
                      onSelected: _goToSection,
                      onShowGuide: _showGuide,
                      onShowUserApp: current.session.canUseUserApp
                          ? _showUserApp
                          : null,
                      onSignOut: _signOut,
                    ),
                  Expanded(
                    child: Column(
                      children: [
                        _AdminToolbar(
                          state: current,
                          compact: compact,
                          busy: busy,
                          searchController: _searchController,
                          onMenuPressed: compact
                              ? () => _scaffoldKey.currentState?.openDrawer()
                              : null,
                          onSearchChanged: _queueSearch,
                          onClearSearch: _clearSearch,
                          onRefresh: _refreshCurrentSection,
                          onShowGuide: _showGuide,
                          onShowUserApp: current.session.canUseUserApp
                              ? _showUserApp
                              : null,
                          onSignOut: _signOut,
                        ),
                        if (busy) const LinearProgressIndicator(minHeight: 2),
                        if (current.paymentReviewAlert.hasPendingReviews &&
                            current.session.hasPermission(
                              AdminPermissions.paymentsWrite,
                            ))
                          _PaymentReviewNotice(
                            count:
                                current.paymentReviewAlert.pendingReviewCount,
                            onOpen: () =>
                                _goToSection(AdminPanelSection.payments),
                          ),
                        Expanded(
                          child: _AdminContentHost(
                            state: current,
                            busy: busy,
                            runningTargetId: _runningTargetId,
                            onAction: _runAction,
                            onGoToSection: _goToSection,
                            onClearSearch: _clearSearch,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _activateSection(AdminPanelSection section) async {
    _searchController.clear();
    if (_lastUsableState?.section != section) _lastUsableState = null;
    await ref.read(adminControllerProvider.notifier).selectSection(section);
  }

  void _goToSection(AdminPanelSection section) {
    final current =
        ref.read(adminControllerProvider).asData?.value ?? _lastUsableState;
    if (current?.section == section) return;
    AppFeedbackService.instance.emit(AppFeedbackType.selection);
    context.go(_routeForSection(section));
  }

  void _queueSearch(String value) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(_searchDebounceDuration, () {
      if (!mounted) return;
      unawaited(ref.read(adminControllerProvider.notifier).search(value.trim()));
    });
  }

  void _clearSearch() {
    _searchDebounce?.cancel();
    if (_searchController.text.isEmpty) return;
    _searchController.clear();
    AppFeedbackService.instance.emit(AppFeedbackType.selection);
    unawaited(ref.read(adminControllerProvider.notifier).search(''));
  }

  Future<void> _refreshCurrentSection() async {
    AppFeedbackService.instance.emit(AppFeedbackType.primaryAction);
    try {
      await ref.read(adminControllerProvider.notifier).refresh();
      if (!mounted) return;
      final next = ref.read(adminControllerProvider);
      final value = next.asData?.value;
      AppFeedbackService.instance.emit(
        next.hasError
            ? AppFeedbackType.error
            : value?.isPermissionDenied == true
            ? AppFeedbackType.warning
            : AppFeedbackType.success,
      );
    } catch (_) {
      if (mounted) AppFeedbackService.instance.emit(AppFeedbackType.error);
    }
  }

  Future<void> _refreshPaymentAlert() async {
    if (!mounted || _paymentAlertRefreshInFlight || _runningTargetId != null) {
      return;
    }
    _paymentAlertRefreshInFlight = true;
    try {
      await ref
          .read(adminControllerProvider.notifier)
          .refreshPaymentReviewAlert();
    } finally {
      _paymentAlertRefreshInFlight = false;
    }
  }

  void _showNotice(AdminPanelState state) {
    final raw = state.lastMessage?.trim();
    if (raw == null || raw.isEmpty || raw == _lastNotice || !mounted) return;
    _lastNotice = raw;
    final warning = state.isPermissionDenied;
    final message = AdminUiCopy.safeNotice(raw);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final messenger = ScaffoldMessenger.of(context);
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            showCloseIcon: true,
            content: Row(
              children: [
                Icon(
                  warning
                      ? Icons.warning_amber_rounded
                      : Icons.check_circle_outline_rounded,
                  color: Colors.white,
                  size: 19,
                ),
                const SizedBox(width: 10),
                Expanded(child: Text(message)),
              ],
            ),
          ),
        );
    });
  }

  void _showGuide() {
    AppFeedbackService.instance.emit(AppFeedbackType.selection);
    showDialog<void>(
      context: context,
      builder: (context) => const _AdminGuideDialog(),
    );
  }

  void _showUserApp() {
    AppFeedbackService.instance.emit(AppFeedbackType.selection);
    ref.read(appSurfaceControllerProvider.notifier).showUser();
  }

  Future<void> _signOut() async {
    AppFeedbackService.instance.emit(AppFeedbackType.primaryAction);
    try {
      await ref.read(adminAccessControllerProvider.notifier).signOut();
      ref.read(appSurfaceControllerProvider.notifier).reset();
      if (mounted) AppFeedbackService.instance.emit(AppFeedbackType.success);
    } catch (_) {
      if (!mounted) return;
      AppFeedbackService.instance.emit(AppFeedbackType.error);
      _showError('Chưa đăng xuất được. Bạn vui lòng thử lại.');
    }
  }

  Future<void> _runAction(
    AdminPanelSection section,
    AdminActionPresentation action,
    AdminWorkItem item,
  ) async {
    if (_runningTargetId != null) return;

    final confirmation = await showDialog<_AdminActionConfirmation>(
      context: context,
      barrierDismissible: false,
      builder: (context) => _AdminReasonDialog(
        action: action,
        itemTitle: item.title,
        requiresTransferVerification:
            section == AdminPanelSection.payments && action.key == 'approve',
      ),
    );
    if (confirmation == null ||
        confirmation.reason.trim().isEmpty ||
        !mounted) {
      return;
    }

    setState(() => _runningTargetId = item.id);
    final payload = <String, Object?>{};

    if (section == AdminPanelSection.payments && action.key == 'approve') {
      payload['transfer_verified'] = confirmation.transferVerified;
    }

    try {
      if (section == AdminPanelSection.saleConversions &&
          action.key == 'mark_paid') {
        final proofPath = await _pickAndUploadSalePayoutProof(item.id);
        if (proofPath == null) return;
        payload['payment_proof_path'] = proofPath;
      }

      AppFeedbackService.instance.emit(AppFeedbackType.primaryAction);
      await ref
          .read(adminControllerProvider.notifier)
          .runMutation(
            section: section,
            action: action.key,
            targetId: item.id,
            reason: confirmation.reason,
            payload: payload,
          );
      if (!mounted) return;

      final latest = ref.read(adminControllerProvider).asData?.value;
      AppFeedbackService.instance.emit(
        latest?.isPermissionDenied == true
            ? AppFeedbackType.warning
            : AppFeedbackType.success,
      );
    } catch (_) {
      if (!mounted) return;
      AppFeedbackService.instance.emit(AppFeedbackType.error);
      _showError('Thao tác chưa hoàn tất. Nội dung bạn đang xem vẫn an toàn.');
    } finally {
      if (mounted) setState(() => _runningTargetId = null);
    }
  }

  Future<String?> _pickAndUploadSalePayoutProof(String conversionId) async {
    try {
      final image = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );
      if (image == null) return null;

      final bytes = await image.readAsBytes();
      return await ref
          .read(adminPayoutProofRepositoryProvider)
          .uploadSalePayoutProof(
            conversionId: conversionId,
            fileName: image.name,
            contentType: image.mimeType ?? 'image/jpeg',
            bytes: bytes,
          );
    } catch (_) {
      if (mounted) {
        _showError(
          'Chưa tải được ảnh xác nhận. Hãy chọn lại ảnh trước khi tiếp tục.',
        );
      }
      return null;
    }
  }

  void _showError(String message) {
    final messenger = ScaffoldMessenger.of(context);
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          showCloseIcon: true,
          content: Row(
            children: [
              const Icon(
                Icons.error_outline_rounded,
                color: Colors.white,
                size: 19,
              ),
              const SizedBox(width: 10),
              Expanded(child: Text(message)),
            ],
          ),
        ),
      );
  }
}
