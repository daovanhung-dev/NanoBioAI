import 'package:nano_app/core/storage/localdb/daos/sleep_safety_dao.dart';
import 'package:nano_app/core/storage/localdb/database_service.dart';
import 'package:sqflite/sqflite.dart';
import '../models/sleep_safety_models.dart';
import '../../domain/entities/safety_contact.dart';
import '../../domain/entities/sleep_safety_event.dart';
import '../../domain/entities/sleep_safety_preference.dart';
import '../../domain/entities/sleep_safety_session.dart';

class SleepSafetyLocalDatasource {
  const SleepSafetyLocalDatasource({this.databaseOverride});
  final Database? databaseOverride;
  Future<SleepSafetyDao> _dao() async => SleepSafetyDao(databaseOverride ?? await DatabaseService.database);
  Future<SleepSafetyPreference> loadPreference(String userId) async {
    final row = await (await _dao()).getPreference(userId);
    return row == null ? SleepSafetyPreference.defaults(userId) : SleepSafetyModelMapper.preferenceFromMap(row);
  }
  Future<void> savePreference(SleepSafetyPreference value) async => (await _dao()).upsertPreference(SleepSafetyModelMapper.preferenceToMap(value));
  Future<void> saveSession(SleepSafetySession value) async => (await _dao()).insertSession(SleepSafetyModelMapper.sessionToMap(value));
  Future<SleepSafetySession?> getSession(String id) async {
    final row = await (await _dao()).getSession(id);
    return row == null ? null : SleepSafetyModelMapper.sessionFromMap(row);
  }
  Future<void> updateSession(String id, Map<String,Object?> values) async => (await _dao()).updateSession(id, values);
  Future<void> saveEvent(SleepSafetyEvent value) async => (await _dao()).insertEvent(SleepSafetyModelMapper.eventToMap(value));
  Future<SleepSafetyEvent?> getEvent(String id) async {
    final row = await (await _dao()).getEvent(id);
    return row == null ? null : SleepSafetyModelMapper.eventFromMap(row);
  }
  Future<void> updateEvent(String id, Map<String,Object?> values) async => (await _dao()).updateEvent(id, values);
  Future<List<SleepSafetyEvent>> listEvents(String userId) async => (await (await _dao()).listEvents(userId)).map(SleepSafetyModelMapper.eventFromMap).toList(growable:false);
  Future<void> cacheContacts(String userId, List<SafetyContact> contacts) async => (await _dao()).replaceContacts(userId, contacts.map(SleepSafetyModelMapper.contactToMap).toList(growable:false));
  Future<List<SafetyContact>> listCachedContacts(String userId) async => (await (await _dao()).listContacts(userId)).map(SleepSafetyModelMapper.contactFromMap).toList(growable:false);
}
