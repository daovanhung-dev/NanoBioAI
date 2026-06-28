/// Versioned Sale terms shown before a user requests the Sale role.
///
/// This is product-facing consent copy. Legal/business owners must review the
/// final contract before any production payout starts.
class SaleTerms {
  const SaleTerms._();

  static const currentVersion = '2026-06-22';

  static const title = 'Dieu le tham gia Sale cung NanoBio';

  static const introduction =
      'Ban tham gia voi vai tro gioi thieu dung thong tin ve NanoBio. '
      'Day khong phai cam ket viec lam hay cam ket thu nhap.';

  static const sections = <SaleTermsSection>[
    SaleTermsSection(
      title: '1. Cach ghi nhan ket qua',
      body:
          'Diem Sale chi co the phat sinh tu giao dich thanh toan hop le do he thong tin cay xac nhan. '
          'Khong co diem cho viec tuyen nguoi, nap tien ho, hay tao giao dich khong dung thuc te.',
    ),
    SaleTermsSection(
      title: '2. Thong tin phai trung thuc',
      body:
          'Ban khong duoc cam ket ket qua suc khoe, thu nhap, uu dai hoac quyen loi khac ngoai noi dung NanoBio da cong bo. '
          'Khong dung ten, hinh anh, du lieu khach hang hoac ma gioi thieu de gay hieu nham.',
    ),
    SaleTermsSection(
      title: '3. Bao ve khach hang va du lieu',
      body:
          'Chi chia se ma gioi thieu cua chinh ban. Khong yeu cau mat khau, OTP, du lieu suc khoe hay thong tin thanh toan cua khach hang. '
          'Khong spam, quay roi hoac lien he ngoai su dong y cua nguoi nhan.',
    ),
    SaleTermsSection(
      title: '4. Dieu kien doi soat',
      body:
          'Bang tong quan la du lieu tham khao theo thoi diem. Diem Sale co the cho duyet, bi dieu chinh hoac dao nguoc khi giao dich hoan tien, bi huy, co tranh chap hoac vi pham dieu le.',
    ),
    SaleTermsSection(
      title: '5. Quyen quan ly cua NanoBio',
      body:
          'NanoBio co the tam dung hoac dong quyen Sale khi phat hien dau hieu gian lan, gia mao, vi pham chinh sach hoac yeu cau cua phap luat. '
          'Cac dieu khoan co the duoc cap nhat; phien ban moi se duoc hien thi truoc khi ban tiep tuc su dung.',
    ),
  ];

  static const bullets = <String>[
    'Chi ghi nhan khi thanh toan hop le duoc he thong tin cay xac nhan.',
    'Khong cam ket thu nhap, khong tra thuong vi tuyen nguoi.',
    'Khong thu thap mat khau, OTP, du lieu suc khoe hoac thong tin thanh toan cua khach hang.',
    'So lieu va diem Sale co the duoc dieu chinh theo giao dich hoan tien, tranh chap hoac vi pham.',
  ];
}

class SaleTermsSection {
  final String title;
  final String body;

  const SaleTermsSection({required this.title, required this.body});
}
