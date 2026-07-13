import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../domain/entities/admin_wellness_reward_models.dart';

abstract class AdminWellnessSecureKeyValueStore {
  Future<String?> read(String key);

  Future<void> write(String key, String value);

  Future<void> delete(String key);
}

class FlutterAdminWellnessSecureKeyValueStore
    implements AdminWellnessSecureKeyValueStore {
  final FlutterSecureStorage storage;

  const FlutterAdminWellnessSecureKeyValueStore({
    this.storage = const FlutterSecureStorage(),
  });

  @override
  Future<String?> read(String key) => storage.read(key: key);

  @override
  Future<void> write(String key, String value) {
    return storage.write(key: key, value: value);
  }

  @override
  Future<void> delete(String key) => storage.delete(key: key);
}

abstract class AdminWellnessMutationIdempotencyStore {
  Future<String> acquire({
    required String userId,
    required String operation,
    required String fingerprint,
  });

  Future<void> markSucceeded({
    required String userId,
    required String operation,
    required String fingerprint,
    required String idempotencyKey,
  });
}

class OsAdminWellnessMutationIdempotencyStore
    implements AdminWellnessMutationIdempotencyStore {
  final AdminWellnessSecureKeyValueStore storage;
  final String Function(String operation) keyFactory;

  OsAdminWellnessMutationIdempotencyStore({
    this.storage = const FlutterAdminWellnessSecureKeyValueStore(),
    String Function(String operation)? keyFactory,
  }) : keyFactory = keyFactory ?? _newIdempotencyKey;

  static const _namespace = 'admin_wellness_mutation_v1';
  static const _pendingState = 'pending';
  static const _succeededState = 'succeeded';

  final Set<String> _succeededInMemory = <String>{};

  @override
  Future<String> acquire({
    required String userId,
    required String operation,
    required String fingerprint,
  }) async {
    final slot = _slot(
      userId: userId,
      operation: operation,
      fingerprint: fingerprint,
    );
    try {
      final stored = _decode(await storage.read(slot));
      final storedKey = stored?['idempotency_key']?.toString().trim();
      final storedState = stored?['state']?.toString();
      if (storedKey != null &&
          storedKey.isNotEmpty &&
          storedState == _pendingState &&
          !_succeededInMemory.contains('$slot:$storedKey')) {
        return storedKey;
      }

      final idempotencyKey = keyFactory(operation).trim();
      if (idempotencyKey.isEmpty || idempotencyKey.length > 256) {
        throw const FormatException('invalid_idempotency_key');
      }
      await storage.write(
        slot,
        jsonEncode({'idempotency_key': idempotencyKey, 'state': _pendingState}),
      );
      return idempotencyKey;
    } catch (error) {
      if (error is AdminWellnessRewardException) rethrow;
      throw const AdminWellnessRewardException(
        'Không thể bảo vệ yêu cầu quản trị trên thiết bị. Hãy kiểm tra khóa bảo mật rồi thử lại.',
      );
    }
  }

  @override
  Future<void> markSucceeded({
    required String userId,
    required String operation,
    required String fingerprint,
    required String idempotencyKey,
  }) async {
    final slot = _slot(
      userId: userId,
      operation: operation,
      fingerprint: fingerprint,
    );
    final normalizedKey = idempotencyKey.trim();
    _succeededInMemory.add('$slot:$normalizedKey');

    // Máy chủ đã xác nhận thành công. Ghi dấu trước khi xóa giúp lần mở ứng
    // dụng sau tạo khóa mới ngay cả khi thao tác xóa của hệ điều hành bị lỗi.
    try {
      final stored = _decode(await storage.read(slot));
      if (stored?['idempotency_key']?.toString().trim() == normalizedKey) {
        await storage.write(
          slot,
          jsonEncode({
            'idempotency_key': normalizedKey,
            'state': _succeededState,
          }),
        );
      }
    } catch (_) {
      // Thành công phía máy chủ không được biến thành lỗi phía giao diện.
    }

    try {
      final stored = _decode(await storage.read(slot));
      if (stored?['idempotency_key']?.toString().trim() == normalizedKey) {
        await storage.delete(slot);
      }
    } catch (_) {
      // Dấu succeeded hoặc bộ nhớ tiến trình sẽ buộc xoay khóa ở lần tiếp theo.
    }
  }

  String _slot({
    required String userId,
    required String operation,
    required String fingerprint,
  }) {
    final normalizedUserId = userId.trim();
    final normalizedOperation = operation.trim().toLowerCase();
    final normalizedFingerprint = fingerprint.trim();
    if (normalizedUserId.isEmpty ||
        normalizedFingerprint.isEmpty ||
        !RegExp(r'^[a-z0-9_]{3,64}$').hasMatch(normalizedOperation)) {
      throw const AdminWellnessRewardException(
        'Thông tin yêu cầu quản trị chưa hợp lệ.',
      );
    }
    return '$_namespace:${_digest(normalizedUserId)}:'
        '$normalizedOperation:${_digest(normalizedFingerprint)}';
  }

  static Map<String, Object?>? _decode(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    try {
      final decoded = jsonDecode(value);
      if (decoded is! Map) return null;
      return decoded.map(
        (key, item) => MapEntry(key.toString(), item as Object?),
      );
    } catch (_) {
      return null;
    }
  }

  static String _digest(String value) {
    return sha256.convert(utf8.encode(value)).toString();
  }

  static String _newIdempotencyKey(String operation) {
    final random = Random.secure();
    final nonce = List<int>.generate(16, (_) => random.nextInt(256));
    final entropy = <int>[
      ...utf8.encode(operation),
      ...utf8.encode(DateTime.now().microsecondsSinceEpoch.toString()),
      ...nonce,
    ];
    return 'admin-wellness-$operation-${sha256.convert(entropy)}';
  }
}

class AdminWellnessMutationFingerprint {
  const AdminWellnessMutationFingerprint._();

  static String upsertOffer(AdminRewardOfferCommand command) {
    final plans =
        command.eligiblePlanCodes
            .map((value) => value.trim().toLowerCase())
            .where((value) => value.isNotEmpty)
            .toSet()
            .toList()
          ..sort();
    return _canonical({
      'offer_id': command.offerId?.trim(),
      'title': command.title.trim(),
      'description': command.description.trim(),
      'provider_name': command.providerName.trim(),
      'cost_points': command.costPoints,
      'eligible_plan_codes': plans,
      'available_from': command.availableFrom?.toUtc().toIso8601String(),
      'available_until': command.availableUntil?.toUtc().toIso8601String(),
      'voucher_expires_at': command.voucherExpiresAt?.toUtc().toIso8601String(),
      'is_active': command.isActive,
      'reason': command.reason.trim(),
    });
  }

  static String importCodes(AdminRewardCodeImportCommand command) {
    final codes =
        command.codes
            .map((value) => value.trim())
            .where((value) => value.isNotEmpty)
            .toSet()
            .toList()
          ..sort();
    return _canonical({
      'offer_id': command.offerId.trim(),
      'codes': codes,
      'voucher_expires_at': command.voucherExpiresAt?.toUtc().toIso8601String(),
      'reason': command.reason.trim(),
    });
  }

  static String cancelRedemption({
    required String redemptionId,
    required String reason,
  }) {
    return _canonical({
      'redemption_id': redemptionId.trim(),
      'reason': reason.trim(),
      'external_revocation_confirmed': true,
    });
  }

  static String _canonical(Map<String, Object?> value) {
    return jsonEncode(value);
  }
}
