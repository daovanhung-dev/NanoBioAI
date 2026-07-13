/// Chuẩn hóa những chuỗi do tầng dữ liệu/domain trả về trước khi hiển thị ở UI.
///
/// File này chỉ được dùng ở Presentation. Không thay đổi enum, mã trạng thái,
/// dữ liệu lưu trữ hoặc thông điệp nghiệp vụ ở các tầng bên dưới.
String vietnameseUiText(String? raw, {String fallback = ''}) {
  var text = raw?.trim() ?? '';
  if (text.isEmpty) text = fallback;

  text = _exactTranslations[text] ?? text;

  return _repairLegacyBrandSpacing(text);
}

/// Chuẩn hóa nội dung do hệ thống/backend kiểm soát trước khi hiển thị.
///
/// Khác với [vietnameseUiText], hàm này không trả nguyên văn chuỗi kỹ thuật,
/// tiếng Anh, mojibake hoặc tiếng Việt không dấu chưa được nhận diện. Dữ liệu
/// thực sự do người dùng nhập (tên, email, ghi chú) không được đưa qua hàm này.
String vietnameseSystemUiText(
  String? raw, {
  String fallback = 'Nabi chưa thể hiển thị nội dung này. Bạn thử lại sau nhé.',
}) {
  final source = raw?.trim() ?? '';
  if (source.isEmpty) return fallback;

  final translated = _exactTranslations[source];
  if (translated != null) return _repairLegacyBrandSpacing(translated);

  final normalized = _repairLegacyBrandSpacing(source);
  if (_mojibakePattern.hasMatch(normalized) ||
      _technicalMessagePattern.hasMatch(normalized) ||
      _internalCodePattern.hasMatch(normalized) ||
      _englishMessagePattern.hasMatch(normalized) ||
      _unaccentedVietnamesePattern.hasMatch(normalized)) {
    return fallback;
  }
  return normalized;
}

String _repairLegacyBrandSpacing(String text) {
  // Sửa các chuỗi thương hiệu cũ bị dính từ khi hiển thị cho người dùng.
  return text
      .replaceAll('Nabiđang', 'Nabi đang')
      .replaceAll('Nabicần', 'Nabi cần')
      .replaceAll('Nabitạo', 'Nabi tạo')
      .replaceAll('Nabixin', 'Nabi xin')
      .replaceAll('Nabinhé', 'Nabi nhé')
      .replaceAll('Nabiở', 'Nabi ở')
      .replaceAll('Nabivẫn', 'Nabi vẫn')
      .replaceAll('Nabimừng', 'Nabi mừng')
      .replaceAll('Nabithấy', 'Nabi thấy')
      .replaceAll('Nabichỉ', 'Nabi chỉ')
      .replaceAll('Nabighi', 'Nabi ghi')
      .replaceAll('Nabigợi', 'Nabi gợi')
      .replaceAll('Nabinghĩ', 'Nabi nghĩ')
      .replaceAll('Nabitính', 'Nabi tính');
}

final _mojibakePattern = RegExp(
  r'(?:Ã|Â|Ä|Æ)[\u0080-\u00BF]|áº|á»|â€™|â€œ|â€|ï¿½|�',
);

final _technicalMessagePattern = RegExp(
  r'\b(exception|stack\s*trace|database|sqlite|postgres|table|query|parser|typeerror|stateerror|format(?:exception)?|rpc|http\s*\d{3})\b',
  caseSensitive: false,
);

final _internalCodePattern = RegExp(r'^[A-Z][A-Z0-9_]{3,}$');

final _englishMessagePattern = RegExp(
  r'\b(please|failed|failure|invalid|unknown|unexpected|sign\s*in|log\s*in|permission|camera|gallery|image|upload|download|network|server|request|response|retry|cancel|success|error|daily|health|reminder|task|complete|completed|take|drink|walk|exercise|breakfast|lunch|dinner|sleep|today|tomorrow|open|tap|continue|redeem|offer|available|pending|issued|expired|points?)\b',
  caseSensitive: false,
);

