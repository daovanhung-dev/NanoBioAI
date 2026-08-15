Commit de xuat: fix(meal-plan): hien thi anh mon an tren card va chi tiet

# Worklog - Meal Plan image wiring direct source

## Thoi gian

- Ngay: 2026-08-15
- Timezone: Asia/Saigon

## Pham vi

- Loai task: coding
- Module chinh: V1 Meal Plan / Presentation
- Yeu cau goc: sua code truc tiep de moi mon trong thuc don tuan hien thi anh tu bo anh Suc Khoe Tu Nha Bep; khong dung installer/patch.

## Da lam

- Sua truc tiep `meal_plan_page.dart`.
- Import va render `MealPhoto` tren tung meal card.
- Render cung `MealPhoto` trong detail sheet de card/detail dung chung resolver.
- Giu co che exact-match/fail-closed cua `MealImageResolver`; khong fuzzy-match anh sai mon.
- Them test contract va resolver cho luong anh mon an.
- Bo sung phu luc ky thuat vao file note thuc don.

## File code/docs da sua

- `lib/app_versions/v1/features/meal_plan/presentation/pages/meal_plan_page.dart` - sua - hien anh o card va detail.
- `test/app_versions/v1/features/meal_plan/presentation/meal_plan_image_contract_test.dart` - tao - contract hai vi tri render anh.
- `test/app_versions/v1/features/meal_plan/presentation/utils/meal_image_resolver_test.dart` - tao - kiem tra canonical mapping va unknown fallback.
- `docs/note/Suc_Khoe_Tu_Nha_Bep_Thuc_Don_Theo_Tung_Muc.md` - sua - huong dan asset/mapping/UI/validation.

## Commands

- Source extraction tu `nano_app(4).rar` bang libarchive: PASS.
- Static source assertions: PASS.
- Python UTF-8/structure verification: PASS.
- `dart format`: SKIPPED - Dart SDK khong co trong runtime sandbox.
- `flutter analyze/test`: SKIPPED - Flutter SDK khong co trong runtime sandbox.

## Loi/Rui ro

- Da fix: UI truoc do khong render `MealPhoto` du resolver/widget da ton tai.
- Chua fix: khong mo rong danh sach asset/resolver; asset moi can duoc xac minh rieng truoc khi them.
- Can kiem tra tiep: chay targeted Flutter analyze/test tren may co Flutter SDK.

## Ty le hoan thanh

- Code va docs trong pham vi: 100%.
- Native Flutter validation trong sandbox: khong kha dung.

## Tu danh gia va toi uu phien sau

- Chat luong dau ra: tot - sua source truc tiep, pham vi nho, khong thay doi data/persistence.
- Muc do hoan thanh task: hoan thanh source delivery theo cau truc du an.
- Bang chung kiem chung: source assertions va structure check PASS.
- Diem ton token/chua toi uu: GitHub clone bi chan DNS nen phai doi chieu connector va archive.
- Cach toi uu cho phien sau: uu tien archive source khi clone bi chan va so SHA file quan trong voi main truoc khi sua.
- Task-skill can doc lan sau: `.codex/task-skills/coding.md`.
