import 'package:dio/dio.dart';

class ApiService {
  final Dio dio;

  ApiService(this.dio);

  Future<Response> get(String path) {
    return dio.get(path);
  }

  Future<Response> post(
    String path,
    Map<String, dynamic> data,
  ) {
    return dio.post(path, data: data);
  }
}