# Worklog - Flutter backend AI only

## Thời gian

- Ngày: 2026-10-30
- Bắt đầu: khoảng 21:30 (Asia/Ho_Chi_Minh)
- Kết thúc: 22:33 (Asia/Ho_Chi_Minh)
- Timezone: Asia/Ho_Chi_Minh

## Phạm vi

- Loại task: coding, kiểm tra và build APK.
- Module chính: Flutter Mobile AI, voice, Food Scan và onboarding.
- Yêu cầu gốc: bỏ màn cài model AI local lúc khởi động; chuyển các chức năng AI sang NanoBio backend; khách phải đăng nhập để dùng AI; không chạy local fallback khi lỗi.
- Giới hạn triển khai: chỉ cập nhật mã nguồn và tạo APK local; không deploy/cutover hoặc phân phối APK.

## Đã làm

- Gỡ `LocalAiSetupGate` khỏi khởi động app, xóa runtime text/vision local và dependency LLM tương ứng. Khách vẫn vào app và dùng chức năng không cần AI; onboarding không gửi yêu cầu tạo kế hoạch AI khi chưa có session backend.
- Chuyển chat, streaming, JSON/kế hoạch, Nabi Care, phân tích sức khỏe/dinh dưỡng/giấc ngủ/vận động, Voice Chat và Food Scan qua `BackendAiTextClient` và API NanoBio. Client kiểm tra session trước khi gửi; không dùng HTTP hoặc local fallback.
- Khi output backend sai cấu trúc, trả lỗi AI an toàn cho UI thay vì tạo lịch từ catalog cục bộ. Chuẩn hóa lỗi timeout/unavailable để người dùng có thể thử lại.
- Bổ sung nội dung thông báo khi gửi ảnh và ngữ cảnh sức khỏe qua HTTPS.
- Giữ ghi âm, phát giọng nói, TTS và kết nối ESP32. Ngoại lệ có phạm vi: Whisper chỉ nhận dạng giọng nói trong Nabi ESP sau khi người dùng chủ động mở tính năng; phần trả lời AI gọi backend. Whisper không được tải/khởi tạo khi khởi động app.
- Cấu hình build release dùng `API_BASE_URL=https://42.118.174.147`; sao lưu APK trước đó tại `build/archives/app-release-before-backend-ai-2026-10-30.apk`.

## Kiểm tra và bằng chứng

- Flutter focused suite: 144/144 kiểm thử đạt, gồm backend AI client, chat/streaming, kế hoạch, onboarding, cold start, Food Scan, Voice Chat và Nabi ESP.
- `dart analyze` trên các file/runtime/test liên quan: không có vấn đề.
- `git diff --check`: đạt.
- Audit source/dependency: không còn `LocalAiTextClient`, `LocalAiRuntimeService`, `LocalAiSetupGate`, `llamadart`, Gemini runtime hoặc gọi inference text/vision local. Whisper còn lại được giới hạn cho nhận dạng tiếng nói Nabi ESP.
- HTTPS health probe tới `https://42.118.174.147/health`: kết nối TCP cổng 443 bị từ chối; không thể xác nhận trust hoặc AI end-to-end trên server.
- `flutter build apk --release --dart-define=API_BASE_URL=https://42.118.174.147`: thành công; bản cuối 455,585,004 bytes, SHA-256 `6d3ec5d3ca1131f24435c610a8898fc9af6ad39371ebd7e33e6ac80353a3dccc`.
- `apksigner verify --verbose --print-certs`: đạt, APK có chữ ký v2; `unzip -t`: không lỗi. Kiểm tra `libapp.so` xác nhận có URL HTTPS backend và không có `LocalAiSetupGate`/`LocalAiTextClient`.
- APK cũ được giữ riêng, SHA-256 `7f861763c9b779d932b611a5bd620ab2309af9d0b2b1b7df340168b1e9ccf412`.

## Giới hạn và trạng thái

- Không deploy server, không write-freeze/import dữ liệu Supabase, không cutover và không phân phối APK.
- Chưa xác nhận AI end-to-end trên thiết bị vì cổng HTTPS 443 không kết nối được. Không dùng HTTP cổng 8080 làm fallback.
- Màn/luồng Whisper chủ động trong Nabi ESP vẫn tải model nhận dạng giọng nói khi cần; model này không trả lời hội thoại và không ảnh hưởng cold start.
