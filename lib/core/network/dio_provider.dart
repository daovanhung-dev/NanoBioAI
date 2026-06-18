import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final dioProvider = Provider<Dio>((ref) {
  return Dio(
    BaseOptions(
      baseUrl: dotenv.env['OPENAI_BASE_URL']!,

      connectTimeout: const Duration(seconds: 30),

      receiveTimeout: const Duration(seconds: 30),

      sendTimeout: const Duration(seconds: 30),
    ),
  );
});
