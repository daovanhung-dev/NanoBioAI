import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nano_app/shared/wellness_rank/domain/entities/wellness_rank_summary.dart';
import 'package:nano_app/shared/wellness_rank/presentation/widgets/wellness_rank_card.dart';
import 'package:nano_app/shared/wellness_rank/providers/wellness_rank_providers.dart';

void main() {
  testWidgets('guest sees sign-in invitation', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          wellnessRankUserIdProvider.overrideWith(
            (ref) => Stream<String?>.value(null),
          ),
        ],
        child: const MaterialApp(home: Scaffold(body: WellnessRankCard())),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('wellness_rank_guest_card')), findsOneWidget);
    expect(
      find.text('Đăng nhập để lưu EXP và hạng của bạn trên các thiết bị.'),
      findsOneWidget,
    );
  });

  testWidgets('rank card shows loading and cached offline snapshot', (
    tester,
  ) async {
    final completer = Completer<WellnessRankSummary?>();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          wellnessRankUserIdProvider.overrideWith(
            (ref) => Stream<String?>.value('user-a'),
          ),
          wellnessRankSummaryProvider(
            'user-a',
          ).overrideWith((ref) => completer.future),
        ],
        child: const MaterialApp(home: Scaffold(body: WellnessRankCard())),
      ),
    );
    await tester.pump();
    expect(find.byKey(const Key('wellness_rank_loading_card')), findsOneWidget);

    completer.complete(
      WellnessRankSummary(
        rankCode: 'wellness_rank_2',
        rankLevel: 2,
        title: 'Người Ươm Nếp Lành',
        experiencePoints: 640,
        currentRankThreshold: 600,
        nextRankThreshold: 1200,
        experienceToNextRank: 560,
        rankProgressExp: 40,
        rankProgressTarget: 600,
        computedAt: DateTime.utc(2026, 10, 15),
        nextDecayAt: DateTime.utc(2026, 10, 22),
        lastSyncedAt: DateTime.utc(2026, 10, 14, 10, 30),
        isStale: true,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('wellness_rank_card')), findsOneWidget);
    expect(find.byKey(const Key('wellness_rank_stale')), findsOneWidget);
    expect(find.text('Người Ươm Nếp Lành'), findsOneWidget);
    expect(find.text('640 EXP'), findsOneWidget);
  });

  testWidgets('rank card exposes retry after loading error', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          wellnessRankUserIdProvider.overrideWith(
            (ref) => Stream<String?>.value('user-a'),
          ),
          wellnessRankSummaryProvider(
            'user-a',
          ).overrideWith((ref) async => throw StateError('offline')),
        ],
        child: const MaterialApp(home: Scaffold(body: WellnessRankCard())),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('wellness_rank_error_card')), findsOneWidget);
    expect(find.text('Chưa thể cập nhật hạng lúc này'), findsOneWidget);
  });
}
