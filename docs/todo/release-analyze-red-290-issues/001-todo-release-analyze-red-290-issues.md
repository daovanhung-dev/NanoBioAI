Commit de xuat: docs(todo): lap todo fix release analyze red issues

# Todo - Dua flutter analyze ve trang thai release-clean

## Issue goc
- Issue: [Flutter analyze dang fail voi 290 issue](../../issues/release-analyze-red-290-issues/001-issue-release-analyze-red-290-issues.md)
- Severity: medium
- Trang thai: done 2026-07-10

## Muc tieu fix
- Giam va xu ly cac warning/lint lam `flutter analyze` exit code 1 truoc release.
- Uu tien warning co kha nang gay bug truoc, deprecation/style theo batch sau.

## Khong lam trong todo nay
- Khong refactor lan ngoai cac warning can xu ly.
- Khong tat lint hang loat de che loi neu chua co baseline ro.
- Khong sua issue runtime rieng neu da co todo chuyen biet, tru khi analyze can.

## Cac viec can lam
1. [x] Chay `flutter analyze` trong mode fix/test phu hop de lay output moi nhat.
2. [x] Nhom loi theo category: unused, unnecessary assertion, deprecated API, imports, generated/stale tests.
3. [x] Sua nhom rui ro cao truoc: AI service, unused production field, imports sai.
4. [x] Xu ly deprecated `withOpacity` theo batch co format/test.
5. [x] Lap docs test/fixbug neu co thay doi dang ke.
6. [x] Cap nhat worklog sau khi fix.

## Ket qua 2026-07-10

- `flutter analyze`: PASS - no issues found.
- Nabi provider names/imports now use lowerCamelCase providers and canonical `nabi_visual_state.dart`.
- Onboarding UI analyzer drift fixed: unused progress/banner helpers removed, deprecated dropdown `value` replaced, child argument ordering fixed, unused imports removed.
- Shared Nabi overlay/character color deprecations switched from `withOpacity` to `withValues(alpha: ...)`.
- Onboarding entry compact landscape layout tightened so the primary CTA remains tappable in the widget-test viewport.

## Fixbug

- [Fixbug - Release analyze red issues](../../fixbug/release-analyze-red-290-issues/001-fixbug-release-analyze-red-290-issues.md)

## File du kien anh huong
- `lib/services/ai/ai_chat_service.dart` - warning non-null assertion.
- `lib/features/ai_chat/presentation/pages/ai_chat_screen.dart` - unused field.
- `lib/core/storage/localdb/models/*` - helper unused neu that su khong can.
- Nhieu file UI - deprecated `withOpacity`.

## Command can kiem chung
- `flutter analyze` - gate chinh cua todo.
- `dart format --set-exit-if-changed .` - xac nhan format sau batch edit.
- `flutter test` - kiem tra regression sau khi lint clean.

## Rui ro can de y
- Sua 290 issue co blast radius lon, nen tach batch nho neu can.
- Can tranh xoa helper dang duoc goi qua pattern/serialization kho nhan ra.
