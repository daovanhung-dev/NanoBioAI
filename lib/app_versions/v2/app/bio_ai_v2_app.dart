import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nano_app/app_versions/v2/features/auth/application/auth_deep_link_coordinator.dart';
import 'package:nano_app/app_versions/v2/features/cloud_sync/cloud_sync.dart';
import 'package:nano_app/app_versions/v2/router/v2_router.dart';
import 'package:nano_app/core/theme/app_theme.dart';
import 'package:nano_app/core/theme/app_experience.dart';
import 'package:nano_app/services/supabase/cloud_sync/authenticated_sync_trigger_registry.dart';

class BioAIV2App extends ConsumerStatefulWidget {
  const BioAIV2App({super.key});

  @override
  ConsumerState<BioAIV2App> createState() => _BioAIV2AppState();
}

class _BioAIV2AppState extends ConsumerState<BioAIV2App> {
  final _deepLinkCoordinator = AuthDeepLinkCoordinator();
  bool _started = false;
  late final Future<void> Function(AuthSyncReason reason) _syncTrigger =
      _handleSyncTrigger;

  @override
  void initState() {
    super.initState();
    AuthenticatedSyncTriggerRegistry.register(_syncTrigger);
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(v2RouterProvider);
    if (!_started) {
      _started = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        unawaited(_deepLinkCoordinator.start(router));
        unawaited(_handleSyncTrigger(AuthSyncReason.startup));
      });
    }

    return MaterialApp.router(
      title: 'BioAI V2',
      debugShowCheckedModeBanner: false,
      builder: AppExperience.builder,
      theme: AppTheme.lightTheme,
      routerConfig: router,
    );
  }

  Future<void> _handleSyncTrigger(AuthSyncReason reason) async {
    await ref.read(userDataSyncControllerProvider.notifier).sync(reason);
  }

  @override
  void dispose() {
    AuthenticatedSyncTriggerRegistry.unregister(_syncTrigger);
    unawaited(_deepLinkCoordinator.stop());
    super.dispose();
  }
}
