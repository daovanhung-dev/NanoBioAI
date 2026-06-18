import 'dart:convert';

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

  static List<dynamic> decodeArray(String text) {
    final decoded = jsonDecode(extractArrayText(text));
    if (decoded is! List) {
      throw const FormatException('AI response must be a JSON array');
    }
    return decoded;
  }
}
