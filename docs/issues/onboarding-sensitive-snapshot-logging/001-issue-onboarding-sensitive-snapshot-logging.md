Commit đề xuất: docs(issue): ghi nhận lỗi log snapshot dữ liệu onboarding nhạy cảm

# Onboarding log toàn bộ snapshot hồ sơ sức khỏe sau khi lưu

## Tóm tắt
- Sau khi lưu onboarding, datasource query lại nhiều bảng SQLite rồi `debugPrint` toàn bộ snapshot.
- Snapshot có thể chứa email, số điện thoại, tên, năm sinh, mục tiêu, bệnh nền, dị ứng, điều trị, survey answers.

## Mức độ ảnh hưởng
- Severity: high
- Ảnh hưởng user: dữ liệu sức khỏe/PII bị lộ trong log thiết bị hoặc log CI.
- Ảnh hưởng dev/build/test: log lớn sau onboarding làm chậm và nhiễu debug.

## Cách tái hiện
1. Hoàn tất onboarding.
2. Quan sát log có block `ONBOARDING SAVED TO SQLITE`.
3. Log in JSON snapshot của các bảng theo `user_id`.

## Đã xác nhận
- `lib/features/onboarding/data/datasource/onboarding_local_datasource.dart:90-91` log userId.
- `lib/features/onboarding/data/datasource/onboarding_local_datasource.dart:261-310` query snapshot nhiều bảng.
- `lib/features/onboarding/data/datasource/onboarding_local_datasource.dart:312-320` `debugPrint` snapshot JSON.
- `lib/core/utils/logger/app_logger.dart:15` đang bật logging cố định.

## Giả thuyết
- Debug log phục vụ kiểm tra migration/onboarding nhưng chưa được gỡ hoặc gate trước release.

## Workaround
- Không chia sẻ log thiết bị/CI từ build có dữ liệu thật.

## Hướng fix đề xuất
- Xóa block snapshot hoặc chỉ log summary count đã lưu.
- Gate log nhạy cảm bằng `kDebugMode` và feature flag nội bộ.
- Không log userId/email/phone/raw health profile.

## Files/log liên quan
- `lib/features/onboarding/data/datasource/onboarding_local_datasource.dart`
- `lib/core/utils/logger/app_logger.dart`

## Liên kết
- Worklog: ../../worklog/2026-06-19/007-worklog-release-1-0-bug-audit.md
