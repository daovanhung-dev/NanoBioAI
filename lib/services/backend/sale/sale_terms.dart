/// Versioned Sale terms shown before a user requests the Sale role.
///
/// This is product-facing consent copy. Legal/business owners must review the
/// final contract before any production payout starts.
class SaleTerms {
  const SaleTerms._();

  static const currentVersion = '2026-06-29';

  static const title =
      'Điều lệ tham gia chương trình cộng tác viên cùng NanoBio';

  static const introduction =
      'Bạn tham gia với vai trò giới thiệu đúng thông tin về NanoBio. '
      'Đây không phải cam kết việc làm hay cam kết thu nhập.';

  static const sections = <SaleTermsSection>[
    SaleTermsSection(
      title: '1. Cách ghi nhận kết quả',
      body:
          'Chỉ thành viên đang có gói Plus hoặc FamilyPlus hợp lệ mới được gửi yêu cầu cộng tác viên. '
          'Điểm giao dịch cộng tác viên chỉ phát sinh từ thanh toán hợp lệ của khách trực tiếp, tính 10% theo giá niêm yết của chủ gói.',
    ),
    SaleTermsSection(
      title: '2. Thông tin phải trung thực',
      body:
          'Bạn không được cam kết kết quả sức khỏe, thu nhập, ưu đãi hoặc quyền lợi khác ngoài nội dung NanoBio đã công bố. '
          'Không dùng tên, hình ảnh, dữ liệu khách hàng hoặc mã giới thiệu để gây hiểu nhầm.',
    ),
    SaleTermsSection(
      title: '3. Bảo vệ khách hàng và dữ liệu',
      body:
          'Chỉ chia sẻ mã giới thiệu của chính bạn. Mã chỉ được gắn khi đăng ký tài khoản và có thể bị chặn khi trùng email, số điện thoại, thiết bị hoặc lịch sử thanh toán. '
          'Không gửi tin nhắn rác, quấy rối hoặc liên hệ ngoài sự đồng ý của người nhận.',
    ),
    SaleTermsSection(
      title: '4. Điều kiện đối soát',
      body:
          'Điểm giao dịch cộng tác viên hiển thị ngay sau khi thanh toán được duyệt nhưng chỉ khả dụng sau 24 giờ. '
          'Nếu hoàn tiền, hủy đơn hoặc tranh chấp, điểm giao dịch bị trừ ngay và có thể làm số dư âm.',
    ),
    SaleTermsSection(
      title: '5. Quyền quản lý của NanoBio',
      body:
          'Bạn cần cập nhật số căn cước công dân và tài khoản ngân hàng trước khi vào bảng điều khiển hoặc rút tiền. '
          'Điểm giao dịch cộng tác viên được quy đổi 1 điểm = 1 VND theo cấu hình của quản trị viên; điểm thưởng chăm sóc chỉ dùng cho ưu đãi và không rút tiền. '
          'NanoBio có thể tạm dừng hoặc đóng quyền cộng tác viên khi phát hiện dấu hiệu gian lận, giả mạo, vi phạm chính sách hoặc yêu cầu của pháp luật. '
          'Các điều khoản có thể được cập nhật; phiên bản mới sẽ được hiển thị trước khi bạn tiếp tục sử dụng.',
    ),
  ];

  static const bullets = <String>[
    'Chỉ thành viên Plus hoặc FamilyPlus được đăng ký làm cộng tác viên.',
    'Hoa hồng cộng tác viên bằng 10% giá niêm yết của chủ gói.',
    'Điểm giao dịch được giữ 24 giờ trước khi quy đổi 1 điểm = 1 VND.',
    'Không cam kết thu nhập, không trả thưởng vì tuyển người.',
    'Cần căn cước công dân và tài khoản ngân hàng trước khi vào bảng điều khiển hoặc rút tiền.',
    'Số liệu và điểm cộng tác viên có thể được điều chỉnh theo giao dịch hoàn tiền, tranh chấp hoặc vi phạm.',
  ];
}

class SaleTermsSection {
  final String title;
  final String body;

  const SaleTermsSection({required this.title, required this.body});
}
