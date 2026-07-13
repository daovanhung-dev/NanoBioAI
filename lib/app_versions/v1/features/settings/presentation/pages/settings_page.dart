import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:nano_app/app_versions/v1/router/v1_route_paths.dart';
import 'package:nano_app/app_versions/v2/features/auth/providers/auth_providers.dart';
import 'package:nano_app/app_versions/v2/features/cloud_sync/cloud_sync.dart';
import 'package:nano_app/app_versions/v2/router/v2_route_paths.dart';
import 'package:nano_app/core/constants/routes/auth_route_paths.dart';
import 'package:nano_app/core/theme/theme.dart';
import 'package:nano_app/app_versions/v1/features/dashboard/domain/entities/dashboard_entity.dart';
import 'package:nano_app/app_versions/v1/features/dashboard/providers/dashboard_provider.dart';
import 'package:nano_app/app_versions/v1/features/settings/domain/entities/settings_preferences_entity.dart';
import 'package:nano_app/app_versions/v1/features/settings/providers/settings_provider.dart';
import 'package:nano_app/app_versions/v1/features/settings/presentation/widgets/guest_account_access_card.dart';
import 'package:nano_app/services/supabase/auth/account_security_provider.dart';
import 'package:nano_app/services/supabase/sale/sale_participation_service.dart';
import 'package:nano_app/sale_referral/presentation/pages/sale_participation_page.dart';

import 'dev_database_viewer_page.dart';

class SettingsView extends ConsumerWidget {
  const SettingsView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashboardAsync = ref.watch(dashboardProvider);
    final preferencesAsync = ref.watch(settingsPreferencesControllerProvider);
    final cacheSizeAsync = ref.watch(settingsCacheSizeProvider);
    final preferences =
        preferencesAsync.value ?? SettingsPreferencesEntity.defaults();
    final dashboard = dashboardAsync.value;
    final saleStateAsync = ref.watch(saleStateProvider);
    final isAuthenticated = ref.watch(currentAuthUserIdProvider) != null;
    final syncState = ref.watch(userDataSyncControllerProvider);

