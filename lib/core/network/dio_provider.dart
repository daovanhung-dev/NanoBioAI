import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nano_app/core/config/app_env.dart';

final dioProvider = Provider<Dio>((ref) {
  return Dio(
    BaseOptions(
      baseUrl: AppEnv.requiredString('OPENAI_BASE_URL'),

      connectTimeout: const Duration(seconds: 30),

      receiveTimeout: const Duration(seconds: 30),

      sendTimeout: const Duration(seconds: 30),
    ),
  );
});
