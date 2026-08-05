Commit de xuat: feat(ui): migrate to NaBi Green Wellness design system

# Worklog - NaBi Green Wellness UI Refactor

## Thoi gian

- Ngay: 2026-08-02
- Bat dau: 16:05
- Ket thuc: 16:31
- Timezone: Asia/Bangkok

## Pham vi

- Loai task: coding
- Module chinh: UI / Theme / NabiCopy, toan bo app surfaces
- Muc tieu: thi cong plan NaBi Green Wellness da duoc nguoi dung xac nhan; khong thay doi nghiep vu

## Da lam

- Khoa baseline, doc lai AGENTS/workflow/task-skill/domain UI.
- Chuyen canonical theme/palette/typography/spacing/radius/shadow/gradient/motion sang Green Wellness.
- Nang cap shared primitives va async states, them semantics/touch target/reduced motion.
- Chay controlled codemod va manual repair tren V1/V2/V3/Admin/Sale/Global Nabi/shared.
- Sua truc tiep 90 source Dart; review 62 source khong can patch cuc bo; giu 50 source regression-only.
- Cap nhat/them 2 test va 1 static validation tool.
- Cap nhat checklist 202 source + 23 tests, tao changed-file manifest, validation report va completion report.

## Validation

- `python3 tools/validate_nabi_green_wellness.py`: PASS, 735 Dart files, 0 blocking findings.
- Import target/duplicate import, delimiter/lexical, raw feature color/radius, unsafe const scan: PASS.
- Pubspec asset existence: BLOCKED, 57 configured paths missing.
- Flutter format/analyze/test/build/device/visual: SKIPPED, khong co SDK va archive thieu assets.

## File dau ra chinh

- `docs/ui/NABI_GREEN_WELLNESS_UI_CHECKLIST.md`
- `docs/ui/NABI_GREEN_WELLNESS_UI_REFACTOR_PLAN.md`
- `docs/ui/NABI_GREEN_WELLNESS_UI_AUDIT_DATA.json`
- `docs/ui/NABI_GREEN_WELLNESS_UI_CHANGED_FILES.md`
- `docs/ui/NABI_GREEN_WELLNESS_UI_VALIDATION_REPORT.md`
- `docs/ui/NABI_GREEN_WELLNESS_UI_COMPLETION_REPORT.md`
- `tools/validate_nabi_green_wellness.py`

## Loi/Rui ro con lai

- Can bo sung lai toan bo root `assets/` tu source day du.
- Can chay Flutter SDK validation va visual matrix tren device/emulator.
- Khong tu tao fake assets va khong tu danh dau runtime/visual PASS.
- Script refresh worklog learning PowerShell khong chay duoc trong moi truong hien tai.

## Ty le hoan thanh

- Coding/static migration: 100%.
- Runtime/analyzer/test/visual acceptance: 0% do blocker moi truong va source assets.
- Trang thai tong: da hoan tat change set; chua du dieu kien dong nghiem thu runtime.