    return MedicalPageScaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(dashboardProvider);
            ref.invalidate(settingsPreferencesControllerProvider);
            ref.invalidate(settingsCacheSizeProvider);
            ref.invalidate(saleStateProvider);
            try {
              await ref.read(dashboardProvider.future);
            } catch (_) {}
            try {
              await ref.read(settingsPreferencesControllerProvider.future);
            } catch (_) {}
            try {
              await ref.read(settingsCacheSizeProvider.future);
            } catch (_) {}
          },
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.pagePadding),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _Header(isLoading: dashboardAsync.isLoading),
                      const SizedBox(height: AppSpacing.lg),
                      _ProfileCard(dashboard: dashboard),
                      if (!isAuthenticated) ...[
                        const SizedBox(height: AppSpacing.lg),
                        GuestAccountAccessCard(
                          onLogin: () => context.go(AuthRoutePaths.login),
                          onRegister: () => context.go(AuthRoutePaths.register),
                        ),
                      ],
                      const SizedBox(height: AppSpacing.xl),
                      _SectionTitle('Tài khoản'),
                      const SizedBox(height: AppSpacing.md),
                      _MenuCard(
                        children: [
                          _MenuItem(
                            icon: Icons.person_rounded,
                            title: 'Thông tin cá nhân',
                            subtitle: dashboard == null
                                ? 'Nabi chưa thấy hồ sơ nào sẵn sàng'
                                : _profileSubtitle(dashboard),
                            onTap: () => context.push(V1RoutePaths.profile),
                          ),
                          if (isAuthenticated) ...[
                            const _DividerLine(),
                            _MenuItem(
                              icon: Icons.lock_rounded,
                              title: 'Bảo mật',
                              subtitle:
                                  'Bảo vệ tài khoản và thông tin cá nhân của bạn',
                              onTap: () => _showChangePasswordSheet(context),
                            ),
                          ],
                          const _DividerLine(),
                          _MenuItem(
                            icon: Icons.notifications_rounded,
                            title: 'Thông báo',
                            subtitle: preferences.pushEnabled
                                ? 'Đang bật nhắc nhở local'
                                : 'Đang tắt nhắc nhở local',
                            trailing: Switch(
                              value: preferences.pushEnabled,
                              activeThumbColor: AppColors.primary,
                              onChanged: preferencesAsync.isLoading
                                  ? null
                                  : (value) => ref
                                        .read(
                                          settingsPreferencesControllerProvider
                                              .notifier,
                                        )
                                        .setPushEnabled(value),
                            ),
                          ),
                        ],
                      ),
                      if (isAuthenticated) ...[
                        const SizedBox(height: AppSpacing.xl),
                        _SectionTitle('Cùng Nabi phát triển'),
                        const SizedBox(height: AppSpacing.md),
                        _MenuCard(
                          children: [
                            _SaleSettingsEntry(saleState: saleStateAsync),
                            const _DividerLine(),
                            const _ReferralCodeSettingsEntry(),
                          ],
                        ),
                      ],
                      const SizedBox(height: AppSpacing.xl),
                      _SectionTitle('Ứng dụng'),
                      const SizedBox(height: AppSpacing.md),
                      _MenuCard(
                        children: [
                          _MenuItem(
                            icon: Icons.dark_mode_rounded,
                            title: 'Chế độ tối',
                            subtitle: preferences.isDarkMode
                                ? 'Đang lưu lựa chọn dark mode'
                                : 'Đang lưu lựa chọn light mode',
                            trailing: Switch(
                              value: preferences.isDarkMode,
                              activeThumbColor: AppColors.primary,
                              onChanged: preferencesAsync.isLoading
                                  ? null
                                  : (value) => ref
                                        .read(
                                          settingsPreferencesControllerProvider
                                              .notifier,
                                        )
                                        .setDarkMode(value),
                            ),
                          ),
                          const _DividerLine(),
                          _MenuItem(
                            icon: Icons.language_rounded,
                            title: 'Ngôn ngữ',
                            subtitle: _languageLabel(preferences.languageCode),
                          ),
                          const _DividerLine(),
                          _MenuItem(
                            icon: Icons.storage_rounded,
                            title: 'Dung lượng',
                            subtitle: cacheSizeAsync.when(
                              data: _formatBytes,
                              loading: () => 'Nabi đang kiểm tra dung lượng...',
                              error: (_, __) =>
                                  'Nabi chưa kiểm tra được dung lượng',
                            ),
                            trailing: IconButton(
                              tooltip: 'Dọn bộ nhớ tạm',
                              icon: const Icon(Icons.cleaning_services_rounded),
                              onPressed: () => ref
                                  .read(
                                    settingsPreferencesControllerProvider
                                        .notifier,
                                  )
                                  .clearCache(),
                            ),
                          ),
                        ],
                      ),
                      if (kDebugMode) ...[
                        const SizedBox(height: AppSpacing.xl),
                        _SectionTitle('Dev'),
                        const SizedBox(height: AppSpacing.md),
                        _MenuCard(
                          children: [
                            _MenuItem(
                              icon: Icons.developer_mode_rounded,
                              title: 'Công cụ dữ liệu',
                              subtitle:
                                  'Chỉ hiển thị trong chế độ phát triển ứng dụng',
                              onTap: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute<void>(
                                    builder: (_) =>
                                        const DevDatabaseViewerPage(),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ],
                      const SizedBox(height: AppSpacing.xl),
                      _SectionTitle('AI & Sức khỏe'),
                      const SizedBox(height: AppSpacing.md),
                      _MenuCard(
                        children: [
                          _MenuItem(
                            icon: Icons.auto_awesome_rounded,
                            title: 'Phong cách AI',
                            subtitle: _aiPersonalityLabel(
                              preferences.aiPersonality,
                            ),
                          ),
                          const _DividerLine(),
                          _MenuItem(
                            icon: Icons.favorite_rounded,
                            title: 'Mục tiêu sức khỏe',
                            subtitle: dashboard == null
                                ? 'Nabi chưa thấy mục tiêu nào được chọn'
                                : _goalsSubtitle(dashboard.goals),
                          ),
                          const _DividerLine(),
                          _MenuItem(
                            icon: Icons.sync_rounded,
                            title: 'Dữ liệu của bạn',
                            subtitle: isAuthenticated
                                ? _syncStatusLabel(
                                    syncState,
                                    fallback: _privacyModeLabel(
                                      preferences.dataPrivacyMode,
                                    ),
                                  )
                                : 'Đăng nhập để đồng bộ dữ liệu khi đổi thiết bị',
                            onTap: isAuthenticated
                                ? () => _showDataSyncSheet(context, ref)
                                : () => context.go(AuthRoutePaths.login),
                          ),
                        ],
                      ),
                      if (isAuthenticated) ...[
                        const SizedBox(height: AppSpacing.xl),
                        _DangerCard(
                          email: dashboard?.email.trim().isEmpty == false
                              ? dashboard!.email
                              : null,
                          onLogout: () => _confirmLogout(context, ref),
                          onDeleteAccount: () =>
                              _confirmDeleteAccount(context, ref),
                        ),
                      ],
                      const SizedBox(height: AppSpacing.xxxl),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showChangePasswordSheet(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => const _ChangePasswordSheet(),
    );
  }

  String _syncStatusLabel(
    UserDataSyncState state, {
    required String fallback,
  }) {
    return switch (state.status) {
      UserDataSyncStatus.syncing => 'Đang đồng bộ dữ liệu...',
      UserDataSyncStatus.awaitingConsent =>
        'Đang chờ bạn xác nhận dữ liệu khách',
      UserDataSyncStatus.pendingUpload =>
        '${state.pendingCount} thay đổi đang chờ đồng bộ',
      UserDataSyncStatus.success => state.lastSuccessAt == null
          ? 'Đã đồng bộ'
          : 'Đồng bộ gần nhất: ${_formatSyncTime(state.lastSuccessAt!)}',
      UserDataSyncStatus.error =>
        state.safeError ?? 'Đồng bộ chưa hoàn tất, dữ liệu vẫn được giữ',
      UserDataSyncStatus.idle => fallback,
    };
  }

  String _formatSyncTime(DateTime value) {
    final local = value.toLocal();
    String two(int number) => number.toString().padLeft(2, '0');
    return '${two(local.hour)}:${two(local.minute)} '
        '${two(local.day)}/${two(local.month)}/${local.year}';
  }

  Future<void> _showDataSyncSheet(BuildContext context, WidgetRef ref) {
    return showModalBottomSheet<void>(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      builder: (_) => const _UserDataSyncSheet(),
    );
  }

  Future<void> _confirmLogout(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Đăng xuất?'),
        content: const Text(
          'Nabi sẽ đưa bạn về màn đăng nhập. Dữ liệu cloud của bạn vẫn được giữ nguyên.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Ở lại'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Đăng xuất'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      final controller = ref.read(v2AuthControllerProvider.notifier);
      var result = await controller.signOut();
      if (!context.mounted) return;

      if (result.requiresForce) {
        final force = await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: const Text('Còn dữ liệu chưa đồng bộ'),
            content: Text(result.message ?? 'Dữ liệu vẫn được giữ trên thiết bị.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(false),
                child: const Text('Ở lại và thử lại'),
              ),
              FilledButton(
                onPressed: () => Navigator.of(dialogContext).pop(true),
                child: const Text('Vẫn đăng xuất'),
              ),
            ],
          ),
        );
        if (force != true) return;
        result = await controller.signOut(force: true);
      }

      if (!result.signedOut || !context.mounted) return;
      invalidateUserScopedProviders(ref);
      context.go(AuthRoutePaths.authGate);
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Nabi chưa thể đăng xuất lúc này. Bạn thử lại nhé.'),
        ),
      );
    }
  }

  Future<void> _confirmDeleteAccount(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Yêu cầu xóa tài khoản?'),
        content: const Text(
          'Yêu cầu này sẽ được gửi tới hệ thống bảo mật. Nabikhông giữ khóa quản trị trong ứng dụng.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Hủy'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Gửi yêu cầu xóa'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      await ref
          .read(accountSecurityControllerProvider.notifier)
          .requestAccountDeletion();
      invalidateUserScopedProviders(ref);
      if (!context.mounted) return;
      context.go(AuthRoutePaths.authGate);
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Nabi chưa thể gửi yêu cầu xóa tài khoản lúc này. Bạn thử lại sau nhé.',
          ),
        ),
      );
    }
  }
}

