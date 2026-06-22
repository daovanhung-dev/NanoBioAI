import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

enum SaleStatus { none, pending, active, suspended, closed }

class SaleState {
  final SaleStatus status;
  final String? referralCode;
  final String? termsVersion;
  final DateTime? approvedAt;
  final String? note;

  const SaleState({
    required this.status,
    this.referralCode,
    this.termsVersion,
    this.approvedAt,
    this.note,
  });

  static const none = SaleState(status: SaleStatus.none);

  bool get isActive => status == SaleStatus.active;

  factory SaleState.fromMap(Map<String, Object?> map) {
    return SaleState(
      status: _statusFromString(map['sale_status'] ?? map['status']),
      referralCode: _readString(map['referral_code']),
      termsVersion: _readString(map['terms_version']),
      approvedAt: _readDate(map['approved_at']),
      note: _readString(map['note']),
    );
  }
}

class SaleDashboardSummary {
  final int directReferrals;
  final int secondLevelReferrals;
  final int pendingCommissionCents;
  final int approvedCommissionCents;
  final int paidCommissionCents;
  final String currency;

  const SaleDashboardSummary({
    required this.directReferrals,
    required this.secondLevelReferrals,
    required this.pendingCommissionCents,
    required this.approvedCommissionCents,
    required this.paidCommissionCents,
    required this.currency,
  });

  factory SaleDashboardSummary.fromMap(Map<String, Object?> map) {
    return SaleDashboardSummary(
      directReferrals: _readInt(map['direct_referrals']),
      secondLevelReferrals: _readInt(map['second_level_referrals']),
      pendingCommissionCents: _readInt(map['pending_commission_cents']),
      approvedCommissionCents: _readInt(map['approved_commission_cents']),
      paidCommissionCents: _readInt(map['paid_commission_cents']),
      currency: _readString(map['currency']) ?? 'VND',
    );
  }
}

class SaleReferralNode {
  final int level;
  final String displayName;
  final DateTime? acceptedAt;
  final int successfulPayments;

  const SaleReferralNode({
    required this.level,
    required this.displayName,
    this.acceptedAt,
    required this.successfulPayments,
  });

  factory SaleReferralNode.fromMap(Map<String, Object?> map) {
    return SaleReferralNode(
      level: _readInt(map['level']),
      displayName: _readString(map['display_name']) ?? 'Người dùng Nami',
      acceptedAt: _readDate(map['accepted_at']),
      successfulPayments: _readInt(map['successful_payments']),
    );
  }
}

class SaleLeaderboardEntry {
  final int rank;
  final String displayName;
  final int directReferrals;
  final int approvedCommissionCents;
  final String currency;

  const SaleLeaderboardEntry({
    required this.rank,
    required this.displayName,
    required this.directReferrals,
    required this.approvedCommissionCents,
    required this.currency,
  });

  factory SaleLeaderboardEntry.fromMap(Map<String, Object?> map) {
    return SaleLeaderboardEntry(
      rank: _readInt(map['rank']),
      displayName: _readString(map['display_name']) ?? 'Sale Nami',
      directReferrals: _readInt(map['direct_referrals']),
      approvedCommissionCents: _readInt(map['approved_commission_cents']),
      currency: _readString(map['currency']) ?? 'VND',
    );
  }
}

class SaleParticipationService {
  final SupabaseClient? clientOverride;

  const SaleParticipationService({this.clientOverride});

  Future<SaleState> fetchState() async {
    final client = _client();
    if (client == null || client.auth.currentUser == null) {
      return SaleState.none;
    }

    final response = await client.rpc('get_my_sale_state');
    return SaleState.fromMap(_firstMap(response));
  }

  Future<SaleState> requestParticipation({required String termsVersion}) async {
    final client = _client();
    if (client == null || client.auth.currentUser == null) {
      throw const AuthException('Missing authenticated session.');
    }

    final response = await client.rpc(
      'request_sale_participation',
      params: {'p_terms_version': termsVersion},
    );
    return SaleState.fromMap(_firstMap(response));
  }

  Future<SaleDashboardSummary> fetchDashboard() async {
    final response = await _rpc('get_my_sale_dashboard');
    return SaleDashboardSummary.fromMap(_firstMap(response));
  }

  Future<List<SaleReferralNode>> fetchReferralTree() async {
    final response = await _rpc('get_my_sale_referral_tree');
    return _maps(response).map(SaleReferralNode.fromMap).toList();
  }

  Future<List<SaleLeaderboardEntry>> fetchLeaderboard() async {
    final response = await _rpc('get_sale_leaderboard');
    return _maps(response).map(SaleLeaderboardEntry.fromMap).toList();
  }

  Future<Object?> _rpc(String functionName) async {
    final client = _client();
    if (client == null || client.auth.currentUser == null) {
      throw const AuthException('Missing authenticated session.');
    }

    return client.rpc(functionName);
  }

  SupabaseClient? _client() {
    if (clientOverride != null) return clientOverride;
    try {
      return Supabase.instance.client;
    } on AssertionError {
      return null;
    }
  }
}

final saleParticipationServiceProvider = Provider<SaleParticipationService>((
  ref,
) {
  return const SaleParticipationService();
});

final saleStateProvider = FutureProvider<SaleState>((ref) {
  return ref.watch(saleParticipationServiceProvider).fetchState();
});

final saleDashboardProvider = FutureProvider<SaleDashboardSummary>((ref) async {
  final state = await ref.watch(saleStateProvider.future);
  if (!state.isActive) {
    throw StateError('Sale dashboard requires active status.');
  }
  return ref.watch(saleParticipationServiceProvider).fetchDashboard();
});

final saleReferralTreeProvider = FutureProvider<List<SaleReferralNode>>((
  ref,
) async {
  final state = await ref.watch(saleStateProvider.future);
  if (!state.isActive) throw StateError('Sale tree requires active status.');
  return ref.watch(saleParticipationServiceProvider).fetchReferralTree();
});

final saleLeaderboardProvider = FutureProvider<List<SaleLeaderboardEntry>>((
  ref,
) async {
  final state = await ref.watch(saleStateProvider.future);
  if (!state.isActive) {
    throw StateError('Sale leaderboard requires active status.');
  }
  return ref.watch(saleParticipationServiceProvider).fetchLeaderboard();
});

Map<String, Object?> _firstMap(Object? response) {
  if (response is Map) return _copyMap(response);
  if (response is List && response.isNotEmpty) {
    final first = response.first;
    if (first is Map) return _copyMap(first);
  }

  return const {};
}

List<Map<String, Object?>> _maps(Object? response) {
  if (response is! List) return const [];

  return response.whereType<Map>().map(_copyMap).toList(growable: false);
}

Map<String, Object?> _copyMap(Map<dynamic, dynamic> map) {
  return map.map((key, value) => MapEntry(key.toString(), value));
}

SaleStatus _statusFromString(Object? value) {
  switch (value?.toString().trim().toLowerCase()) {
    case 'pending':
      return SaleStatus.pending;
    case 'active':
      return SaleStatus.active;
    case 'suspended':
      return SaleStatus.suspended;
    case 'closed':
      return SaleStatus.closed;
    default:
      return SaleStatus.none;
  }
}

String? _readString(Object? value) {
  final text = value?.toString().trim();
  return text == null || text.isEmpty ? null : text;
}

int _readInt(Object? value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? 0;
}

DateTime? _readDate(Object? value) {
  final text = _readString(value);
  return text == null ? null : DateTime.tryParse(text);
}
