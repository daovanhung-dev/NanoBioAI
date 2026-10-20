Commit de xuat: docs(worklog): ghi nhan ket qua Food Scan v6 tren Xiaomi

# Worklog - Fix Food Scan picker va local vision tren Xiaomi

## Thoi gian

- Ngay: 2026-10-20
- Bat dau: Khoang 21:44; tiep tuc tu phien QA/fix truoc.
- Ket thuc: 22:21
- Timezone: Asia/Saigon

## Pham vi

- Loai task: Nap context, dieu tra bug, fix va QA tren Android that.
- Module chinh: Food Scan picker, local vision/nutrition fallback, local AI startup gate.
- Yeu cau goc: lam cho Food Scan dung duoc tren Xiaomi 4 GB class voi anh banh mi that trong thu vien, co ket qua dinh duong de xem.

## Da lam

- Nap lai `AGENTS.md`, `.codex/AGENTS.md`, project map, bugfix workflow/task-skill, AI service domain va trang thai worktree trong checkout nested `Nabi/NanoBioAI`; giu nguyen cac thay doi co san.
- Tai hien loi moi: `LocalAiSetupGate` nap model text khi khoi dong lanh; PSS len khoang 1.88 GiB truoc picker va MIUI force-stop app.
- Chuyen gate sang kiem tra model/hash ma khong nap model vao RAM; giu runtime operation lease xuyen suot picker va image preparation.
- Chay lai anh `IMG_20261020_191224.jpg`; picker tra anh ve app voi cung PID, PSS khoang 431 MiB khi picker mo.
- Xac nhan loi schema v6: lan dau vision nhan dien mon nhung calories/macros khong du; chuyen parser sang chap nhan ca hai ten `fallback_nutrition` va `nutrition`, sau do van can them nutrition fallback rieng.
- Them text-only local prompt de uoc tinh macros cho mon va khoi luong vision da nhan dien; kiem tra calories > 0 va macros >= 0, khong co du lieu thi van chan ket qua.
- Chay lai cung anh. UI hien Banh mi, 120 g, 320 kcal, protein 10 g, carbohydrate 55 g, chat beo 6 g; trang suc khoe bao can thu lai, nut `Xac nhan da an` hien nhung khong bam.
- Cap nhat fixbug va worklog theo root cause/final evidence; build APK debug moi nhat.

## File code/docs da sua

- `lib/core/ai_local/local_ai_runtime_service_native.dart`, `local_ai_runtime_service_stub.dart`, `presentation/local_ai_setup_gate.dart` - khong nap model text moi startup; serial hoa thao tac picker voi unload.
- `lib/app_versions/v3/features/food_scan/application/food_scan_prompts.dart` - compact v6 vision schema va prompt local macro fallback.
- `lib/app_versions/v3/features/food_scan/application/food_scan_service.dart` - chan ket qua neu nutrition core van thieu.
- `lib/app_versions/v3/features/food_scan/data/datasources/food_scan_ai_datasource.dart` - nutrition alias, completeness check, text-only fallback merge va gioi han anh payload.
- `lib/app_versions/v3/features/food_scan/providers/food_scan_providers.dart`, `presentation/pages/food_scan_page.dart`, `data/services/food_scan_image_service.dart`, `lib/services/image_picker/image_picker_service.dart` - picker lease/recovery va copy UI/catalog.
- `lib/core/ai_local/local_ai_model_catalog.dart` - SmolVLM asset/hash, download size va RAM guidance.
- `test/app_versions/v3/features/food_scan/*`, `test/core/ai_local/local_ai_model_catalog_test.dart`, `test/services/image_picker_service_test.dart` - test regression da co trong worktree.
- `docs/fixbug/food-scan-unavailable/002-fixbug-food-scan-picker-process-death.md` - cap nhat root cause, thay doi, ket qua va gioi han.

## Tai lieu lien quan