class _ChangePasswordSheet extends ConsumerStatefulWidget {
  const _ChangePasswordSheet();

  @override
  ConsumerState<_ChangePasswordSheet> createState() =>
      _ChangePasswordSheetState();
}

class _ChangePasswordSheetState extends ConsumerState<_ChangePasswordSheet> {
  final _formKey = GlobalKey<FormState>();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.lg,
        bottomInset + AppSpacing.lg,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Đổi mật khẩu', style: AppTextStyles.heading3),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Mật khẩu mới cần có ít nhất 8 ký tự. Nabi sẽ không lưu mật khẩu trong hồ sơ công khai.',
              style: AppTextStyles.bodyMedium,
            ),
            const SizedBox(height: AppSpacing.lg),
            TextFormField(
              controller: _password,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Mật khẩu mới'),
              validator: _validatePassword,
            ),
            const SizedBox(height: AppSpacing.md),
            TextFormField(
              controller: _confirm,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Nhập lại mật khẩu'),
              validator: (value) {
                final passwordError = _validatePassword(value);
                if (passwordError != null) return passwordError;
                if (value != _password.text) {
                  return 'Hai mật khẩu chưa khớp nhau';
                }
                return null;
              },
            ),
            const SizedBox(height: AppSpacing.lg),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _saving ? null : _save,
                child: _saving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Cập nhật mật khẩu'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String? _validatePassword(String? value) {
    final text = value ?? '';
    if (text.length < 8) return 'Mật khẩu cần ít nhất 8 ký tự';
    return null;
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      await ref
          .read(accountSecurityControllerProvider.notifier)
          .updatePassword(_password.text);
      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nabi đã cập nhật mật khẩu.')),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Nabi chưa thể cập nhật mật khẩu lúc này. Bạn thử lại sau nhé.',
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}

