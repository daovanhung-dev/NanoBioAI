# Overall — M32 / Chế độ luyện tập

## 0. Document information

| Field | Value |
|---|---|
| Module | M32 FITNESS_TRAINING |
| Version | v1.0 |
| DD decision | Draft |
| Implementation | Implemented in Flutter/Edge pilot; reviewer approval pending |
| Verification | 28 M32/FeatureHub Flutter tests, 16 M05 sync tests, 12 Edge tests, targeted analyze and Android debug/release builds passed; device/Sandbox unverified |
| Source BD | BD-NANOBIO-FITNESS-TRAINING-001 |
| Owner | M32 pilot implementation; Tech/Privacy, Clinical and QA sign-off pending |
| Updated | 2026-10-05 |

## Runtime implementation record — 2026-10-05

PO-directed pilot source is now wired from FeatureHub through the intake, catalog selection, preview/confirm, program calendar and weekly check-in/replan flow. SQLite v25 stores the 28-day program; applying a week replaces only future incomplete M32 schedule rows in one local transaction. M02 is checked before Gemini for members and the one-time Guest allowance is checked before Gemini and consumed atomically when the preview is saved. Gemini operations are limited to `fitness_training_generate` and `fitness_training_replan`; app validation rejects unknown catalog IDs, unsafe filters and response keys outside the declared schema.

The static pilot pack is bundled in `assets/data/fitness_training/`: 24 exercise, 10 equipment, 35 recipe and 47 candidate ingredient records with nine original illustration atlases. Nutrition metadata retains USDA FDC IDs. Current YouTube rows are not approved for embedding; the app keeps original instructions/illustrations and offers an external YouTube search fallback. The feature is connected to FeatureHub and the v1 router. Member self-owned rows have an M05 snapshot/RLS source contract; FamilyPlus subject selection and consent flow are not implemented. SQLite/Edge tests and Android build evidence are recorded in the 2026-10-05 runtime worklog.

This implementation is a pilot and does not close reviewer decisions. The age check uses self-declared birth date on device and is spoofable; catalog, nutrition, clinical safety, retention/deletion, FamilyPlus scope and platform/device acceptance remain review items. Do not treat the source or local tests as deployment, sandbox, or release approval.

## 1. Goal and boundary

Tạo một chương trình wellness 28 ngày phù hợp hồ sơ, mục tiêu, địa điểm tập, thiết bị, lịch sinh hoạt và lựa chọn thực phẩm. Tuần đang hoạt động được áp vào lịch 7 ngày; các tuần còn lại lưu trong program aggregate. Người dùng xem trước và xác nhận mọi lần áp dụng.

V1 chỉ gồm Gym và tập tại nhà cho người đủ 18 tuổi. Không gồm Yoga/Boxing, chẩn đoán, điều trị, phục hồi chấn thương hoặc thực đơn trị bệnh. BMI/BMR/TDEE lấy từ công thức M04; AI không thay thế công thức hoặc chẩn đoán.

## 2. Actors and access

| Actor | Access | Constraint |
|---|---|---|
| Guest | Theo quyền tạo lịch đầu tiên M02; lưu cục bộ | Guest đã dùng lượt khởi tạo không được thêm ngoại lệ |
| Member Free | Theo quota lịch M02/M06; đồng bộ theo hướng M05 sau duyệt | Tạo mới và mỗi replan đều tiêu thụ một lượt |
| Plus/FamilyPlus | Theo trusted entitlement hiện hành; đồng bộ theo M05/M11 sau duyệt | Family subject chỉ theo ownership/consent được chấp thuận |
| System | Validate, lưu program, áp tuần vào lịch | Atomic, idempotent, không ghi raw prompt/PII |

## 3. Feature and data summary

Features: M32-F01 intake/eligibility; M32-F02 curated catalog; M32-F03 generate/apply; M32-F04 weekly check-in/replan.

Entities:

| Entity | Purpose | Sensitivity |
|---|---|---|
| Training profile snapshot | Mục tiêu, lịch rảnh, địa điểm, gear, restrictions, food groups | Health-related |
| Training program | Phiên bản chương trình 28 ngày và tuần hiện tại | Health-related |
| Program day/session | Buổi tập, bữa ăn, giờ ngủ, trạng thái áp dụng | Health-related |
| Exercise/equipment catalog | Bài tập, điều kiện thiết bị, media IDs | Public product content |
| Ingredient/recipe catalog | Thành phần, FDC provenance, dị ứng, nutrition | Nutrition data |
| Weekly check-in | Phản hồi để đề xuất replan | Health-related |

