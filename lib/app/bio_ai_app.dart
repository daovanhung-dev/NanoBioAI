import 'dart:async';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:nano_app/app/android_runtime_permission_coordinator.dart';
import 'package:nano_app/app/app_surface_controller.dart';
import 'package:nano_app/app_versions/admin/app/bio_ai_admin_app.dart';
import 'package:nano_app/app_versions/admin/features/admin_panel/providers/admin_providers.dart';
import 'package:nano_app/app_versions/v1/features/settings/providers/settings_provider.dart';
import 'package:nano_app/app_versions/v2/app/bio_ai_v2_app.dart';
import 'package:nano_app/app_versions/v2/features/auth/providers/auth_providers.dart';
import 'package:nano_app/app_versions/v2/features/membership_entitlement/providers/membership_entitlement_providers.dart';
import 'package:nano_app/core/health_events/health_domain_event.dart';
import 'package:nano_app/core/health_events/health_event_type.dart';
import 'package:nano_app/core/theme/app_text_scale.dart';
import 'package:nano_app/core/theme/theme.dart';
import 'package:nano_app/core/config/app_env.dart';
import 'package:nano_app/services/health_orchestration/health_domain_event_sink.dart';

class BioAIApp extends ConsumerStatefulWidget {
  const BioAIApp({super.key});

  @override
  ConsumerState<BioAIApp> createState() => _BioAIAppState();
}

