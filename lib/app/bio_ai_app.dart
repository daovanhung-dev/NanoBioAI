import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nano_app/app/app_surface_controller.dart';
import 'package:nano_app/app_versions/admin/app/bio_ai_admin_app.dart';
import 'package:nano_app/app_versions/admin/features/admin_panel/providers/admin_providers.dart';
import 'package:nano_app/app_versions/v1/features/settings/providers/settings_provider.dart';
import 'package:nano_app/app_versions/v2/app/bio_ai_v2_app.dart';
import 'package:nano_app/app_versions/v2/features/auth/providers/auth_providers.dart';
import 'package:nano_app/core/theme/theme.dart';
import 'package:nano_app/core/theme/app_text_scale.dart';

class BioAIApp extends ConsumerWidget {
  const BioAIApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
    });

    // Root surface identity follows the resolved AuthController state instead
    // of the timing of Supabase.onAuthStateChange. During the first release
    // login, keep a neutral resolving surface while AuthController finalizes
    // the authenticated route rather than remounting the login app.
    if (ref.watch(authBackendAvailabilityProvider).isReady &&
        authState.isLoading &&
        authState.value == null) {
      return _AccessResolvingApp(
        key: const ValueKey('auth-identity-resolving'),
        preferences: experiencePreferences,
        themeMode: themeMode,
        textScaleFactor:
            ref.watch(appTextScaleControllerProvider).value?.preset.factor ??
            AppTextScalePreset.standard.factor,
      );
    }

    if (currentUserId == null) {
      return const BioAIV2App(key: ValueKey('user-app'));
    }

    final adminAccess = ref.watch(adminAccessControllerProvider);
    if (adminAccess.isLoading) {
      return _AccessResolvingApp(
        preferences: experiencePreferences,
        themeMode: themeMode,
        textScaleFactor:
            ref.watch(appTextScaleControllerProvider).value?.preset.factor ??
            AppTextScalePreset.standard.factor,
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

    if (resolvedSurface == AppSurface.admin) {
      return const BioAIAdminApp(key: ValueKey('admin-app'));
    }

    return const BioAIV2App(key: ValueKey('user-app'));
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
