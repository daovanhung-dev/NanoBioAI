Commit de xuat: docs(worklog): ghi nhan build Android App Bundle

# Worklog - Xuất Android App Bundle Nabi

## Thời gian

- Ngày: 2026-10-05
- Bắt đầu: không ghi nhận riêng
- Kết thúc: 13:32
- Timezone: Asia/Saigon

## Phạm vi

- Loại task: release build và xác minh artifact
- Module chính: Android release signing, Android App Bundle
- Yêu cầu gốc: xuất file AAB để người dùng tải lên Google Play Console.

## Đã làm

- Dùng cấu hình ký release có sẵn trong dự án; không đọc/ghi lại password hay private keystore.
- Tạo `build/app/outputs/bundle/release/app-release.aab` với version `1.0.1+4`.
- Bundletool xác nhận cấu trúc AAB và manifest: package `com.nanobioai.app`, version name `1.0.1`, version code `4`, nhãn `Nabi`.
- Xác nhận AAB có chữ ký release; chứng thư ký công khai tự ký, SHA-256 fingerprint: `0E:53:59:9A:7E:2D:0F:85:69:AA:68:0E:D5:98:0B:9F:22:94:01:90:ED:65:68:0D:CA:0C:FF:17:F4:4A:A7:3F`.
- Kiểm tra `auth.env` trong bundle chỉ có Supabase client anon key với claim `role=anon`; không tìm thấy biến có tên Gemini/service-role/private-key/password/token.
- Không upload bundle lên Play Console.

## File code/docs đã sửa

- `docs/worklog/2026-10-05/005-worklog-release-aab.md`: ghi kết quả build.
- `build/app/outputs/bundle/release/app-release.aab`: artifact sinh ra, được quản lý trong thư mục build.
- Không sửa source code, signing config hoặc tệp chứa credential.

## Tài liệu liên quan

- `docs/features/rebrand-nabi/001-feature-rebrand-nabi.md`
- Google Play xác định giới hạn theo kích thước download đã nén sau khi phân tích bundle; artifact này chưa được upload để Play Console tính kích thước thực tế.

## Commands

- `/tmp/nabi_flutter_sdk/bin/flutter build appbundle --release`: PASS; tạo AAB 148,736,117 bytes.
- `java -jar bundletool-all-1.18.3.jar validate --bundle=...`: PASS, exit code 0.
- `java -jar bundletool-all-1.18.3.jar dump manifest --bundle=... --module=base`: PASS; manifest khớp package/name/version.
- `keytool -printcert -jarfile ...`: PASS; lấy fingerprint chứng thư công khai.
- Kiểm tra asset env trong AAB bằng script chỉ xuất tên biến và JWT role, không xuất giá trị: PASS.
- `git diff --check`: PASS.

## Lỗi/Rủi ro

- Đã fix: không phát sinh lỗi build.
- Chưa fix: không thể xác nhận fingerprint có trùng upload key đã đăng ký trên Play Console nếu ứng dụng đã có listing; người dùng cần so khớp fingerprint trước upload.
- Cần kiểm tra tiếp: upload vào Internal testing track để Play Console kiểm tra đầy đủ policy, target API, kích thước download và signing continuity.

## Tỷ lệ hoàn thành

- Hoàn thành: tạo AAB release có chữ ký và xác minh manifest.
- Đang dở: chưa tải lên Play Console.

## Tự đánh giá và tối ưu phiên sau

- Chất lượng đầu ra: tốt - artifact release có chữ ký, version và package đã được bundletool kiểm tra.
- Mức độ hoàn thành task: hoàn thành yêu cầu xuất file; chưa phát hành.
- Bằng chứng kiểm chứng: `flutter build appbundle --release`, bundletool validate/dump manifest, public signing certificate fingerprint.
- Điểm tốn token/chưa tối ưu: lần đầu gọi nhầm bundletool library jar không phải executable standalone; đã chuyển sang bundletool-all để kiểm tra đúng.
- Cách tối ưu cho phiên sau: kiểm tra sẵn standalone bundletool và kế hoạch ký release trước khi bắt đầu đóng gói.
- Task-skill cần đọc lần sau: `.codex/task-skills/coding.md`
