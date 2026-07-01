/// Chuẩn hóa những chuỗi do tầng dữ liệu/domain trả về trước khi hiển thị ở UI.
///
/// File này chỉ được dùng ở Presentation. Không thay đổi enum, mã trạng thái,
/// dữ liệu lưu trữ hoặc thông điệp nghiệp vụ ở các tầng bên dưới.
String vietnameseUiText(String? raw, {String fallback = ''}) {
  var text = raw?.trim() ?? '';
  if (text.isEmpty) text = fallback;

  text = _exactTranslations[text] ?? text;

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
  'Thong tin FamilyPlus chua hop le.':
      'Thông tin FamilyPlus chưa hợp lệ.',

  // Sale/referral & payment fallback copy
  'Nguoi dung NanoBio': 'Người dùng NanoBio',
  'So diem quy doi phai lon hon 0.': 'Số điểm quy đổi phải lớn hơn 0.',
  'So diem chua dat muc toi thieu de quy doi.':
      'Số điểm chưa đạt mức tối thiểu để quy đổi.',
  'So diem quy doi vuot qua diem kha dung.':
      'Số điểm quy đổi vượt quá điểm khả dụng.',
  'Thong tin tao yeu cau thanh toan chua hop le.':
      'Thông tin tạo yêu cầu thanh toán chưa hợp lệ.',
};
