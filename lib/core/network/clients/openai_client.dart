import 'package:dio/dio.dart';

class OpenAIClient {
  final Dio dio;

  OpenAIClient(this.dio);

  Future<Response> analyzeHealth(Map<String, dynamic> payload) {
    return dio.post(
      '/chat/completions',
      data: payload,
    );
  }
}