Commit de xuat: docs(test): ghi nhan kiem tra live 95 API backend

# Kiểm tra live API backend

## Phạm vi và môi trường

- Ngày chạy: 2026-10-31 (Asia/Ho_Chi_Minh).
- Đích: backend đang chạy trên `100.86.238.91`, truy cập qua SSH tunnel tới loopback API.
- Danh sách đối chiếu: `docs/backend/listapi.md`.
- Kết quả từng route: [`docs/backend/result.md`](../../backend/result.md).
- Không sửa source, cấu hình, feature flag hoặc migration trên server.

## Kết quả

- Đã gọi tuần tự đủ 95/95 operation; không thiếu và không trùng endpoint.
- 84 API `Sống`, 11 API `Chết` với mã HTTP/business code và nguyên nhân được ghi ở báo cáo; không còn dòng chưa test.
- OpenAPI live có 85 path và 95 operation, khớp method/path trong danh sách local.
- Các route tạo/đọc/cập nhật/xóa đã dùng actor và bản ghi tổng hợp riêng. Payment thử dùng payment event riêng. File và FamilyPlus được xóa sau khi thử.
- Sleep Safety verification và dispatch chỉ gọi nhánh an toàn; không phát SMS/cuộc gọi. Callback webhook dùng token sai trên event tổng hợp, không cập nhật event thật.
- Tất cả actor/bản ghi seed được xóa sau lượt gọi; hai actor sạch được xóa qua API, các seed còn lại được xóa bằng service account. Kiểm tra cuối cho các ID theo dõi trả 0 bản ghi còn lại.

## API chết

| Endpoint | Kết quả |
|---|---|
| `POST /api/v1/food/scan/analyze` | `503 FEATURE_NOT_ENABLED`; vision feature flag đang tắt. |
| `POST /api/v1/early-access` | `503 REGISTRATION_UNAVAILABLE`; server không chấp nhận đăng ký với cấu hình rate-limit/HMAC/client-context hiện có. |
| `POST /api/v1/payments/google-play/verify` | `503 PAYMENT_PROVIDER_UNAVAILABLE`; cấu hình provider Google Play chưa sẵn sàng. |
| `POST /api/v1/sleep-safety/contacts/verification` | `503 SLEEP_SAFETY_DISABLED`; feature đang tắt. Không gửi SMS. |
| `POST /api/v1/sleep-safety/dispatch` | `503 SLEEP_SAFETY_DISABLED`; feature đang tắt. Không gửi SMS hoặc gọi điện. |
| `POST /api/v1/webhooks/sleep-safety/{provider}` | `401 INVALID_CALLBACK_TOKEN`; callback token không được chấp nhận và webhook secret chưa cấu hình. |
| `POST /api/v1/payments/membership-requests` | `503 MEMBERSHIP_PAYMENT_NOT_CONFIGURED`; thiếu cấu hình giá gói/ngân hàng. |
| `POST /api/v1/sale/conversions` | `409 SALE_CONVERSION_DISABLED`; conversion đang tắt theo cấu hình. |
| `POST /api/v1/schedule-rewards/eligibilities` | `500 INTERNAL_SERVER_ERROR`; schema PostgreSQL live thiếu bảng `schedule_reward_registrations`. |
| `POST /api/v1/schedule-rewards/health-checkins` | `500 INTERNAL_SERVER_ERROR`; schema PostgreSQL live thiếu bảng `schedule_health_checkins`. |
| `POST /api/v1/schedule-rewards/health-checkins/undo` | `500 UndefinedTable`; schema PostgreSQL live thiếu bảng `schedule_health_checkins`. |

## Giới hạn bằng chứng

- Thư mục server không có Git metadata để đọc revision. SHA-256 cây source server là `ee7922119ab0592265e2127a9a288f21c76885d12054af27e50aba2a2012b6b5`; cây source local là `4e915156f129a81120b2f0bb018762e0e7d3aa433e94b70dc71603b9a11a6a01`. Hai fingerprint khác nhau; kết quả ở đây xác nhận hành vi server đang chạy và OpenAPI live, không khẳng định server chạy đúng snapshot local.
- Các route schedule completion/proof trả guard `404` đúng contract với attempt không tồn tại do thiếu bảng đăng ký eligibility; các guard này được đánh dấu `Sống`. Route đăng ký eligibility và hai route health-checkin bị đánh dấu `Chết` theo lỗi schema nêu trên.
