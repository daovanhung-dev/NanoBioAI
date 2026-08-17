Commit de xuat: feat(theme): chuyen Blue Wellness mac dinh va chuan bi Nabi Blue

# Worklog - Nabi Blue va Blue Wellness cutover

## Thoi gian

- Ngay: 2026-08-17
- Bat dau: 10:36:35
- Ket thuc: 10:50:03 (partial, dang cho xac nhan image CLI fallback)
- Timezone: Asia/Saigon (UTC+07:00)

## Pham vi

- Loai task: coding / asset generation / docs / test
- Module chinh: UI / Theme / NabiCopy, Nabi v2 asset bundle
- Yeu cau goc: thay identity Nabi v2 bang Nabi Blue, giu nguyen runtime asset contract, va chuyen Green Wellness sang Blue Wellness mac dinh ma khong doi business logic.

## Da lam

- Audit va xac nhan bundle Nabi v2 hien tai hop le: 84 static state, 10 expression, 30 animation x 30 frame, 7 effect x 30 frame.
- Xac nhan `NabiAssetCatalog` va `NabiAssets` da dung mot root selector, dung ID/path V2, nen khong can sua runtime mapping.
- Tao duoc concept Nabi Blue neutral dung identity tu hai anh tham chieu, nhung built-in image tool tra RGB co checkerboard thay vi RGBA alpha sau hai lan thu; concept khong duoc chep vao asset production.
- Chuyen `STITCH_GREEN_UI_ENABLED` sang `defaultValue: false`; Blue Wellness la mac dinh, Green Wellness duoc giu bang `STITCH_GREEN_UI_ENABLED=true`.
- Chuan hoa Blue brand/navigation/CTA va green health/leaf/success accent trong `AppColors`, semantic colors, gradients, shadows, foundation va token facade.
- Promote Blue dark scheme thanh canonical; giu alias `legacyBlueDark` de source cu van compile.
- Doi contract test Green sang Blue va cap nhat assertion semantics theo Flutter `Tristate` hien tai.
- Dong bo canonical design handoff cap foundation sang Blue Wellness.

## File code/docs da sua

- `.codex/design/README.md` - sua - Blue Wellness palette authority va Green rollback.
- `.codex/design/00_NABI_KINETIC_AURA_MASTER_DESIGN.md` - sua - token va dark seed Blue.
- `.codex/design/groups/01_foundation_shell.md` - sua - foundation contract Blue/green accent.
- `.codex/design/15_CODING_PLAN.md` - sua - Blue default va Green compatibility.
- `lib/core/theme/` - sua - cutover flag, color/semantic/gradient/shadow/foundation/token va copy he thong.
- `test/core/theme/blue_wellness_contract_test.dart` - tao tu contract Green cu - contract Blue canonical.
- `test/core/theme/green_wellness_contract_test.dart` - xoa/doi ten - khong con la canonical contract.
- `test/core/theme/theme_cutover_flag_test.dart` - sua - Blue default, Green rollback.
- `test/core/theme/semantic_contrast_contract_test.dart` - sua - Blue canonical va Green compatibility.
- `test/core/theme/foundation/gradient_test.dart` - sua - Blue foundation.

## Tai lieu lien quan

- `assets/nabi_v2/00_master/nabi_v2_character_sheet.md`
- `docs/features/nabi_character/NABI_V2_ROLLOUT.md`
- `tools/generate_nabi_v2_assets.py`

## Commands

- `python tools/generate_nabi_v2_assets.py validate --static-root assets/images/nabi_v2 --sprite-root assets/nabi_v2 --catalog-root assets/config/nabi_v2`: PASS - baseline bundle day du va hop le.
- Built-in image generation neutral master: PARTIAL - visual dung, output RGB thay vi RGBA.
- Built-in background extraction: FAIL contract - van la RGB, khong co alpha channel.
- `dart format <touched Dart files>`: PASS.
- `flutter test test/core/theme/theme_cutover_flag_test.dart test/core/theme/blue_wellness_contract_test.dart test/core/theme/semantic_contrast_contract_test.dart test/core/theme/semantic_dark_components_test.dart test/core/theme/foundation/gradient_test.dart`: PASS.
- `flutter test --dart-define=STITCH_GREEN_UI_ENABLED=true test/core/theme/theme_cutover_flag_test.dart test/core/theme/semantic_contrast_contract_test.dart test/core/theme/semantic_dark_components_test.dart`: PASS.
- `flutter analyze lib/core/theme test/core/theme`: PASS.
- `powershell -ExecutionPolicy Bypass -File .codex/tools/validate_codex_integrity.ps1`: FAIL do baseline dang tham chieu cac file `docs/supabase/*` khong ton tai; khong lien quan den thay doi theme/Nabi cua phien nay.

## Loi/Rui ro

- Da fix: Green khong con la default; hard-coded green overlays/shadows trong foundation da duoc chuyen sang Blue canonical; Green rollback va dark contrast van pass.
- Chua fix: 5 master RGBA Nabi Blue chua duoc tao; vi vay bundle derivative van la identity ivory cu va chua duoc regenerate.
- Chua fix: `.codex` integrity baseline con stale path den `docs/supabase/README.md`, `config.sql` va `11-admin-access-dashboard.sql`; task nay khong duoc phep tai tao Supabase docs.
- Can kiem tra tiep: can user xac nhan CLI/API image fallback voi `OPENAI_API_KEY` da cau hinh, hoac cung cap 5 master RGBA da tach nen. Sau do regenerate/validate bundle, build APK, verify release assets va visual QA.

## Ty le hoan thanh

- Hoan thanh: Blue Wellness theme foundation, canonical dark mode, Green rollback, focused docs va tests.
- Dang do: Nabi Blue production assets, manifest regeneration, APK/release verification va visual QA.

## Tu danh gia va toi uu phien sau

- Chat luong dau ra: tot cho theme; asset production chua dat vi alpha contract cua image tool.
- Muc do hoan thanh task: partial; theme cutover hoan tat va co bang chung, asset cutover chua duoc phep chuyen sang CLI fallback.
- Bang chung kiem chung: baseline asset validation, default/rollback Flutter tests va targeted analyze deu PASS.
- Diem ton token/chua toi uu: lan audit asset dau tien liet ke qua nhieu file; lan sau chi can count/manifest va cac section generator lien quan.
- Cach toi uu cho phien sau: bat dau tu 5 master RGBA da duoc chap thuan, sau do chay mot lan generator, contact-sheet QA va release verification.
- Task-skill can doc lan sau: `.codex/task-skills/coding.md`
