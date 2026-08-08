import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nano_app/app_versions/v1/features/water_tracking/data/water_tracking_local_store.dart';
import 'package:nano_app/app_versions/v1/features/water_tracking/presentation/pages/water_tracking_page.dart';
import 'package:nano_app/app_versions/v2/features/auth/providers/auth_providers.dart';
import 'package:nano_app/core/theme/app_theme.dart';

final _testAuthUserIdProvider =
    NotifierProvider<_TestAuthUserIdController, String?>(
      _TestAuthUserIdController.new,
    );

void main() {
  testWidgets('requires a user-selected target and persists local progress', (
    tester,
  ) async {
    final store = _FakeWaterTrackingLocalStore();

    await tester.pumpWidget(_TestApp(store: store));
    await tester.pumpAndSettle();

    expect(find.text('Bạn chưa chọn mục tiêu.'), findsOneWidget);
    expect(find.textContaining('không phải khuyến nghị y tế'), findsOneWidget);

    await tester.tap(find.byKey(const Key('water-goal-button')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('water-target-field')), '1750');
    await tester.tap(find.byKey(const Key('water-save-target')));
    await tester.pumpAndSettle();

    expect(find.text('Mục tiêu bạn đã chọn: 1750 ml'), findsOneWidget);
    expect(store.targetMl, 1750);

    final addButton = find.byKey(const Key('water-add-250'));
    await tester.ensureVisible(addButton);
    await tester.tap(addButton);
    await tester.pumpAndSettle();

    expect(find.text('250 ml'), findsOneWidget);
    expect(store.amountMl, 250);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpWidget(_TestApp(store: store));
    await tester.pumpAndSettle();

    expect(find.text('250 ml'), findsOneWidget);
    expect(find.text('Mục tiêu bạn đã chọn: 1750 ml'), findsOneWidget);
  });

  testWidgets('shows a retry state when local storage cannot be read', (
    tester,
  ) async {
    final store = _FakeWaterTrackingLocalStore(failNextLoad: true);

    await tester.pumpWidget(_TestApp(store: store));
    await tester.pumpAndSettle();

    expect(find.text('Chưa mở được ghi nhận local'), findsOneWidget);
    await tester.tap(find.text('Thử lại'));
    await tester.pumpAndSettle();

    expect(find.text('Bạn chưa chọn mục tiêu.'), findsOneWidget);
  });
  testWidgets('reloads the new local day before adding water after midnight', (
    tester,
  ) async {
    var now = DateTime(2026, 8, 8, 23, 59);
    final store = _FakeWaterTrackingLocalStore(targetMl: 1800)
      ..setAmountForDay(now, 750);

    await tester.pumpWidget(_TestApp(store: store, now: () => now));
    await tester.pumpAndSettle();

    expect(find.text('750 ml'), findsOneWidget);

    now = DateTime(2026, 8, 9, 0, 1);
    final addButton = find.byKey(const Key('water-add-250'));
    await tester.ensureVisible(addButton);
    await tester.tap(addButton);
    await tester.pumpAndSettle();

    expect(find.text('250 ml'), findsOneWidget);
    expect(store.amountForDay(DateTime(2026, 8, 8)), 750);
    expect(store.amountForDay(DateTime(2026, 8, 9)), 250);
    expect(store.loadedDays.last, DateTime(2026, 8, 9));
  });

  testWidgets(
    'clears and reloads actor state on same mounted page before writing',
    (tester) async {
      late ProviderContainer container;
      final memberBLoadGate = Completer<void>();
      final store =
          _ActorScopedFakeWaterTrackingLocalStore(
              actorScope: () =>
                  _actorScope(container.read(_testAuthUserIdProvider)),
            )
            ..setSnapshot(
              actorScope: 'member:member-a',
              day: DateTime(2026, 8, 8),
              targetMl: 1800,
              amountMl: 750,
            )
            ..setSnapshot(
              actorScope: 'member:member-b',
              day: DateTime(2026, 8, 8),
              targetMl: 2200,
              amountMl: 0,
            )
            ..blockNextLoad(
              actorScope: 'member:member-b',
              until: memberBLoadGate.future,
            );
      container = ProviderContainer(
        overrides: [
          currentAuthUserIdProvider.overrideWith(
            (ref) => ref.watch(_testAuthUserIdProvider),
          ),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        _TestApp(
          store: store,
          now: () => DateTime(2026, 8, 8, 12),
          container: container,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('750 ml'), findsOneWidget);
      final mountedPageState = tester.state(find.byType(WaterTrackingPage));

      container.read(_testAuthUserIdProvider.notifier).switchTo('member-b');
      await tester.pump();

      expect(
        tester.state(find.byType(WaterTrackingPage)),
        same(mountedPageState),
      );
      expect(find.text('750 ml'), findsNothing);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      memberBLoadGate.complete();
      await tester.pumpAndSettle();

      expect(find.text('0 ml'), findsOneWidget);
      final addButton = find.byKey(const Key('water-add-250'));
      await tester.ensureVisible(addButton);
      await tester.tap(addButton);
      await tester.pumpAndSettle();

      expect(find.text('250 ml'), findsOneWidget);
      expect(
        store.amountForActor('member:member-a', DateTime(2026, 8, 8)),
        750,
      );
      expect(
        store.amountForActor('member:member-b', DateTime(2026, 8, 8)),
        250,
      );
    },
  );
}

class _TestApp extends StatelessWidget {
  final WaterTrackingLocalStore store;
  final DateTime Function()? now;
  final ProviderContainer? container;

  const _TestApp({required this.store, this.now, this.container});

  @override
  Widget build(BuildContext context) {
    final app = MaterialApp(
      theme: AppTheme.lightTheme,
      home: WaterTrackingPage(localStore: store, now: now),
    );
    final providerContainer = container;
    if (providerContainer != null) {
      return UncontrolledProviderScope(
        container: providerContainer,
        child: app,
      );
    }
    return ProviderScope(
      overrides: [currentAuthUserIdProvider.overrideWithValue(null)],
      child: app,
    );
  }
}

class _FakeWaterTrackingLocalStore implements WaterTrackingLocalStore {
  int? targetMl;
  int amountMl = 0;
  bool failNextLoad;
  final Map<String, int> _amountsByDay = <String, int>{};
  final List<DateTime> loadedDays = <DateTime>[];

  _FakeWaterTrackingLocalStore({this.targetMl, this.failNextLoad = false});

  @override
  Future<WaterTrackingSnapshot> load(DateTime localDay) async {
    loadedDays.add(_dateOnly(localDay));
    if (failNextLoad) {
      failNextLoad = false;
      throw StateError('read failed');
    }
    return WaterTrackingSnapshot(
      targetMl: targetMl,
      amountMl: _amountsByDay[_dayKey(localDay)] ?? 0,
    );
  }

  @override
  Future<void> saveAmountMl(DateTime localDay, int amountMl) async {
    this.amountMl = amountMl;
    _amountsByDay[_dayKey(localDay)] = amountMl;
  }

  @override
  Future<void> saveTargetMl(int targetMl) async {
    this.targetMl = targetMl;
  }

  void setAmountForDay(DateTime day, int amountMl) {
    _amountsByDay[_dayKey(day)] = amountMl;
  }

  int amountForDay(DateTime day) => _amountsByDay[_dayKey(day)] ?? 0;

  static DateTime _dateOnly(DateTime day) =>
      DateTime(day.year, day.month, day.day);

  static String _dayKey(DateTime day) =>
      '${day.year.toString().padLeft(4, '0')}-'
      '${day.month.toString().padLeft(2, '0')}-'
      '${day.day.toString().padLeft(2, '0')}';
}

class _TestAuthUserIdController extends Notifier<String?> {
  @override
  String? build() => 'member-a';

  void switchTo(String? userId) {
    state = userId;
  }
}

class _ActorScopedFakeWaterTrackingLocalStore
    implements WaterTrackingLocalStore {
  final String Function() actorScope;
  final Map<String, int> _targets = <String, int>{};
  final Map<String, int> _amounts = <String, int>{};
  String? _blockedActorScope;
  Future<void>? _blockedUntil;

  _ActorScopedFakeWaterTrackingLocalStore({required this.actorScope});

  @override
  Future<WaterTrackingSnapshot> load(DateTime localDay) async {
    final scope = actorScope();
    if (scope == _blockedActorScope) {
      final blockedUntil = _blockedUntil;
      _blockedActorScope = null;
      _blockedUntil = null;
      if (blockedUntil != null) await blockedUntil;
    }
    return WaterTrackingSnapshot(
      targetMl: _targets[scope],
      amountMl: _amounts[_amountKey(scope, localDay)] ?? 0,
    );
  }

  @override
  Future<void> saveAmountMl(DateTime localDay, int amountMl) async {
    final scope = actorScope();
    _amounts[_amountKey(scope, localDay)] = amountMl;
  }

  @override
  Future<void> saveTargetMl(int targetMl) async {
    _targets[actorScope()] = targetMl;
  }

  void setSnapshot({
    required String actorScope,
    required DateTime day,
    required int targetMl,
    required int amountMl,
  }) {
    _targets[actorScope] = targetMl;
    _amounts[_amountKey(actorScope, day)] = amountMl;
  }

  void blockNextLoad({
    required String actorScope,
    required Future<void> until,
  }) {
    _blockedActorScope = actorScope;
    _blockedUntil = until;
  }

  int amountForActor(String actorScope, DateTime day) =>
      _amounts[_amountKey(actorScope, day)] ?? 0;

  static String _amountKey(String actorScope, DateTime day) =>
      '$actorScope:${_dayKey(day)}';
}

String _actorScope(String? userId) {
  final normalizedUserId = userId?.trim();
  return normalizedUserId == null || normalizedUserId.isEmpty
      ? 'guest:install'
      : 'member:$normalizedUserId';
}

String _dayKey(DateTime day) =>
    '${day.year.toString().padLeft(4, '0')}-'
    '${day.month.toString().padLeft(2, '0')}-'
    '${day.day.toString().padLeft(2, '0')}';
