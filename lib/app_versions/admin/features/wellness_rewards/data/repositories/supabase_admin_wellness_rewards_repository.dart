import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/entities/admin_wellness_reward_models.dart';
import '../../domain/repositories/admin_wellness_rewards_repository.dart';
import '../datasources/admin_wellness_rewards_remote_datasource.dart';

class SupabaseAdminWellnessRewardsRepository
    implements AdminWellnessRewardsRepository {
  final AdminWellnessRewardsRemoteDatasource datasource;

  const SupabaseAdminWellnessRewardsRepository({required this.datasource});

  @override
  Future<AdminWellnessRewardsSnapshot> load({String query = ''}) async {
    try {
      final response = await datasource.list(query: query);
      final rows = _rows(response);
      final offers = <AdminWellnessRewardOffer>[];
      final redemptions = <AdminWellnessRewardRedemption>[];
      for (final row in rows) {
        final type = row['item_type']?.toString().trim().toLowerCase();
        if (type == 'offer') {
          offers.add(AdminWellnessRewardOffer.fromMap(row));
        } else if (type == 'redemption') {
          redemptions.add(AdminWellnessRewardRedemption.fromMap(row));
        }
      }
      return AdminWellnessRewardsSnapshot(
        offers: offers.where((item) => item.id.isNotEmpty).toList(),
        redemptions: redemptions.where((item) => item.id.isNotEmpty).toList(),
      );
    } on AuthException {
      throw const AdminWellnessRewardException(
        'Phiên quản trị đã hết hạn. Hãy đăng nhập lại.',
      );
    } on PostgrestException catch (error) {
      throw _safeError(error);
    } catch (_) {
      throw const AdminWellnessRewardException(
        'Chưa tải được dữ liệu ưu đãi. Hãy thử lại.',
      );
    }
  }

  @override
  Future<AdminRewardMutationResult> upsertOffer(
    AdminRewardOfferCommand command,
  ) {
    return _mutate(() => datasource.upsertOffer(command));
  }

  @override
  Future<AdminRewardMutationResult> importCodes(
    AdminRewardCodeImportCommand command,
  ) {
    return _mutate(() => datasource.importCodes(command));
  }

  @override
  Future<AdminRewardMutationResult> cancelRedemption({
    required String redemptionId,
    required String reason,
    required String idempotencyKey,
  }) {
    return _mutate(
      () => datasource.cancelRedemption(
        redemptionId: redemptionId,
        reason: reason,
        idempotencyKey: idempotencyKey,
      ),
    );
  }

  Future<AdminRewardMutationResult> _mutate(
    Future<Object?> Function() operation,
  ) async {
    try {
      final response = await operation();
      final result = AdminRewardMutationResult.fromMap(_firstMap(response));
      if (!result.success) {
        throw const AdminWellnessRewardException(
          'Yêu cầu chưa được xử lý. Hãy kiểm tra dữ liệu và thử lại.',
        );
      }
      return result;
    } on AdminWellnessRewardException {
      rethrow;
    } on AuthException {
      throw const AdminWellnessRewardException(
        'Phiên quản trị đã hết hạn. Hãy đăng nhập lại.',
      );
    } on PostgrestException catch (error) {
      throw _safeError(error);
    } catch (_) {
      throw const AdminWellnessRewardException(
        'Chưa cập nhật được dữ liệu ưu đãi. Hãy thử lại.',
      );
    }
  }
}

AdminWellnessRewardException _safeError(PostgrestException error) {
  final message = error.message.toLowerCase();
  if (message.contains('permission') || message.contains('forbidden')) {
    return const AdminWellnessRewardException(
      'Tài khoản chưa có quyền quản lý Điểm chăm sóc.',
    );
  }
  if (message.contains('invalid_vietnamese_copy')) {
    return const AdminWellnessRewardException(
      'Tên và mô tả ưu đãi phải là tiếng Việt có dấu.',
    );
  }
  if (message.contains('voucher_code_conflict')) {
    return const AdminWellnessRewardException(
      'Kho mã có dữ liệu trùng hoặc không hợp lệ.',
    );
  }
  if (message.contains('voucher_codes_count_invalid') ||
      message.contains('voucher_expiry_invalid') ||
      message.contains('voucher_expiry_required')) {
    return const AdminWellnessRewardException(
      'Danh sách mã hoặc hạn dùng voucher chưa hợp lệ.',
    );
  }
  if (message.contains('eligible_plans_invalid') ||
      message.contains('offer_window_invalid') ||
      message.contains('reward_cost_invalid') ||
      message.contains('provider_name_required') ||
      message.contains('admin_reason_required')) {
    return const AdminWellnessRewardException(
      'Thông tin ưu đãi chưa hợp lệ. Bạn vui lòng kiểm tra lại.',
    );
  }
  if (message.contains('redemption_not_found') ||
      message.contains('redemption_required')) {
    return const AdminWellnessRewardException(
      'Không tìm thấy giao dịch cần xử lý.',
    );
  }
  if (message.contains('external_revocation_confirmation_required')) {
    return const AdminWellnessRewardException(
      'Bạn cần xác nhận mã đã được xử lý bên ngoài trước khi hủy.',
    );
  }
  if (message.contains('reward_cannot_be_undone')) {
    return const AdminWellnessRewardException(
      'Giao dịch này không còn đủ điều kiện để hủy.',
    );
  }
  if (message.contains('idempotency_conflict')) {
    return const AdminWellnessRewardException(
      'Yêu cầu đã thay đổi. Hãy tải lại dữ liệu trước khi thử lại.',
    );
  }
  return const AdminWellnessRewardException(
    'Hệ thống chưa xử lý được yêu cầu quản trị. Hãy thử lại.',
  );
}

List<Map<String, Object?>> _rows(Object? response) {
  if (response is Map) {
    final offers = response['offers'];
    final redemptions = response['redemptions'];
    return <Map<String, Object?>>[
      if (offers is List)
        ...offers.whereType<Map>().map(
          (row) => {'item_type': 'offer', ..._copy(row)},
        ),
      if (redemptions is List)
        ...redemptions.whereType<Map>().map(
          (row) => {'item_type': 'redemption', ..._copy(row)},
        ),
    ];
  }
  if (response is! List) return const [];
  return response.whereType<Map>().map(_copy).toList(growable: false);
}

Map<String, Object?> _firstMap(Object? response) {
  if (response is Map) return _copy(response);
  if (response is List && response.isNotEmpty && response.first is Map) {
    return _copy(response.first as Map);
  }
  return const {};
}

Map<String, Object?> _copy(Map<dynamic, dynamic> map) {
  return map.map((key, value) => MapEntry(key.toString(), value));
}