- `.codex/AGENTS.md`, `.codex/PROJECT_MAP.md`, `.codex/workflows/bugfix.md`, `.codex/task-skills/bugfix.md`, `.codex/domains/ai-service.md`
- `.codex/DOCS_WORKFLOW.md`, `.codex/history/SESSION_QUALITY_REVIEW.md`
- `docs/fixbug/food-scan-unavailable/001-fixbug-food-scan-unavailable.md`

## Commands

- `dart format <3 touched Food Scan Dart files>`: PASS.
- Dart MCP `analyze_files` tren prompt, service, datasource Food Scan: PASS - no errors.
- Dart MCP hot restart tren Xiaomi qua Flutter DTD: PASS; sau do app khoi tao lai va live flow dung code vua sua.
- `flutter build apk --debug`: PASS - `build/app/outputs/flutter-apk/app-debug.apk` kich thuoc 744 MiB; kiem tra ZIP khong thay asset GGUF/projector, nhung co 106 meal images (~275.5 MB chua nen) va native libs cho nhieu ABI; release/split APK chua duoc danh gia.
- Xiaomi `220333QPG` picker va inference voi anh Camera that: PASS cho preview/result; PSS khi picker khoang 431 MiB, PID `16506` van song.
- Inference v6 + nutrition fallback: PASS - 120 g, 320 kcal, P10/C55/F6; tong thoi gian gan 155 giay; PSS lay mau cao nhat khoang 1.87 GiB, sau ket qua khoang 1.73 GiB va swap PSS khoang 560 MiB.
- Kiem tra `logcat` cho ANR/FATAL/MiuiMemoryService moi trong luot thanh cong: khong thay.
- `flutter test` focused suite: SKIPPED sau thay doi nutrition fallback; 27 tests da pass truoc thay doi cuoi.
- `pwsh -NoProfile -File .codex/tools/validate_codex_integrity.ps1`: FAIL - thieu `docs/audit/source_truth_manifest.json` va co stale path trong history/task-skill cu, ngoai Food Scan.
- `git diff --check`: PASS; hai docs moi khong co trailing whitespace.

## Loi/Rui ro

- Da fix: cold-start text-model residency lam MIUI stop app trong picker; model re-load co the chen vao picker; schema v6 thieu nutrition estimates; parser khong chap nhan alias nutrition.
- Chua fix: inference tren thiet bi nay mat gan 155 giay, PSS cao va swap; chua danh gia nhiet do/quay lien tuc hay thiet bi RAM thap hon.
- Can kiem tra tiep: QA nhieu mon/anh va ho so suc khoe day du; danh gia suc khoe tren luot nay hien can thu lai.
- Qwen assets cu trong app storage duoc giu nguyen; khong xoa anh Camera cua nguoi dung.

## Ty le hoan thanh

- Hoan thanh: context, root cause picker, startup RAM fix, picker return, nutrition v6 fallback, live result cho anh banh mi, analyzer va debug APK build.
- Dang do: chua co test run sau nutrition fallback; chua co ket qua health review thanh cong trong luot nay; chua co QA nhieu anh/thiet bi.

## Tu danh gia va toi uu phien sau

- Chat luong dau ra: tot - ket qua nutrition da chay duoc voi anh Camera that va ket qua fail-closed neu core fields van thieu.
- Muc do hoan thanh task: dat yeu cau Food Scan chinh; health review va performance tren nhieu lan quet con mo.
- Bang chung kiem chung: targeted analyzer pass, debug APK build pass, picker giu PID va PSS thap, inference hien dung 120 g / 320 kcal / P10 C55 F6.
- Diem ton token/chua toi uu: mot so tap tay vao picker row khong chon duoc file; doc UI hierarchy va dung DPAD Down/Enter giai quyet nhanh hon.
- Cach toi uu cho phien sau: doc bounds/focus cua DocumentsUI truoc khi bam; giu rieng evidence cho picker, v6 macro fallback va health review.
- Task-skill can doc lan sau: `.codex/task-skills/bugfix.md`
