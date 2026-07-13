import 'package:flutter_secure_storage/flutter_secure_storage.dart';

abstract class WellnessVoucherSecureStore {
  Future<void> writeCode({
    required String userId,
    required String redemptionId,
    required String code,
  });

  Future<String?> readCode({
    required String userId,
    required String redemptionId,
  });

  Future<void> writePendingRedemptionKey({
    required String userId,
    required String offerId,
    required String idempotencyKey,
  });

  Future<String?> readPendingRedemptionKey({
    required String userId,
    required String offerId,
  });

  Future<void> deletePendingRedemptionKey({
    required String userId,
    required String offerId,
  });

  Future<void> deleteUserCodes(String userId);
}

class OsWellnessVoucherSecureStore implements WellnessVoucherSecureStore {
  final FlutterSecureStorage storage;

  const OsWellnessVoucherSecureStore({
    this.storage = const FlutterSecureStorage(),
  });

  static const _namespace = 'wellness_reward_voucher_v1';

  @override
  Future<void> writeCode({
    required String userId,
    required String redemptionId,
    required String code,
  }) async {
    final normalizedCode = code.trim();
    if (!_isValidId(userId) ||
        !_isValidId(redemptionId) ||
        normalizedCode.isEmpty) {
      return;
    }
    await storage.write(
      key: _codeKey(userId, redemptionId),
      value: normalizedCode,
    );

    final ids = await _readIndex(userId);
    if (ids.add(redemptionId)) {
      await storage.write(key: _indexKey(userId), value: ids.join('\n'));
    }
  }

  @override
  Future<String?> readCode({
    required String userId,
    required String redemptionId,
  }) async {
    if (!_isValidId(userId) || !_isValidId(redemptionId)) return null;
    final value = await storage.read(key: _codeKey(userId, redemptionId));
    final normalized = value?.trim();
    return normalized == null || normalized.isEmpty ? null : normalized;
  }

  @override
  Future<void> writePendingRedemptionKey({
    required String userId,
    required String offerId,
    required String idempotencyKey,
  }) async {
    final normalizedKey = idempotencyKey.trim();
    if (!_isValidId(userId) ||
        !_isValidId(offerId) ||
        normalizedKey.isEmpty ||
        normalizedKey.length > 256) {
      throw ArgumentError('Thông tin yêu cầu đổi ưu đãi chưa hợp lệ.');
    }
    await storage.write(
      key: _pendingKey(userId, offerId),
      value: normalizedKey,
    );
    final offerIds = await _readPendingIndex(userId);
    if (offerIds.add(offerId)) {
      await storage.write(
        key: _pendingIndexKey(userId),
        value: offerIds.join('\n'),
      );
    }
  }

  @override
  Future<String?> readPendingRedemptionKey({
    required String userId,
    required String offerId,
  }) async {
    if (!_isValidId(userId) || !_isValidId(offerId)) return null;
    final value = await storage.read(key: _pendingKey(userId, offerId));
    final normalized = value?.trim();
    return normalized == null || normalized.isEmpty ? null : normalized;
  }

  @override
  Future<void> deletePendingRedemptionKey({
    required String userId,
    required String offerId,
  }) async {
    if (!_isValidId(userId) || !_isValidId(offerId)) return;
    await storage.delete(key: _pendingKey(userId, offerId));
    final offerIds = await _readPendingIndex(userId)
      ..remove(offerId);
    if (offerIds.isEmpty) {
      await storage.delete(key: _pendingIndexKey(userId));
    } else {
      await storage.write(
        key: _pendingIndexKey(userId),
        value: offerIds.join('\n'),
      );
    }
  }

  @override
  Future<void> deleteUserCodes(String userId) async {
    if (!_isValidId(userId)) return;
    final ids = await _readIndex(userId);
    for (final redemptionId in ids) {
      await storage.delete(key: _codeKey(userId, redemptionId));
    }
    await storage.delete(key: _indexKey(userId));
    final pendingOfferIds = await _readPendingIndex(userId);
    for (final offerId in pendingOfferIds) {
      await storage.delete(key: _pendingKey(userId, offerId));
    }
    await storage.delete(key: _pendingIndexKey(userId));
  }

  Future<Set<String>> _readIndex(String userId) async {
    final value = await storage.read(key: _indexKey(userId));
    if (value == null || value.trim().isEmpty) return <String>{};
    return value
        .split('\n')
        .map((entry) => entry.trim())
        .where(_isValidId)
        .toSet();
  }

  Future<Set<String>> _readPendingIndex(String userId) async {
    final value = await storage.read(key: _pendingIndexKey(userId));
    if (value == null || value.trim().isEmpty) return <String>{};
    return value
        .split('\n')
        .map((entry) => entry.trim())
        .where(_isValidId)
        .toSet();
  }

  String _codeKey(String userId, String redemptionId) {
    return '$_namespace:$userId:code:$redemptionId';
  }

  String _indexKey(String userId) => '$_namespace:$userId:index';

  String _pendingKey(String userId, String offerId) {
    return '$_namespace:$userId:pending:$offerId';
  }

  String _pendingIndexKey(String userId) {
    return '$_namespace:$userId:pending_index';
  }

  bool _isValidId(String value) {
    final normalized = value.trim();
    return normalized.isNotEmpty &&
        normalized.length <= 128 &&
        RegExp(r'^[a-zA-Z0-9_-]+$').hasMatch(normalized);
  }
}