Guest data theo local policy hiện có. Member data theo M05/Supabase owner/RLS contract; schema, retention, consent và subject behavior cần Tech/Privacy sign-off.

## 4. Rules

| Rule | Contract |
|---|---|
| M32-BR01 | Chỉ bắt đầu nếu ngày sinh đầy đủ trong hồ sơ cho biết người dùng đã đủ 18 tuổi. |
| M32-BR02 | Bản pilot tính tuổi trên thiết bị từ ngày sinh người dùng tự khai; DOB không gửi Gemini/logs. Đây không phải bằng chứng tin cậy phía máy chủ và có thể bị giả mạo. |
| M32-BR03 | Mọi AI generation/replan đi qua M02/M06 quota gateway |
| M32-BR04 | AI output chỉ chứa catalog IDs đã được lọc; local/server validator kiểm tra schema, ownership, range và restrictions |
| M32-BR05 | Gym chỉ dùng bài có gear đã chọn; home chỉ dùng movement được đánh dấu home-compatible |
| M32-BR06 | Allergies/restrictions là hard filters; không có catalog match thì dừng, không tự bịa món/bài |
| M32-BR07 | Không cập nhật lịch trước khi người dùng review và xác nhận |
| M32-BR08 | Atomic replace chỉ áp vào task tương lai chưa hoàn thành thuộc workout/meal/sleep; giữ task khác và history |
| M32-BR09 | Lỗi Gemini/validator/quota giữ program/lịch cũ; M02 BR02 quy định quota không commit trước kết quả hợp lệ |
| M32-BR10 | Nội dung là wellness support; no diagnosis/treatment/medical claim |
| M32-BR11 | Log chỉ stage/status/count/error type/correlation ID, không raw prompt/response/profile |
| M32-BR12 | Phạm vi phát hành v1 hướng tới Android/iOS; video là tùy chọn, chỉ dùng YouTube IFrame đã kiểm tra và luôn có minh họa/hướng dẫn cùng đường dẫn mở YouTube dự phòng. QA/Tech xác nhận ma trận cuối. |

## 5. Main flow and failures

1. FeatureHub → adult gate → review onboarding → training questionnaire.
2. Chọn home/gym; chọn thiết bị hoặc bodyweight; chọn food groups, restrictions, meal windows và sleep/wake targets.
3. M04 tính metric cục bộ; catalog được lọc trước khi AI request.
4. M02/M06 authorize/quota check; backend Gemini generate program dùng allowlisted catalog context.
5. Validator kiểm tra IDs, giới hạn thời gian/sets/reps, allergens, gear, recovery và 28 ngày.
6. Hiển thị preview; confirm lưu program và transactionally thay tuần hiện tại.
7. Cuối mỗi tuần hỏi check-in. Nếu user chọn điều chỉnh và có quota, replan phần còn lại; preview rồi confirm tuần kế.

| Failure | Result |
|---|---|
| Under 18 / DOB chưa xác minh | Chặn trước quota và AI; giữ dữ liệu hiện có |
| Quota denied | Không gọi AI; giữ program/lịch cũ, dùng thông điệp M02 |
| AI/network/invalid response | Không sửa schedule/program đang active; retry idempotent theo M02 |
| Không có bài/món an toàn phù hợp | Không tạo phần đó; yêu cầu người dùng điều chỉnh lựa chọn hoặc dừng |
| YouTube blocked/unavailable | Hiện hình/minh họa và mô tả; nút mở YouTube |
| Schedule write/sync thất bại | Rollback transaction, giữ trạng thái cũ; retry an toàn |

## 6. Schedule contract

Program là 4 tuần; calendar chỉ giữ cửa sổ 7 ngày của tuần đang áp dụng. Ngày bắt đầu theo lịch người dùng trong Asia/Ho_Chi_Minh. Meal windows và sleep/wake lấy từ routine hiện có, cho phép chỉnh trong intake. Workout có buổi và ngày nghỉ; không áp dụng quy tắc hai bài tập chung mỗi ngày từ normalizer cũ.

Khi confirm: tạo snapshot/version program; xóa/thay future incomplete items thuộc fitness workout, meal và sleep cho đúng tuần; giữ completed items, unrelated health tasks, source IDs và notification semantics. Week review không tự thay lịch: replan preview và confirm là bắt buộc. Nếu bỏ qua AI adjustment, chuyển sang tuần kế tiếp trong program đã lưu.

