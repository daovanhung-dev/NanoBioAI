# TOKEN_SAVING_RULES

Muc tieu: doc du de lam dung, dung som khi da du can cu. Context la tai nguyen can quan ly, khong phai cang nhieu cang tot.

## Default Read Pack

Moi task bat dau bang:

1. `.codex/AGENTS.md`
2. `.codex/PROJECT_MAP.md`
3. `.codex/DOCS_WORKFLOW.md` neu co code/review/test/sua docs
4. `.codex/ISSUE_TODO_WORKFLOW.md` neu task la tim bug/tao issue/tao todo/fix issue
5. Dung 1 playbook lien quan truc tiep

Khong doc toan bo `.codex`, toan bo `lib/`, toan bo `test/`, docs cu, build/cache/generated neu chua can.

## Ba Muc Lay Context

### 1. Structure scan

Dung khi can hieu repo hoac user yeu cau "doc du an":

```bash
rg --files -g '!build/**' -g '!.dart_tool/**' -g '!.git/**'
Get-ChildItem lib\features -Directory
Get-Content pubspec.yaml
Get-Content lib\core\storage\localdb\database_version.dart
```

Ket qua mong doi: biet module, config, test/doc folders, va hotspot can doc sau.

### 2. Targeted deep read

Dung cho hau het coding/review/fix:

1. File user dang nhac hoac file dang loi.
2. Import truc tiep cua file do.
3. Provider/controller/repository/datasource usage bang `rg`.
4. Test lien quan.
5. DAO/model/table/service lien quan.
6. Module lan can chi khi dependency da duoc chung minh.

### 3. Exhaustive read

Chi dung khi user yeu cau ro doc noi dung moi file, audit toan repo, hoac migration/architecture lon bat buoc.

Van bo qua:

- `build/`, `.dart_tool/`, `.git/`, IDE/cache/generated output.
- Binary/assets lon.
- `.env` that, secret, token, API key.

## Stop Conditions

Dung mo rong context khi da co:

- mode lam viec;
- module/source chinh;
- trieu chung hoac muc tieu;
- file can sua/doc;
- usage anh huong;
- command kiem chung phu hop.

Neu context moi khong thay doi patch/plan/test, khong doc them.

## Budget Theo Loai Task

- Tiny copy/UI: core docs + UI playbook + file UI + theme tokens lien quan.
- Bug mot module: core docs + playbook module + file loi + usage + test gan nhat.
- Schema/flow lon: core docs + playbook module + DB/service files lien quan + tests + migration history can thiet.
- Find issues: core docs + `ISSUE_TODO_WORKFLOW.md` + 1 playbook + file/user scope + usage/test gan nhat; khong doc DD neu khong duoc yeu cau.
- Create issues: core docs + `ISSUE_TODO_WORKFLOW.md` + findings/log/source toi thieu de xac minh.
- Create todo: core docs + `ISSUE_TODO_WORKFLOW.md` + issue goc; chi mo source neu can xac dinh file fix.
- Fix issues: core docs + `ISSUE_TODO_WORKFLOW.md` + todo + issue + 1 playbook + file can sua.
- Coding theo DD: doc `docs/DD/README.md`, `docs/DD/MODULE_INDEX.md`, DD module lien quan, khong doc toan bo DD.

## Lenh Uu Tien

```bash
rg "keyword" lib test
rg --files lib/features/<feature> test/features/<feature>
git diff -- path
```

Chi dung lenh liet ke rong khi can map module. Tranh paste output dai vao final.

## Khong Nen Lam

- Mo nhieu playbook cung luc neu task chi thuoc mot module.
- Doc prompt mau tru khi user yeu cau dung prompt.
- Copy code/docs dai vao tra loi cuoi.
- Refactor vi thay code co the dep hon nhung khong lien quan loi goc.
- Tron mode lam viec: review/tim bug kem coding, todo kem fix, test kem sua code.
- Sua file dang dirty khong lien quan task.

## Khi Cap Nhat `.codex`

Chi them rule khi rule do:

- ngan loi lap lai nhieu lan;
- bao ve flow nghiep vu/kien truc quan trong;
- giup task sau tiet kiem doc file hoac chay dung command.

Xoa rule loi thoi. Khong them roadmap, log cu, hoac giai thich dai.
