# 01 - Bản đồ tài liệu và truy vết BD

## 1. Cấu trúc thư mục

```text
docs/DD/authentication/
├── 00_READ_FIRST.md
├── 01_DOCUMENT_MAP.md
├── 02_MODULE_OVERVIEW.md
├── 03_DATA_MODEL_RLS_AND_MIGRATIONS.md
├── 04_FEATURE_REGISTRATION.md
├── 05_FEATURE_PROFILE_BOOTSTRAP.md
├── 06_FEATURE_MANUAL_ACCOUNT_CREATION.md
├── 07_FEATURE_EMAIL_VERIFICATION.md
├── 08_FEATURE_LOGIN_SESSION_AUTH_GATE.md
├── 09_FEATURE_ONBOARDING_COMPLETION.md
├── 10_FEATURE_PROFILE_UPDATE.md
├── 11_FEATURE_PASSWORD_RECOVERY_AND_CHANGE.md
├── 12_FEATURE_LOGOUT_AND_ACCOUNT_DELETION.md
├── 13_ERROR_HANDLING_AND_DATA_RECOVERY.md
├── 14_FLUTTER_LAYER_CONTRACTS.md
├── 15_TEST_ACCEPTANCE_AND_TRACEABILITY.md
├── 16_IMPLEMENTATION_ORDER.md
├── database/
├── guides/
├── templates/
└── references/
```

## 2. Mapping từ BD sang DD

| BD requirement | DD chính | DD phụ thuộc |
|---|---|---|
| AUTH-FR-01 Đăng ký email/mật khẩu | `04_FEATURE_REGISTRATION.md` | 03, 05, 07, 14 |
| AUTH-FR-02 Khởi tạo profile tự động | `05_FEATURE_PROFILE_BOOTSTRAP.md` | 03, database |
| AUTH-FR-03 Tạo thủ công Dashboard | `06_FEATURE_MANUAL_ACCOUNT_CREATION.md` | 05, 13 |
| AUTH-FR-04 Xác thực email | `07_FEATURE_EMAIL_VERIFICATION.md` | 04, 08 |
| AUTH-FR-05 Đăng nhập | `08_FEATURE_LOGIN_SESSION_AUTH_GATE.md` | 03, 07, 14 |
| AUTH-FR-06 Khôi phục session | `08_FEATURE_LOGIN_SESSION_AUTH_GATE.md` | 13, 14 |
| AUTH-FR-07 Hoàn thành onboarding | `09_FEATURE_ONBOARDING_COMPLETION.md` | 03, 10, 14 |
| AUTH-FR-08 Cập nhật profile | `10_FEATURE_PROFILE_UPDATE.md` | 03, 14 |
| AUTH-FR-09 Quên/đổi mật khẩu | `11_FEATURE_PASSWORD_RECOVERY_AND_CHANGE.md` | 14 |
| AUTH-FR-10 Đăng xuất | `12_FEATURE_LOGOUT_AND_ACCOUNT_DELETION.md` | 14 |
| AUTH-FR-11 Xóa account | `12_FEATURE_LOGOUT_AND_ACCOUNT_DELETION.md` | 03, 13 |
| AUTH-FR-12 Lỗi/backfill | `13_ERROR_HANDLING_AND_DATA_RECOVERY.md` | 03, database |

## 3. Quy ước tên tài liệu

- `DD-AUTH-MOD-*`: thiết kế cấp module.
- `DD-AUTH-DB-*`: thiết kế database/migration/RLS.
- `DD-AUTH-FR-*`: thiết kế feature tương ứng Business Requirement.
- `DD-AUTH-CTR-*`: hợp đồng/controller/route Flutter.
- `DD-AUTH-TEST-*`: tiêu chí kiểm thử và traceability.

Mỗi DD mới phải ghi mã, trạng thái, owner, ngày cập nhật, BD nguồn và dependency. Không tạo file “tổng hợp mơ hồ” trùng nội dung của DD đã tồn tại.
