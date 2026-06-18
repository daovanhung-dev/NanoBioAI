class AIJsonPromptBuilder {
  const AIJsonPromptBuilder._();

  static String buildArrayPrompt(String prompt) {
    return '''
Chỉ trả về một mảng JSON hợp lệ.

Quy tắc bắt buộc:
- Không viết giải thích.
- Không bọc trong khối mã.
- Không thêm chữ trước hoặc sau mảng.
- Không thêm khóa ngoài schema.
- Giá trị số phải là số, không phải chuỗi.
- Nội dung người dùng nhìn thấy phải là tiếng Việt có dấu.

$prompt
''';
  }
}
