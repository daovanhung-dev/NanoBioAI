Commit de xuat: docs(feature): mo ta M32 che do luyen tap

# Feature — Chế độ luyện tập M32

## Mục tiêu

Tạo trải nghiệm PT wellness cá nhân hóa cho người trưởng thành, bắt đầu với Gym và tập tại nhà, bằng chương trình 4 tuần có buổi tập, bữa ăn, giờ ngủ và check-in hằng tuần.

## Luồng người dùng

1. Mở FeatureHub, xác minh đủ 18 tuổi và rà soát hồ sơ onboarding.
2. Chọn mục tiêu, kinh nghiệm, ngày/giờ tập, thời lượng, giờ ngủ, hạn chế vận động, dị ứng và nhóm thực phẩm.
3. Chọn Gym cùng thiết bị có sẵn, hoặc tập tại nhà và chỉ nhận động tác phù hợp tại nhà.
4. Gemini sắp xếp catalog đã duyệt thành lịch 28 ngày sau khi qua quota M02 và kiểm tra dữ liệu.
5. Xem trước, xác nhận áp dụng tuần 7 ngày hiện tại.
6. Check-in sau mỗi tuần; nếu muốn và còn quota, xem trước đề xuất cập nhật các tuần còn lại.

## Data/content v1

Pilot draft: 24 bài tập (16 gym, 8 tại nhà), 10 thiết bị, 35 món ăn và 47 nguyên liệu ứng viên. Catalog hiện có 69 minh họa gốc qua 9 atlas (bài tập, thiết bị, món ăn) cùng 4 biểu tượng nhóm thực phẩm; manifest ánh xạ atlas/cell tới từng ID. Các recipe macro là phép tính từ dữ liệu nguồn, chưa được duyệt. Hai video YouTube cho bài kéo cáp ngồi được tìm trong Chrome nhưng chưa xác minh được nhúng (player error 153 trong browser client), nên chưa được duyệt để đưa vào catalog. Recipe/exercise text viết mới; ingredient nutrition giữ FDC ID/provenance từ USDA. Video là tùy chọn; khi được duyệt chỉ nhúng qua IFrame player chính thức; không tải media hoặc thumbnail. Xem manifest tại `docs/DD/fitness_training/assets/README.md`.

## Guardrails

- PO-confirmed 2026-10-05 for this pilot: check the self-declared full birth date on device; block if missing or under 18. This can be spoofed and is not server-trusted adult proof. DOB is excluded from Gemini payloads and logs. Tech/Privacy must decide the release proof, consent, retention and deletion policy.
- Guest tiếp tục lưu cục bộ; Member/FamilyPlus theo hướng đồng bộ M05 ownership/RLS sau khi Tech/Privacy duyệt contract.
- Phạm vi wellness, với dị ứng và hạn chế vận động được lọc cứng; Clinical phải duyệt sàng lọc, stop/consult guidance và nội dung dinh dưỡng.
- Mục tiêu phát hành đầu tiên Android/iOS; video YouTube tùy chọn với minh họa/hướng dẫn và mở YouTube khi IFrame không dùng được; QA/Tech xác nhận platform matrix.
- Dùng M04 cho BMI/BMR/TDEE; không chẩn đoán hoặc kê điều trị.
- Mỗi Gemini generate/replan dùng quota lịch M02.
- Chỉ thay task tương lai tập/ăn/ngủ chưa hoàn thành; giữ history và task sức khỏe khác.
- PO-directed pilot coding proceeds before reviewer sign-off. Keep M32 Draft and do not represent it as release-approved while Tech/Privacy, Clinical and QA reviews remain pending.

## Trạng thái

BD/DD remain Draft; Tech/Privacy, Clinical and QA approvals remain pending. The PO-directed runtime pilot is implemented in FeatureHub with local intake, 28-day program preview/apply, week check-in/replan, M02 quota flow, SQLite persistence/schedule integration and named Gemini backend operations. Assets bundle 24 exercises, 10 equipment records, 35 recipes, 47 USDA FDC candidate ingredients and nine original illustration atlases. Nutrition and content remain candidates pending review. No current YouTube candidate is approved for embedding; UI retains original illustration, instructions and an external YouTube fallback. See `docs/DD/fitness_training/Overall.md` and the dated runtime worklog for verification and remaining acceptance.
