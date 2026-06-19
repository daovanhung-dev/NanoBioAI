Commit de xuat: docs(dd): them huong dan dung design document khi coding

# Codex DD Guide

Dung file nay khi mot task can tham chieu Design Document truoc khi code, review, audit hoac sua docs.

## Muc Tieu

DD trong repo nay phai phuc vu coding thuc te:

- dinh tuyen dung module/source;
- giu dung flow san pham;
- tranh tao architecture violation;
- tim nhanh data contract va migration can co;
- biet test nao can chay/cap nhat;
- ghi lai decision kho doi bang ADR.

## Workflow Cho Moi Task

1. Xac dinh task thuoc module nao bang `.codex/PROJECT_MAP.md` va `docs/DD/MODULE_INDEX.md`.
2. Mo DD module/feature gan nhat neu co.
3. Kiem tra `Known Gaps` de biet DD dang lech code o dau.
4. Dung `rg` tim provider/repository/datasource/model/DAO lien quan.
5. Neu phai doi behavior, cap nhat DD hoac them worklog theo `.codex/DOCS_WORKFLOW.md`.
6. Neu phai chon giua nhieu phuong an ky thuat, tao ADR tu `ADR_TEMPLATE.md`.
7. Sau khi sua, cap nhat `Verification` va `Known Gaps` neu can.

## Phan Biet Tai Lieu

| Loai tai lieu | Dung khi nao | Noi dung bat buoc |
| --- | --- | --- |
| Coding DD | Mo rong/sua mot module/feature | scope, runtime flow, data contract, UI states, tests, gaps |
| ADR | Co quyet dinh kho doi/rui ro | context, options, decision, consequences, confirmation |
| Worklog | Co code/review/test/docs | da lam gi, file nao, command nao, rui ro |
| Issue doc | Loi chua fix hoac ngoai scope | trieu chung, impact, cach tai hien, huong fix |

## Checklist Truoc Khi Code

- Module DD co trung voi module code khong?
- User-facing copy co can tieng Viet co dau/giong Nami khong?
- UI co goi dung Provider/Controller thay vi DAO/API truc tiep khong?
- Source of truth la SQLite, Supabase, AI response hay in-memory state?
- Co schema/table/model/DAO/migration nao bi anh huong khong?
- Co notification/action/background flow nao bi anh huong khong?
- Test hien co nam o dau?

## Checklist Sau Khi Code

- DD/ADR/worklog da cap nhat neu behavior/contract thay doi.
- `Known Gaps` khong con mo ta sai tinh trang moi.
- Command validate da chay hoac ghi ro ly do skip.
- Khong them mock/fake/sample data vao production de che loi.
- Khong hard-code secret/API key.

## Quy Tac Khi DD Lech Code

Neu DD va code khac nhau:

1. Uu tien code de xac dinh tinh trang hien tai.
2. Uu tien DD de xac dinh y dinh san pham ban dau.
3. Ghi ro khoang cach trong `Known Gaps`.
4. Chi sua code theo DD khi user/task yeu cau hoac gap do la bug ro rang.

