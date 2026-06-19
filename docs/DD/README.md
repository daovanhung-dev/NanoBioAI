Commit de xuat: docs(dd): thiet ke lai bo tai lieu design document cho coding

# Design Documents - NanoBio / BioAI

Thu muc nay la nguon tham chieu san pham va ky thuat truoc khi coding. Muc tieu khong phai viet tai lieu dai, ma giup Codex va developer tra loi nhanh:

- Can sua module nao?
- Luong nguoi dung va luong runtime di qua dau?
- Data nao la source of truth?
- Provider/repository/datasource/DAO nao lien quan?
- Quyet dinh kien truc nao da duoc chon va vi sao?
- Can test/regression gi truoc khi xem task la xong?

## Cach Doc Nhanh

1. Doc file nay.
2. Doc `CODEX_DD_GUIDE.md` de biet cach dung DD trong mot phien coding.
3. Doc `MODULE_INDEX.md` de chon module lien quan.
4. Neu can viet/cap nhat DD, dung `TEMPLATE_CODING_DD.md`.
5. Neu can ghi mot quyet dinh kho doi, dung `ADR_TEMPLATE.md`.
6. Chi mo tai lieu cu trong `DD_Module/**` khi can truy nguon yeu cau san pham ban dau.

## Cau Truc Moi

```text
docs/DD/
  README.md                 # entry point
  CODEX_DD_GUIDE.md          # cach Codex/developer dung DD khi coding
  MODULE_INDEX.md            # ban do module DD -> code -> trang thai
  TEMPLATE_CODING_DD.md      # mau DD thuc dung cho mot module/feature
  ADR_TEMPLATE.md            # mau ghi quyet dinh kien truc/thiet ke
  checklist_DD.md            # doi chieu model/code hien co voi DD cu
  DD_Module/                 # tai lieu module cu, giu lam legacy source
  DD Features/Template/      # template cu, giu lam legacy source
```

## Nguyen Tac Viet DD

- Viet ngan, co cau truc, uu tien thong tin co the coding/test ngay.
- Moi DD phai noi ro `scope`, `non-goals`, `source of truth`, `runtime flow`, `data contract`, `error/empty/loading`, `test plan`.
- Moi thay doi schema phai noi ro table/model/DAO/migration/version.
- Moi thay doi flow lon phai link den ADR hoac tao ADR moi.
- DD khong thay the code. Neu code va DD lech nhau, ghi ro lech o `Known Gaps` thay vi suy doan.

## Nguon Tham Khao

- Google Software Engineering at Google: design doc va review giup chia se context va danh gia thiet ke truoc khi code.
- arc42: bo cuc architecture documentation gom goals, constraints, context, solution strategy, runtime view, decisions, quality, risks.
- C4 model: cach nhin he thong theo tang system/container/component/code va cac dynamic/deployment diagram.
- MADR/ADR: ghi tung quyet dinh thiet ke co context, option, outcome va consequence.

