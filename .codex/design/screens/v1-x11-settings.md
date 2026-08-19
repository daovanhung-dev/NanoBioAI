# V1-X11 — Settings / Của bạn

> Baseline audit: `daovanhung-dev/NanoBioAI` @ `30587ab9b04d95aa621e5412502aafd0d0ca4827`  
> Classification: **source-sub-surface** · Group: `05_profile_settings` · Archetype: `settings-hub`

## Purpose

Cung cấp một điểm tập trung để người dùng quản lý hồ sơ, tài khoản, lịch sinh hoạt, quyền riêng tư, đồng bộ, cỡ chữ, hiệu ứng và các lựa chọn ứng dụng.

## Entry

`MainNavigationPage` tab **Của bạn**. Đây là logical surface trong `/menu`, không phải route độc lập.

## UX contract

- Hiển thị dữ liệu thật từ provider hiện hữu; không tạo trạng thái thành công giả khi refresh thất bại.
- Các mutation quan trọng phải có loading/disabled/error feedback phù hợp.
- Guest và authenticated state phải phân biệt rõ.
- Cỡ chữ, motion, sound/haptic và dark mode phải dùng các controller/tokens hiện có.
- Internal implementation terms không xuất hiện trong consumer copy.
- Các card/CTA phải chịu được compact width và text scale tăng.

## Refresh states

Refresh toàn màn phải aggregate kết quả. Nếu một nguồn phụ thất bại, giữ dữ liệu hiện có và báo trạng thái chưa cập nhật đầy đủ; chỉ phát success khi các nguồn bắt buộc đã hoàn tất.

## Accessibility

Touch target tối thiểu 48dp khi thực tế, hỗ trợ text scale lớn, tooltip cho icon-only control và không dùng màu làm tín hiệu duy nhất.