class _SaleSettingsEntry extends StatelessWidget {
  final AsyncValue<SaleState> saleState;

  const _SaleSettingsEntry({required this.saleState});

  @override
  Widget build(BuildContext context) {
    return saleState.when(
      loading: () => const _MenuItem(
        icon: Icons.workspace_premium_rounded,
        title: 'Không gian Sale',
        subtitle: 'Nabiđang kiểm tra quyền Sale của bạn...',
        trailing: SizedBox(
          height: 22,
          width: 22,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
      error: (_, __) => _MenuItem(
        icon: Icons.volunteer_activism_rounded,
        title: 'Tham gia kiếm tiền cùng Nabi',
        subtitle: 'Mở điều lệ tham gia và thử kiểm tra lại quyền Sale.',
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => const SaleParticipationPage(),
          ),
        ),
      ),
      data: (state) {
        if (state.isActive) {
          return _MenuItem(
            icon: Icons.workspace_premium_rounded,
            title: 'Chuyển sang không gian Sale',
            subtitle: state.referralCode == null
                ? 'Theo dõi mạng lưới, xếp hạng và công cụ Sale'
                : 'Mã giới thiệu: ${state.referralCode}',
            onTap: () => context.push(V2RoutePaths.sale),
          );
        }

        return _MenuItem(
          icon: Icons.volunteer_activism_rounded,
          title: 'Tham gia kiếm tiền cùng Nabi',
          subtitle: _subtitleFor(state.status),
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => const SaleParticipationPage(),
            ),
          ),
        );
      },
    );
  }

  String _subtitleFor(SaleStatus status) {
    switch (status) {
      case SaleStatus.pending:
        return 'Xem lại điều lệ và trạng thái tham gia của bạn';
      case SaleStatus.suspended:
        return 'Quyền Sale đang tạm khóa; xem thông tin hỗ trợ';
      case SaleStatus.closed:
        return 'Quyền Sale đã đóng; xem thông tin hỗ trợ';
      case SaleStatus.none:
      case SaleStatus.active:
        return 'Đọc điều lệ, chấp nhận và nhận quyền Sale cho tài khoản';
    }
  }
}

