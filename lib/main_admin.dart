import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app_versions/admin/app/bio_ai_admin_app.dart';
import 'core/config/app_env.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await AppEnv.loadOptionalDotEnv();

  await Supabase.initialize(
    url: AppEnv.requiredString('SUPABASE_URL'),
    anonKey: AppEnv.requiredString('SUPABASE_ANON_KEY'),
  );

  runApp(const ProviderScope(child: BioAIAdminApp()));
}
