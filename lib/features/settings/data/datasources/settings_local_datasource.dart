import 'dart:io';

import 'package:nano_app/core/storage/localdb/database_service.dart';
import 'package:nano_app/core/utils/logger/app_logger.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';

/// SettingsLocalDatasource handles all local data operations for the Settings feature.
///
/// This datasource is responsible for:
/// - Profile operations (querying and updating users + health_profiles tables)
/// - SharedPreferences operations (saving and retrieving app settings)
/// - Storage operations (calculating cache size, clearing cache, deleting meal plans)
///
/// All database operations use the DatabaseService singleton to access SQLite.
class SettingsLocalDatasource {
  static const _tag = 'SETTINGS_LOCAL_DS';

  const SettingsLocalDatasource();

  Future<Database> _db() async {
    return DatabaseService.database;
  }

  // ============================================================================
  // PROFILE OPERATIONS
  // ============================================================================

  /// Retrieves the user profile by joining users and health_profiles tables.
  ///
  /// Returns a Map containing all fields from both tables, or null if user not found.
  /// The returned map includes:
  /// - id, full_name, email, phone, gender, birth_year, avatar_url (from users)
  /// - occupation, height_cm, weight_kg, bmi (from health_profiles)
  Future<Map<String, dynamic>?> getUserProfile(String userId) async {
    AppLogger.database(_tag, 'Getting user profile for userId: $userId');

    try {
      final db = await _db();

      // Query users table
      final userRows = await db.query(
        'users',
        where: 'id = ?',
        whereArgs: [userId],
        limit: 1,
      );

      if (userRows.isEmpty) {
        AppLogger.info(_tag, 'User not found: $userId');
        return null;
      }

      final user = userRows.first;

      // Query health_profiles table
      final profileRows = await db.query(
        'health_profiles',
        where: 'user_id = ?',
        whereArgs: [userId],
        limit: 1,
      );

      if (profileRows.isEmpty) {
        AppLogger.warning(_tag, 'Health profile not found for user: $userId');
        return null;
      }

      final profile = profileRows.first;

      // Combine both tables into a single map
      final result = {
        'id': user['id'],
        'full_name': user['full_name'],
        'email': user['email'],
        'phone': user['phone'],
        'gender': user['gender'],
        'birth_year': user['birth_year'],
        'avatar_url': user['avatar_url'],
        'occupation': profile['occupation'],
        'height_cm': profile['height_cm'],
        'weight_kg': profile['weight_kg'],
        'bmi': profile['bmi'],
      };

      AppLogger.success(_tag, 'User profile retrieved successfully');
      return result;
    } catch (e, st) {
      AppLogger.error(_tag, 'Failed to get user profile', e, st);
      rethrow;
    }
  }

  /// Updates the user profile in both users and health_profiles tables.
  ///
  /// The data map should contain fields to update. This method automatically
  /// separates fields that belong to the users table vs health_profiles table.
  ///
  /// Users table fields: full_name, email, phone, gender, birth_year, avatar_url
  /// Health profiles fields: occupation, height_cm, weight_kg, bmi
  Future<void> updateUserProfile(
    String userId,
    Map<String, dynamic> data,
  ) async {
    AppLogger.database(_tag, 'Updating user profile for userId: $userId');

    try {
      final db = await _db();
      final now = DateTime.now().toIso8601String();

      await db.transaction((txn) async {
        // Separate fields for users table
        final usersFields = <String, dynamic>{};
        if (data.containsKey('full_name')) {
          usersFields['full_name'] = data['full_name'];
        }
        if (data.containsKey('email')) {
          usersFields['email'] = data['email'];
        }
        if (data.containsKey('phone')) {
          usersFields['phone'] = data['phone'];
        }
        if (data.containsKey('gender')) {
          usersFields['gender'] = data['gender'];
        }
        if (data.containsKey('birth_year')) {
          usersFields['birth_year'] = data['birth_year'];
        }
        if (data.containsKey('avatar_url')) {
          usersFields['avatar_url'] = data['avatar_url'];
        }

        // Update users table if there are fields to update
        if (usersFields.isNotEmpty) {
          usersFields['updated_at'] = now;

          final count = await txn.update(
            'users',
            usersFields,
            where: 'id = ?',
            whereArgs: [userId],
          );

          AppLogger.database(_tag, 'Updated $count row(s) in users table');
        }

        // Separate fields for health_profiles table
        final healthProfileFields = <String, dynamic>{};
        if (data.containsKey('occupation')) {
          healthProfileFields['occupation'] = data['occupation'];
        }
        if (data.containsKey('height_cm')) {
          healthProfileFields['height_cm'] = data['height_cm'];
        }
        if (data.containsKey('weight_kg')) {
          healthProfileFields['weight_kg'] = data['weight_kg'];
        }
        if (data.containsKey('bmi')) {
          healthProfileFields['bmi'] = data['bmi'];
        }

        // Update health_profiles table if there are fields to update
        if (healthProfileFields.isNotEmpty) {
          healthProfileFields['updated_at'] = now;

          final count = await txn.update(
            'health_profiles',
            healthProfileFields,
            where: 'user_id = ?',
            whereArgs: [userId],
          );

          AppLogger.database(
            _tag,
            'Updated $count row(s) in health_profiles table',
          );
        }
      });

      AppLogger.success(_tag, 'User profile updated successfully');
    } catch (e, st) {
      AppLogger.error(_tag, 'Failed to update user profile', e, st);
      rethrow;
    }
  }

