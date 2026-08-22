class VoiceResponseChunker {
  static const int _softMaxChars = 180;
  static const int _timedMinChars = 12;

  String _buffer = '';

  bool get hasBufferedText => _buffer.trim().isNotEmpty;

  List<String> add(String delta) {
    if (delta.isEmpty) return const <String>[];
    _buffer += delta;
    final output = <String>[];

    while (true) {
      final boundary = _findSentenceBoundary(_buffer);
      if (boundary < 0) break;
      final chunk = _buffer.substring(0, boundary + 1).trim();
      _buffer = _buffer.substring(boundary + 1).trimLeft();
      if (chunk.isNotEmpty) output.add(chunk);
    }

    if (_buffer.length > _softMaxChars) {
      final split = _findSoftSplit(_buffer, _softMaxChars);
      final chunk = _buffer.substring(0, split).trim();
      _buffer = _buffer.substring(split).trimLeft();
      if (chunk.isNotEmpty) output.add(chunk);
    }

    return output;
  }

  String? flushIfSpeakable() {
    final text = _buffer.trim();
    if (text.length < _timedMinChars || !text.contains(' ')) return null;
    _buffer = '';
    return text;
  }

  String? flush() {
    final text = _buffer.trim();
    _buffer = '';
    return text.isEmpty ? null : text;
  }

  static int _findSentenceBoundary(String value) {
    for (var i = 0; i < value.length; i++) {
      final char = value[i];
      if (char == '.' || char == '!' || char == '?' || char == '\n') {
        return i;
      }
    }
    return -1;
  }

  static int _findSoftSplit(String value, int maxChars) {
    final capped = maxChars < value.length ? maxChars : value.length;
    for (var i = capped; i > capped ~/ 2; i--) {
      if (value[i - 1] == ' ' || value[i - 1] == ',' || value[i - 1] == ';') {
        return i;
      }
    }
    return capped;
  }
}
