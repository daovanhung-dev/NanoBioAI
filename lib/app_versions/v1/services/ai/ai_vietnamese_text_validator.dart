class AIVietnameseTextValidator {
  static final RegExp _mojibakePattern = RegExp(
    r'(?:Ã|Â|Ä|Æ)[\u0080-\u00BF]|áº|á»|â€™|â€œ|â€|ï¿½|�',
  );
  static final RegExp _letterPattern = RegExp(r"[A-Za-zÀ-ỹĐđ]", unicode: true);
  static final RegExp _vietnameseMarkPattern = RegExp(
    r'[àáạảãâầấậẩẫăằắặẳẵèéẹẻẽêềếệểễìíịỉĩòóọỏõôồốộổỗơờớợởỡùúụủũưừứựửữỳýỵỷỹđÀÁẠẢÃÂẦẤẬẨẪĂẰẮẶẲẴÈÉẸẺẼÊỀẾỆỂỄÌÍỊỈĨÒÓỌỎÕÔỒỐỘỔỖƠỜỚỢỞỠÙÚỤỦŨƯỪỨỰỬỮỲÝỴỶỸĐ]',
    unicode: true,
  );
  static final RegExp _technicalTokenPattern = RegExp(
    r'\b(AI|BMI|JSON|API|GEMINI|Gemini|kcal|ml|mg|g|kg|cm|m|km|ph|pH|HDL|LDL|HbA1c)\b',
  );

  const AIVietnameseTextValidator._();

  static bool isValidDisplayText(String value) {
    final text = value.trim();
    if (text.isEmpty) return true;
    if (_mojibakePattern.hasMatch(text)) return false;

    final readableText = text
        .replaceAll(_technicalTokenPattern, ' ')
        .replaceAll(RegExp(r'\d+([.,]\d+)?'), ' ');

    if (!_letterPattern.hasMatch(readableText)) return true;
    return _vietnameseMarkPattern.hasMatch(readableText);
  }

  static void validateJsonFields({
    required List<dynamic> items,
    required List<String> fields,
    required String label,
  }) {
    for (var index = 0; index < items.length; index++) {
      final item = items[index];
      if (item is! Map) {
        continue;
      }

      final map = Map<Object?, Object?>.from(item);
      for (final field in fields) {
        final rawValue = map[field];
        if (rawValue == null) {
          continue;
        }

        final value = rawValue.toString();
        if (!isValidDisplayText(value)) {
          throw FormatException(
            '$label item ${index + 1} field "$field" must be Vietnamese text with diacritics',
          );
        }
      }
    }
  }
}