  /// Updates only the avatar_url field in the users table.
  ///
  /// This is a convenience method for avatar updates that doesn't require
  /// updating the health_profiles table.
  Future<void> updateAvatar(String userId, String avatarUrl) async {
    AppLogger.database(_tag, 'Updating avatar for userId: $userId');

    try {
      final db = await _db();
      final now = DateTime.now().toIso8601String();

      final count = await db.update(
        'users',
        {
          'avatar_url': avatarUrl,
          'updated_at': now,
        },
        where: 'id = ?',
        whereArgs: [userId],
      );

      AppLogger.success(_tag, 'Avatar updated successfully ($count row(s))');
    } catch (e, st) {
      AppLogger.error(_tag, 'Failed to update avatar', e, st);
      rethrow;
    }
  }

  // ============================================================================
  // SHAREDPREFERENCES OPERATIONS
  // ============================================================================

  /// Saves a boolean preference to SharedPreferences.
  Future<void> saveBoolPreference(String key, bool value) async {
    AppLogger.database(_tag, 'Saving bool preference: $key = $value');

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(key, value);
      AppLogger.success(_tag, 'Bool preference saved: $key');
    } catch (e, st) {
      AppLogger.error(_tag, 'Failed to save bool preference: $key', e, st);
      rethrow;
    }
  }

  /// Gets a boolean preference from SharedPreferences.
  ///
  /// Returns the stored value or the provided default value if not found.
  Future<bool> getBoolPreference(
    String key, {
    bool defaultValue = false,
  }) async {
    AppLogger.database(_tag, 'Getting bool preference: $key');

    try {
      final prefs = await SharedPreferences.getInstance();
      final value = prefs.getBool(key) ?? defaultValue;
      AppLogger.database(_tag, 'Bool preference retrieved: $key = $value');
      return value;
    } catch (e, st) {
      AppLogger.error(_tag, 'Failed to get bool preference: $key', e, st);
      return defaultValue;
    }
  }

  /// Saves a string preference to SharedPreferences.
  Future<void> saveStringPreference(String key, String value) async {
    AppLogger.database(_tag, 'Saving string preference: $key = $value');

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(key, value);
      AppLogger.success(_tag, 'String preference saved: $key');
    } catch (e, st) {
      AppLogger.error(_tag, 'Failed to save string preference: $key', e, st);
      rethrow;
    }
  }

  /// Gets a string preference from SharedPreferences.
  ///
  /// Returns the stored value or the provided default value if not found.
  Future<String> getStringPreference(
    String key, {
    String defaultValue = '',
  }) async {
    AppLogger.database(_tag, 'Getting string preference: $key');

    try {
      final prefs = await SharedPreferences.getInstance();
      final value = prefs.getString(key) ?? defaultValue;
      AppLogger.database(_tag, 'String preference retrieved: $key = $value');
      return value;
    } catch (e, st) {
      AppLogger.error(_tag, 'Failed to get string preference: $key', e, st);
      return defaultValue;
    }
  }

  /// Clears all preferences from SharedPreferences.
  ///
  /// This is used during logout with "Clear All Data" option.
  Future<void> clearAllPreferences() async {
    AppLogger.database(_tag, 'Clearing all preferences');

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
      AppLogger.success(_tag, 'All preferences cleared');
    } catch (e, st) {
      AppLogger.error(_tag, 'Failed to clear all preferences', e, st);
      rethrow;
    }
  }

  // ============================================================================
  // STORAGE OPERATIONS
  // ============================================================================

  /// Calculates the total cache size in bytes.
  ///
  /// Returns the size of the temporary directory used by the app for caching.
  Future<int> calculateCacheSize() async {
    AppLogger.database(_tag, 'Calculating cache size');

    try {
      final cacheDir = await getTemporaryDirectory();
      int totalSize = 0;

      if (await cacheDir.exists()) {
        await for (final entity in cacheDir.list(recursive: true)) {
          if (entity is File) {
            totalSize += await entity.length();
          }
        }
      }

      AppLogger.success(_tag, 'Cache size calculated: $totalSize bytes');
      return totalSize;
    } catch (e, st) {
      AppLogger.error(_tag, 'Failed to calculate cache size', e, st);
      return 0;
    }
  }

  /// Clears all cached data by deleting files in the temporary directory.
  ///
  /// This removes all files and subdirectories from the cache directory.
  Future<void> clearCache() async {
    AppLogger.database(_tag, 'Clearing cache');

    try {
      final cacheDir = await getTemporaryDirectory();

      if (await cacheDir.exists()) {
        await for (final entity in cacheDir.list(recursive: false)) {
          if (entity is File) {
            await entity.delete();
          } else if (entity is Directory) {
            await entity.delete(recursive: true);
          }
        }
      }

      AppLogger.success(_tag, 'Cache cleared successfully');
    } catch (e, st) {
      AppLogger.error(_tag, 'Failed to clear cache', e, st);
      rethrow;
    }
  }

  /// Deletes all meal plans for a specific user from the database.
  ///
  /// This removes all records from the meal_plans table associated with the user.
  Future<void> deleteMealPlans(String userId) async {
    AppLogger.database(_tag, 'Deleting meal plans for userId: $userId');

    try {
      final db = await _db();

      final count = await db.delete(
        'meal_plans',
        where: 'user_id = ?',
        whereArgs: [userId],
      );

      AppLogger.success(_tag, 'Deleted $count meal plan(s)');
    } catch (e, st) {
      AppLogger.error(_tag, 'Failed to delete meal plans', e, st);
      rethrow;
    }
  }
}
