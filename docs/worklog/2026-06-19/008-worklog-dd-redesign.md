Commit de xuat: docs(worklog): ghi nhan phien dd redesign

# Worklog - DD redesign

## Thoi gian
- Ngay: 2026-06-19
- Bat dau: Khong ghi nhan tu dong
- Ket thuc: Khong ghi nhan tu dong
- Timezone: Asia/Saigon

## Pham vi
- Loai task: Sua docs/thiet ke lai tai lieu
- Module chinh: `docs/DD`
- Yeu cau goc: Doc `docs/DD`, tham khao tai lieu DD tren cac trang uy tin va thiet ke lai de phuc vu coding sau nay.

## Da lam
- Doc cau truc va noi dung hien co trong `docs/DD`.
- Xac dinh legacy DD dang chia theo `Overview`, `FeatureList`, `ActivityFlow` nhung con tong quat va bi loi encoding o nhieu file.
- Tham khao cac huong dan/tai lieu ve design docs, architecture documentation, C4 model va ADR.
- Them lop tai lieu moi cho Codex/developer dung khi coding: entry point, guide, module index, coding DD template va ADR template.

## File code/docs da sua
- `docs/DD/README.md` - tao - entry point moi cho bo DD.
- `docs/DD/CODEX_DD_GUIDE.md` - tao - huong dan dung DD trong workflow coding.
- `docs/DD/MODULE_INDEX.md` - tao - map module DD sang code va gap hien tai.
- `docs/DD/TEMPLATE_CODING_DD.md` - tao - template DD thuc dung cho feature/module.
- `docs/DD/ADR_TEMPLATE.md` - tao - template ghi quyet dinh thiet ke/kien truc.
- `docs/worklog/2026-06-19/008-worklog-dd-redesign.md` - tao - ghi nhan phien.

## Tai lieu lien quan
- Khong phat sinh feature/fixbug/test/issue rieng.

## Commands
- `Get-ChildItem -Recurse docs\DD`: PASS - xem cau truc DD hien co.
- `Get-Content docs\DD\...`: PASS - doc template, checklist va module DD cu.
- `web search/open`: PASS - tham khao nguon ben ngoai.
- `dart format --set-exit-if-changed .`: SKIPPED - chi sua Markdown.
- `flutter analyze`: SKIPPED - chi sua Markdown.
- `flutter test`: SKIPPED - chi sua Markdown.

## Loi/Rui ro
- Da fix: Tao entry point va template de DD phuc vu coding ro hon.
- Chua fix: Chua chuyen doi tung legacy module DD sang template moi.
- Can kiem tra tiep: Neu user muon, co the migrate lan luot 09 module DD cu sang `TEMPLATE_CODING_DD.md`.