## 7. AI/API and privacy

Hai operation trên luồng Gemini backend hiện có: tạo chương trình và điều chỉnh các tuần còn lại. Request gồm request_id, cờ đã qua bước tuổi trên thiết bị, hồ sơ tối thiểu/metrics M04, nơi tập/thiết bị/nhóm thực phẩm, ID catalog đã lọc, giờ sinh hoạt và check-in tuần. DOB, ghi chú sức khỏe tự do và user ID không gửi đến Gemini. Cờ tuổi có thể bị giả mạo ở client; người dùng đã chấp nhận hạn chế này cho pilot. Server giới hạn operation/payload; app kiểm tra schema, catalog ID, quota M02 và idempotency trước khi áp dụng.

M32-Q01 — PO chọn ngày 2026-10-05: bản pilot đọc ngày sinh đầy đủ tự khai trong hồ sơ và tính đủ tuổi ngay trên thiết bị. Gemini không nhận DOB; request chỉ mang cờ đã qua bước tuổi. Đây không phải kiểm soát đáng tin cậy phía máy chủ. Tech/Privacy vẫn cần duyệt consent, lưu trữ, retention/xóa và quyết định xác minh tuổi cho phát hành.

## 8. Non-functional and safety requirements

- Privacy: explicit review/consent before AI, data minimization, subject ownership, delete/retention policy approved by M19/Privacy.
- Security: client không giữ Gemini/USDA secret; no raw prompt/response in logs.
- Integrity: request ID, program version, idempotent schedule transaction and rollback.
- Safety: catalog restriction labels, reviewed movement and recipe content, allergy hard-filter, no injury treatment or disease-specific nutrition. Clinical reviewer must define red-flag/restriction behavior before approval.
- Accessibility: semantic forms/cards/player controls, text scaling, screen-reader labels, reduced motion; no state indicated only by color.
- External media: official YouTube embed only; no download/rehosting; public page may disable embed at any time.

## 9. Open decisions and approval gates

| ID | Question / gate | Owner | Status |
|---|---|---|---|
| M32-Q01 | Age gate from self-declared full birth date on device; server trust, DOB residency, consent, retention and deletion | Tech + Privacy | PO selected local self-declared age check 2026-10-05; server trust limitation accepted for pilot; reviewer decision open |
| M32-Q02 | Clinical review of intake screening, movement safety, nutrition constraints and stop/consult guidance | Clinical | PO wellness boundary confirmed 2026-10-05; clinical rules/content approval open |
| M32-Q03 | Member/FamilyPlus cloud schema, M05 ownership/RLS, consent, retention, deletion and audit | Tech + Privacy | PO sync direction confirmed 2026-10-05; reviewer contract open |
| M32-Q04 | QA acceptance matrix for Android/iOS, accessibility, YouTube IFrame and fallback coverage | QA + Tech | PO target/fallback confirmed 2026-10-05; platform validation open |
| M32-GATE01 | PO, Tech Lead, Privacy, Clinical and QA sign-offs recorded in README/BD | All | Coding exception directed by PO 2026-10-05; reviewer sign-offs remain pending and release remains blocked |

PO directed runtime implementation on 2026-10-05 without waiting for the review packet. This instruction is not a reviewer sign-off: Tech/Privacy, Clinical and QA remain pending, and the feature must not be represented as release-approved. Runtime status and evidence are tracked separately.

## 10. PO-confirmed product directions and reviewer packet

The PO confirmed the following product directions on 2026-10-05: local age check from self-declared profile birth date for the pilot; Member sync under the M05 owner/RLS contract with Guest local storage; wellness-only scope with allergy and movement hard filters; Android/iOS as the first release target; optional official YouTube embeds with illustration, instructions and open-on-YouTube fallback. Coding proceeds by PO direction while reviewer decisions remain pending. Existing [review packet](./Review_Packet.md) records pending review only; no reviewer approval is inferred.

## 11. Traceability

| BD | Feature | Function | View | Test |
|---|---|---|---|---|
| M32-BR01..02 | M32-F01 | M32-FN01 | M32-V01/V02 | M32-TC01..02 |
| M32-BR04..06 | M32-F02 | M32-FN02 | M32-V03/V04 | M32-TC03..05 |
| M32-BR03..09 | M32-F03 | M32-FN03/FN04 | M32-V05/V06 | M32-TC06..11 |
| M32-BR03..11 | M32-F04 | M32-FN05 | M32-V07 | M32-TC12..16 |
