Commit de xuat: docs(test): khoi tao campaign full-project-2026-07-28

# Campaign acceptance toàn bộ NanoBio — 2026-07-28

## Mục đích

Thư mục này là nơi ghi bằng chứng mới cho đợt nghiệm thu toàn dự án trên máy
Android thật. Campaign bao phủ bốn Business Design (BD) hiện hành, 37 persona
fixture sandbox và các chuỗi actor/target cần thiết. Nó không tái sử dụng ảnh,
kết quả PASS hay dữ liệu thực thi của campaign cũ.

Đây là bộ khung lập kế hoạch, **không phải kết quả kiểm thử**. Tại thời điểm
khởi tạo chưa có case evidence, screenshot hoặc finding nào được xác nhận.

## Nguồn và phạm vi

- Product Flow M01–M19: `docs/BD/project_flow/BD_BioAI_Product_Flow_Sale_Admin_v2.0.md`.
- Advanced Health M20–M29: `docs/BD/advanced_health/BD_BioAI_Advanced_Health_Features_v1.0.md`.
- Wellness Rewards: `docs/BD/wellness_rewards/BD_BioAI_Daily_Proof_Wellness_Rewards_v1.0.md`.
- Nabi M30: `docs/BD/notification_Nabi/BD_thong_bao_nut_noi_Nabi.md`.
- Persona fixture sandbox: `docs/supabase/19-dev-sandbox-accounts.md`.

Mọi đăng nhập fixture chỉ được dùng trên sandbox đã được xác nhận. Tài liệu
campaign dùng alias persona thay vì email, mật khẩu, token hoặc định danh thật.
Alias được đối chiếu một-một với tài liệu fixture ở trên.

## Cấu trúc

- `001-test-full-project-2026-07-28.md`: ma trận kế hoạch và truy vết chính;
  đây là nơi duy nhất chứa trạng thái lập kế hoạch ban đầu.
- `cases/`: một Markdown bằng chứng sau khi thực thi cho từng case.
- `assets/`: PNG mới đã kiểm tra/redact của các trạng thái thấy được.
- `technical/`: tóm tắt evidence kỹ thuật đã redact cho case backend/RLS/race.
- `findings/`: ghi nhận bug logic, nghiệp vụ, UI hoặc UX được xác minh.

## Quy tắc thực thi và đóng case

- Dùng build thống nhất từ `lib/main.dart` trên Android thật; ghi device, build,
  command ID và reset sandbox/app-data vào evidence case.
- Cần ảnh PNG mới, đã xem và redaction, cho mọi trạng thái người dùng nhìn thấy.
  Evidence kỹ thuật an toàn được thêm cho RLS, race, ledger, retry và backend;
  không đưa secret, JWT, mật khẩu, dữ liệu sức khỏe hoặc payload hệ thống vào
  Markdown/ảnh.
- Chỉ xóa dữ liệu của `com.example.nano_app` giữa các persona độc lập. Giữ state
  riêng cho chuỗi Guest → đăng ký → đồng bộ cần kiểm thử.
- Sau khi chạy, một case phải được đóng là `PASS`, `FAIL`, `N/A`, `GAP` hoặc
  `BLOCKED`, kèm lý do và artifacts. Không được để trạng thái lập kế hoạch ở
  trong ma trận khi campaign kết thúc.
- `N/A`/`GAP` chỉ dùng khi có căn cứ BD rõ ràng; không dùng để che failure, build
  blocker, fixture thiếu hoặc evidence chưa đủ.
- Bug được ghi trong `findings/` và liên kết đến case; campaign này không tự sửa
  code sản phẩm.

## Quy tắc Advanced Health M20–M29

BD Advanced Health đang ở trạng thái **Draft — UI catalog shell approved**.
Kiểm thử bề mặt đã duyệt gồm đủ mười card, thứ tự, nhãn gói, điều hướng
placeholder, copy/accessibility và không có side effect. Các nghiệp vụ record,
AI, persistence, permission và clinical workflow chưa được triển khai không
được đánh dấu là bug chỉ vì vắng mặt.

Sau khi xác minh, case nghiệp vụ Draft có thể đóng `N/A` hoặc `GAP` **chỉ khi**
evidence nêu module/AC/BR BD, gate Draft và lý do cụ thể. Không được suy diễn
`PASS` cho nghiệp vụ Draft từ việc placeholder mở được.

## Quy tắc oracle Nabi M30

Khi BD Nabi dùng thuật ngữ gói hoặc quota cũ, oracle nghiệp vụ của campaign là
Product Flow hiện hành: Free/Plus/FamilyPlus và quota hiện hành. Khác biệt từ
thuật ngữ VIP/VIP năm hoặc quota cũ trong BD Nabi được ghi là **gap tài liệu**,
không tự động là lỗi app. Trigger, suppression, ưu tiên, cooldown, CTA,
deep-link, offline/retry, accessibility và analytics vẫn phải được kiểm thử
theo các ID Nabi và acceptance của BD Nabi.

## Format evidence từng case

Mỗi file mới trong `cases/` phải bắt đầu bằng YAML front matter sau. Đây là
template, không phải evidence đã thực thi:

```yaml
---
case_id: PF-001
status: PASS # PASS | FAIL | N/A | GAP | BLOCKED
command_id: CMD-YYYYMMDD-001
actual_result: "Tóm tắt kết quả quan sát, không chứa dữ liệu nhạy cảm."
artifacts:
  - assets/PF-001--surface--YYYYMMDD-HHMMSS.png
  - technical/PF-001--safe-summary.md
---
```

Với `N/A` hoặc `GAP`, thêm `rationale` trong front matter, nêu chính xác
reference BD và lý do. Sau front matter phải có persona, precondition, bước,
expected/actual, reference BD/AC/BR, thiết bị/build, reset, evidence an toàn và
liên kết finding (nếu có). Xem template chi tiết tại `cases/README.md`.

## Tiêu chí hoàn tất campaign

- Mọi dòng ma trận được đóng bằng trạng thái hợp lệ có evidence hoặc rationale.
- Mỗi một trong 37 persona có ít nhất một case bề mặt/quyền phù hợp.
- Mọi trạng thái thấy được có PNG mới, được kiểm tra/redact; technical cases có
  evidence kỹ thuật tối thiểu cần thiết.
- Báo cáo cuối không tuyên bố toàn bộ PASS nếu còn finding, blocker, sandbox
  failure hoặc gap tài liệu.
