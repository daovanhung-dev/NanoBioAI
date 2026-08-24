import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nano_app/core/config/app_env.dart';
import 'package:nano_app/core/utils/logger/dio_log_interceptor.dart';

final dioProvider = Provider<Dio>((ref) {
  final dio = Dio(
    BaseOptions(
      baseUrl: AppEnv.requiredString('OPENAI_BASE_URL'),
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      sendTimeout: const Duration(seconds: 30),
    ),
  );
  return attachDioLogging(dio, scope: 'CoreDio');
});
