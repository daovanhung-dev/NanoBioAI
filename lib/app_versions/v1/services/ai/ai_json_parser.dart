import 'dart:convert';

class AIJsonParseException extends FormatException {
  AIJsonParseException(this.code) : super('AI JSON response was rejected.');

  final String code;
}

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
    final cleaned = text
        .replaceAll('```json', '')
        .replaceAll('```', '')
        .trim()
        .replaceAll(RegExp(r',\s*]'), ']')
        .replaceAll(RegExp(r',\s*}'), '}');
    if (cleaned.startsWith('{')) {
      final dynamic root;
      try {
        root = jsonDecode(cleaned);
      } on FormatException {
        throw AIJsonParseException('invalid_json_syntax');
      }
      if (root is Map && root.length == 1 && root['items'] is List) {
        return List<dynamic>.from(root['items'] as List);
      }
      throw AIJsonParseException('invalid_items_envelope');
    }

    if (cleaned.startsWith('[')) {
      final String arrayText;
      try {
        arrayText = extractArrayText(cleaned);
      } on FormatException {
        throw AIJsonParseException('invalid_json_array');
      }
      final dynamic decoded;
      try {
        decoded = jsonDecode(arrayText);
      } on FormatException {
        throw AIJsonParseException('invalid_json_syntax');
      }
      if (decoded is List) return decoded;
      throw AIJsonParseException('invalid_json_array');
    }
    throw AIJsonParseException('invalid_json_root');
  }
}
