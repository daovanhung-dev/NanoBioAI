import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:nano_app/core/storage/localdb/database_service.dart';
import 'package:nano_app/core/storage/localdb/tables/nabi_esp_credential_table.dart';

import '../../app_versions/v1/features/nabi_esp_assistant/data/services/nabi_esp_android_bridge.dart';

class NabiEspAccountCredential {
  const NabiEspAccountCredential({
    required this.identifierType,
    required this.identifier,
    required this.password,
  });

  final String identifierType;
  final String identifier;
  final String password;
}

/// Stores one signed-in account's Nabi setup credential as Android Keystore
/// ciphertext in SQLite. The raw password is never written to the database.
class NabiEspCredentialVault {
  const NabiEspCredentialVault._();

  static const instance = NabiEspCredentialVault._();

  Future<bool> save({
    required String userId,
    required String identifierType,
    required String identifier,
    required String password,
  }) async {
    if (defaultTargetPlatform != TargetPlatform.android ||
        userId.trim().isEmpty ||
        !_isSupportedIdentifierType(identifierType) ||
        identifier.trim().isEmpty ||
        password.isEmpty) {
      return false;
    }

    final payload = jsonEncode({
      'version': 1,
      'identifier_type': identifierType,
      'identifier': identifier.trim(),
      'password': password,
    });
    final encrypted = await NabiEspAndroidBridge.encryptNabiCredential(payload);
    final database = await DatabaseService.database;
    final now = DateTime.now().toUtc().toIso8601String();
    await database.transaction((transaction) async {
      await transaction.delete(NabiEspCredentialTable.tableName);
      await transaction.insert(NabiEspCredentialTable.tableName, {
        'user_id': userId.trim(),
        'ciphertext': encrypted['ciphertext'],
        'initialization_vector': encrypted['iv'],
        'updated_at': now,
      });
    });
    return true;
  }

  Future<NabiEspAccountCredential?> read(String userId) async {
    if (defaultTargetPlatform != TargetPlatform.android ||
        userId.trim().isEmpty) {
      return null;
    }
    final database = await DatabaseService.database;
    final rows = await database.query(
      NabiEspCredentialTable.tableName,
      columns: const ['ciphertext', 'initialization_vector'],
      where: 'user_id = ?',
      whereArgs: [userId.trim()],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    try {
      final plaintext = await NabiEspAndroidBridge.decryptNabiCredential(
        ciphertext: rows.single['ciphertext']?.toString() ?? '',
        iv: rows.single['initialization_vector']?.toString() ?? '',
      );
      final payload = jsonDecode(plaintext);
      if (payload is! Map || payload['version'] != 1) {
        throw const FormatException('Invalid Nabi credential payload.');
      }
      final identifierType = payload['identifier_type']?.toString() ?? '';
      final identifier = payload['identifier']?.toString() ?? '';
      final password = payload['password']?.toString() ?? '';
      if (!_isSupportedIdentifierType(identifierType) ||
          identifier.isEmpty ||
          password.isEmpty) {
        throw const FormatException('Invalid Nabi credential payload.');
      }
      return NabiEspAccountCredential(
        identifierType: identifierType,
        identifier: identifier,
        password: password,
      );
    } catch (_) {
      await clear();
      rethrow;
    }
  }

  Future<void> clear() async {
    if (defaultTargetPlatform != TargetPlatform.android) return;
    final database = await DatabaseService.database;
    await database.delete(NabiEspCredentialTable.tableName);
  }

  static bool _isSupportedIdentifierType(String value) =>
      value == 'phone' || value == 'email' || value == 'username';
}
