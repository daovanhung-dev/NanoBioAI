class UserDataSnapshot {
  final Map<String, Object?>? user;
  final Map<String, List<Map<String, Object?>>> tables;

  const UserDataSnapshot({required this.user, required this.tables});

  bool get hasUser => user != null && user!.isNotEmpty;

  List<String> get tablesWithRows {
    return tables.entries
        .where((entry) => entry.value.isNotEmpty)
        .map((entry) => entry.key)
        .toList(growable: false);
  }
}
