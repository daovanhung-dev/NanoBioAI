# Overall — M32 / Chế độ luyện tập

## 0. Document information

| Field | Value |
|---|---|
| Module | M32 FITNESS_TRAINING |
| Version | v1.0 |
| DD decision | Draft |
| Implementation | Implemented in Flutter/Edge pilot; reviewer approval pending |
| Verification | Workout-only/conflict consent: 24 focused Flutter tests and targeted analyze passed; Android QA profile acceptance pending; personal device data untouched |
| Source BD | BD-NANOBIO-FITNESS-TRAINING-001 |
| Owner | M32 pilot implementation; Tech/Privacy, Clinical and QA sign-off pending |
| Updated | 2026-10-05 |

## Runtime implementation record — 2026-10-05

PO-directed pilot source is now wired from FeatureHub through the intake, catalog selection, preview/confirm, program calendar and weekly check-in/replan flow. SQLite v25 stores the 28-day program. M02 is checked before Gemini for members and the one-time Guest allowance is checked before Gemini and consumed atomically when the preview is saved. Gemini operations are limited to `fitness_training_generate` and `fitness_training_replan`; app validation rejects unknown exercise IDs, unsafe movement filters and response keys outside the declared schema.

2026-10-05 pilot scope update: this flow now creates workout-only programs. Food restrictions, recipes and sleep preferences do not gate training generation and are excluded from its AI payload; new program days serialize empty meals and blank legacy sleep fields while older saved meal/sleep data remains readable. Before quota/AI, the app checks the coming workout week against incomplete future schedule entries. On conflict, it proposes the nearest free option among the eight existing workout times; that option must be clear on every selected workout date, with earlier time winning ties. The app reports the requested time and conflict count, then asks one-time consent before AI. Consent changes only the current M32 program's time; profile and existing schedule rows are preserved. Declining or finding no free option does not use quota, call AI or write data. Confirm rechecks inside the SQLite transaction; only future incomplete M32 `routine` rows are replaceable. If a conflict appears after preview, rollback preserves the preview and schedule; the app resolves current availability and asks consent again. Changing the preview time does not call AI again.

The static pilot pack is bundled in `assets/data/fitness_training/`: 24 exercise, 10 equipment, 35 recipe and 47 candidate ingredient records with nine original illustration atlases. Nutrition metadata retains USDA FDC IDs. Current YouTube rows are not approved for embedding; the app keeps original instructions/illustrations and offers an external YouTube search fallback. The feature is connected to FeatureHub and the v1 router. Member self-owned rows have an M05 snapshot/RLS source contract; FamilyPlus subject selection and consent flow are not implemented. SQLite/Edge tests and Android build evidence are recorded in the 2026-10-05 runtime worklog.

This implementation is a pilot and does not close reviewer decisions. The age check uses self-declared birth date on device and is spoofable; catalog, nutrition, clinical safety, retention/deletion, FamilyPlus scope and platform/device acceptance remain review items. Do not treat the source or local tests as deployment, sandbox, or release approval.

## 1. Goal and boundary

