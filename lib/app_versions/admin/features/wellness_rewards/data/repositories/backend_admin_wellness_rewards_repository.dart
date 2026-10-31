import 'package:nano_app/core/network/backend_api_client.dart';

import '../../domain/entities/admin_wellness_reward_models.dart';
import '../../domain/repositories/admin_wellness_rewards_repository.dart';
import '../datasources/backend_admin_wellness_rewards_remote_datasource.dart';

class BackendAdminWellnessRewardsRepository
    implements AdminWellnessRewardsRepository {
  final BackendAdminWellnessRewardsRemoteDatasource datasource;

  const BackendAdminWellnessRewardsRepository({required this.datasource});

  @override
  Future<AdminWellnessRewardsSnapshot> load({String query = ''}) async {
    try {
      final rows = _rows(await datasource.list(query: query));
      final offers = <AdminWellnessRewardOffer>[];
      final redemptions = <AdminWellnessRewardRedemption>[];
      for (final row in rows) {
        switch (row['item_type']?.toString().trim().toLowerCase()) {
          case 'offer':
            offers.add(AdminWellnessRewardOffer.fromMap(row));
            break;
          case 'redemption':
            redemptions.add(AdminWellnessRewardRedemption.fromMap(row));
            break;
        }
      }
      return AdminWellnessRewardsSnapshot(
        offers: offers.where((item) => item.id.isNotEmpty).toList(),
        redemptions: redemptions.where((item) => item.id.isNotEmpty).toList(),
      );
    } on BackendApiException catch (error) {
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
  ) => _mutate(() => datasource.upsertOffer(command));

  @override
  Future<AdminRewardMutationResult> importCodes(
    AdminRewardCodeImportCommand command,
  ) => _mutate(() => datasource.importCodes(command));

  @override
  Future<AdminRewardMutationResult> cancelRedemption({
    required String redemptionId,
    required String reason,
    required String idempotencyKey,
  }) => _mutate(
    () => datasource.cancelRedemption(
      redemptionId: redemptionId,
      reason: reason,
      idempotencyKey: idempotencyKey,
    ),
  );

  @override
  Future<AdminRewardMutationResult> markRedemptionReceived({
    required String redemptionId,
    required String reason,
    required String idempotencyKey,
  }) => _mutate(
    () => datasource.markRedemptionReceived(
      redemptionId: redemptionId,
      reason: reason,
      idempotencyKey: idempotencyKey,
    ),
  );

  Future<AdminRewardMutationResult> _mutate(
    Future<Object?> Function() operation,
  ) async {
    try {
      final response = AdminRewardMutationResult.fromMap(
        _firstMap(await operation()),
      );
      if (!response.success) {
        throw const AdminWellnessRewardException(
          'Yêu cầu chưa được xử lý. Hãy kiểm tra dữ liệu và thử lại.',
        );
      }
      return response;
    } on AdminWellnessRewardException {
      rethrow;
    } on BackendApiException catch (error) {
      throw _safeError(error);
    } catch (_) {
      throw const AdminWellnessRewardException(
        'Chưa cập nhật được dữ liệu ưu đãi. Hãy thử lại.',
      );
    }
  }
}

AdminWellnessRewardException _safeError(BackendApiException error) {
  final message = '${error.businessCode} ${error.message}'.toLowerCase();
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
  if (message.contains('voucher_code') || message.contains('reward_codes')) {
    return const AdminWellnessRewardException(
      'Kho mã có dữ liệu trùng hoặc không hợp lệ.',
    );
  }
  if (message.contains('expiry') || message.contains('offer_window')) {
    return const AdminWellnessRewardException(
      'Danh sách mã hoặc hạn dùng ưu đãi chưa hợp lệ.',
    );
  }
  if (message.contains('redemption_not_found') ||
      message.contains('redemption_required')) {
    return const AdminWellnessRewardException(
      'Không tìm thấy giao dịch cần xử lý.',
    );
  }
  if (message.contains('revocation_confirmation_required')) {
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
  if (error.statusCode == 401) {
    return const AdminWellnessRewardException(
      'Phiên quản trị đã hết hạn. Hãy đăng nhập lại.',
    );
  }
  return const AdminWellnessRewardException(
    'Hệ thống chưa xử lý được yêu cầu quản trị. Hãy thử lại.',
  );
}

List<Map<String, Object?>> _rows(Object? response) {
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

Map<String, Object?> _copy(Map<dynamic, dynamic> map) =>
    map.map((key, value) => MapEntry(key.toString(), value));
