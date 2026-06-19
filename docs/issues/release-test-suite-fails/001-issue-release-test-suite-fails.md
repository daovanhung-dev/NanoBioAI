Commit đề xuất: docs(issue): ghi nhận lỗi test suite fail trước release

# Flutter test đang fail 3 case trước release 1.0

## Tóm tắt
- `flutter test` exit code 1.
- Test suite fail 3 case: AI JSON preservation, Features Hub widget, AIChatService missing API key.

## Mức độ ảnh hưởng
- Severity: high
- Ảnh hưởng user: có ít nhất một failure là crash thật của AIChatService khi dotenv chưa init.
- Ảnh hưởng dev/build/test: không thể đóng release 1.0 với test suite đỏ.

## Cách tái hiện
1. Chạy `flutter test`.
2. Command kết thúc `Some tests failed`.

## Đã xác nhận
- Fail 1: `test/architecture_preservation_property_test.dart:124` kỳ vọng `ai_service.dart` chứa `jsonDecode`; parser đã tách sang `ai_json_parser.dart`.
- Fail 2: `test/features/features_hub/features_hub_page_test.dart:11` không tìm thấy text `AI Coach`.
- Fail 3: `test/services/ai/ai_service_test.dart:406` `AIChatService(apiKeyOverride: '')` ném `NotInitializedError`.

## Giả thuyết
- Có cả test contract stale và bug runtime thật.

## Workaround
- Không dùng kết quả test tổng làm release gate cho tới khi triage 3 failure.

## Hướng fix đề xuất
- Fix bug AIChatService trước vì là crash thật.
- Cập nhật architecture preservation test để kiểm tra `AIJsonParser.decodeArray` hoặc parser file.
- Cập nhật Features Hub test theo behavior sản phẩm hiện tại.

## Files/log liên quan
- `test/architecture_preservation_property_test.dart`
- `test/features/features_hub/features_hub_page_test.dart`
- `test/services/ai/ai_service_test.dart`

## Liên kết
- Worklog: ../../worklog/2026-06-19/007-worklog-release-1-0-bug-audit.md
