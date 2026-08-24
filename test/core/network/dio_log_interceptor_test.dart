import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nano_app/core/utils/logger/dio_log_interceptor.dart';
import 'package:nano_app/core/utils/logger/terminal_log_sink.dart';

void main() {
  tearDown(() => TerminalLogSink.setTestWriter(null));

  test('Dio interceptor logs request/response without secret values', () async {
    final output = <String>[];
    TerminalLogSink.setTestWriter(output.add);

    final dio = Dio()..httpClientAdapter = _FakeAdapter();
    attachDioLogging(dio, scope: 'TestDio');

    final response = await dio.get<Object?>(
      'https://example.com/resource?token=very-secret&q=hello',
      options: Options(headers: {'Authorization': 'Bearer also-secret'}),
    );

    expect(response.statusCode, 200);
    final text = output.join('\n');
    expect(text, contains('[HTTP][TestDio][REQUEST]'));
    expect(text, contains('[HTTP][TestDio][RESPONSE]'));
    expect(text, contains('keys=q,token'));
    expect(text, isNot(contains('very-secret')));
    expect(text, isNot(contains('also-secret')));
    expect(text, contains('corr=http-'));
  });

  test('Dio interceptor logs network failures with stack context', () async {
    final output = <String>[];
    TerminalLogSink.setTestWriter(output.add);

    final dio = Dio()..httpClientAdapter = _FakeAdapter(fail: true);
    attachDioLogging(dio, scope: 'TestDio');

    await expectLater(
      dio.get<Object?>('https://example.com/fail'),
      throwsA(isA<DioException>()),
    );

    final text = output.join('\n');
    expect(text, contains('[HTTP][TestDio][ERROR]'));
    expect(text, contains('errorType=DioException'));
  });
}

class _FakeAdapter implements HttpClientAdapter {
  _FakeAdapter({this.fail = false});

  final bool fail;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    if (fail) {
      throw DioException(
        requestOptions: options,
        type: DioExceptionType.connectionTimeout,
        stackTrace: StackTrace.current,
      );
    }
    return ResponseBody.fromString(
      '{"ok":true}',
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}