class _UserDataSyncSheet extends ConsumerWidget {
  const _UserDataSyncSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(userDataSyncControllerProvider);
    final isWorking = state.status == UserDataSyncStatus.syncing;
    final message = switch (state.status) {
      UserDataSyncStatus.awaitingConsent =>
        'Bạn cần hoàn tất lựa chọn dữ liệu tại màn xác nhận tài khoản.',
      UserDataSyncStatus.pendingUpload =>
        'Còn ${state.pendingCount} thay đổi trên thiết bị chưa gửi thành công. '
        'Không có dữ liệu nào bị xóa.',
      UserDataSyncStatus.error =>
        state.safeError ?? 'Đồng bộ chưa hoàn tất. Dữ liệu vẫn được giữ trên thiết bị.',
      UserDataSyncStatus.success => 'Dữ liệu tài khoản đã được đồng bộ.',
      UserDataSyncStatus.syncing => 'Nabi đang đồng bộ dữ liệu của bạn...',
      UserDataSyncStatus.idle =>
        'Dữ liệu sức khỏe và lịch trình của tài khoản được đồng bộ theo cơ chế '
        'an toàn: gửi thay đổi trên thiết bị trước, sau đó mới tải dữ liệu tài khoản.',
    };

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Dữ liệu của bạn', style: AppTextStyles.heading3),
          const SizedBox(height: AppSpacing.sm),
          Text(message, style: AppTextStyles.bodyMedium),
          if (state.lastSuccessAt != null) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Lần thành công gần nhất: ${state.lastSuccessAt!.toLocal()}',
              style: AppTextStyles.bodySmall,
            ),
          ],
          const SizedBox(height: AppSpacing.lg),
          FilledButton.icon(
            onPressed: isWorking
                ? null
                : () async {
                    final outcome = await ref
                        .read(userDataSyncControllerProvider.notifier)
                        .retry();
                    if (!context.mounted) return;
                    final text = outcome.isSuccess
                        ? 'Đồng bộ dữ liệu thành công.'
                        : outcome.safeError ??
                            'Chưa thể đồng bộ. Dữ liệu vẫn được giữ để thử lại.';
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(text)),
                    );
                  },
            icon: isWorking
                ? const SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.refresh_rounded),
            label: const Text('Thử đồng bộ lại'),
          ),
          const SizedBox(height: AppSpacing.sm),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Đóng'),
          ),
        ],
      ),
    );
  }
}

class _ReferralCodeSettingsEntry extends StatelessWidget {
  const _ReferralCodeSettingsEntry();

  @override
  Widget build(BuildContext context) {
    return _MenuItem(
      icon: Icons.confirmation_number_rounded,
      title: 'Nhap ma gioi thieu',
      subtitle: 'Ma gioi thieu chi duoc nhap trong luc dang ky tai khoan moi.',
      onTap: () => showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        builder: (_) => const _ReferralCodeSheet(),
      ),
    );
  }
}

class _ReferralCodeSheet extends ConsumerStatefulWidget {
  const _ReferralCodeSheet();

  @override
  ConsumerState<_ReferralCodeSheet> createState() => _ReferralCodeSheetState();
}

