import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app_versions/admin/app/bio_ai_admin_app.dart';
import 'app_versions/admin/features/admin_panel/providers/admin_providers.dart';
import 'core/config/app_env.dart';
import 'core/config/auth_backend_availability.dart';

const _bootstrapTag = 'ADMIN_BOOTSTRAP';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppEnv.loadOptionalDotEnv();

  final availability = await initializeAuthBackendAvailability(
    config: AppEnv.maybeSupabaseConfig(),
    initialize: (url, anonKey) async {
      await Supabase.initialize(
        url: url,
        anonKey: anonKey,
        authOptions: FlutterAuthClientOptions(
          detectSessionInUri: false,
          localStorage: SharedPreferencesLocalStorage(
            persistSessionKey: 'nanobio_admin_auth_session',
          ),
        ),
      );
    },
    onInitializationError: (error, stackTrace) {
      debugPrint('$_bootstrapTag: initialization failed');
      debugPrintStack(stackTrace: stackTrace);
    },
  );

  runApp(
    ProviderScope(
      overrides: [
        adminBackendAvailabilityProvider.overrideWithValue(availability),
      ],
      child: const BioAIAdminApp(),
    ),
  );
}
