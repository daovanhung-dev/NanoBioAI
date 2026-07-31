import 'package:nano_app/core/storage/localdb/daos/users_dao.dart';
import 'package:nano_app/core/storage/localdb/database_service.dart';
import 'package:sqflite/sqflite.dart';

abstract interface class MembershipPaymentPayerProfileLocalDatasource {
  Future<String?> readFullName(String userId);
}

class SqliteMembershipPaymentPayerProfileLocalDatasource
    implements MembershipPaymentPayerProfileLocalDatasource {
  final Database? databaseOverride;

  const SqliteMembershipPaymentPayerProfileLocalDatasource({
    this.databaseOverride,
  });

  @override
  Future<String?> readFullName(String userId) async {
    final normalizedUserId = userId.trim();
    if (normalizedUserId.isEmpty) return null;

    final database = databaseOverride ?? await DatabaseService.database;
    final user = await UsersDao(database).getById(normalizedUserId);
    final fullName = user?.fullName?.trim();
    return fullName == null || fullName.isEmpty ? null : fullName;
  }
}
