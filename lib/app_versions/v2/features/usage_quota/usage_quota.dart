import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nano_app/services/supabase/usage_quota/usage_quota_gateway.dart';

export 'package:nano_app/services/supabase/usage_quota/usage_quota_gateway.dart'
    show
        TrustedBackendUsageQuotaGateway,
        UsageQuotaAuthRequiredException,
        UsageQuotaDecision,
        UsageQuotaExceededException,
        UsageQuotaException,
        UsageQuotaFeatureKey,
        UsageQuotaGateway,
        UsageQuotaUnavailableException;

final trustedBackendUsageQuotaGatewayProvider =
    Provider<TrustedBackendUsageQuotaGateway>((ref) {
      return const TrustedBackendUsageQuotaGateway();
    });

class V2UsageQuotaFeature {
  const V2UsageQuotaFeature._();

  static const status = 'runtime_contract';
  static const accessLayer = 'v2/free-authenticated';
  static const resetTimezone = TrustedBackendUsageQuotaGateway.resetTimezone;

  static const responsibilities = <String>[
    'Track Free AI chat usage with a daily limit of 3 questions.',
    'Track Free personal schedule generation with a monthly limit of 3 runs.',
    'Block quota-limited use cases before calling AI services.',
    'Keep quota reads and writes behind trusted Supabase RPC contracts.',
  ];
}
