Commit de xuat: docs(feature): chot luong M32 workout-only

# Feature — Chế độ luyện tập M32

## Mục tiêu

Tạo lịch tập wellness cá nhân hóa cho người trưởng thành, bắt đầu với Gym và tập tại nhà, bằng chương trình tập-only 4 tuần có buổi tập và check-in hằng tuần.

## Luồng người dùng

1. Mở FeatureHub, xác minh đủ 18 tuổi và rà soát hồ sơ onboarding.
2. Chọn mục tiêu, kinh nghiệm, ngày/giờ tập, thời lượng và hạn chế vận động.
3. Chọn Gym cùng thiết bị có sẵn, hoặc tập tại nhà và chỉ nhận động tác phù hợp tại nhà.
4. Trước quota/AI, kiểm tra giờ tập trên tất cả ngày tập trong tuần sắp áp dụng với các mục lịch tương lai chưa hoàn thành. Nếu trùng, đề xuất giờ trống gần nhất trong tám lựa chọn (phải trống trên mọi ngày; nếu cách đều thì chọn giờ sớm hơn) và hỏi đồng ý rõ ràng.
5. Từ chối hoặc không tìm được giờ phù hợp thì giữ lựa chọn, không gọi AI, tiêu quota hay ghi dữ liệu. Chỉ sau khi đồng ý, Gemini sắp xếp exercise catalog thành lịch tập 28 ngày theo giờ mới; mỗi thao tác chỉ gọi AI một lần.
6. Xem trước hiển thị giờ mới. Lúc xác nhận kiểm tra xung đột lần nữa trong transaction; nếu lịch đã đổi, rollback, đề xuất giờ mới và hỏi đồng ý lại. Đổi giờ trong bản xem trước không gọi AI; chỉ áp các buổi tập M32 sau khi người dùng xác nhận.
7. Check-in sau mỗi tuần; nếu muốn và còn quota, xem trước đề xuất cập nhật các tuần còn lại.

## Data/content v1

Pilot draft: workout flow dùng 24 bài tập (16 gym, 8 tại nhà) và 10 thiết bị. Repo vẫn đóng gói 35 món ăn và 47 nguyên liệu ứng viên cho catalog/legacy data, nhưng M32 workout flow không tạo hoặc áp thực đơn. Catalog hiện có 69 minh họa gốc qua 9 atlas (bài tập, thiết bị, món ăn) cùng 4 biểu tượng nhóm thực phẩm; manifest ánh xạ atlas/cell tới từng ID. Recipe macro chưa được duyệt. Hai video YouTube cho bài kéo cáp ngồi chưa xác minh được nhúng (player error 153 trong browser client), nên chưa được duyệt. Ingredient nutrition giữ FDC ID/provenance từ USDA. Xem manifest tại `docs/DD/fitness_training/assets/README.md`.

## Guardrails

- PO-confirmed 2026-10-05 for this pilot: check the self-declared full birth date on device; block if missing or under 18. This can be spoofed and is not server-trusted adult proof. DOB is excluded from Gemini payloads and logs. Tech/Privacy must decide the release proof, consent, retention and deletion policy.
- Guest tiếp tục lưu cục bộ; Member/FamilyPlus theo hướng đồng bộ M05 ownership/RLS sau khi Tech/Privacy duyệt contract.
- Phạm vi M32 này là lịch tập-only; lọc cứng hạn chế vận động. Dị ứng/thực đơn không tham gia điều kiện tạo hoặc payload AI ở đây; recipe/catalog cũ vẫn cần review nếu được dùng ở luồng riêng.
- Mục tiêu phát hành đầu tiên Android/iOS; video YouTube tùy chọn với minh họa/hướng dẫn và mở YouTube khi IFrame không dùng được; QA/Tech xác nhận platform matrix.
- Dùng M04 cho BMI/BMR/TDEE; không chẩn đoán hoặc kê điều trị.
- Mỗi Gemini generate/replan dùng quota lịch M02; overlap được kiểm tra trước quota/AI.
- Chỉ thay buổi tập M32 tương lai chưa hoàn thành; giữ mục M32 ăn/ngủ, lịch sức khỏe, nguồn lịch khác, lịch đã hoàn thành và quá khứ. Không tự dời mục xung đột.
- Đồng ý đổi giờ chỉ áp dụng cho đề xuất của thao tác hiện tại; chỉ cập nhật giờ của chương trình M32, không sửa giờ tập hồ sơ hoặc lịch hiện có.
- Đổi giờ khi còn preview áp dụng cùng preview, không gọi AI lần nữa.
- PO-directed pilot coding proceeds before reviewer sign-off. Keep M32 Draft and do not represent it as release-approved while Tech/Privacy, Clinical and QA reviews remain pending.

## Trạng thái

BD/DD remain Draft; Tech/Privacy, Clinical and QA approvals remain pending. The PO-directed runtime pilot is implemented in FeatureHub with local workout intake, 28-day workout-only preview/apply, week check-in/replan, M02 quota flow, SQLite persistence/schedule integration and named Gemini backend operations. New program days store empty meals and blank legacy sleep fields; older saved meal/sleep program data remains readable. Food, meal and sleep profile data are not sent to the workout AI operation. See `docs/DD/fitness_training/Overall.md` and the dated worklog for verification and remaining acceptance.
