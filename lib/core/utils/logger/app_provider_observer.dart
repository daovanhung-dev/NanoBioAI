import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app_log_category.dart';
import 'app_logger.dart';

final class AppProviderObserver extends ProviderObserver {
  const AppProviderObserver();

  @override
  void providerDidFail(
    ProviderObserverContext context,
    Object error,
    StackTrace stackTrace,
  ) {
    AppLogger.captureError(
      category: AppLogCategory.logic,
      scope: 'Riverpod',
      operation: 'PROVIDER_FAILED',
      message: 'Provider failed',
      error: error,
      stackTrace: stackTrace,
      metadata: {'provider': context.provider.toString()},
    );
  }
}
