import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';

class TerminalLogSink {
  TerminalLogSink._();

  static void Function(String line)? _testWriter;

  static void write(String line) {
    final writer = _testWriter;
    if (writer != null) {
      writer(line);
      return;
    }
    developer.log(line, name: 'NanoBio');
  }

  @visibleForTesting
  static void setTestWriter(void Function(String line)? writer) {
    _testWriter = writer;
  }
}