Tạo một chương trình luyện tập wellness 28 ngày phù hợp mục tiêu, địa điểm tập, thiết bị, nhóm vận động cần tránh và lịch tập. Tuần đang hoạt động được áp vào lịch 7 ngày; các tuần còn lại lưu trong program aggregate. Người dùng xem trước và xác nhận mọi lần áp dụng.

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
| Training profile snapshot | Mục tiêu, lịch tập, địa điểm, gear, movement restrictions | Health-related |
| Training program | Phiên bản chương trình 28 ngày và tuần hiện tại | Health-related |
| Program day/session | Buổi tập, trạng thái áp dụng; legacy JSON có thể còn meals/sleep | Health-related |
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
| M32-BR06 | Lịch tập M32 chỉ lọc hạn chế vận động và catalog bài tập; dị ứng/thực đơn không tham gia luồng này |
| M32-BR07 | Không cập nhật lịch trước khi người dùng review và xác nhận |
| M32-BR08 | Atomic replace chỉ áp vào buổi tập M32 tương lai chưa hoàn thành; giữ mục M32 meal/sleep, lịch sức khỏe, lịch khác và history |
| M32-BR09 | Lỗi Gemini/validator/quota giữ program/lịch cũ; M02 BR02 quy định quota không commit trước kết quả hợp lệ |
| M32-BR10 | Nội dung là wellness support; no diagnosis/treatment/medical claim |
| M32-BR11 | Log chỉ stage/status/count/error type/correlation ID, không raw prompt/response/profile |
| M32-BR12 | Phạm vi phát hành v1 hướng tới Android/iOS; video là tùy chọn, chỉ dùng YouTube IFrame đã kiểm tra và luôn có minh họa/hướng dẫn cùng đường dẫn mở YouTube dự phòng. QA/Tech xác nhận ma trận cuối. |
| M32-BR13 | Khi lịch tập trùng, chỉ đề xuất giờ trống trên mọi ngày tập; hỏi đồng ý trước khi quota/AI. Consent chỉ đổi giờ trong chương trình M32 hiện tại và không lưu mặc định. Apply-time conflict phải rollback và yêu cầu đồng ý lại cho giờ mới. |

## 5. Main flow and failures

1. FeatureHub → adult gate → review onboarding → training questionnaire.
2. Chọn home/gym; chọn thiết bị hoặc bodyweight; chọn ngày/giờ, thời lượng và movement restrictions.
3. Kiểm tra overlap với lịch sắp tới trước quota/AI; mục đang tồn tại chưa hoàn thành, gồm M32 meal/sleep, có thể chặn buổi tập.
4. Nếu giờ trùng, tìm giờ gần nhất còn trống trong tám lựa chọn trên mọi ngày tập (hòa chọn giờ sớm hơn). Từ chối hoặc không tìm được giờ thì giữ nguyên, không gọi AI, tiêu quota hay ghi dữ liệu. Chỉ sau khi đồng ý, tiếp tục với giờ mới ở chương trình M32.
5. M04 tính metric cục bộ; catalog bài tập được lọc trước khi AI request.
6. M02/M06 authorize/quota check; backend Gemini generate program dùng allowlisted exercise catalog context.
7. Validator kiểm tra IDs, giới hạn sets/reps/duration và đúng 28 ngày. Output không có meals.
8. Hiển thị preview; confirm transaction kiểm tra overlap lần nữa trước mọi mutation, rồi chỉ thay tuần tập hiện tại. Conflict mới rollback; app đề xuất giờ hiện trống và hỏi consent lại. Áp dụng cần xác nhận lại, không gọi AI.
9. Cuối mỗi tuần hỏi check-in. Nếu user chọn điều chỉnh và có quota, replan phần còn lại; conflict cần consent trước AI, rồi preview và confirm tuần kế.

| Failure | Result |
|---|---|
| Under 18 / DOB chưa xác minh | Chặn trước quota và AI; giữ dữ liệu hiện có |
| Quota denied | Không gọi AI; giữ program/lịch cũ, dùng thông điệp M02 |
| AI/network/invalid response | Không sửa schedule/program đang active; retry idempotent theo M02 |
| Không có bài phù hợp | Không tạo; yêu cầu người dùng điều chỉnh thiết bị/hạn chế vận động hoặc dừng |
| Lịch chồng lấn | Nêu giờ yêu cầu và số lịch trùng; đề xuất giờ gần nhất còn trống trên mọi ngày tập và xin consent một lần trước AI. Từ chối/no slot không dùng quota hoặc ghi dữ liệu. Conflict mới lúc áp dụng rollback và cần consent lại. |
| YouTube blocked/unavailable | Hiện hình/minh họa và mô tả; nút mở YouTube |
| Schedule write/sync thất bại | Rollback transaction, giữ trạng thái cũ; retry an toàn |

## 6. Schedule contract

