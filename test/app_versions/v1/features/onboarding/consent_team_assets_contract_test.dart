import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('consent team portraits are bundled as Flutter assets', () {
    const assetDirectory = 'docs/note/19-08-2026/image_char/';
    final pubspec = File('pubspec.yaml').readAsStringSync();

    expect(pubspec, contains('- $assetDirectory'));
    for (final path in const [
      'docs/note/19-08-2026/image_char/Lưu Hải Minh.jpg',
      'docs/note/19-08-2026/image_char/Lê Quang Thành.jpg',
      'docs/note/19-08-2026/image_char/Thủy tiên.jpg',
    ]) {
      expect(File(path).existsSync(), isTrue, reason: path);
    }
  });
}
