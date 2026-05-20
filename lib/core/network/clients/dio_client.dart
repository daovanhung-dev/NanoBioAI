import 'package:dio/dio.dart';

import '../config/network_constants.dart';
import '../interceptors/logger_interceptor.dart';

class DioClient {
  static Dio create() {
    final dio = Dio(
      BaseOptions(
        connectTimeout: Duration(
          milliseconds: NetworkConstants.connectTimeout,
        ),
        receiveTimeout: Duration(
          milliseconds: NetworkConstants.receiveTimeout,
        ),
      ),
    );

    dio.interceptors.add(LoggerInterceptor());

    return dio;
  }
}