final _unaccentedVietnamesePattern = RegExp(
  r'\b(khong|chua|vui long|tai khoan|nguoi dung|thong tin|du lieu|thu lai|dang nhap|dang ky|nhiem vu|suc khoe|gia dinh|thanh vien|diem|gioi thieu|hoan tat)\b',
  caseSensitive: false,
);

const _exactTranslations = <String, String>{
  // Body metrics
  'Chieu cao can nam trong khoang 80-230 cm.':
      'Chiều cao cần nằm trong khoảng 80–230 cm.',
  'Can nang can nam trong khoang 20-300 kg.':
      'Cân nặng cần nằm trong khoảng 20–300 kg.',
  'Tuoi can nam trong khoang 13-100.': 'Tuổi cần nằm trong khoảng 13–100.',
  'Thieu can': 'Thiếu cân',
  'Can doi': 'Cân đối',
  'Thua can': 'Thừa cân',
  'Can theo doi beo phi': 'Cần theo dõi béo phì',
  'Nu': 'Nữ',
  'It van dong': 'Ít vận động',
  'Van dong nhe': 'Vận động nhẹ',
  'Van dong vua': 'Vận động vừa',
  'Van dong cao': 'Vận động cao',
  'Nguoi truong thanh nen uu tien 7-9 gio ngu moi dem.':
      'Người trưởng thành nên ưu tiên ngủ 7–9 giờ mỗi đêm.',
  'Dat muc tieu toi thieu 150 phut van dong vua moi tuan, tang dan theo the luc.':
      'Đặt mục tiêu tối thiểu 150 phút vận động vừa mỗi tuần, tăng dần theo thể lực.',

  // V2 health score
  'Please sign in to view health score.':
      'Vui lòng đăng nhập để xem điểm sức khỏe.',
  'Chua co lich su cham soc trong giai doan nay.':
      'Chưa có lịch sử chăm sóc trong giai đoạn này.',
  'Tam thoi chua tai duoc diem suc khoe. Ban thu lai sau.':
      'Tạm thời chưa tải được điểm sức khỏe. Bạn thử lại sau.',
  'Nhiem vu va thoi quen': 'Nhiệm vụ và thói quen',
  'Suc khoe': 'Sức khỏe',
  'Thoi quen': 'Thói quen',

  // V3 family context
  'Gia dinh cua toi': 'Gia đình của tôi',
  'Thanh vien': 'Thành viên',
  'Chua co nhom gia dinh. Hay tao nhom de bat dau.':
      'Chưa có nhóm gia đình. Hãy tạo nhóm để bắt đầu.',
  'Tai khoan chua co quyen FamilyPlus phu hop.':
      'Tài khoản chưa có quyền FamilyPlus phù hợp.',
  'Thong tin FamilyPlus chua hop le.': 'Thông tin FamilyPlus chưa hợp lệ.',

  // Sale/referral & payment fallback copy
  'Nguoi dung NanoBio': 'Người dùng NanoBio',
  'So diem quy doi phai lon hon 0.': 'Số điểm quy đổi phải lớn hơn 0.',
  'So diem chua dat muc toi thieu de quy doi.':
      'Số điểm chưa đạt mức tối thiểu để quy đổi.',
  'So diem quy doi vuot qua diem kha dung.':
      'Số điểm quy đổi vượt quá điểm khả dụng.',
  'Thong tin tao yeu cau thanh toan chua hop le.':
      'Thông tin tạo yêu cầu thanh toán chưa hợp lệ.',

  // Stable backend/error codes. Không hiển thị mã nội bộ trên UI.
  'AUTH_REQUIRED': 'Vui lòng đăng nhập để tiếp tục.',
  'FORBIDDEN': 'Bạn chưa có quyền sử dụng nội dung này.',
  'INVALID_COMMAND': 'Thông tin gửi lên chưa hợp lệ.',
  'NOT_FOUND': 'Nội dung bạn cần hiện chưa có sẵn.',
  'NETWORK_ERROR': 'Kết nối chưa ổn định. Bạn thử lại sau nhé.',
  'SERVER_ERROR': 'Hệ thống đang bận. Bạn thử lại sau nhé.',
};
