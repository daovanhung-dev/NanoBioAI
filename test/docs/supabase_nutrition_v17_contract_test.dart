import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('build script keeps base and V18 nutrition contracts', () {
    final build = File('docs/supabase/01_build_system.sql').readAsStringSync();

    for (final token in [
      'create table if not exists public.nutrition_profiles',
      'create table if not exists public.food_restrictions',
      'create table if not exists public.nutrition_preference_rules',
      'alter table public.meal_catalog enable row level security',
      'grant select on public.meal_catalog to anon, authenticated',
      'revoke insert, update, delete on public.meal_catalog',
      "'source_hash', 'source_page'",
    ]) {
      expect(build, contains(token), reason: token);
    }
    for (final token in [
      'meal_catalog_nutrition_nonnegative_v18',
      'sugar_g numeric(10,2)',
      'saturated_fat_g numeric(10,2)',
      'nutrition_status text',
      'insert_mobile_snapshot_row',
    ]) {
      expect(build, contains(token), reason: token);
    }
  });

  test('seed script contains exactly 163 catalog upserts', () {
    final seed = File('docs/supabase/02_seed_data.sql').readAsStringSync();

    expect(
      RegExp(r'insert into public\.meal_catalog', caseSensitive: false)
          .allMatches(seed)
          .length,
      163,
    );
    expect(seed, contains("'unclassified'"));
    expect(seed, contains('false'));
  });
}
