# Test — M32 xin phép đổi giờ khi có xung đột

## Phạm vi

Xác minh bộ đề xuất giờ trống gần nhất, một lần đồng ý trước AI, cách xử lý khi lịch đổi sau xem trước, và không sửa hồ sơ/lịch đang có.

## Kết quả

- Giờ đề xuất được kiểm tra trên mọi ngày tập trong tuần; lựa chọn gần nhất được ưu tiên và nếu cách đều thì chọn giờ sớm hơn. Bỏ qua lựa chọn gần hơn nếu bất kỳ ngày tập nào còn trùng; nếu cả tám khung đều trùng thì không tự đổi.
- Từ chối giữ lựa chọn ban đầu, không gọi AI hoặc lưu bản xem trước. Đồng ý đổi `17:30` sang `16:30` tạo bản xem trước bằng đúng một lần gọi AI; giờ chỉ nằm trong intake của chương trình M32.
- Nếu transaction áp lịch gặp xung đột mới, bản xem trước và lịch được giữ nguyên. UI nêu đề xuất mới, xin đồng ý lại, cho phép áp sau lần xác nhận tiếp theo và không gọi AI lần nữa.
- Kiểm thử SQLite tiếp tục xác minh rollback khi lịch thay đổi, giữ mục ăn/ngủ M32, mục sức khỏe, lịch nguồn khác, mục hoàn thành và lịch quá khứ.
- Không thay đổi hồ sơ người dùng hay schema SQLite.

## Commands

- `LD_LIBRARY_PATH=/tmp/nanobio-sqlite flutter test <4 focused M32 test files>`: PASS, 24/24.
- `flutter analyze <10 touched M32 source/test files>`: PASS, 0 issues.
- `dart format <touched Dart files>`: PASS.
- `git diff --check`: PASS.
- Android QA-profile acceptance: NOT RUN; no APK was installed and no personal schedule on the connected phone was changed.

## Ranh giới

M32 remains Draft/pilot. Tech/Privacy, Clinical and QA sign-offs, Android QA profile/device acceptance, live Gemini and Supabase Sandbox acceptance remain pending.
