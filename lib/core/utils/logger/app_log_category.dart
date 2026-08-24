enum AppLogCategory {
  app,
  ui,
  navigation,
  logic,
  database,
  http,
  supabase,
  auth,
  ai,
  notification,
  storage,
  performance;

  String get label => switch (this) {
    AppLogCategory.app => 'APP',
    AppLogCategory.ui => 'UI',
    AppLogCategory.navigation => 'NAV',
    AppLogCategory.logic => 'LOGIC',
    AppLogCategory.database => 'DB',
    AppLogCategory.http => 'HTTP',
    AppLogCategory.supabase => 'SUPABASE',
    AppLogCategory.auth => 'AUTH',
    AppLogCategory.ai => 'AI',
    AppLogCategory.notification => 'NOTIFICATION',
    AppLogCategory.storage => 'STORAGE',
    AppLogCategory.performance => 'PERFORMANCE',
  };
}
