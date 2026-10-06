Commit de xuat: feat(m31): cho phép gọi cảnh báo theo consent chưa xác minh

# M31 — Gọi cảnh báo cho liên hệ chưa xác minh

## Trạng thái

- Implementation: source Flutter, SQLite, Supabase SQL và Edge cascade đã cập
  nhật.
- Verification: Flutter focused 33/33 and targeted analyzer clean. Migration
  11:00 was applied to confirmed QA; read-only checks verified its default-off
  column, eight-argument RPC and grants. Contact UI save/reload/delete remains
  pending because Android input injection is blocked. No contact, OTP, flag
  change, dialer launch or call occurred.
- Rollout: QA migration only; Edge Functions, production and runtime flags are
  unchanged.

## Chính sách

- Liên hệ đang chờ xác minh chỉ nhận cuộc gọi thoại tự động sau khi chủ tài
  khoản bật riêng `allow_unverified_voice_alert`. Lựa chọn này mặc định tắt.
- Liên hệ chưa xác minh không nhận SMS. Khi voice thất bại hoặc không
  có người nghe, dispatch bỏ qua SMS cho số đó và xét liên hệ đủ điều kiện tiếp
  theo theo thứ tự ưu tiên.
- Liên hệ đã xác minh giữ nguyên luồng voice/SMS hiện có. SMS cần số đã
  xác minh.
- Người dùng có thể chủ động mở `ACTION_DIAL`/`tel:` cho liên hệ active đã bật
  phone fallback, bất kể trạng thái xác minh. Chỉ mở dialer sau thao tác rõ
  ràng; app không tự gọi.
- Quyền Plus/FamilyPlus, cờ rollout, điều kiện sự kiện, rate limit và
  idempotency hiện có tiếp tục được kiểm tra.

## Thay đổi lưu trữ và API

- `SafetyContact` và SQLite cache có `allow_unverified_voice_alert`, mặc định
  false. SQLite schema tăng lên v27.
- App dùng overload RPC 7 tham số. RPC 5 tham số cũ được giữ để tương thích;
  migration 12:00 thay thế các overload cũ đã mang tùy chọn đã nghỉ.
- Dispatch tức thời và provider callback cùng lọc contact theo consent; callback
  cũng không được gửi SMS cho contact chưa xác minh.

## Nguồn chính

- Business contract: `docs/BD/sleep_safety/BD_NanoBio_Sleep_Safety_M31_v1.2.md`,
  delta v1.3.
- DD: `docs/DD/sleep_safety_monitoring/README.md`, `Overall.md`,
  `List_Features.md`, `Function_List.md`, `Views.md`.
- Flutter: `lib/app_versions/v1/features/sleep_tracking/`.
- SQLite: `lib/core/storage/localdb/migrations/migration_v27.dart`.
- Supabase canonical source:
  `docs/supabase/01_build_system.sql`.
- Additive migration:
  `supabase/migrations/20261006110000_m31_unverified_voice_alert.sql`.
- Edge Functions: `supabase/functions/sleep-safety-dispatch/` and
  `supabase/functions/sleep-safety-provider-webhook/`.

## Chấp nhận

- [x] Consent voice riêng cho số chưa xác minh, mặc định tắt.
- [x] Số pending được voice-only; thất bại tiếp tục contact đủ điều kiện kế
  tiếp, không gửi SMS đến số pending.
- [x] Manual dialer chấp nhận contact pending khi cài đặt contact và cờ
  `phone_fallback_enabled` cho phép; thao tác vẫn do người dùng bắt đầu.
- [x] Giữ overload RPC cũ, điều kiện access/event/rate/idempotency và các cờ
  môi trường hiện có.
- [x] Apply migration trên QA; verify column default, 8-argument RPC and grants.
- [ ] Deploy Edge and verify dispatch/callback behavior on QA.
- [ ] Save one synthetic contact through Android UI, verify it after reload,
  then delete it through UI; currently blocked by device input permission.
- [ ] Chấp nhận thao tác dialer trên Android/iOS thật mà không thực hiện cuộc
  gọi.

Chi tiết test và lệnh chạy được lưu trong
`docs/worklog/2026-10-06/005-worklog-m31-unverified-voice-alert.md`.
