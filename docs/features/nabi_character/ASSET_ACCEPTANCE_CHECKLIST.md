# ASSET_ACCEPTANCE_CHECKLIST

- [x] 84 file PNG theo checklist: 8 core, 9 onboarding, 10 chat, 14 daily, 12 progress, 10 engagement, 11 system, 10 future.
- [x] Mỗi PNG dùng RGBA và có vùng alpha trong suốt.
- [x] Không có chữ/khung UI trong asset action.
- [x] Đường dẫn chia theo nhóm nghiệp vụ.
- [x] Có JSON manifest và YAML state matrix.
- [x] Có motion recipe để animate sau này.
- [x] Có context/persona và prompt Codex.
- [x] Có script kiểm tra tính toàn vẹn.

## Lưu ý chất lượng

Bộ ảnh là asset PNG tĩnh để tích hợp nhanh. Khi production cần animation xương/chuyển động mượt, giữ nguyên ID/path và thay layer implementation bằng Rive/Lottie hoặc sprite sequence; không đổi semantic state contract.
