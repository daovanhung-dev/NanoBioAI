# TOKEN_SAVING_RULES

Muc tieu: doc du de lam dung, dung som khi da du can cu.

## Default Read Pack

Moi task bat dau bang:

1. `.codex/AGENTS.md`
2. `.codex/PROJECT_MAP.md`
3. `.codex/DOCS_WORKFLOW.md` neu co code/review/test/sua docs
4. Dung 1 playbook lien quan truc tiep

Khong doc toan bo `.codex`, toan bo `lib/`, toan bo `test/`, docs cu, build/cache/generated neu chua can.

## Mo rong context theo thu tu

1. File user dang nhac hoac file dang loi.
2. Import truc tiep cua file do.
3. Provider/controller/repository/datasource usage bang `rg`.
4. Test lien quan.
5. DAO/model/table/service lien quan.
6. Module lan can chi khi dependency da duoc chung minh.

Dung lai khi da co: trieu chung, nguyen nhan goc, file can sua, cach kiem chung.

## Budget theo loai task

- Tiny copy/UI: core docs + UI playbook + file UI + theme tokens lien quan.
- Bug mot module: core docs + playbook module + file loi + usage + test gan nhat.
- Schema/flow lon: core docs + playbook module + DB/service files lien quan + tests + migration history can thiet.

## Lenh uu tien

```bash
rg "keyword" lib test
rg --files lib/features/<feature> test/features/<feature>
git diff -- path
```

Chi dung lenh liet ke rong khi can map module. Tranh paste output dai vao final.

## Khong nen lam

- Mo nhieu playbook cung luc neu task chi thuoc mot module.
- Doc prompt mau tru khi user yeu cau dung prompt.
- Copy code/docs dai vao tra loi cuoi.
- Refactor vi thay code co the dep hon nhung khong lien quan loi goc.
- Sua file dang dirty khong lien quan task.

## Khi cap nhat `.codex`

Chi them rule khi rule do:

- Ngan loi lap lai nhieu lan.
- Bao ve flow nghiep vu/kien truc quan trong.
- Giup task sau tiet kiem doc file hoac chay dung command.

Xoa rule loi thoi. Khong them roadmap, log cu, hoac giai thich dai.