class _ReferralCodeSheetState extends ConsumerState<_ReferralCodeSheet> {
  final _formKey = GlobalKey<FormState>();
  final _controller = TextEditingController();
  final _validator = const SaleReferralCodeValidator();
  final bool _submitting = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.lg,
        bottomInset + AppSpacing.lg,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Nhap ma gioi thieu', style: AppTextStyles.heading3),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Theo chinh sach Sale moi, ma gioi thieu chi duoc gan trong luc dang ky tai khoan. Tai khoan da tao khong the gan ma tu man hinh cai dat.',
              style: AppTextStyles.bodyMedium,
            ),
            const SizedBox(height: AppSpacing.lg),
            TextFormField(
              controller: _controller,
              textCapitalization: TextCapitalization.characters,
              decoration: const InputDecoration(
                labelText: 'Ma gioi thieu',
                prefixIcon: Icon(Icons.confirmation_number_rounded),
              ),
              validator: (value) => _validator.validate(value ?? ''),
            ),
            const SizedBox(height: AppSpacing.lg),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _submitting ? null : _submit,
                icon: _submitting
                    ? const SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.check_rounded),
                label: const Text('Gan ma gioi thieu'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final code = _validator.normalize(_controller.text);
    if (code.isEmpty || _submitting) return;

    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Ma gioi thieu chi duoc gan khi dang ky tai khoan moi.'),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final bool isLoading;

  const _Header({required this.isLoading});

  @override
  Widget build(BuildContext context) {
    return MedicalPageHero(
      eyebrow: 'CÀI ĐẶT & QUYỀN RIÊNG TƯ',
      title: 'Cài đặt',
      subtitle: isLoading
          ? 'Nabi đang mở lại các lựa chọn của bạn...'
          : 'Quản lý tài khoản, quyền riêng tư, đồng bộ và trải nghiệm ứng dụng tại một nơi.',
      icon: Icons.tune_rounded,
    );
  }
}

class _ProfileCard extends StatelessWidget {
  final DashboardEntity? dashboard;

  const _ProfileCard({required this.dashboard});

  @override
  Widget build(BuildContext context) {
    final fullName = _displayText(
      dashboard?.fullName,
      fallback: 'Chưa có hồ sơ',
    );
    final subtitle = dashboard == null
        ? 'Hoàn thành phần làm quen để Nabi ghi nhớ hồ sơ của bạn'
        : _subscriptionLabel(dashboard!.subscriptionTier);

    return MedicalSurfaceCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
      gradient: AppGradients.hero,
      borderColor: Colors.transparent,
      elevated: true,
      child: Row(
        children: [
          Container(
            height: 72,
            width: 72,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: .18),
              borderRadius: BorderRadius.circular(AppRadius.circular),
            ),
            child: const Icon(
              Icons.person_rounded,
              color: Colors.white,
              size: 36,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  fullName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.heading3.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  subtitle,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: Colors.white.withValues(alpha: .9),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.sm,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: .16),
                    borderRadius: BorderRadius.circular(AppRadius.circular),
                  ),
                  child: Text(
                    dashboard == null
                        ? 'Nabi đang chờ hồ sơ'
                        : 'Nabi đã ghi nhớ hồ sơ này',
                    style: AppTextStyles.labelMedium.copyWith(
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Icon(
            Icons.arrow_forward_ios_rounded,
            color: Colors.white70,
            size: 18,
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;

  const _SectionTitle(this.title);

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: AppTextStyles.heading3.copyWith(fontWeight: FontWeight.w700),
    );
  }
}

class _MenuCard extends StatelessWidget {
  final List<Widget> children;

  const _MenuCard({required this.children});

  @override
  Widget build(BuildContext context) {
    return MedicalSurfaceCard(
      padding: EdgeInsets.zero,
      elevated: true,
      child: Column(children: children),
    );
  }
}

class _MenuItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;

  const _MenuItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(AppRadius.xl),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          children: [
            MedicalIconBadge(
              icon: icon,
              color: AppColors.primaryDark,
              backgroundColor: AppColors.primarySoft,
              size: 48,
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTextStyles.labelLarge.copyWith(fontSize: 15),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: AppTextStyles.bodySmall.copyWith(height: 1.5),
                  ),
                ],
              ),
            ),
            trailing ??
                const Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 18,
                  color: AppColors.textHint,
                ),
          ],
        ),
      ),
    );
  }
}

