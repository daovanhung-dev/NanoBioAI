import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nano_app/app_versions/v3/features/familyplus/familyplus.dart';

void main() {
  testWidgets('renders loading state safely', (tester) async {
    final completer = Completer<FamilyPlusViewModel>();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          familyPlusContextProvider.overrideWith((ref) => completer.future),
        ],
        child: const MaterialApp(home: FamilyPlusPage()),
      ),
    );

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    completer.complete(FamilyPlusViewModel.ready(_context()));
  });

  testWidgets('renders locked state safely', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          familyPlusContextProvider.overrideWith(
            (ref) async => const FamilyPlusViewModel.locked(),
          ),
        ],
        child: const MaterialApp(home: FamilyPlusPage()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Danh cho FamilyPlus'), findsOneWidget);
  });

  testWidgets('renders empty state safely', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          familyPlusContextProvider.overrideWith(
            (ref) async => FamilyPlusViewModel.empty(_emptyContext()),
          ),
        ],
        child: const MaterialApp(home: FamilyPlusPage()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Quan ly gia dinh'), findsOneWidget);
    expect(find.text('Tao nhom FamilyPlus'), findsOneWidget);
  });

  testWidgets('renders ready member list safely', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          familyPlusContextProvider.overrideWith(
            (ref) async => FamilyPlusViewModel.ready(_context()),
          ),
        ],
        child: const MaterialApp(home: FamilyPlusPage()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Gia dinh'), findsOneWidget);
    expect(find.text('Me'), findsOneWidget);
    expect(find.textContaining('1/5'), findsOneWidget);
  });
}

FamilyPlusContext _emptyContext() {
  return const FamilyPlusContext(
    actorId: 'u1',
    selfSubjectId: 'subject-self',
    hasFamilyPlus: true,
    group: FamilyPlusGroup(
      id: 'group-1',
      ownerUserId: 'u1',
      displayName: 'Gia dinh',
      status: 'active',
    ),
  );
}

FamilyPlusContext _context() {
  return const FamilyPlusContext(
    actorId: 'u1',
    selfSubjectId: 'subject-self',
    hasFamilyPlus: true,
    group: FamilyPlusGroup(
      id: 'group-1',
      ownerUserId: 'u1',
      displayName: 'Gia dinh',
      status: 'active',
    ),
    members: [
      FamilyPlusMember(
        id: 'member-1',
        familyGroupId: 'group-1',
        subjectId: 'subject-1',
        displayName: 'Me',
        role: 'adult',
        status: 'active',
        canView: true,
        canEdit: true,
      ),
    ],
  );
}
