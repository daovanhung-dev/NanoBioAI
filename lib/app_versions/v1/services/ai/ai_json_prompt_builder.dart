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
- Không tự tạo mã ngoài danh sách allowed.
- Không trả về text hiển thị cuối cùng như tên món, mô tả, hướng dẫn, tiêu đề, đơn vị hoặc lời động viên.

$prompt
''';
  }
}
