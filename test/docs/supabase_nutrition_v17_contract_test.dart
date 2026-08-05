import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('config includes V17 nutrition schema and read-only catalog contract', () {
    final config = File('docs/supabase/config.sql').readAsStringSync();

    expect(config, contains('create table if not exists public.nutrition_profiles'));
    expect(config, contains('create table if not exists public.food_restrictions'));
    expect(config, contains('create table if not exists public.nutrition_preference_rules'));
    expect(config, contains('alter table public.meal_catalog enable row level security'));
    expect(config, contains('grant select on public.meal_catalog to anon, authenticated'));
    expect(config, contains('revoke insert, update, delete on public.meal_catalog'));
    expect(config, contains("'source_hash', 'source_page'"));
  });

  test('source seed contains exactly 163 catalog upserts', () {
    final seed = File(
      'docs/supabase/22-meal-catalog-source-seed.sql',
    ).readAsStringSync();

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
