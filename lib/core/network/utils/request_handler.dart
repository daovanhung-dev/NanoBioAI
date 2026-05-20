class RequestHandler {
  static Future<T> handle<T>(
    Future<T> Function() request,
  ) async {
    return await request();
  }
}