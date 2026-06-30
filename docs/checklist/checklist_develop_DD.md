Commit de xuat: docs(checklist): ghi nhan chuc nang DD chua coding

# Checklist develop DD

**Nguon DD da doc:** `docs/DD/product_flow/` (17 file)
**Ngay cap nhat:** 2026-06-30
**Pham vi:** doi chieu DD Product Flow / Membership / Sale voi source hien co trong `lib/`, `docs/supabase/`, `test/`.

## Ghi chu

- `docs/DD/authentication/*` dang khong co trong working tree hien tai, trong khi product-flow DD van tham chieu folder nay nhu dependency.
- `Chua coding` nghia la chua thay implementation app/backend hoan chinh theo DD. Mot so muc da co scaffold hoac SQL draft, nhung chua duoc wire thanh chuc nang.

## Chuc nang chua duoc coding theo DD

| # | Nhom chuc nang | DD lien quan | Trang thai coding | Note ngan |
|---:|---|---|---|---|
| 1 | Guest sinh lich trinh AI lan dau sau onboarding | 04, 12 | Runtime local da coding | `GeneratedPlanService.generateInitialGuestPlan` cho guest khong can auth, request ledger ghi success va onboarding chi completed sau khi sinh lich thanh cong. |
| 2 | Chan Guest tao lai lich trinh lan 2 theo Q-01 | 04 | Runtime local da coding | SQLite v10 co `guest_initial_plan_used` va request ledger; guest tao request moi sau lan dau bi chan truoc AI, retry cung request dung ket qua cu. |
| 3 | V1 allowlist route/use-case cho Guest | 04, 14 | Coding mot phan | AI chat/nutrition/profile co auth guard; dashboard guard dang comment, community va mot so route/use-case chua co guard theo implementation evidence backlog. |
| 4 | Effective access Free/Plus/FamilyPlus va Sale axis doc lap | 05 | Chua coding hoan chinh | Auth doc `subscription_tier`, nhung chua co domain effective access/gate; source `membership_entitlement` dang khong ton tai. |
| 5 | Free quota AI Chat 3 luot/ngay | 06 | Chua coding | `usage_quota` chi la planned placeholder; chua thay repository/RPC/guard truoc AI chat. |
| 6 | Free quota tao lich trinh 3 lan/thang | 06 | App guard da coding, backend blocked | Member generation co `PersonalScheduleQuotaGateway` check truoc AI va chi commit sau transaction thanh cong; production adapter van blocked toi khi co trusted M06 RPC/RLS sandbox. |
| 7 | Health score theo completion history dung cong thuc DD | 07 | Runtime local draft da coding | `v2/health_scoring` co domain service, SQLite read model, provider, `/v2/health-score`, va tests cho cong thuc local draft; Q-14/Q-15 da chot trong DD; DD docs da approved; official implementation va evidence nam trong backlog. |
| 8 | Plus premium AI, goal roadmap, advanced tracking | 08 | Chua coding | `lib/app_versions/v3/features/*` la placeholder `status = planned`, chua co route/use-case/data layer that. |
| 9 | FamilyPlus member, family subject, family schedule | 09, 12 | Chua coding app | Co SQL draft family tables, nhung v3 family features chi la placeholder; chua co UI/repository/RLS smoke wired trong app. |
| 10 | FamilyPlus notification theo member/subject | 12 | Chua coding | Notification hien la local single-user/source item; chua co subject-aware family routing. |
| 11 | Sale/referral registration va referral code | 10 | Chua coding app | `lib/sale_referral` chi la placeholder; chua co repository/backend call/flow gan ma gioi thieu. |
| 12 | Sale dashboard/referral overview | 10, 11 | Chua coding app | Chi co placeholder `SaleDashboardFeature`, chua co page/provider/data source that. |
| 13 | Payment event va direct Sale commission | 11 | Chua coding app/backend runtime | DD docs da approved; legacy two-level commission is not implementation source; Flutter/backend integration va sandbox evidence nam trong backlog. |
| 14 | Supabase foundation deploy/verify cho membership/quota/family/sale | 03 | Chua xac nhan coding xong | DD docs da approved; sandbox/staging va acceptance/RLS checks pass nam trong backlog. |
| 15 | Product-flow test matrix TC-PF-01..38 | 15 | Chua coding day du | Khong thay test ID `TC-PF-*`; chi co test rieng le cho auth, notification, generated plan auth, architecture. |
| 16 | Error/security/privacy policy theo product-flow DD | 13, 14 | Coding mot phan | Co mot so rule/logger/architecture test, nhung chua co guard va test bao phu paid/quota/payment/referral/family theo DD. |
