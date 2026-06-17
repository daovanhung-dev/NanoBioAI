import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/datasources/lifestyle_schedule_local_datasource.dart';
import '../domain/repositories/lifestyle_schedule_repository.dart';
import '../domain/repositories/lifestyle_schedule_repository_impl.dart';
import '../presentation/controllers/lifestyle_schedule_controller.dart';
import '../presentation/controllers/lifestyle_schedule_state.dart';

final lifestyleScheduleLocalDatasourceProvider =
    Provider<LifestyleScheduleLocalDatasource>((ref) {
      return LifestyleScheduleLocalDatasource();
    });

final lifestyleScheduleRepositoryProvider =
    Provider<LifestyleScheduleRepository>((ref) {
      return LifestyleScheduleRepositoryImpl(
        datasource: ref.read(lifestyleScheduleLocalDatasourceProvider),
      );
    });

final lifestyleScheduleControllerProvider =
    AsyncNotifierProvider<LifestyleScheduleController, LifestyleScheduleState>(
      LifestyleScheduleController.new,
    );
