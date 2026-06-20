Commit de xuat: docs(codex): cap nhat project flow theo access tier

# Worklog - Codex Project Flow

## Thoi gian

- Ngay: 2026-06-20
- Bat dau: Khoang 16:03
- Ket thuc: Khoang 16:04
- Timezone: Asia/Saigon

## Pham vi

- Loai task: docs/context update
- Module chinh: `.codex` project workflow
- Yeu cau goc: Cap nhat `.codex` de cac phien sau hieu flow moi: `v1` la guest/basic, `v2` la authenticated free, `v3` la Plus/FamilyPlus planned, sale/referral la vai tro doc lap.

## Da lam

- Cap nhat rule loi trong `.codex/AGENTS.md` ve version/access map, critical product flow moi va membership rules.
- Cap nhat `.codex/PROJECT_MAP.md` de dinh tuyen task access/membership/auth/referral sale va v3 planned.
- Cap nhat `.codex/workRule/develop.md` de chon version theo access tier thay vi mac dinh tao moi o `v2`.
- Tao playbook `.codex/playbooks/access_membership_referral.md` cho guest/free/Plus/FamilyPlus/sale, quota, referral sale va guardrails.
- Cap nhat nhe README, CHECKLIST va playbook onboarding/AI/notification/dashboard de tham chieu playbook access moi.

## File code/docs da sua

- `.codex/AGENTS.md` - sua - cap nhat flow san pham, access map va membership rules.
- `.codex/PROJECT_MAP.md` - sua - them routing cho access/membership/auth/referral sale va v3 planned.
- `.codex/workRule/develop.md` - sua - chon version theo access tier.
- `.codex/README.md` - sua - them access map va playbook moi vao context.
- `.codex/CHECKLIST.md` - sua - them checklist doc playbook access va guardrail membership/referral.
- `.codex/playbooks/access_membership_referral.md` - tao - playbook access, membership va referral sale.
- `.codex/playbooks/onboarding.md` - sua - nhac quota guest sau onboarding.
- `.codex/playbooks/ai_service.md` - sua - nhac quota AI theo tier.
- `.codex/playbooks/notification.md` - sua - nhac notification theo guest/basic va family gate.
- `.codex/playbooks/dashboard.md` - sua - nhac score theo lich su va membership scope.
- `docs/worklog/2026-06-20/005-worklog-codex-project-flow.md` - tao - ghi nhan phien docs/context update.

## Tai lieu lien quan

- Khong phat sinh feature/DD/test docs moi vi phien nay chi cap nhat `.codex`.

## Commands

- `rg "guest|free|Plus|FamilyPlus|sale|referral|v1|v2|v3" .codex`: PASS - tim thay access/version/referral rule moi trong `.codex`.
- ``rg "mặc định tạo chức năng mới ở `v2`|AuthGate chan Dashboard neu chua login" .codex``: PASS - khong con match; `rg` exit 1 vi khong tim thay chuoi cu.
- `git diff --check`: PASS - khong co whitespace error; Git chi canh bao line-ending LF se duoc thay bang CRLF khi Git cham file tren Windows.
- `dart format`, `flutter analyze`, `flutter test`: SKIPPED - khong sua runtime code.

## Loi/Rui ro

- Da fix: Context `.codex` cu chua phan biet ro guest/basic, authenticated free, paid tier va sale/referral.
- Chua fix: Chua cap nhat BD/DD/auth checklist cu vi ngoai scope theo plan.
- Can kiem tra tiep: Khi bat dau code membership/referral that, can tao BD/DD va chay test/ops rieng cho Supabase, quota, payment webhook va RLS.
