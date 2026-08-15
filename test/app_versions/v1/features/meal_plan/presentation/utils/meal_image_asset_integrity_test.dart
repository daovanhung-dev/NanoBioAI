import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('PDF meal image bundle contains 123 unique WebP assets', () {
    final directory = Directory('assets/images/meals/pdf_health_book');
    expect(directory.existsSync(), isTrue);
    final images = directory
        .listSync()
        .whereType<File>()
        .where((file) => file.path.toLowerCase().endsWith('.webp'))
        .toList(growable: false);
    expect(images.length, 123);
    for (final image in images) {
      expect(image.lengthSync(), greaterThan(0), reason: image.path);
    }
  });
}
