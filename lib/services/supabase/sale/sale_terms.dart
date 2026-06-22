/// Versioned Sale terms shown before a user accepts the Sale role.
///
/// The text is a product-facing consent summary. Legal/business owners must
/// review and publish the final contract before any production payout starts.
class SaleTerms {
  const SaleTerms._();

  static const currentVersion = '2026-06-22';

  static const title = 'Điều lệ tham gia Sale cùng Nami';

  static const introduction =
      'Bạn tham gia với vai trò giới thiệu đúng thông tin về Nami. '
      'Đây không phải cam kết việc làm hay cam kết thu nhập.';

  static const sections = <SaleTermsSection>[
    SaleTermsSection(
      title: '1. Cách ghi nhận kết quả',
      body:
          'Hoa hồng chỉ có thể phát sinh từ giao dịch thanh toán hợp lệ do hệ thống xác nhận. '
          'Không có hoa hồng cho việc tuyển người, nạp tiền hộ, hay tạo giao dịch không đúng thực tế.',
    ),
    SaleTermsSection(
      title: '2. Thông tin phải trung thực',
      body:
          'Bạn không được cam kết kết quả sức khỏe, thu nhập, ưu đãi hoặc quyền lợi khác ngoài nội dung Nami đã công bố. '
          'Không dùng tên, hình ảnh, dữ liệu khách hàng hoặc mã giới thiệu để gây hiểu nhầm.',
    ),
    SaleTermsSection(
      title: '3. Bảo vệ khách hàng và dữ liệu',
      body:
          'Chỉ chia sẻ mã giới thiệu của chính bạn. Không yêu cầu mật khẩu, mã OTP, dữ liệu sức khỏe hay thông tin thanh toán của khách hàng. '
          'Không spam, quấy rối hoặc liên hệ ngoài sự đồng ý của người nhận.',
    ),
    SaleTermsSection(
      title: '4. Điều kiện đối soát',
      body:
          'Bảng tổng quan là dữ liệu tham khảo theo thời điểm. Hoa hồng có thể chờ duyệt, bị điều chỉnh hoặc đảo ngược khi giao dịch hoàn tiền, bị hủy, có tranh chấp hoặc vi phạm điều lệ.',
    ),
    SaleTermsSection(
      title: '5. Quyền quản lý của Nami',
      body:
          'Nami có thể tạm khóa hoặc đóng quyền Sale khi phát hiện dấu hiệu gian lận, giả mạo, vi phạm chính sách hoặc yêu cầu của pháp luật. '
          'Các điều khoản có thể được cập nhật; phiên bản mới sẽ được hiển thị trước khi bạn tiếp tục sử dụng.',
    ),
  ];

  static const bullets = <String>[
    'Chỉ ghi nhận khi thanh toán hợp lệ được hệ thống xác nhận.',
    'Không cam kết thu nhập, không trả thưởng vì tuyển người.',
    'Không thu thập mật khẩu, OTP, dữ liệu sức khỏe hoặc thông tin thanh toán của khách hàng.',
    'Số liệu và hoa hồng có thể được điều chỉnh theo giao dịch hoàn tiền, tranh chấp hoặc vi phạm.',
  ];
}

class SaleTermsSection {
  final String title;
  final String body;

  const SaleTermsSection({required this.title, required this.body});
}