class _DangerCard extends StatelessWidget {
  final String? email;
  final VoidCallback onLogout;
  final VoidCallback onDeleteAccount;

  const _DangerCard({
    required this.email,
    required this.onLogout,
    required this.onDeleteAccount,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: AppDecoration.card(
        radius: AppRadius.xxl,
        shadows: AppShadows.sm,
      ),
      child: Column(
        children: [
          Container(
            height: 72,
            width: 72,
            decoration: BoxDecoration(
              color: AppColors.errorSoft,
              borderRadius: BorderRadius.circular(AppRadius.circular),
            ),
            child: const Icon(
              Icons.logout_rounded,
              color: AppColors.error,
              size: 34,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Đăng xuất',
            style: AppTextStyles.heading3.copyWith(color: AppColors.error),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            email == null
                ? 'Nabi chưa thấy email tài khoản để hiển thị.'
                : 'Tài khoản hiện tại: $email',
            textAlign: TextAlign.center,
            style: AppTextStyles.bodyMedium,
          ),
          const SizedBox(height: AppSpacing.lg),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error,
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                ),
              ),
              onPressed: onLogout,
              child: const Text('Đăng xuất'),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          TextButton.icon(
            onPressed: onDeleteAccount,
            icon: const Icon(Icons.delete_forever_rounded),
            label: const Text('Yêu cầu xóa tài khoản'),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
          ),
        ],
      ),
    );
  }
}

class _DividerLine extends StatelessWidget {
  const _DividerLine();

  @override
  Widget build(BuildContext context) {
    return const Divider(height: 1, thickness: 1, color: AppColors.borderLight);
  }
}

String _displayText(String? value, {required String fallback}) {
  final text = value?.trim() ?? '';
  return text.isEmpty ? fallback : text;
}

String _profileSubtitle(DashboardEntity dashboard) {
  final items = [
    if (dashboard.email.trim().isNotEmpty) dashboard.email.trim(),
    if (dashboard.phone.trim().isNotEmpty) dashboard.phone.trim(),
  ];
  return items.isEmpty ? 'Nabi đã ghi nhớ hồ sơ của bạn' : items.join(' • ');
}

String _goalsSubtitle(List<String> goals) {
  if (goals.isEmpty) return 'Nabi chưa thấy mục tiêu nào được chọn';
  if (goals.length == 1) return goals.single;
  return '${goals.length} mục tiêu đang hoạt động';
}

String _subscriptionLabel(String value) {
  final normalized = value.trim().toLowerCase();
  if (normalized.isEmpty || normalized == 'free') return 'Gói Free';
  if (normalized == 'premium') return 'Gói Premium';
  if (normalized == 'pro') return 'Gói Pro';
  return 'Gói ${value.trim()}';
}

String _languageLabel(String code) {
  switch (code) {
    case 'en':
      return 'English';
    case 'vi':
      return 'Tiếng Việt';
    default:
      return code.isEmpty ? '--' : code;
  }
}

String _aiPersonalityLabel(String value) {
  switch (value) {
    case 'professional':
      return 'Chuyên nghiệp';
    case 'motivational':
      return 'Động viên';
    case 'friendly':
      return 'Thân thiện';
    default:
      return value.isEmpty ? '--' : value;
  }
}

String _privacyModeLabel(String value) {
  switch (value) {
    case 'cloud':
      return 'Ưu tiên đồng bộ cloud';
    case 'local':
      return 'Chỉ lưu trên thiết bị';
    default:
      return value.isEmpty ? '--' : value;
  }
}

String _formatBytes(int bytes) {
  if (bytes <= 0) return '0 B';
  const units = ['B', 'KB', 'MB', 'GB'];
  var value = bytes.toDouble();
  var unitIndex = 0;
  while (value >= 1024 && unitIndex < units.length - 1) {
    value /= 1024;
    unitIndex++;
  }
  return '${value.toStringAsFixed(unitIndex == 0 ? 0 : 1)} ${units[unitIndex]}';
}
