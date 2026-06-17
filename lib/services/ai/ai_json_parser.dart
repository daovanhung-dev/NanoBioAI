class AIJsonParser {
  const AIJsonParser._();

  static String extractArrayText(String text) {
    var cleaned = text.replaceAll('```json', '').replaceAll('```', '').trim();

    cleaned = cleaned.replaceAll(RegExp(r',\s*]'), ']');
    cleaned = cleaned.replaceAll(RegExp(r',\s*}'), '}');

    final start = cleaned.indexOf('[');
    final end = cleaned.lastIndexOf(']');

    if (start == -1 || end == -1 || end < start) {
      throw const FormatException('Invalid AI JSON array format');
    }

    return cleaned.substring(start, end + 1);
  }
}
