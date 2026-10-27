Commit de xuat: docs(iot): them ho so ESP OSTB 3ST vao agent context

# Worklog - Hồ sơ ESP OSTB 3ST và bắt buộc nạp context IoT

## Thời gian

- Ngày: 2026-10-23
- Bắt đầu: 12:31
- Kết thúc: 12:39
- Timezone: Asia/Ho_Chi_Minh

## Phạm vi

- Loại task: docs-context
- Module chính: IoT, XiaoZhi ESP32 OSTB 3ST và NanoBio agent context
- Yêu cầu gốc: kiểm tra cấu hình ESP đang kết nối, ghi hồ sơ thiết bị có phân loại bằng chứng, và bắt agent đọc hồ sơ mỗi khi làm task IoT.

## Đã làm

- Dùng esptool v5.6.0 và USB descriptor để đọc chip, flash, trạng thái bảo mật, partition table và app descriptor. Lệnh chỉ đọc; thiết bị được reset vào bootloader và hard-reset để khởi động lại. Không ghi/xóa flash và không đọc NVS.
- Tạo hồ sơ phân biệt giá trị đọc trực tiếp với cấu hình board/build lấy từ source; bỏ MAC, serial USB đầy đủ và thông tin bí mật.
- Ghi nhận firmware `ostb_3st_lcd_hello_scroll`/ESP-IDF v5.4 và partition `factory` 1 MB khác profile XiaoZhi OTA/assets trong checkout.
- Nối quy tắc đọc hồ sơ vào router gốc, domain, subproject `AGENTS.md` và context README.
- Sửa board README để không còn khẳng định CSV source trùng partition table thực tế.
- Đồng bộ FILE_INDEX với Git: 1773 đường dẫn gồm 1772 tracked và 1 first-party untracked.

## File code/docs đã sửa

- `iot/xiaozhi-esp32/docs/agent-context/CONNECTED_DEVICE_OSTB_3ST.md` - tạo - hồ sơ thiết bị và cấu hình source có gắn mức bằng chứng.
- `.codex/AGENTS.md`, `.codex/domains/xiaozhi-esp32.md` - sửa - bắt buộc đọc hồ sơ cho mọi task IoT/ESP32.
- `iot/xiaozhi-esp32/AGENTS.md`, `iot/xiaozhi-esp32/docs/agent-context/README.md` - sửa - thêm hồ sơ vào thứ tự nạp context.
- `iot/xiaozhi-esp32/docs/agent-context/FILE_INDEX.md` - sửa - thêm hồ sơ và đồng bộ status, size, counts.
- `iot/xiaozhi-esp32/main/boards/ostb/ostb-xiaozhi-3st/README.md` - sửa - phân biệt partition source và partition live.
- `docs/worklog/2026-10-23/002-worklog-connected-esp32-profile.md` - tạo - ghi nhận thay đổi và bằng chứng.
- `.codex/history/*`, `.codex/task-skills/*` - sinh lại từ worklog nếu refresh có thay đổi.

## Tài liệu liên quan

- `iot/xiaozhi-esp32/main/boards/ostb/ostb-xiaozhi-3st/config.h`
- `iot/xiaozhi-esp32/main/boards/ostb/ostb-xiaozhi-3st/config.json`
- `iot/xiaozhi-esp32/main/boards/ostb/ostb-xiaozhi-3st/config.local-ai.json`
- `iot/xiaozhi-esp32/partitions/ostb-xiaozhi-3st-16m.csv`

## Commands

- Esptool `chip-id`, `flash-id`, `get-security-info`, và `read-flash` vùng partition/app header: PASS - đọc chip ESP32-S3 rev 0.2, PSRAM 8 MB, flash 16 MB, security flags, partition `factory` 1 MB và metadata app; không ghi/xóa flash.
- Python đồng bộ inventory Git vào `FILE_INDEX.md`: PASS - 1772 tracked, 1 first-party untracked, 0 tracked path thiếu.
- Kiểm tra relative Markdown links, rule bắt buộc đọc hồ sơ, và loại MAC/credential khỏi hồ sơ: PASS.
- `git diff --check`: PASS.
- `pwsh -NoLogo -NoProfile -File .codex/tools/validate_codex_integrity.ps1`: FAIL - validator báo thiếu `docs/audit/source_truth_manifest.json` và stale path trong history/task-skill cũ. Các lỗi này không thuộc thay đổi IoT hiện tại.
- Build/test Flutter hoặc ESP-IDF: SKIPPED - chỉ cập nhật tài liệu/context.

## Lỗi/Rủi ro

- Đã sửa: tài liệu OSTB từng nói partition source đang trùng thiết bị; số đo live cho thấy không đúng.
- Chưa xác minh: firmware source/commit, pin map đang chạy, SSID/IP/OTA URL trong NVS, trạng thái màn hình/audio/touch và giao tiếp phone-local AI.
- Cần kiểm tra tiếp: xác nhận vật lý board/pin nếu cần vượt mức bằng chứng metadata và source; trước khi ghi flash phải chốt image/partition tương thích.

## Tỷ lệ hoàn thành

- Hoàn thành: 100% cập nhật hồ sơ và mandatory-read routing.
- Đang đo: 0% kiểm thử runtime; ngoài phạm vi docs-context.

## Tự đánh giá và tối ưu phiên sau

- Chất lượng đầu ra: tốt - tách rõ thông số live, source profile và phần chưa xác minh.
- Mức độ hoàn thành task: hoàn tất; validator repo-wide có lỗi ngoài phạm vi.
- Bằng chứng kiểm chứng: truy vấn esptool chỉ đọc, đối chiếu source, kiểm tra link/routing, inventory và diff whitespace.
- Điểm tốn token/chưa tối ưu: cần đối chiếu profile hardware, firmware descriptor và partition table vì chúng khác nhau.
- Cách tối ưu cho phiên sau: đọc file hồ sơ mới trước mọi task IoT/ESP32 rồi chỉ re-probe khi board hoặc firmware thay đổi.
- Task-skill cần đọc lần sau: `.codex/task-skills/docs-context.md`
