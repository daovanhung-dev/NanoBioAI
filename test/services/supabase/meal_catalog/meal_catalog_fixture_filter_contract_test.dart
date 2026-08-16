import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Supabase meal cache excludes fixture rows before replacing local cache', () {
    final source = File(
      'lib/services/supabase/meal_catalog/meal_catalog_cache_refresh_service.dart',
    ).readAsStringSync();

    expect(source, contains(".eq('is_active', true)"));
    expect(source, contains('!_isFixtureCode(item.code)'));
    expect(source, contains("startsWith('fixture-')"));
    expect(source, contains('replaceMeals(remoteItems)'));
  });
}
