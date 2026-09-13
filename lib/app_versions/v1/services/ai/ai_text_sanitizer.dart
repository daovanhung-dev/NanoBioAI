/// Cleans free-form AI text immediately before it is shown or persisted.
///
/// Structured AI payloads must not use this sanitizer because removing
/// characters from JSON would change its meaning. User input is never passed
/// through this class.
class AITextSanitizer {
  const AITextSanitizer._();

  static String sanitize(String value) {
    final source = value.replaceAll(RegExp(r'<[^>\r\n]*>'), ' ');
    final cleaned = StringBuffer();
    for (final rune in source.runes) {
      if (rune == 10) {
        cleaned.write('\n');
      } else if (_isWhitespace(rune)) {
        cleaned.write(' ');
      } else if (_isAllowedLetterOrDigit(rune) || _isAllowedPunctuation(rune)) {
        cleaned.writeCharCode(rune);
      } else {
        cleaned.write(' ');
      }
    }

    final lines = cleaned
        .toString()
        .replaceAll(RegExp(r'[ \t]+'), ' ')
        .split('\n')
        .map(
          (line) => line
              .replaceAll(RegExp(r' +([.,;:!?])'), r'$1')
              .replaceAll(RegExp(r' +\)'), ')')
              .replaceAll(RegExp(r'([({]) +'), r'$1')
              .trim(),
        )
        .toList(growable: false);
    return lines.join('\n').replaceAll(RegExp(r'\n{3,}'), '\n\n').trim();
  }

  static bool _isWhitespace(int rune) {
    return rune == 9 || rune == 11 || rune == 12 || rune == 13 || rune == 32 ||
        (rune >= 0x2000 && rune <= 0x200A) || rune == 0x00A0;
  }

  static bool _isAllowedLetterOrDigit(int rune) {
    return rune >= 0x30 && rune <= 0x39 ||
        rune >= 0x41 && rune <= 0x5A ||
        rune >= 0x61 && rune <= 0x7A ||
        rune >= 0x00C0 && rune <= 0x024F ||
        rune >= 0x1E00 && rune <= 0x1EFF;
  }

  static bool _isAllowedPunctuation(int rune) {
    return switch (rune) {
      0x2E || // .
      0x2C || // ,
      0x3B || // ;
      0x3A || // :
      0x21 || // !
      0x3F || // ?
      0x28 || // (
      0x29 || // )
      0x27 || // '
      0x22 || // "
      0x2F || // /
      0x2D => true, // -
      _ => false,
    };
  }
}
