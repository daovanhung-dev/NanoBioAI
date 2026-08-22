abstract final class SpeechTranscriptMerger {
  const SpeechTranscriptMerger._();

  static String merge(String committed, String current) {
    final left = committed.trim();
    final right = current.trim();
    if (left.isEmpty) return right;
    if (right.isEmpty) return left;
    if (right == left || right.startsWith('$left ')) return right;
    if (left.startsWith('$right ')) return left;

    final leftWords = left.split(RegExp(r'\s+'));
    final rightWords = right.split(RegExp(r'\s+'));
    final maxOverlap = leftWords.length < rightWords.length
        ? leftWords.length
        : rightWords.length;

    for (var overlap = maxOverlap; overlap > 0; overlap--) {
      var matches = true;
      for (var index = 0; index < overlap; index++) {
        final leftWord = _normalize(leftWords[leftWords.length - overlap + index]);
        final rightWord = _normalize(rightWords[index]);
        if (leftWord != rightWord) {
          matches = false;
          break;
        }
      }
      if (matches) {
        return [...leftWords, ...rightWords.skip(overlap)].join(' ').trim();
      }
    }

    return '$left $right'.trim();
  }

  static String _normalize(String value) {
    return value.toLowerCase().replaceAll(RegExp(r'[^a-z0-9à-ỹđ]'), '');
  }
}
