import 'package:nano_app/core/health_events/health_domain_event.dart';

class HealthEventDeduplicator {
  final Duration ttl;
  final int maxEntries;
  final DateTime Function() now;
  final Map<String, DateTime> _seen = <String, DateTime>{};

  HealthEventDeduplicator({
    this.ttl = const Duration(minutes: 5),
    this.maxEntries = 256,
    DateTime Function()? now,
  }) : now = now ?? DateTime.now;

  bool accept(HealthDomainEvent event) {
    final current = now();
    _prune(current);
    final key = event.dedupeKey;
    final seenAt = _seen[key];
    if (seenAt != null && current.difference(seenAt) <= ttl) {
      return false;
    }
    _seen[key] = current;
    if (_seen.length > maxEntries) {
      final oldest = _seen.entries.reduce(
        (left, right) => left.value.isBefore(right.value) ? left : right,
      );
      _seen.remove(oldest.key);
    }
    return true;
  }

  void clear() => _seen.clear();

  void _prune(DateTime current) {
    _seen.removeWhere((_, seenAt) => current.difference(seenAt) > ttl);
  }
}