Program là 4 tuần; calendar chỉ giữ cửa sổ 7 ngày của tuần đang áp dụng. Workout slot dùng giờ tập và thời lượng đã chọn; khoảng thời gian dùng quy tắc nửa mở để nhận diện overlap. Mục có giờ bắt đầu nhưng không có giờ kết thúc được xem như một điểm; mục qua nửa đêm kéo dài sang ngày kế tiếp. Bỏ qua mục đã hoàn thành và mục đã qua. Buổi tập M32 tương lai chưa hoàn thành bị thay trong cùng transaction và không tự được xem là xung đột; M32 meal/sleep và mọi nguồn khác được giữ nguyên, đồng thời vẫn được kiểm tra.

Khi confirm: kiểm tra conflict lại bên trong transaction trước khi archive program hoặc xóa/ghi lịch. Conflict rollback toàn bộ thay đổi, giữ preview, program đang active và lịch hiện tại. Khi không có conflict, chỉ xóa future incomplete M32 `routine` rows rồi ghi workout rows; giữ nguyên M32 meal/sleep, completed items, unrelated health tasks, source IDs và notification semantics. Week review không tự thay lịch: replan preview và confirm là bắt buộc. Đổi giờ khi còn preview chỉ áp lại cùng preview, không gọi AI lần nữa.

## 7. AI/API and privacy

Hai operation trên luồng Gemini backend hiện có: tạo chương trình và điều chỉnh các tuần còn lại. Request gồm request_id, cờ đã qua bước tuổi trên thiết bị, mục tiêu/kinh nghiệm/nơi tập/thiết bị/lịch tập/movement restrictions, metrics M04, ID bài tập đã lọc và check-in tuần. Payload không chứa dị ứng, nhóm thực phẩm, món ăn hoặc giờ ngủ. DOB, ghi chú sức khỏe tự do và user ID không gửi đến Gemini. Cờ tuổi có thể bị giả mạo ở client; người dùng đã chấp nhận hạn chế này cho pilot. Client kiểm tra overlap trước quota/AI; app kiểm tra schema/catalog IDs, còn transaction local kiểm tra overlap lại trước khi áp lịch.

M32-Q01 — PO chọn ngày 2026-10-05: bản pilot đọc ngày sinh đầy đủ tự khai trong hồ sơ và tính đủ tuổi ngay trên thiết bị. Gemini không nhận DOB; request chỉ mang cờ đã qua bước tuổi. Đây không phải kiểm soát đáng tin cậy phía máy chủ. Tech/Privacy vẫn cần duyệt consent, lưu trữ, retention/xóa và quyết định xác minh tuổi cho phát hành.

## 8. Non-functional and safety requirements

- Privacy: explicit review/consent before AI, data minimization, subject ownership, delete/retention policy approved by M19/Privacy.
- Security: client không giữ Gemini/USDA secret; no raw prompt/response in logs.
- Integrity: request ID, program version, idempotent schedule transaction and rollback.
- Safety: catalog restriction labels, reviewed movement content, no injury treatment or disease-specific nutrition. Recipe and allergy review remains necessary before any meal flow uses that catalog; Clinical reviewer must define exercise red-flag/restriction behavior before approval.
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

The PO confirmed the following product directions on 2026-10-05: local age check from self-declared profile birth date for the pilot; Member sync under the M05 owner/RLS contract with Guest local storage; wellness-only scope with movement restrictions hard-filtered in this workout flow; Android/iOS as the first release target; optional official YouTube embeds with illustration, instructions and open-on-YouTube fallback. The later pilot-scope update keeps food restrictions and meal plans outside M32 training generation. Coding proceeds by PO direction while reviewer decisions remain pending. Existing [review packet](./Review_Packet.md) records pending review only; no reviewer approval is inferred.

## 11. Traceability

| BD | Feature | Function | View | Test |
|---|---|---|---|---|
| M32-BR01..02 | M32-F01 | M32-FN01 | M32-V01/V02 | M32-TC01..02 |
| M32-BR04..06 | M32-F02 | M32-FN02 | M32-V03/V04 | M32-TC03..05 |
| M32-BR03..09 | M32-F03 | M32-FN03/FN04 | M32-V05/V06 | M32-TC06..11 |
| M32-BR03..11 | M32-F04 | M32-FN05 | M32-V07 | M32-TC12..16 |
