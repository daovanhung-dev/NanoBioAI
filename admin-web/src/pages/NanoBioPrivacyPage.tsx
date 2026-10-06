import { useEffect } from 'react';
import { Link } from 'react-router-dom';
import './nanobio/privacy.css';

export function NanoBioPrivacyPage() {
  useEffect(() => {
    const previousTitle = document.title;
    document.title = 'Quyền riêng tư | NanoBio';
    return () => { document.title = previousTitle; };
  }, []);

  return (
    <main className="nanobio-privacy-page">
      <article className="nb-policy">
        <Link className="nb-policy-back" to="/nanobio">← Quay lại NanoBio</Link>
        <span className="nb-policy-kicker">QUYỀN RIÊNG TƯ</span>
        <h1>Tải ứng dụng & ưu đãi Plus 30 ngày</h1>
        <p className="nb-policy-updated">Cập nhật: 07/10/2026</p>

        <section>
          <h2>1. Dữ liệu được ghi nhận</h2>
          <p>Khi bạn chủ động gửi đăng ký, NanoBio ghi nhận số điện thoại, nguồn đăng ký, phiên bản ứng dụng, trạng thái đồng ý, mã ưu đãi và thời điểm gửi. Để hiểu nguồn truy cập và hỗ trợ xử lý sự cố, hệ thống có thể lưu thông tin chiến dịch (UTM), đường dẫn giới thiệu đã loại phần truy vấn, trang đăng ký và thông tin trình duyệt.</p>
          <p>Hệ thống đăng ký không lưu địa chỉ IP nguyên bản trong dữ liệu lead. Một mã HMAC chỉ dùng để giới hạn yêu cầu được xóa trong vòng 24 giờ.</p>
        </section>

        <section>
          <h2>2. Mục đích sử dụng</h2>
          <ul>
            <li>Ghi nhận người dùng NanoBio Early Access và hỗ trợ cài đặt bản Android.</li>
            <li>Đối chiếu số điện thoại với tài khoản NanoBio để hỗ trợ ưu đãi Plus 30 ngày.</li>
            <li>Hiểu hiệu quả nguồn chiến dịch và khắc phục sự cố khi gửi đăng ký.</li>
          </ul>
        </section>

        <section>
          <h2>3. Ưu đãi Plus 30 ngày</h2>
          <p>“VIP 1 tháng” là tên ưu đãi trên website. Trong NanoBio, ưu đãi tương ứng với quyền lợi gói Plus trong 30 ngày, không tự động bao gồm quyền FamilyPlus. Việc kích hoạt được thực hiện qua quy trình hỗ trợ đáng tin cậy sau khi tài khoản được đối chiếu.</p>
        </section>

        <section>
          <h2>4. Lưu trữ và bảo mật</h2>
          <p>Thông tin đăng ký chỉ được dùng để hỗ trợ Early Access và quyền lợi đã thông báo. Website không công khai số điện thoại, không đưa số điện thoại vào URL và không gửi số điện thoại tới công cụ phân tích truy cập. Trình duyệt không có quyền xem hoặc chỉnh sửa dữ liệu đăng ký trực tiếp.</p>
          <p>Thông tin liên hệ được lưu trong thời gian cần thiết để hỗ trợ cài đặt và xử lý ưu đãi. Bạn có thể yêu cầu cập nhật hoặc xóa thông tin qua kênh hỗ trợ chính thức của NanoBio.</p>
        </section>

        <section>
          <h2>5. Dữ liệu sức khỏe</h2>
          <p>Website giới thiệu này không yêu cầu hồ sơ sức khỏe. Dữ liệu sức khỏe trong ứng dụng tuân theo chính sách và lựa chọn đồng ý riêng của sản phẩm.</p>
        </section>

        <section>
          <h2>6. Lưu ý y khoa</h2>
          <p>NanoBio/Nabi hỗ trợ theo dõi sức khỏe và xây dựng thói quen sống lành mạnh. Nội dung không phải chẩn đoán y khoa, không thay thế thăm khám, kê đơn hoặc tư vấn trực tiếp từ bác sĩ/chuyên gia có chuyên môn.</p>
        </section>
      </article>
    </main>
  );
}
