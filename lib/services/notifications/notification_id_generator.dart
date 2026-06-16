int deterministicNotificationId(String value) {
  var hash = 0x811c9dc5;

  for (final codeUnit in value.codeUnits) {
    hash ^= codeUnit;
    hash = (hash * 0x01000193) & 0xffffffff;
  }

  final id = hash & 0x7fffffff;
  return id == 0 ? 1 : id;
}
