/// Versioned Sale terms shown before a user requests the Sale role.
///
/// This is product-facing consent copy. Legal/business owners must review the
/// final contract before any production payout starts.
class SaleTerms {
  const SaleTerms._();

  static const currentVersion = '2026-06-29';

  static const title = 'Dieu le tham gia Sale cung NanoBio';

  static const introduction =
      'Ban tham gia voi vai tro gioi thieu dung thong tin ve NanoBio. '
      'Day khong phai cam ket viec lam hay cam ket thu nhap.';

  static const sections = <SaleTermsSection>[
    SaleTermsSection(
      title: '1. Cach ghi nhan ket qua',
      body:
          'Chi thanh vien dang co goi Plus hoac FamilyPlus hop le moi duoc gui yeu cau Sale. '
          'Diem giao dich Sale chi phat sinh tu thanh toan hop le cua khach truc tiep, tinh 10% theo gia niem yet cua chu goi.',
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
          'Chi chia se ma gioi thieu cua chinh ban. Ma chi duoc gan trong luc dang ky tai khoan va co the bi chan khi trung email, so dien thoai, thiet bi hoac lich su thanh toan. '
          'Khong spam, quay roi hoac lien he ngoai su dong y cua nguoi nhan.',
    ),
    SaleTermsSection(
      title: '4. Dieu kien doi soat',
      body:
          'Diem giao dich Sale hien thi ngay sau khi thanh toan duoc duyet nhung chi kha dung sau 24 gio. '
          'Neu hoan tien, huy don hoac tranh chap, diem giao dich Sale bi tru ngay va co the lam so du am.',
    ),
    SaleTermsSection(
      title: '5. Quyen quan ly cua NanoBio',
      body:
          'Ban can cap nhat so can cuoc cong dan va tai khoan ngan hang truoc khi vao dashboard hoac rut tien. '
          'Diem giao dich Sale duoc quy doi 1 diem = 1 VND theo cau hinh Admin; diem thuong chuyen can chi dung cho voucher va khong rut tien. '
          'NanoBio co the tam dung hoac dong quyen Sale khi phat hien dau hieu gian lan, gia mao, vi pham chinh sach hoac yeu cau cua phap luat. '
          'Cac dieu khoan co the duoc cap nhat; phien ban moi se duoc hien thi truoc khi ban tiep tuc su dung.',
    ),
  ];

  static const bullets = <String>[
    'Chi paid member Plus/FamilyPlus duoc dang ky Sale.',
    'Hoa hong Sale tinh 10% theo gia niem yet cua chu goi.',
    'Diem giao dich Sale giu 24 gio truoc khi quy doi 1 diem = 1 VND.',
    'Khong cam ket thu nhap, khong tra thuong vi tuyen nguoi.',
    'Can CCCD va tai khoan ngan hang truoc khi vao dashboard/rut tien.',
    'So lieu va diem Sale co the duoc dieu chinh theo giao dich hoan tien, tranh chap hoac vi pham.',
  ];
}

class SaleTermsSection {
  final String title;
  final String body;

  const SaleTermsSection({required this.title, required this.body});
}
