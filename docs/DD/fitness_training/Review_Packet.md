# M32 — Gói rà duyệt cho pilot và trước phát hành

| Trường | Giá trị |
|---|---|
| Module | M32 FITNESS_TRAINING |
| Tài liệu nguồn | [BD](../../BD/fitness_training/BD_NanoBio_Fitness_Training_M32_v1.0.md), [Overall](./Overall.md), [catalog assets](./assets/README.md) |
| Trạng thái | PO-directed pilot code is present; Tech/Privacy, Clinical and QA/Tech review remains pending; no release sign-off |
| Hướng sản phẩm PO xác nhận | 2026-10-05 |

## Hướng sản phẩm đã xác nhận

- Bản pilot kiểm tra DOB tự khai trên thiết bị; DOB không gửi Gemini. Cách này có thể bị giả mạo và không phải adult attestation tin cậy.
- Guest lưu cục bộ; Member đồng bộ theo M05 self-subject. FamilyPlus dependent-subject selection/consent is not implemented in the pilot.
- Phạm vi wellness; không chẩn đoán/điều trị. Food allergy filtering is not part of the workout-only M32 flow; movement restrictions are honored.
- Requested pilot-scope update 2026-10-05: M32 app flow is workout-only. Food restrictions, recipes and sleep targets do not gate or enter workout AI requests; any future meal flow must own its allergy-safe filtering. This scope update is not reviewer approval.
- Check workout interval overlaps for the week before quota/AI and again in the apply transaction. If the requested time conflicts, propose the nearest free option from the eight existing workout times; a proposal must be free on every selected workout date, and equal-distance choices select the earlier time. Report the requested time and conflict count, then ask for one-time consent before AI. Consent changes only this M32 program's workout time; profile data and existing calendar entries remain unchanged. Declining or finding no free option must not consume quota, call AI or write data.
- If a conflict appears after preview, the apply transaction must roll back without changing the preview or calendar. Recheck current availability, request consent again for any new proposal, and require the user to confirm apply; changing the time in an existing preview must not call AI again. Apply only future incomplete M32 workout entries.
- Android/iOS là mục tiêu phát hành đầu tiên. Video YouTube tùy chọn, chỉ nhúng qua IFrame chính thức sau kiểm tra; khi không phát được vẫn có minh họa, hướng dẫn và nút mở YouTube.

Các hướng trên là quyết định sản phẩm của PO, chưa phải quyết định kỹ thuật/lâm sàng hoặc bằng chứng QA. DD vẫn Draft; pilot implementation is In Progress and is not release-approved.

## Tech Lead

- [ ] Chốt nguồn phát hành adult proof và cách backend xác minh; không tin cờ đủ tuổi tự khai từ client.
- [ ] Chốt ownership Member/FamilyPlus, M05/M11 subject rules, RLS, đồng bộ/xóa/audit và migration cần thiết. Cập nhật canonical Supabase build script nếu có thay đổi schema/RLS/RPC.
- [ ] Duyệt hai operation Gemini, model allowlist, schema giới hạn, validation catalog, M02 quota/idempotency và safe logging.
- [ ] Duyệt transaction áp lịch 7 ngày, rollback, versioning và cập nhật notification; không dùng chế độ replacement xóa các mục sức khỏe khác.
- [ ] Xác nhận ranh giới Android/iOS và khả năng YouTube IFrame trên mỗi nền tảng.

## Privacy

- [ ] Chốt nơi xử lý/lưu ngày sinh, thời điểm chỉ gửi trạng thái đủ tuổi, consent, retention và xóa; chứng minh DOB không vào Gemini hoặc log.
- [ ] Duyệt consent, mục đích dùng dữ liệu sức khỏe, tối thiểu hóa payload, retention, ownership, audit và luồng xóa cùng Tech.

## Clinical

- [ ] Duyệt nội dung sàng lọc và cách xử lý khi người dùng nêu đau/chấn thương, hạn chế vận động hoặc dấu hiệu cần dừng tập/hỏi chuyên gia.
- [ ] Duyệt tiến độ buổi tập, ngày nghỉ, cảnh báo thiết bị/tư thế và điều kiện dừng; không đưa lời khuyên điều trị chấn thương hoặc bệnh lý.
- [ ] Duyệt quy tắc dị ứng/loại trừ nguyên liệu và nội dung 35 món ăn; xác nhận dữ liệu dinh dưỡng là thông tin wellness, không phải thực đơn y khoa.

## QA + Tech

- [ ] Xác nhận ma trận phát hành Android/iOS; Web/desktop ngoài phạm vi v1.
- [ ] Duyệt M32-TC01..TC16: tuổi, trust boundary, nơi tập/thiết bị, movement restrictions, workout-only payload, quota, sai schema/ID, retry/idempotency, cancel preview, overlap/overnight/point-event cases, nearest free time/tie/all selected dates/no option, consent refusal/acceptance and one AI call, apply-time transaction rollback/re-consent, preview time change without another AI call, đổi tuần và thông báo.
- [ ] Xác nhận accessibility: TalkBack/VoiceOver, text scaling, focus order, tương phản, reduced motion và nhãn điều khiển video.
- [ ] Xác nhận video chỉ dùng ID được duyệt; kiểm tra public/embed và IFrame trên từng nền tảng. Khi lỗi/private/embed-disabled phải hiện hình, hướng dẫn và đường dẫn mở YouTube.
- [ ] Xác nhận catalog có provenance/ID nguồn và số lượng mục; không phát hành candidate chưa được duyệt.

## Bằng chứng nội dung/media

- Pilot hiện có: 24 bài tập (16 gym, 8 tại nhà), 10 thiết bị, 35 món ăn, 47 ứng viên nguyên liệu USDA FDC và các atlas minh họa gốc được ánh xạ qua manifest.
- Các giá trị món ăn/nguyên liệu là ứng viên cần rà soát; FDC ID, nguồn và phiên bản phải giữ nguyên. Không đặt USDA API key trong app.
- Hai ứng viên video kéo cáp ngồi chưa được duyệt: lần kiểm tra trước gặp YouTube IFrame error 153. Video không bắt buộc để dùng bài tập; khi chưa có ID qua kiểm tra, dùng ảnh minh họa và hướng dẫn.
- Không tải/lưu video hoặc thumbnail. Không thể cam kết rủi ro bản quyền bằng không; mọi nguồn media bên thứ ba cần được rà theo điều khoản và trạng thái nhúng.

## Ghi nhận sign-off

| Vai trò | Người duyệt / nhóm | Quyết định | Ngày, múi giờ | Bằng chứng / ghi chú |
|---|---|---|---|---|
| Tech Lead | Chưa ghi nhận | Pending | — | — |
| Privacy reviewer | Chưa ghi nhận | Pending | — | — |
| Clinical reviewer | Chưa ghi nhận | Pending | — | — |
| QA Lead | Chưa ghi nhận | Pending | — | — |

Ghi đầy đủ tên, vai trò, phiên bản tài liệu và ngày trước khi đổi trạng thái. Không tự điền thay reviewer. Pilot source code is present by PO direction; keep the feature marked Draft and do not claim release readiness until each applicable reviewer signs and Android/iOS, sandbox and content checks pass.
