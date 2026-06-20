# Playbook - Access / Membership / Referral Sale

## Muc tieu

Dung playbook nay khi task lien quan auth gate, guest/basic access, membership tier, gioi han tinh nang, Supabase entitlement, referral sale, hoa hong, hoac route theo quyen.

## Access matrix

| Axis | Version/module | Duoc dung | Gioi han chinh |
| --- | --- | --- | --- |
| Guest / unauthenticated | `v1` | Onboarding, AI tao lich trinh ca nhan lan dau, module tinh toan suc khoe co ban, notification theo lich trinh | Chi tao lich trinh AI 1 lan ngay sau onboarding; muon tao them hoac dung tinh nang ngoai basic phai dang nhap |
| Free / authenticated | `v2` | Ke thua v1, AI chat, tao lich trinh moi, health score theo lich su lam lich trinh | AI chat 3 cau/ngay; tao lich trinh 3 lan/thang |
| Plus | `v3` planned | Ke thua free, lo trinh rieng theo muc tieu, module/tinh nang theo doi suc khoe cao hon | Chat AI khong gioi han; tao thuc don/lich trinh khong gioi han |
| FamilyPlus | `v3` planned | Ke thua Plus, onboarding gia dinh, menu gia dinh, theo doi thanh vien, them thanh vien, xem/theo doi lich trinh cua nhau | Quyen xem/chinh sua phai theo family membership va role duoc server xac nhan |
| Sale/referral | module doc lap | Nguoi dung co the gioi thieu app va nhan hoa hong | Khong phai membership tier; khong tu ke thua v1/v2/v3 |

## Doc truoc

- `.codex/AGENTS.md`
- `.codex/PROJECT_MAP.md`
- BD/DD lien quan trong `docs/BD` va `docs/DD` neu coding/test/fix theo feature.
- Auth/access code: `lib/app_versions/v2/features/auth/`, `lib/services/supabase/`
- Router/access gate: `lib/app_versions/v1/router/`, `lib/app_versions/v2/router/`
- Guest schedule/basic flow: `lib/app_versions/v1/features/onboarding/`, `lib/app_versions/v1/services/ai/`, `lib/app_versions/v1/features/lifestyle_schedule/`, `lib/app_versions/v1/services/notifications/`
- Settings/profile hien membership: `lib/app_versions/v1/features/settings/`, `lib/app_versions/v1/features/profile/`

## Luong dung

```text
Guest onboarding
-> save local profile data
-> Gemini creates initial personal schedule once
-> local notifications and basic health modules
-> login/sign-up when user wants more
-> Supabase auth session
-> fetch membership tier and sale/referral status from trusted source
-> access gate enables free/Plus/FamilyPlus or sale features
```

## Membership rules

- Tier cao hon duoc ke thua tinh nang tier thap hon.
- Membership tier, sale status, referral tree, commission rule va usage quota phai den tu Supabase/server-side source hoac repository abstraction dang tin cay.
- Khong tin client, route param, local SQLite, SharedPreferences, metadata tu form, hoac UI hidden state de mo khoa paid/sale feature.
- Guest v1 khong duoc mo tinh nang ngoai basic neu chua dang nhap.
- Free v2 phai co quota ro cho AI chat va tao lich trinh; khi het quota, UI moi user dang nhap/nang cap bang copy Nami nhe nhang.
- Plus/FamilyPlus la planned v3; khong dua feature paid vao v1/v2 neu BD/DD chua yeu cau.

## Referral sale rules

- Sale la vai tro doc lap: mot user co 1 membership tier va co the co/khong co sale status.
- Tang 1: A gioi thieu B; khi B chuyen khoan thanh cong mua/renew goi, A nhan 10%.
- Tang 2: B dang ky sale va gioi thieu C; khi C chuyen khoan thanh cong mua/renew goi, B nhan 10% va A nhan 5%.
- Cay sale gioi han do sau 2 tang cho moi nhanh hoa hong; so nhanh cung tang khong gioi han.
- Hoa hong chi phat sinh tu giao dich thanh cong. Neu B khong con mua goi, A khong nhan hoa hong theo thang tu B; neu C van dong tien thanh cong, A van co the nhan 5% tu giao dich cua C theo rule tang 2.
- Khong tinh hoa hong tren du lieu client tu bao da thanh toan. Payment success phai den tu backend/webhook/trusted payment record.

## Guardrails

- Khong hard-code secret, service-role key, referral payout, hoac payment success trong Flutter.
- Khong log thong tin thanh toan, ma gioi thieu nhay cam, raw webhook, token, PII, ho so suc khoe chi tiet.
- UI user-facing khong noi `tier`, `entitlement`, `gate`, `commission tree`, `database`, `webhook`.
- Neu sua schema/quota/referral/payment: can migration, RLS/policy, repository/datasource, tests va manual ops docs rieng.
- Neu task chi la guest/basic flow, khong refactor auth/membership/referral.

## Tim nhanh

```bash
rg "membership|subscription|tier|entitlement|quota|limit|referral|commission|sale|FamilyPlus|Plus" lib docs .codex
rg "AuthGate|auth|session|onboarding_status|subscription_tier|referral_code" lib/app_versions lib/services test
rg "generate.*plan|GeneratedPlan|meal plan|lifestyle schedule|notification" lib/app_versions/v1 test
```

## Test nen chay

- Access/quota unit tests cho guest/free/Plus/FamilyPlus khi co logic.
- Auth route/access gate tests neu doi route.
- Repository/datasource contract tests cho membership/referral source.
- Payment/referral logic phai test bang fake trusted backend/webhook data, khong test dua vao client flag.
