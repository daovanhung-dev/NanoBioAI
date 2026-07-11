Commit de xuat: fix(regression): on dinh baseline va che du lieu AI trace

# Fixbug - Ổn định baseline P0 cho regression v2 + Admin

## Tóm tắt

- Baseline trước sửa có 502 test PASS và 6 test FAIL: 4 case onboarding và
  2 case FamilyPlus.
- Onboarding lỗi do các hero cố định chiều cao không giới hạn headline/chip ở
  viewport 390x844; stable key của AI dev banner cũng bị mất sau refactor.
- Hai lỗi FamilyPlus là expectation không dấu đã cũ; copy production hiện tại
  đúng DD/Nabitone nên chỉ sửa test.
- AI trace đang ghi prompt, raw response, hồ sơ sức khỏe, output đã chuẩn hóa,
  exception và stack. Đây là dữ liệu không được phép xuất hiện trong log.

## Cách sửa

- Giới hạn headline bằng `Expanded`, `maxLines`, `TextOverflow.ellipsis`; cho
  chip trạng thái co giãn bằng `Flexible`/`Expanded` tại Welcome, Lifestyle,
  Extras và Consent.
- Khôi phục key `onboarding_ai_dev_check_banner` trực tiếp trên `_AiCheckCard`
  và đồng bộ expectation với copy UI hiện hành.
- Đồng bộ ba expectation FamilyPlus sang copy tiếng Việt có dấu; không đổi
  production behavior.
- Biến `AITraceLogger` thành logger metadata-only với whitelist key tường minh;
  bỏ public raw payload sink và không chuyển tiếp exception/stack nguyên bản.
- AI plan/chat chỉ log trace/stage, model/source, duration, count/length và
  error type. Generated-plan request được ghi bằng fingerprint đã che.
- Thêm regression test dùng sentinel để chứng minh chat message, AI response,
  health data, prompt, exception và stack không xuất hiện trong log.

## Kiểm chứng

- Targeted onboarding + AI + generated plan + FamilyPlus: 80/80 PASS.
- `flutter analyze`: PASS, không có issue.
- `flutter test --reporter compact`: 510/510 PASS.
- Source grep không còn `AITraceLogger.payload`, `PROMPT_SENT`, `RAW_RESPONSE`,
  prompt-original, decoded/normalized/fallback raw payload step trong AI
  services.
- `git diff --check`: PASS; chỉ còn cảnh báo line-ending Windows, không có
  whitespace error.

## Giới hạn

- Đây mới là gate P0 tự động; chưa phải kết quả E2E của 17 module.
- Chưa reset/seed Supabase sandbox, chưa có evidence screenshot theo case và
  chưa chạy notification case trên thiết bị Android API 33+.
- Kết quả sandbox/E2E về sau không được suy diễn thành production-ready.
