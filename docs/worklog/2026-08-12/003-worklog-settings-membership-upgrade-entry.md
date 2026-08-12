# Worklog — Settings membership upgrade entry

- Date: 2026-08-12
- Workflow: coding
- Primary domain: access / membership / referral
- UI surface: Settings
- Base commit: `dfc9ea312e3988e39e26634cef6dc56914593037`

## Pham vi

Them entry point nang cap goi trong Settings ma khong thay doi contract cap quyen hay Supabase:

- Guest: khong hien CTA thanh toan, giu luong dang nhap/dang ky.
- Free: hien `Nang cap Plus` va dieu huong bang canonical membership payment helper.
- Plus: hien `Nang cap FamilyPlus`.
- FamilyPlus: hien trang thai goi, khong tao CTA nang cap tiep.
- Loading/error/unknown: fail closed, khong tu suy dien la Free.
- Pull-to-refresh reload trusted `effectiveAccessProvider`.

## Thay doi

- Them `settings_membership_card.dart` theo Green Wellness tokens va feedback service hien co.
- `settings_page.dart` doc `effectiveAccessProvider`, map trusted plan sang presentation state, va dung `buildMembershipUpgradeRoute` cho navigation.
- Them widget/navigation tests cho Guest, Free, Plus, FamilyPlus, loading, error, unknown va refresh.
- Khong thay doi QR, gia, bank account, payment RPC, entitlement hoac Admin approval.

## Kiem chung

Runtime hien tai khong co `dart`/`flutter`, nen Flutter format/analyze/test chua the chay trong phien nay. Bundle co static patch validation va danh sach targeted commands de chay sau khi apply tren full checkout.

## Tu danh gia va toi uu phien sau

- Chat luong dau ra: tot - thay doi nho, fail-closed, tai su dung route contract va theme primitive hien co.
- Muc do hoan thanh task: source/test patch hoan thanh; Flutter runtime verification bi chan boi toolchain trong runtime.
- Bang chung kiem chung: context/design/source trace tren HEAD, patch idempotency/static sentinel checks trong bundle.
- Diem ton token/chua toi uu: Settings la file lon; lan sau uu tien source transform theo anchor thay vi doc rong.
- Cach toi uu cho phien sau: chay targeted Flutter tests ngay khi co full checkout + Flutter SDK, sau do refresh worklog history.
- Task-skill can doc lan sau: `.codex/task-skills/coding.md`.
