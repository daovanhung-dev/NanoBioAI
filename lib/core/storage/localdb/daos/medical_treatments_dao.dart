import 'package:sqflite/sqflite.dart';

import '../models/medical_treatment_model.dart';

class MedicalTreatmentsDao {
  final Database db;

  MedicalTreatmentsDao(this.db);

  Future<void> insert(
    MedicalTreatmentModel model,
  ) async {
    // TODO: Insert data
  }

  Future<List<MedicalTreatmentModel>> getAll() async {
    return [];
  }

  Future<void> update(
    MedicalTreatmentModel model,
  ) async {
    // TODO: Update data
  }

  Future<void> delete(
    String id,
  ) async {
    // TODO: Delete data
  }
}