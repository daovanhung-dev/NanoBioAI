Commit de xuat: docs(todo): lap todo fix release test suite failures

# Todo - Xu ly 3 failure trong flutter test truoc release

## Issue goc
- Issue: [Flutter test dang fail 3 case truoc release 1.0](../../issues/release-test-suite-fails/001-issue-release-test-suite-fails.md)
- Severity: high
- Trang thai: todo

## Muc tieu fix
- Dua `flutter test` ve trang thai pass bang cach triage 3 failure da xac nhan.
- Phan biet test stale voi bug runtime that.

## Khong lam trong todo nay
- Khong bo qua/xoa test chi de suite xanh.
- Khong sua cac issue ngoai 3 failure neu khong can.
- Khong goi API that trong test.

## Cac viec can lam
1. [ ] Fix bug AIChatService dotenv uninitialized theo todo rieng truoc.
2. [ ] Cap nhat architecture preservation test de kiem tra parser moi thay vi bat `jsonDecode` trong `ai_service.dart`.
3. [ ] Cap nhat Features Hub widget test theo behavior hien tai hoac spec da chot.
4. [ ] Chay tung test fail de xac nhan xanh.
5. [ ] Chay lai `flutter test` tong.
6. [ ] Cap nhat docs test/fixbug/worklog sau khi fix.

## File du kien anh huong
- `test/architecture_preservation_property_test.dart` - cap nhat contract parser.
- `test/features/features_hub/features_hub_page_test.dart` - cap nhat UI expectation.
- `test/services/ai/ai_service_test.dart` - xac nhan AIChatService missing key.
- `lib/services/ai/ai_chat_service.dart` - fix bug runtime neu chua fix.

## Command can kiem chung
- `flutter test test/services/ai/ai_service_test.dart` - kiem tra AI failure.
- `flutter test test/features/features_hub/features_hub_page_test.dart` - kiem tra Features Hub failure.
- `flutter test test/architecture_preservation_property_test.dart` - kiem tra architecture contract.
- `flutter test` - gate tong.

## Rui ro can de y
- Issue nay gom nhieu failure; nen fix theo todo con de tranh lan scope.
- Architecture test can giu y dinh bao ve parser, khong chi sua cho qua.
