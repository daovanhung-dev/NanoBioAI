# DD-PRODUCT-FLOW-MOD-001 - Tổng quan Product Flow / Membership / Sale

**BD nguồn:** `BD-BIOAI-PRODUCT-FLOW-001`  
**Status:** Draft  
**Dependencies:** `docs/supabase/*`, `docs/DD/authentication/*`, `.codex/playbooks/access_membership_referral.md`  

## 1. Mục tiêu

Chuẩn hóa thiết kế kỹ thuật cho luồng "trải nghiệm trước, đăng nhập để mở rộng, nâng cấp gói để dùng sâu hơn, Sale là lớp quyền độc lập" của NanoBio/BioAI.

## 2. Scope / Out of scope

- In scope: Guest/V1 allowlist, Free/V2 membership gate và quota, Plus/FamilyPlus planned V3, health score theo lịch trình AI, notification theo lịch trình, Sale/referral/commission 2 tầng, Supabase là source of truth.
- Out of scope: giá gói, chu kỳ billing chi tiết, refund/chargeback/payout thực tế, công thức điểm cuối cùng, chính sách consent FamilyPlus chi tiết, thuật toán y tế nâng cao.

## 3. Actors và thành phần

| Actor/component | Responsibility | Boundary |
|---|---|---|
| Guest | Onboarding, sinh lịch trình lần đầu, dùng V1 allowlist | Không mở AI Chat, score Free, Plus, FamilyPlus, Sale dashboard nếu chưa đăng nhập/quyền |
| Member Free | Dùng V2, AI Chat và sinh lịch trình theo quota | Quota phải kiểm tra trước khi gọi AI |
| Member Plus | Kế thừa Free, mở planned advanced capabilities | Không tự mở FamilyPlus data boundary |
| Member FamilyPlus | Quản lý nhiều health subjects trong family | Chỉ trong nhóm gia đình được server xác nhận |
| Sale | Dùng referral code, xem hoa hồng liên quan | Không phải membership tier |
| Flutter app | UI, state, route, local cache/offline experience | Không chứa secret hoặc quyết định quyền cao cấp |
| Supabase / trusted backend | Auth, membership, quota, Sale, payment, commission, RLS | Là source of truth cho quyền và tiền |

## 4. Kiến trúc / flow tổng quát

```text
Guest app open
-> onboarding
-> save local profile data
-> generate initial personal schedule once
-> save meal/task/schedule
-> schedule reminders
-> V1 allowlist only
-> login/signup
-> Supabase Auth + membership lookup
-> effective access + quota
-> Free/Plus/FamilyPlus/Sale feature boundary
```

## 5. Invariants / business rules

1. Guest/V1 là allowlist đóng, không phải Free.
2. Membership tier và Sale status là hai trục độc lập.
3. Quyền cao cấp và hoa hồng không được mở bằng local SQLite, route param, hidden UI state hoặc client flag.
4. Plus kế thừa Free; FamilyPlus kế thừa Plus; Sale không kế thừa membership.
5. Payment success là điều kiện duy nhất tạo commission, phải từ trusted source.
6. Các phần phụ thuộc Q-01..Q-10 giữ `Draft` cho đến khi PO xác nhận.

## 6. Data ownership và security

| Data | Owner | Permission | Notes |
|---|---|---|---|
| Onboarding/profile | User/health subject | Guest local; member Supabase by RLS | Guest sync sau đăng nhập phụ thuộc Q-02 |
| Meal/tasks/schedule | User/health subject | Subject owner/family allowed actor | Không bịa data cho dashboard |
| Membership/quota | Supabase/trusted backend | Client read own effective state | Client không ghi counter/subscription trực tiếp |
| Family data | Family owner/member by permission | RLS/backend controlled | Consent/member limit phụ thuộc Q-07 |
| Sale/referral/payment/commission | Trusted backend/admin/payment webhook | Client read related rows | Client không tự xác nhận payment |

## 7. Dependencies / integration points

- `docs/supabase/00-system-database-design.md` đến `09-dev-seed-membership-test-accounts.sql`.
- `docs/DD/authentication/*` cho auth/session/profile bootstrap.
- `lib/app_versions/v1/` cho Guest/basic flow.
- `lib/app_versions/v2/` cho authenticated Free layer.
- `lib/app_versions/v3/` cho planned Plus/FamilyPlus scaffold.
- `lib/sale_referral/` cho Sale/referral axis.

## 8. Acceptance / links to test

Xem `15_TEST_ACCEPTANCE_AND_TRACEABILITY.md`, đặc biệt TC-PF-01..TC-PF-25.

## 9. Open decisions

Q-01..Q-10 trong BD vẫn là blocker cho Ready status của các phần liên quan: chống tạo lịch trình Guest, sync Guest data, quota unit/reset, scoring formula, billing lifecycle, FamilyPlus consent/limits, Sale approval, anti-fraud/refund/payout.

