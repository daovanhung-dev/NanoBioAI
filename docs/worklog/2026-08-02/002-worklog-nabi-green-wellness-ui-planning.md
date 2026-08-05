Commit de xuat: docs(ui): lap checklist va ke hoach NaBi Green Wellness

# Worklog - NaBi Green Wellness UI Planning

## Thoi gian

- Ngay: 2026-08-02
- Bat dau: 15:49
- Ket thuc: 16:03
- Timezone: Asia/Bangkok

## Pham vi

- Loai task: coding - pha khao sat/checklist/plan, chua coding runtime
- Module chinh: UI / Theme / NabiCopy, toan bo app surfaces
- Yeu cau goc: coding lai toan bo UI theo `.codex/Design_NaBi_Green_Wellness.md`, bat buoc tao checklist va plan truoc coding

## Da lam

- Doc `nano_context.md`, root/canonical AGENTS, PROJECT_MAP, LEARNED_SKILLS, workflow/task-skill coding, domain UI.
- Giai nen RAR5 va quet 580 Dart source trong `lib/`, 154 Dart test trong `test/`.
- Doc toan bo cau truc va cac contract chinh cua Design System NaBi Green Wellness.
- Xay import graph va static scan cho theme usage, raw style literals, responsive, accessibility, UI states, direct storage imports va raw error candidates.
- Tao checklist 202 source UI-facing/adjacent va 23 widget/theme tests.
- Tao ke hoach 12 giai doan, validation ladder, visual matrix, rui ro va gate xac nhan.
- Chua sua source runtime.

## File code/docs da sua

- `docs/ui/NABI_GREEN_WELLNESS_UI_CHECKLIST.md` - tao - checklist tung file/component/test.
- `docs/ui/NABI_GREEN_WELLNESS_UI_REFACTOR_PLAN.md` - tao - ke hoach chi tiet.
- `docs/ui/NABI_GREEN_WELLNESS_UI_AUDIT_DATA.json` - tao - du lieu audit co the tai lap.
- `docs/worklog/2026-08-02/002-worklog-nabi-green-wellness-ui-planning.md` - tao - ghi nhan phien.

## Tai lieu lien quan

- `.codex/Design_NaBi_Green_Wellness.md`
- `.codex/domains/ui-nami.md`
- `.codex/workflows/coding.md`
- `.codex/task-skills/coding.md`
- `docs/checklist/checklist_complete_DD.md`
- `docs/checklist/checklist_task_coding.md`

## Commands

- Giai nen RAR5 bang libarchive custom extractor: PASS - 7,975 entries.
- Static scan Python: PASS - 202 source rows, 23 test rows.
- Markdown existence/table validation: PASS - 202 source rows, 23 test rows, plan gate ton tai.
- Flutter/Dart/PowerShell: SKIPPED - khong co executable trong PATH.

## Loi/Rui ro

- Da fix: moi truong khong co unrar/7z; dung libarchive de giai nen RAR5.
- Chua fix: chua co Flutter/Dart/PowerShell de analyze/test/build.
- Can kiem tra tiep: runtime route, accessibility, reduced-motion, visual matrix, device screenshot.

## Ty le hoan thanh

- Hoan thanh: 100% pha khao sat/checklist/plan.
- Dang do: 0% coding UI runtime; cho nguoi dung xac nhan plan.

## Tu danh gia va toi uu phien sau

- Chat luong dau ra: tot - checklist theo tung file, co static evidence va phase gate.
- Muc do hoan thanh task: dung pham vi phan hoi dau tien; chua coding theo yeu cau.
- Bang chung kiem chung: inventory, import graph, audit JSON, checklist va plan.
- Diem ton token/chua toi uu: Design file lon; da dung heading/index va static scan thay vi doc broad worklogs.
- Cach toi uu cho phien sau: thi cong theo batch Core Theme -> primitives -> shell -> features, cap nhat checklist ngay sau moi batch.
- Task-skill can doc lan sau: `.codex/task-skills/coding.md`