class _BioAIAppState extends ConsumerState<BioAIApp>
    with WidgetsBindingObserver {
  Set<AndroidRuntimePermission> _permanentlyDenied = const {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) unawaited(_checkRuntimePermissions());
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      ref.invalidate(effectiveAccessProvider);
      unawaited(_checkRuntimePermissions());
    }
  }

  Future<void> _checkRuntimePermissions() async {
    final denied = await ref
        .read(androidRuntimePermissionCoordinatorProvider)
        .checkAndRequestMissing();
    if (!mounted ||
        denied.length == _permanentlyDenied.length &&
            denied.containsAll(_permanentlyDenied)) {
      return;
    }
    setState(() => _permanentlyDenied = denied);
  }

  Future<void> _openPermissionSettings() async {
    await ref
        .read(androidRuntimePermissionCoordinatorProvider)
        .openAppSettings();
  }

  @override
  Widget build(BuildContext context) {
    if (kIsWeb && _isAdminRoute(Uri.base.path)) {
      return const _WebAdminRouteApp();
    }
    final authState = ref.watch(v2AuthControllerProvider);
    final currentUserId = ref.watch(currentAuthUserIdProvider);
    final requestedSurface = ref.watch(appSurfaceControllerProvider);
    final experiencePreferences =
        ref.watch(appExperiencePreferencesProvider).value ??
        AppExperiencePreferences.defaults;
    final themeMode =
        ref.watch(settingsPreferencesControllerProvider).value?.isDarkMode ==
            true
        ? ThemeMode.dark
        : ThemeMode.light;

    ref.listen<String?>(currentAuthUserIdProvider, (previous, next) {
      if (previous != null && next == null) {
        ref.read(appSurfaceControllerProvider.notifier).reset();
      }
      final nextSubject = next?.trim();
      if (nextSubject != null &&
          nextSubject.isNotEmpty &&
          nextSubject != previous?.trim()) {
        unawaited(_publishIdentityChanged(ref, nextSubject));
      }
    });

    // Root surface identity follows the resolved AuthController state instead
    // of backend auth-state timing. During the first release
    // login, keep a neutral resolving surface while AuthController finalizes
    // the authenticated route rather than remounting the login app.
    if (ref.watch(authBackendAvailabilityProvider).isReady &&
        authState.isLoading &&
        authState.value == null) {
      return _withPermissionNotice(
        _AccessResolvingApp(
          key: const ValueKey('auth-identity-resolving'),
          preferences: experiencePreferences,
          themeMode: themeMode,
          textScaleFactor:
              ref.watch(appTextScaleControllerProvider).value?.preset.factor ??
              AppTextScalePreset.standard.factor,
        ),
        themeMode,
      );
    }

    if (currentUserId == null) {
      return _withPermissionNotice(
        const BioAIV2App(key: ValueKey('user-app')),
        themeMode,
      );
    }

    final adminAccess = ref.watch(adminAccessControllerProvider);
    if (adminAccess.isLoading) {
      return _withPermissionNotice(
        _AccessResolvingApp(
          preferences: experiencePreferences,
          themeMode: themeMode,
          textScaleFactor:
              ref.watch(appTextScaleControllerProvider).value?.preset.factor ??
              AppTextScalePreset.standard.factor,
        ),
        themeMode,
      );
    }

    final access = adminAccess.asData?.value;
    final session = access?.session;
    final resolvedSurface = resolveAppSurface(
      isSignedIn: true,
      isAuthorizedAdmin: access?.isAuthorized == true && session != null,
      canUseUserApp: session?.canUseUserApp ?? true,
      requestedSurface: requestedSurface,
    );

    if (resolvedSurface == AppSurface.admin &&
        (!kIsWeb || session?.canUseUserApp != true)) {
      if (kIsWeb) return const _WebAdminRouteApp();
      return _withPermissionNotice(
        const BioAIAdminApp(key: ValueKey('admin-app')),
        themeMode,
      );
    }

    return _withPermissionNotice(
      const BioAIV2App(key: ValueKey('user-app')),
      themeMode,
    );
  }

  bool _isAdminRoute(String path) => path == '/admin' || path == '/admin/';

  Widget _withPermissionNotice(Widget app, ThemeMode themeMode) {
    return Stack(
      fit: StackFit.expand,
      textDirection: TextDirection.ltr,
      children: [
        app,
        if (_permanentlyDenied.isNotEmpty)
          _AndroidPermissionSettingsNotice(
            permissions: _permanentlyDenied,
            themeMode: themeMode,
            onOpenSettings: _openPermissionSettings,
            onDismiss: () => setState(() => _permanentlyDenied = const {}),
          ),
      ],
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  Future<void> _publishIdentityChanged(WidgetRef ref, String subjectId) async {
    try {
      await ref
          .read(healthDomainEventSinkProvider)
          .publish(
            HealthDomainEvent.create(
              type: HealthEventType.authIdentityChanged,
              subjectId: subjectId,
              sourceFeature: 'app.auth_identity',
              changedFields: const {'active_subject'},
            ),
          );
    } catch (_) {
      // Identity resolution itself is authoritative. Refresh orchestration must
      // never block mounting the authenticated application surface.
    }
  }
}

class _WebAdminRouteApp extends StatefulWidget {
  const _WebAdminRouteApp();

  @override
  State<_WebAdminRouteApp> createState() => _WebAdminRouteAppState();
}

class _WebAdminRouteAppState extends State<_WebAdminRouteApp> {
  String? _launchError;

  Uri? get _adminUri {
    final rawValue = AppEnv.maybeString('ADMIN_WEB_URL');
    if (rawValue == null) return null;
    final uri = Uri.tryParse(rawValue);
    if (uri == null ||
        !uri.hasAuthority ||
        uri.userInfo.isNotEmpty ||
        uri.scheme != 'https') {
      return null;
    }
    return uri;
  }

  Future<void> _openAdmin() async {
    final uri = _adminUri;
    if (uri == null) return;
    final opened = await launchUrl(uri, mode: LaunchMode.platformDefault);
    if (opened || !mounted) return;
    setState(
      () => _launchError = 'Chưa mở được cổng quản trị. Bạn thử lại nhé.',
    );
  }

  Future<void> _openUserApp() async {
    final userAppUri = Uri.base.replace(path: '/', query: null, fragment: null);
    await launchUrl(userAppUri, mode: LaunchMode.platformDefault);
  }

  @override
  Widget build(BuildContext context) {
    final uri = _adminUri;
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'NanoBio - Quản trị',
      theme: AppTheme.lightTheme,
      home: Scaffold(
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.admin_panel_settings_outlined, size: 48),
                    const SizedBox(height: 16),
                    Text(
                      'Cổng quản trị NanoBio',
                      style: AppTextStyles.heading2,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      uri == null
                          ? 'Cổng quản trị chưa được cấu hình cho trang web này.'
                          : 'Khu vực quản trị được mở tại trang riêng.',
                      textAlign: TextAlign.center,
                      style: AppTextStyles.bodyMedium,
                    ),
                    if (_launchError case final message?) ...[
                      const SizedBox(height: 8),
                      Text(message, textAlign: TextAlign.center),
                    ],
                    const SizedBox(height: 20),
                    if (uri != null)
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          onPressed: _openAdmin,
                          icon: const Icon(Icons.open_in_new_rounded),
                          label: const Text('Mở cổng quản trị'),
                        ),
                      ),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: _openUserApp,
                      child: const Text('Về ứng dụng NanoBio'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AndroidPermissionSettingsNotice extends StatelessWidget {
  const _AndroidPermissionSettingsNotice({
    required this.permissions,
    required this.themeMode,
    required this.onOpenSettings,
    required this.onDismiss,
  });

  final Set<AndroidRuntimePermission> permissions;
  final ThemeMode themeMode;
  final VoidCallback onOpenSettings;
  final VoidCallback onDismiss;

  static const _labels = <AndroidRuntimePermission, String>{
    AndroidRuntimePermission.callPhone: 'gọi điện',
    AndroidRuntimePermission.microphone: 'micro',
    AndroidRuntimePermission.notifications: 'thông báo',
    AndroidRuntimePermission.camera: 'máy ảnh',
  };

  @override
  Widget build(BuildContext context) {
    final missingLabels = AndroidRuntimePermissionCoordinator.requestOrder
        .where(permissions.contains)
        .map((permission) => _labels[permission]!)
        .toList(growable: false);
    final view = View.of(context);
    final noticeTheme = themeMode == ThemeMode.dark
        ? AppTheme.darkTheme
        : AppTheme.lightTheme;

    return Positioned.fill(
      child: MediaQuery(
        data: MediaQueryData.fromView(view),
        child: SafeArea(
          child: Align(
            alignment: Alignment.topCenter,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Theme(
                data: noticeTheme,
                child: Directionality(
                  textDirection: TextDirection.ltr,
                  child: Material(
                    elevation: 8,
                    borderRadius: BorderRadius.circular(16),
                    clipBehavior: Clip.antiAlias,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 560),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Một số quyền đang tắt',
                              style: noticeTheme.textTheme.titleMedium,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Bạn có thể bật quyền '
                              '${missingLabels.join(', ')} trong Cài đặt '
                              'để Nabi hoạt động đầy đủ.',
                            ),
                            const SizedBox(height: 12),
                            Wrap(
                              spacing: 8,
                              runSpacing: 4,
                              children: [
                                FilledButton.icon(
                                  onPressed: onOpenSettings,
                                  icon: const Icon(Icons.settings_outlined),
                                  label: const Text('Mở Cài đặt'),
                                ),
                                TextButton(
                                  onPressed: onDismiss,
                                  child: const Text('Để sau'),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
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

class _AccessResolvingApp extends StatelessWidget {
  const _AccessResolvingApp({
    super.key,
    required this.textScaleFactor,
    required this.preferences,
    required this.themeMode,
  });

  final double textScaleFactor;
  final AppExperiencePreferences preferences;
  final ThemeMode themeMode;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      builder: (context, child) => AppExperience.builderWithTextScale(
        context,
        child,
        presetFactor: textScaleFactor,
        preferences: preferences,
      ),
      home: const MedicalPageScaffold(
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: AppSpacing.md),
              Text('Nabi đang chuẩn bị không gian phù hợp với tài khoản...'),
            ],
          ),
        ),
      ),
    );
  }
}
