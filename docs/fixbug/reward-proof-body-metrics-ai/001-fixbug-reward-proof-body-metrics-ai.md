Commit de xuat: fix(rewards): bat buoc anh minh chung gan voi diem va ca nhan hoa Body Metrics AI

# Fixbug - Proof reward invariant và personalized Body Metrics AI

## Phạm vi

### Reward proof

Luồng cũ cho phép `capture proof -> complete -> 0 points` qua nhánh “tiếp tục không nhận điểm”. Bản vá loại bỏ nhánh này ở cả `Lifestyle Schedule` và `Today Tasks`.

Luồng mới:

```text
begin_my_schedule_completion
  -> camera proof
  -> persist local proof + trusted attempt IDs
  -> upload private object
  -> finalize_my_schedule_completion
  -> points_delta > 0
```

- Camera chỉ mở sau khi server tạo reward attempt hợp lệ.
- Nếu người dùng hủy camera, nhiệm vụ không hoàn thành và không có điểm.
- Nếu upload/finalize lỗi tạm thời sau khi ảnh đã được chụp, proof giữ trạng thái pending để reconcile.
- Finalize phải trả `pointsDelta > 0`; client không tự cộng điểm local.
- Retry/finalize/undo tiếp tục dùng idempotency key server-owned hiện có.

### Supabase

- Rebuild source giữ `wellness_rewards_rollout.enabled = false` theo release guardrail; bản vá không tự bật reward trong destructive rebuild.
- `finalize_my_schedule_completion` cho phép object proof của một attempt đã bắt đầu trong completion window được upload/reconcile trong grace tối đa 24 giờ.
- `27-wellness-rewards-runtime-fix.sql` là migration opt-in: chỉ khi được apply có chủ đích sau sandbox/device acceptance mới xuất một config version active mới; không sửa lịch sử config cũ.
- Với môi trường Supabase hiện hữu: apply bản `16-wellness-rewards.sql` đã cập nhật trước, sau đó apply migration `27-wellness-rewards-runtime-fix.sql` trong sandbox.

## Body Metrics

`BodyMetricsPage` chuyển từ form nhập tay thuần túy sang flow cá nhân hóa:

```text
Page
  -> Provider
  -> Repository
  -> Local Datasource
  -> profile + latest tracking + meal plan + lifestyle schedule
```

- Prefill chiều cao/cân nặng/tuổi/giới tính/mức vận động từ dữ liệu thật nếu có.
- Cân nặng tracking mới hơn profile được ưu tiên.
- Chỉ tính ngày thực đơn có ít nhất ba meal rows để tránh xem một ngày thiếu bữa là một ngày đầy đủ.
- BMI/BMR/RMR/TDEE/hydration vẫn do `BasicHealthCalculator` M04 tính deterministic.
- Kịch bản 30 ngày chỉ phân loại xu hướng năng lượng dựa trên average planned calories so với TDEE và coverage của lịch trình.
- AI nhận các metric app-owned đã tính, nhưng output bị cấm sinh chữ số mới, chẩn đoán, điều trị, kê thuốc hoặc cam kết kết quả.
- Thiếu dữ liệu kế hoạch thì không gọi AI.
- UI thông báo trước nút phân tích rằng thao tác sẽ gửi các chỉ số wellness tổng hợp/bối cảnh kế hoạch tới AI; không gửi ảnh minh chứng hoặc nhật ký thô.

## Giới hạn an toàn

- Không sinh cân nặng/body-fat/bệnh lý dự đoán sau 30 ngày khi chưa có công thức/clinical contract được phê duyệt.
- AI chỉ diễn giải xu hướng wellness; số liệu app-owned hiển thị ở UI riêng.
- Không log raw prompt, raw Gemini response hoặc health profile.
- Thay đổi source Supabase chưa đồng nghĩa đã deploy vào sandbox/production.
