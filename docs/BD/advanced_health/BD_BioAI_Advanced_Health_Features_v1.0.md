# BD — Danh mục chức năng sức khỏe nâng cao M20–M29

> **Dự án:** BioAI / NanoBio  
> **Mã tài liệu:** BD-BIOAI-ADVANCED-HEALTH-001  
> **Phiên bản:** 1.0  
> **Trạng thái:** Draft - UI catalog shell approved  
> **Ngày tạo:** 13/07/2026  
> **Nguồn nền:** ../project_flow/BD_BioAI_Product_Flow_Sale_Admin_v2.0.md (BD-BIOAI-PRODUCT-FLOW-002)  
> **Phạm vi phê duyệt hiện tại:** Chỉ phê duyệt tên, thứ tự, nhãn gói và hành vi điều hướng của 10 mục trong Danh mục chức năng. Nghiệp vụ ghi nhận dữ liệu, AI, cảnh báo, đồng bộ, thiết bị và chia sẻ chưa được phê duyệt để coding.

## Kiểm soát thay đổi

| Phiên bản | Ngày | Nội dung | Trạng thái |
|---|---|---|---|
| 1.0 | 13/07/2026 | Khởi tạo BD riêng cho M20–M29; chốt UI catalog shell và mô tả nghiệp vụ dự kiến để làm nguồn cho DD sau này. | Draft - UI catalog shell approved |

## Quan hệ tài liệu và thứ tự ưu tiên

1. BD-BIOAI-PRODUCT-FLOW-002 tiếp tục là nguồn chuẩn cho M01–M19, access, FamilyPlus, notification, AI, privacy và audit.
2. Tài liệu này là extension cho M20–M29; không thay thế hoặc làm giảm hiệu lực của M04, M07, M08, M09, M10, M11 và M19.
3. Khi có mâu thuẫn, dừng ở điểm mâu thuẫn, ghi issue và xin Product Owner xác nhận; không tự chọn quy tắc thuận tiện cho implementation.
4. Các nguồn y tế ở Source Registry là tài liệu tham khảo để thiết kế an toàn, không phải công thức hoặc ngưỡng production đã được phê duyệt.

# 1. Mục tiêu và kết quả mong đợi

## 1.1. Mục tiêu

- Mở rộng Danh mục chức năng với 10 khả năng theo dõi và cải thiện sức khỏe, có lộ trình tích hợp AI có kiểm soát.
- Cho người dùng nhìn thấy hướng phát triển sản phẩm ngay từ UI catalog.
- Khi người dùng đủ access chọn một mục mới, mở trang thông báo “Đang trong quá trình phát triển”; Guest được chuyển tới đăng nhập và Free chọn mục Plus được chuyển tới nâng cấp, không dẫn tới route rỗng hoặc màn hình giả có dữ liệu mẫu.
- Cung cấp đủ business context, ranh giới an toàn, actor, input, flow, state, BR, AC và UC để tạo DD riêng cho từng module sau này.

## 1.2. Kết quả được phê duyệt trong phiên bản này

- Có đúng 10 mục M20–M29 trong Danh mục chức năng, đúng tên, thứ tự và nhãn gói tại bảng Module Registry.
- Mỗi mục dùng cùng access-aware route: Guest → đăng nhập; Free mở M20–M22 → placeholder; Free mở M23–M29 → nâng cấp; Plus/FamilyPlus → placeholder.
- Placeholder không thu dữ liệu sức khỏe, không gọi AI, không ghi local/cloud, không tạo notification và không ngầm cấp entitlement.
- Copy tiếng Việt theo Nabitone: ấm áp, rõ ràng, không phán xét và không hứa hẹn hiệu quả y tế.

## 1.3. Ngoài phạm vi hiện tại

- Coding toàn bộ nghiệp vụ M20–M29, persistence, schema, API, RLS, migration hoặc cloud sync.
- Chẩn đoán, sàng lọc tự động, kê đơn, đổi liều thuốc, dự báo điều trị hoặc thay thế nhân viên y tế.
- Ngưỡng cảnh báo y khoa production, công thức lâm sàng hoặc khuyến nghị cá nhân hóa chưa được chuyên môn phê duyệt.
- Kết nối Apple Health, Health Connect, thiết bị đeo, máy đo huyết áp, máy đo đường huyết, pulse oximeter hoặc thiết bị y tế khác.
- OCR ảnh kết quả xét nghiệm, đọc toa thuốc, đọc nhãn thuốc hoặc nhập dữ liệu tự động từ tài liệu y khoa.
- Tích hợp AI production, prompt contract, model selection, quota, safety evaluation hoặc lưu lịch sử AI.

# 2. Module Registry

| Mã | Module code | Tên hiển thị | Gói nghiệp vụ tương lai | Use case | Trạng thái nghiệp vụ |
|---|---|---|---|---|---|
| M20 | BLOOD_PRESSURE_TRACKING | Nhật ký huyết áp | Free | UC-25 | Draft; catalog shell approved |
| M21 | HEART_OXYGEN_TRACKING | Nhịp tim & SpO₂ | Free | UC-26 | Draft; catalog shell approved |
| M22 | MEDICATION_ADHERENCE | Lịch dùng thuốc | Free | UC-27 | Draft; catalog shell approved |
| M23 | GLUCOSE_TRACKING | Theo dõi đường huyết | Plus | UC-28 | Draft; catalog shell approved |
| M24 | SYMPTOM_PAIN_JOURNAL | Nhật ký triệu chứng & cơn đau | Plus | UC-29 | Draft; catalog shell approved |
| M25 | WOMENS_CYCLE_HEALTH | Chu kỳ & sức khỏe nữ | Plus | UC-30 | Draft; catalog shell approved |
| M26 | RESPIRATORY_ALLERGY_TRACKING | Hô hấp & dị ứng | Plus | UC-31 | Draft; catalog shell approved |
| M27 | LAB_RESULT_TRACKING | Xét nghiệm & chỉ số y khoa | Plus | UC-32 | Draft; catalog shell approved |
| M28 | PREVENTIVE_CARE | Lịch chăm sóc dự phòng | Plus | UC-33 | Draft; catalog shell approved |
| M29 | AI_HEALTH_TRENDS | Báo cáo xu hướng sức khỏe AI | Plus | UC-34 | Draft; catalog shell approved |

“Free” và “Plus” trong bảng là access contract cho nghiệp vụ tương lai. Catalog shell không chứng minh entitlement, không tiêu quota và không được tính là module đã coding.

# 3. Actor, access và FamilyPlus

## 3.1. Actor

| Actor | Trách nhiệm/quyền dự kiến | Giới hạn |
|---|---|---|
| Guest | Có thể nhìn thấy catalog nếu Features Hub hiện hành cho phép. | Không tạo hoặc xem dữ liệu M20–M29; placeholder không cấp quyền. |
| Free Member | Dùng M20–M22 sau khi DD và implementation được duyệt; ở UI shell hiện tại M20–M22 mở placeholder. | M23–M29 hiển thị nhãn Plus và chuyển tới nâng cấp khi được chọn; không mở placeholder Plus cho Free. |
| Plus Member | Dùng M20–M29 sau khi từng module được phát hành. | Không có quyền FamilyPlus nếu không thuộc gói FamilyPlus. |
| FamilyPlus Member | Kế thừa Plus và có thể thao tác theo subject trong family scope. | Phải tuân thủ full-sharing disclosure, actor-subject và revoke rules. |
| System | Kiểm tra entitlement, subject, consent, validation và audit. | Không tự suy diễn chẩn đoán hoặc quyền từ việc UI đang hiển thị. |
| AI | Chỉ có vai trò sản phẩm ở M24, M27 và M29 sau khi DD tương ứng được duyệt. | Không chẩn đoán, kê đơn, đổi thuốc/liều, tự phát cảnh báo khẩn cấp hoặc che giấu bất định. |

## 3.2. Full-sharing disclosure của FamilyPlus

- Theo quyết định Q-15 của baseline, mọi thành viên đã tham gia cùng một gói FamilyPlus có thể xem toàn bộ thông tin của nhau trong package scope.
- Trước lần ghi dữ liệu sức khỏe đầu tiên trong family context, UI phải hiển thị disclosure rõ rằng các thành viên đã tham gia gói có thể xem dữ liệu đó.
- Khi actor đổi subject, UI phải luôn hiển thị tên subject đang được thao tác; không dùng trạng thái ẩn hoặc chỉ dựa vào avatar.
- Mọi bản ghi phải phân biệt actor_user_id, subject_user_id và family_id; actor không được giả làm subject.
- Full sharing không có chế độ ẩn riêng từng bản ghi trong BD hiện tại. Nếu người dùng không chấp nhận full sharing, hệ thống không được tạo bản ghi mới trong family context và phải hướng dẫn lựa chọn rời/revoke participation theo policy được duyệt.
- Khi membership bị remove, left, revoked, expired hoặc suspended, quyền đọc/ghi mới phải dừng ngay; cache và notification theo subject phải bị vô hiệu hóa.
- Revoke quyền chia sẻ không đồng nghĩa xóa dữ liệu. Retention, export và delete phải theo policy riêng, có audit và không làm mất dữ liệu của subject ngoài ý muốn.
- M20–M29 không được mở rộng quyền Sale/Admin xem raw health data. M19 tiếp tục sở hữu privacy, audit và least-privilege contract.

# 4. Chính sách dữ liệu, AI và nguồn nhập

## 4.1. Manual-entry-first

1. Bản nghiệp vụ đầu tiên sau DD chỉ nhận dữ liệu do người dùng nhập hoặc xác nhận thủ công.
2. Mọi số đo phải lưu unit, thời điểm đo, timezone, nguồn nhập và subject; không lưu một con số mất ngữ cảnh.
3. Thiết bị/wearable/import file/OCR là phase sau, cần BD addendum, device/source provenance, duplicate policy, permission, sync conflict và validation riêng.
4. Không được gắn nhãn dữ liệu nhập tay là dữ liệu thiết bị hoặc dữ liệu đã xác minh lâm sàng.
5. Catalog shell hiện tại không hiển thị form nhập và không tạo dữ liệu mẫu như dữ liệu thật.

## 4.2. Dữ liệu nhạy cảm

- Blood pressure, heart rate, SpO₂, medication, glucose, symptom, pain, menstrual, respiratory/allergy và lab result đều là health data nhạy cảm.
- Chỉ thu field cần cho use case đã phê duyệt; không ghi health PII, raw AI prompt/response hoặc tài liệu y khoa vào log.
- Export/delete/retention, encryption, consent version, audit và RLS phải được quyết định trong DD/M19 trước implementation.
- Analytics sản phẩm chỉ dùng event tối thiểu; không đưa value đo, triệu chứng, thuốc, kết quả xét nghiệm hoặc cycle detail vào analytics payload.

## 4.3. Vai trò AI

- M20–M23, M25–M26 và M28 là luồng deterministic/manual; không có vai trò AI.
- M24 bắt đầu bằng nhập tay. Phase AI sau DD chỉ được tóm tắt nhật ký người dùng đã xác nhận và chuẩn bị câu hỏi để trao đổi với bác sĩ; không symptom checker, diagnosis hoặc triage.
- M27 bắt đầu bằng nhập tay. Phase AI sau DD chỉ được hỗ trợ trích xuất field từ nguồn người dùng cung cấp; mọi value, unit, reference range và source phải được người dùng kiểm tra/xác nhận trước khi lưu.
- M29 phải tính thống kê bằng logic xác định trước rồi mới cho AI diễn đạt. Báo cáo phải hiển thị nguồn dữ liệu, khoảng thời gian, dữ liệu thiếu và mức bất định; AI không tự tạo số liệu hoặc nguyên nhân bệnh.
- AI không được đưa ra diagnosis, treatment, medication/dose change, fertility guarantee, insulin advice hoặc emergency clearance.
- Nếu dữ liệu không đủ, mâu thuẫn hoặc vượt safety boundary, AI phải từ chối diễn giải và hướng dẫn người dùng trao đổi với chuyên gia phù hợp.
- Mọi AI production phải đi qua contract của M07, access/quota của M06 và audit/privacy của M19; không gọi model trực tiếp từ Presentation.

## 4.4. Safety escalation

- UI không được trấn an rằng người dùng “an toàn” chỉ từ một số đo hoặc AI summary.
- Tình huống có dấu hiệu khẩn cấp phải dùng nội dung escalation được chuyên môn/local policy phê duyệt, hướng người dùng liên hệ cơ sở y tế hoặc cấp cứu địa phương.
- Không hard-code số điện thoại cấp cứu, threshold hoặc lời khuyên điều trị trước khi locale/clinical owner phê duyệt.

# 5. UI Catalog Shell Contract

## 5.1. Luồng chính

1. Người dùng mở Danh mục chức năng.
2. Hệ thống hiển thị M20–M29 theo đúng thứ tự trong Module Registry.
3. Mỗi card có tên tiếng Việt, mô tả ngắn mang tính wellness/logging và nhãn Free hoặc Plus.
4. Người dùng chọn một card; route kiểm tra effective access từ nguồn tin cậy.
5. Guest được chuyển tới đăng nhập.
6. Free chọn M23–M29 được chuyển tới luồng nâng cấp; Free chọn M20–M22 và Plus/FamilyPlus chọn M20–M29 được mở placeholder.
7. Placeholder có tiêu đề đúng tên module và thông báo “Tính năng đang trong quá trình phát triển”; người dùng quay lại bằng điều hướng chuẩn của app.

## 5.2. Trạng thái UI bắt buộc

| State | Hành vi |
|---|---|
| Catalog loaded | Hiển thị đủ 10 card; không dùng dữ liệu health. |
| Tap/opening | Chỉ điều hướng và kiểm tra effective access; không gọi module health API/AI, không xin device permission. |
| Placeholder | Hiển thị icon/illustration phù hợp, tiêu đề, thông báo phát triển và nút quay lại. |
| Login required | Guest được chuyển tới đăng nhập; không mở dữ liệu hoặc cấp quyền. |
| Upgrade required | Free chọn M23–M29 được chuyển tới trang nâng cấp; không mở dữ liệu Plus. |
| Route unavailable | Fallback an toàn về Features Hub hoặc trang lỗi Nabi; không lộ route/stack trace. |
| Accessibility | Card có semantic label, touch target phù hợp và không truyền thông tin chỉ bằng màu tier badge. |

## 5.3. Business rules UI shell

| ID | Rule |
|---|---|
| AHF-BR-001 | Catalog phải có đúng 10 mục M20–M29 theo registry của BD này. |
| AHF-BR-002 | Route phải áp gate: Guest → login; Free M20–M22 → placeholder; Free M23–M29 → upgrade; Plus/FamilyPlus M20–M29 → placeholder. Không mở form nghiệp vụ chưa duyệt. |
| AHF-BR-003 | Placeholder không đọc/ghi health data, không gọi module health API/AI và không tạo notification; effective-access lookup phục vụ gate vẫn được phép. |
| AHF-BR-004 | Tier badge phản ánh minimum access tương lai nhưng không phải bằng chứng feature đã phát hành; effective access vẫn phải được kiểm tra trước placeholder. |
| AHF-BR-005 | UI shell không làm thay đổi DD completeness hoặc business coding progress của M20–M29. |
| AHF-BR-006 | Copy không được ngụ ý chẩn đoán, điều trị hoặc tính năng đã sẵn sàng. |

## 5.4. Acceptance Criteria UI shell

| ID | Tình huống | Kết quả phải đạt |
|---|---|---|
| AHF-AC-001 | Mở Danh mục chức năng | Thấy đủ 10 mục đúng tên, thứ tự và tier. |
| AHF-AC-002 | Free chọn M20–M22 hoặc Plus/FamilyPlus chọn M20–M29 | Mở đúng placeholder mang tên module và thông báo đang phát triển. |
| AHF-AC-003 | Theo dõi side effect khi mở placeholder | Không có health write, module health API/AI call, quota commit, notification hoặc device permission request; chỉ access lookup được phép. |
| AHF-AC-004 | Guest chọn bất kỳ module hoặc Free chọn M23–M29 | Guest được chuyển tới đăng nhập; Free được chuyển tới nâng cấp; không cấp entitlement hoặc dữ liệu Plus. |
| AHF-AC-005 | Kiểm tra copy/accessibility | Copy tiếng Việt theo Nabitone, semantic label và điều hướng quay lại hoạt động. |

# 6. Đặc tả module M20–M29

## M20 — BLOOD_PRESSURE_TRACKING / Nhật ký huyết áp

### Mục tiêu, actor và tier

- Mục tiêu: Cho Member ghi lại các lần đo huyết áp để xem lịch sử và chia sẻ với chuyên gia y tế khi cần.
- Actor: Free, Plus, FamilyPlus; System validation; AI không tham gia phase đầu.
- Tier: Free; Plus/FamilyPlus kế thừa.

### Input dự kiến

- Tâm thu, tâm trương, nhịp tim tùy chọn; unit mmHg/bpm.
- Thời điểm đo, timezone, tay đo, tư thế, trạng thái nghỉ, ghi chú ngắn và nguồn nhập manual.
- Actor/subject/family context và consent version nếu thao tác FamilyPlus.

### Luồng chính tương lai

1. Actor chọn đúng subject và xem full-sharing disclosure nếu ở FamilyPlus.
2. Actor nhập số đo cùng bối cảnh; hệ thống validate type/range kỹ thuật và bắt buộc tâm thu/tâm trương.
3. Actor xác nhận; hệ thống lưu bản ghi immutable về giá trị gốc và source.
4. Hệ thống hiển thị lịch sử theo thời gian và cho sửa bằng correction record, không âm thầm ghi đè.
5. Người dùng có thể chuẩn bị bản tóm tắt để trao đổi với chuyên gia sau khi export policy được duyệt.

### Ngoại lệ và state

- Thiếu unit/thời gian, số âm, tâm thu nhỏ hơn hoặc bằng tâm trương, future timestamp quá policy: từ chối và giải thích bằng copy dễ hiểu.
- Một số đo cao/thấp đơn lẻ không được tự gắn diagnosis; chỉ hiển thị safety copy đã được duyệt.
- State: draft_entry → recorded → corrected → archived; invalid draft không tạo record.

### Dữ liệu nhạy cảm, AI và dependency

- Sensitive: toàn bộ số đo và ghi chú.
- AI role: none ở phase đầu; M29 chỉ được phân tích sau consent và có provenance.
- Dependencies: M10 sở hữu tracking framework/goal; M11 subject; M19 privacy/audit; M08 sở hữu health score, không tự cộng điểm từ M20.

### Rule và acceptance

| ID | Nội dung |
|---|---|
| M20-BR01 | Mọi record phải có subject, timestamp, timezone, unit và source. |
| M20-BR02 | Không chẩn đoán hoặc khuyên đổi thuốc từ số đo. |
| M20-BR03 | Correction giữ trace tới record gốc. |
| M20-AC01 | Record hợp lệ được lưu đúng actor/subject và hiển thị trong lịch sử. |
| M20-AC02 | Input thiếu/sai không tạo record một phần. |
| M20-AC03 | UI luôn có disclaimer và không biến category tham khảo thành diagnosis. |

## M21 — HEART_OXYGEN_TRACKING / Nhịp tim & SpO₂

### Mục tiêu, actor và tier

- Mục tiêu: Ghi nhận nhịp tim và SpO₂ theo từng thời điểm với bối cảnh đo để người dùng theo dõi xu hướng cá nhân.
- Actor: Free, Plus, FamilyPlus; AI không tham gia phase đầu.
- Tier: Free; Plus/FamilyPlus kế thừa.

### Input dự kiến

- Heart rate bpm, SpO₂ %, thời điểm, trạng thái nghỉ/vận động, vị trí đo, triệu chứng tùy chọn, device note và source manual.
- Actor/subject/family context; xác nhận người dùng tự nhập và không phải continuous monitoring.

### Luồng chính tương lai

1. Actor chọn subject, nhập một hoặc cả hai chỉ số cùng bối cảnh.
2. Hệ thống validate unit và range kỹ thuật, giữ nguyên giá trị người dùng xác nhận.
3. Lưu record theo timestamp/source, hiển thị lịch sử và quality note; khi dữ liệu heart rate/SpO₂ tương thích đã tồn tại trong tracking log, tái sử dụng contract hiện có thay vì tạo nguồn sự thật trùng lặp.
4. Khi dữ liệu có vẻ bất thường, chỉ dùng safety copy đã phê duyệt; khuyến khích đánh giá triệu chứng và liên hệ chuyên gia khi lo ngại.

### Ngoại lệ và state

- Không nhận SpO₂ ngoài 0–100 hoặc heart rate không phải số; không tự sửa số người dùng nhập.
- Không xem pulse oximeter là tuyệt đối chính xác; không trấn an chỉ dựa trên SpO₂.
- Không tuyên bố điện thoại tự đo nhịp tim/SpO₂ hoặc là thiết bị y tế nếu không có integration và phê duyệt chuyên biệt.
- State: draft_entry → recorded → corrected → archived.

### Dữ liệu nhạy cảm, AI và dependency

- Sensitive: số đo, symptom context và device note.
- AI role: none trực tiếp; M29 phải nêu hạn chế thiết bị và missing context.
- Dependencies: M10 tracking, M24 symptoms, M11 subject, M19 privacy/audit; device integration later.

### Rule và acceptance

| ID | Nội dung |
|---|---|
| M21-BR01 | Số đo phải gắn context và source; không giả định là dữ liệu thiết bị đã xác minh. |
| M21-BR02 | Không đánh giá an toàn chỉ từ SpO₂ hoặc heart rate. |
| M21-BR03 | Device import chỉ được thêm sau DD/addendum và provenance contract. |
| M21-BR04 | Tái sử dụng field/log nhịp tim và SpO₂ hiện có khi contract tương thích; không tạo hai nguồn sự thật cho cùng record. |
| M21-AC01 | Record hợp lệ hiển thị đúng chỉ số, unit, time và context. |
| M21-AC02 | Input không hợp lệ bị chặn mà không tạo record. |
| M21-AC03 | UI hiển thị limitation/safety copy đã duyệt. |
| M21-AC04 | UI không mô tả điện thoại là thiết bị đo y tế và record hiện có không bị nhân đôi khi được hiển thị trong M21. |

## M22 — MEDICATION_ADHERENCE / Lịch dùng thuốc

### Mục tiêu, actor và tier

- Mục tiêu: Giúp Member ghi danh sách thuốc do họ nhập, lịch dùng theo chỉ dẫn hiện có và trạng thái đã dùng/bỏ qua.
- Actor: Free, Plus, FamilyPlus; notification thuộc M09; AI không quyết định thuốc.
- Tier: Free; Plus/FamilyPlus kế thừa.

### Input dự kiến

- Tên thuốc/sản phẩm, dạng, liều và unit đúng theo nhãn/chỉ dẫn người dùng nhập, lịch thời gian, ngày bắt đầu/kết thúc, prescriber note tùy chọn.
- Adherence event: due, taken, skipped, snoozed; timestamp, actor/subject và lý do tùy chọn.

### Luồng chính tương lai

1. Actor chọn subject và xác nhận chỉ ghi lại chỉ dẫn hiện có, không yêu cầu app kê đơn.
2. Actor nhập thuốc và lịch; hệ thống validate field kỹ thuật, không suy diễn dose.
3. Nếu reminder được bật sau này, module gửi schedule intent cho M09 thay vì tự lên lịch notification.
4. Tại thời điểm đến lịch, actor đánh dấu taken/skipped/snoozed; event được lưu idempotent.
5. Thay đổi lịch tạo version mới và không sửa lịch sử adherence đã ghi.

### Ngoại lệ và state

- Không cho AI/ứng dụng đề xuất bắt đầu, dừng, thay thế hoặc đổi liều.
- Trùng action/retry không tạo hai taken events; timezone change không làm nhân đôi reminder.
- State thuốc: draft → active → paused → ended → archived. State event: scheduled → due → taken/skipped/snoozed/missed.

### Dữ liệu nhạy cảm, AI và dependency

- Sensitive: medication name, dose, schedule, adherence, prescriber note.
- AI role: chỉ có thể tóm tắt adherence trong M29; không làm drug interaction checker.
- Dependencies: M09 notification, M10 tracking, M11 subject, M19 privacy/audit.

### Rule và acceptance

| ID | Nội dung |
|---|---|
| M22-BR01 | Lịch thuốc là bản ghi theo chỉ dẫn người dùng nhập, không phải đơn thuốc của app. |
| M22-BR02 | Không đổi thuốc/liều hoặc đưa advice điều trị. |
| M22-BR03 | Adherence event idempotent và giữ lịch sử version. |
| M22-AC01 | Người dùng tạo được lịch hợp lệ và thấy đúng subject/timezone. |
| M22-AC02 | Taken/skipped retry không tạo event trùng. |
| M22-AC03 | Thay đổi lịch không sửa lịch sử cũ và notification được ủy quyền cho M09. |

## M23 — GLUCOSE_TRACKING / Theo dõi đường huyết

### Mục tiêu, actor và tier

- Mục tiêu: Cho Plus/FamilyPlus ghi số đo glucose cùng bối cảnh bữa ăn để theo dõi và trao đổi với đội ngũ chăm sóc.
- Actor: Plus, FamilyPlus; Free chỉ thấy catalog/upgrade semantics khi feature phát hành.
- Tier: Plus.

### Input dự kiến

- Giá trị, unit mg/dL hoặc mmol/L, thời điểm, fasting/before meal/after meal/bedtime/other, meal note, source manual.
- Actor/subject/family, device note và correction reason nếu sửa.

### Luồng chính tương lai

1. Hệ thống xác thực entitlement và subject.
2. Actor nhập giá trị, unit và meal context; hệ thống không tự đoán unit.
3. Hệ thống validate kỹ thuật, lưu original value/unit và hiển thị lịch sử.
4. Conversion unit, nếu được DD duyệt, chỉ là display derivative có version và không thay original.
5. Người dùng có thể xem summary; target range chỉ hiển thị nếu được chuyên gia/policy cung cấp và có source/version.

### Ngoại lệ và state

- Không dùng home meter để chẩn đoán diabetes; không đề xuất insulin/dose hoặc xử lý hạ/tăng đường huyết bằng AI.
- Missing meal context được phép với nhãn unknown, không tự gán fasting.
- State: draft_entry → recorded → corrected → archived.

### Dữ liệu nhạy cảm, AI và dependency

- Sensitive: glucose, meal context, condition note.
- AI role: M29 có thể tóm tắt trend, không xác nhận/chẩn đoán diabetes.
- Dependencies: M10 tracking, M08 score ownership, M11 subject, M19 privacy/audit.

### Rule và acceptance

| ID | Nội dung |
|---|---|
| M23-BR01 | Luôn lưu original value/unit và context; không tự gán fasting. |
| M23-BR02 | Không diagnosis hoặc insulin/medication advice. |
| M23-BR03 | Target/threshold phải có owner, source và version trước production. |
| M23-AC01 | Entitled user lưu và xem đúng original value/unit/context. |
| M23-AC02 | Free hoặc subject ngoài scope bị chặn ở use case/backend, không chỉ UI. |
| M23-AC03 | Summary không biến một số đo thành diagnosis. |

## M24 — SYMPTOM_PAIN_JOURNAL / Nhật ký triệu chứng & cơn đau

### Mục tiêu, actor và tier

- Mục tiêu: Ghi thời điểm, vị trí, mức độ và ảnh hưởng của triệu chứng/cơn đau để người dùng nhớ diễn biến và trao đổi rõ hơn với chuyên gia.
- Actor: Plus, FamilyPlus.
- Tier: Plus.

### Input dự kiến

- Symptom tag do catalog versioned cung cấp hoặc free text hạn chế; body area; severity 0–10; onset, duration, frequency; trigger/relief note; impact on activity/sleep.
- Actor/subject, timestamp, timezone và source manual.

### Luồng chính tương lai

1. Actor chọn subject và bắt đầu journal entry.
2. Actor ghi symptom/pain context; hệ thống validate severity và thời gian.
3. Hệ thống lưu entry, hiển thị timeline và cho correction có trace.
4. Nếu có red-flag disclosure được clinical owner duyệt, UI hiển thị escalation tĩnh; không dùng AI tự triage.
5. Ở phase AI sau DD, người dùng có thể yêu cầu M24 tóm tắt chính nhật ký đã xác nhận và chuẩn bị câu hỏi cho bác sĩ; hệ thống không đưa diagnosis, triage hoặc treatment advice.
6. M29 có thể nhóm pattern mô tả ở báo cáo liên module, luôn nêu đây không phải nguyên nhân/chẩn đoán.

### Ngoại lệ và state

- Free text không được đưa nguyên văn vào analytics/log; cần chống nội dung quá dài và unsafe rendering.
- Không xây symptom checker, differential diagnosis hoặc treatment recommender trong module này.
- State: draft_entry → recorded → updated_with_correction → resolved/ongoing → archived.

### Dữ liệu nhạy cảm, AI và dependency

- Sensitive: symptom, body location, pain severity, free text.
- AI role: sau DD có thể tóm tắt journal đã xác nhận và chuẩn bị câu hỏi cho bác sĩ; M29 chỉ dùng dữ liệu M24 khi có consent. Không diagnosis/triage.
- Dependencies: M07 AI safety, M10 tracking, M11 subject, M19 privacy/audit.

### Rule và acceptance

| ID | Nội dung |
|---|---|
| M24-BR01 | Severity là self-report, không được mô tả như clinical measurement. |
| M24-BR02 | Không symptom checker, diagnosis, triage AI hoặc treatment advice. |
| M24-BR03 | Free text không đi vào analytics/log và phải được bảo vệ khi hiển thị. |
| M24-BR04 | AI chỉ xử lý journal đã được người dùng xác nhận để tạo summary/câu hỏi; không tự bổ sung symptom hoặc medical conclusion. |
| M24-AC01 | Entry hợp lệ lưu đúng timeline, severity và impact. |
| M24-AC02 | Invalid duration/severity không tạo record. |
| M24-AC03 | Escalation dùng copy đã duyệt và không trì hoãn hỗ trợ khẩn cấp. |
| M24-AC04 | Summary AI trace được tới entry đã chọn, nêu thiếu dữ liệu và chỉ đưa câu hỏi để người dùng cân nhắc trao đổi với bác sĩ. |

## M25 — WOMENS_CYCLE_HEALTH / Chu kỳ & sức khỏe nữ

### Mục tiêu, actor và tier

- Mục tiêu: Cho người dùng tự ghi ngày chu kỳ, mức độ ra máu và triệu chứng liên quan để theo dõi lịch sử cá nhân.
- Actor: Plus, FamilyPlus; subject là người có dữ liệu chu kỳ.
- Tier: Plus.

### Input dự kiến

- Ngày bắt đầu/kết thúc kỳ kinh, flow level tự báo cáo, symptom/mood/pain tags, note, contraception/pregnancy context chỉ khi scope và consent được PO phê duyệt.
- Actor/subject/family context, timezone và source manual.

### Luồng chính tương lai

1. Subject hoặc actor được phép mở calendar, xem disclosure cực kỳ nhạy cảm và FamilyPlus full-sharing.
2. Actor nhập period day/symptoms; hệ thống lưu theo subject và time.
3. Hệ thống tính cycle interval mô tả từ dữ liệu đã nhập, không cam kết ngày rụng trứng/fertility.
4. Người dùng sửa bằng correction và có thể export/delete theo policy sau này.
5. Khi revoke/leave FamilyPlus, quyền truy cập mới dừng ngay theo mục 3.2.

### Ngoại lệ và state

- Không dùng module làm biện pháp tránh thai, xác nhận mang thai, chẩn đoán hiếm muộn hoặc đưa treatment advice.
- Minor, pregnancy, postpartum, menopause và gender-inclusive copy cần clinical/legal review trước production.
- State cycle entry: draft → recorded → corrected → archived; sharing access: active → revoked/expired.

### Dữ liệu nhạy cảm, AI và dependency

- Sensitive mức cao: cycle, bleeding, pregnancy/contraception context, pain/mood.
- AI role: không dự báo fertility; M29 chỉ tóm tắt cycle history sau explicit consent.
- Dependencies: M11 full-sharing/subject, M24 symptom/pain, M19 privacy/audit/delete; M08 không tự thay score.

### Rule và acceptance

| ID | Nội dung |
|---|---|
| M25-BR01 | Hiển thị explicit sensitive/full-sharing disclosure trước record đầu tiên trong family context. |
| M25-BR02 | Không fertility/contraception guarantee, pregnancy diagnosis hoặc treatment advice. |
| M25-BR03 | Actor và subject luôn tách biệt; revoke dừng truy cập mới ngay. |
| M25-AC01 | Entry lưu đúng subject/date và disclosure version. |
| M25-AC02 | Actor ngoài family scope không đọc/ghi được dữ liệu. |
| M25-AC03 | Revoke/expiry chặn đọc/ghi mới và hủy subject notification/cache liên quan. |

## M26 — RESPIRATORY_ALLERGY_TRACKING / Hô hấp & dị ứng

### Mục tiêu, actor và tier

- Mục tiêu: Ghi symptom hô hấp, dị ứng, trigger phơi nhiễm và chỉ số peak flow tự nhập nếu có để xem pattern theo thời gian.
- Actor: Plus, FamilyPlus.
- Tier: Plus.

### Input dự kiến

- Symptom type/severity, onset/duration, trigger/allergen, location/context, rescue medication event chỉ như self-report, peak flow value/unit tùy chọn và source manual.
- Actor/subject, timezone và note.

### Luồng chính tương lai

1. Actor chọn subject và nhập symptom/trigger context.
2. Hệ thống validate kỹ thuật, lưu event và hiển thị timeline.
3. Nếu actor nhập peak flow, record phải có unit/device/source; không suy diễn action zone nếu chưa có clinician-authored plan.
4. App có thể nhắc người dùng tham khảo action plan của chuyên gia; không tự sửa kế hoạch.
5. M29 chỉ mô tả correlation quan sát được và không kết luận nguyên nhân.

### Ngoại lệ và state

- Symptom nghiêm trọng phải dùng escalation copy đã duyệt; app không được trì hoãn chăm sóc để chờ AI.
- Allergen catalog/version và environmental data integration là scope sau.
- State: draft_entry → recorded → corrected → resolved/ongoing → archived.

### Dữ liệu nhạy cảm, AI và dependency

- Sensitive: respiratory symptoms, allergens, rescue medication event, peak flow.
- AI role: trend description only; no asthma diagnosis/action-plan change.
- Dependencies: M21 heart/oxygen, M22 medication logging, M24 symptoms, M11 subject, M19 privacy/audit.

### Rule và acceptance

| ID | Nội dung |
|---|---|
| M26-BR01 | Peak flow phải có unit/source và không tự map action zone. |
| M26-BR02 | Không diagnosis hoặc thay đổi asthma/allergy action plan. |
| M26-BR03 | Severe symptom escalation không phụ thuộc AI. |
| M26-AC01 | Event hợp lệ lưu đúng symptom/trigger/time/source. |
| M26-AC02 | Peak flow thiếu unit/source bị từ chối hoặc lưu draft, không thành record hợp lệ. |
| M26-AC03 | Summary chỉ mô tả pattern, không kết luận allergen/nguyên nhân. |

## M27 — LAB_RESULT_TRACKING / Xét nghiệm & chỉ số y khoa

### Mục tiêu, actor và tier

- Mục tiêu: Cho người dùng nhập thủ công kết quả xét nghiệm để lưu lịch sử có unit/reference range theo đúng báo cáo gốc.
- Actor: Plus, FamilyPlus.
- Tier: Plus.

### Input dự kiến

- Tên xét nghiệm, value dạng number/text theo loại, unit, reference range và flag đúng từ báo cáo, specimen/date, laboratory/source note, attachment reference chỉ ở phase sau.
- Actor/subject, timezone, source manual và correction reason.

### Luồng chính tương lai

1. Actor chọn subject và nhập chính xác field từ báo cáo.
2. Hệ thống không tự chọn unit/reference range; validate schema kỹ thuật và lưu original text/value.
3. UI hiển thị kết quả cùng range/source của chính báo cáo đó.
4. Correction tạo version/trace; không thay raw historical result.
5. Ở phase AI extraction sau DD/addendum, AI có thể đề xuất field từ nguồn người dùng cung cấp; UI bắt buộc hiển thị bản đối chiếu và không lưu trước khi người dùng xác nhận value, unit, range và source.
6. M29 có thể so sánh cùng test/unit tương thích, nhưng không diễn giải clinical meaning nếu chưa có policy.

### Ngoại lệ và state

- Reference range khác nhau theo lab/method/person; app không dùng một range toàn cục để chẩn đoán.
- OCR/import PDF/image và chuẩn hóa LOINC là phase sau cần DD riêng.
- State: draft_entry → recorded → corrected → archived; verification: user_entered, source_document_pending hoặc verified_by_policy trong tương lai.

### Dữ liệu nhạy cảm, AI và dependency

- Sensitive mức cao: test name/value/range, lab/source and attachments.
- AI role: chỉ hỗ trợ trích xuất field để người dùng xác nhận; không tự điền dữ liệu thiếu, không giải thích kết quả đơn lẻ hoặc chẩn đoán. Trend summary cần compatible unit/method và consent.
- Dependencies: M04 formula boundary, M10 tracking, M11 subject, M19 privacy/audit/export/delete.

### Rule và acceptance

| ID | Nội dung |
|---|---|
| M27-BR01 | Lưu original value, unit, reference range và source cùng nhau. |
| M27-BR02 | Không áp range toàn cục hoặc diagnosis từ lab result. |
| M27-BR03 | OCR/device/import/LOINC là phase sau, không nằm trong manual-entry-first. |
| M27-BR04 | AI extraction chỉ tạo đề xuất; người dùng phải xác nhận từng field bắt buộc trước khi record được lưu. |
| M27-AC01 | Record hiển thị nguyên vẹn field/source người dùng xác nhận. |
| M27-AC02 | Thiếu field bắt buộc không tạo result hoàn chỉnh. |
| M27-AC03 | Trend chỉ so sánh dữ liệu tương thích và luôn có disclaimer. |
| M27-AC04 | Field AI trích xuất không được persist khi chưa xác nhận và không được tự bù value/unit/range/source bị thiếu. |

## M28 — PREVENTIVE_CARE / Lịch chăm sóc dự phòng

### Mục tiêu, actor và tier

- Mục tiêu: Giúp Plus/FamilyPlus lưu các mốc khám, tiêm chủng và sàng lọc do người dùng hoặc bác sĩ/chuyên gia cung cấp, rồi theo dõi trạng thái hoàn thành.
- Actor: Plus, FamilyPlus; M09 sở hữu reminder delivery.
- Tier: Plus.

### Input dự kiến

- Care item type, nguồn user-entered hoặc clinician-provided, due date/window, completed date, provider/location note, evidence note và subject.
- Age/sex/condition context chỉ được lưu nếu người dùng chủ động cung cấp và policy cho phép; app không dùng context đó để tự quyết định lịch y khoa.

### Luồng chính tương lai

1. Actor chọn subject và tạo mốc từ thông tin do chính người dùng hoặc bác sĩ/chuyên gia cung cấp.
2. Hệ thống lưu nhãn nguồn, source/version nếu có và due window; không biến guideline hoặc catalog tham khảo thành chỉ định cá nhân.
3. Reminder intent gửi sang M09; user đánh dấu completed/skipped/rescheduled.
4. Thay đổi guideline tạo config version mới, không sửa lịch sử completion.
5. UI khuyến khích xác nhận với chuyên gia về lịch phù hợp cá nhân.

### Ngoại lệ và state

- Không tự khẳng định người dùng “quá hạn nguy hiểm” hoặc đủ điều kiện sàng lọc nếu context/source chưa đủ.
- Child/minor, pregnancy và risk-condition schedule cần policy chuyên biệt.
- State: planned → due → completed/skipped/rescheduled → archived.

### Dữ liệu nhạy cảm, AI và dependency

- Sensitive: preventive item, condition/risk context, provider and completion history.
- AI role: none trong scheduling phase đầu; không tự tạo recommendation.
- Dependencies: M09 notifications, M11 subject, M19 privacy/audit, M04/M08 không sở hữu preventive rules.

### Rule và acceptance

| ID | Nội dung |
|---|---|
| M28-BR01 | Mọi item phải ghi rõ user-entered hoặc clinician-provided; tài liệu tham chiếu kèm theo phải có locale, source, version và effective date. |
| M28-BR02 | App không tự tạo lịch khám/tiêm/tầm soát, không đánh giá chống chỉ định và không quyết định người dùng “cần” thủ thuật nào. |
| M28-BR03 | Reminder delivery thuộc M09 và phải idempotent theo subject/item. |
| M28-AC01 | Item hợp lệ lưu đúng source/subject/due window. |
| M28-AC02 | Không có item nào được tự thêm từ profile/context; reference thiếu source/version không được hiển thị như chỉ định. |
| M28-AC03 | Completion/reschedule giữ lịch sử và không tạo reminder trùng. |

## M29 — AI_HEALTH_TRENDS / Báo cáo xu hướng sức khỏe AI

### Mục tiêu, actor và tier

- Mục tiêu: Tạo báo cáo mô tả xu hướng từ dữ liệu sức khỏe mà người dùng chọn, giúp họ nhìn lại và chuẩn bị câu hỏi cho chuyên gia.
- Actor: Plus, FamilyPlus; System aggregation; AI under M07/M19 governance.
- Tier: Plus.

### Input dự kiến

- Subject, date range, selected metrics/modules, consent version, normalized aggregates, data completeness/provenance và user goal/context tùy chọn.
- Không gửi unnecessary raw free text, medication detail, cycle note hoặc lab attachment cho AI.

### Luồng chính tương lai

1. Hệ thống xác thực entitlement, subject, FamilyPlus disclosure và explicit AI consent.
2. Người dùng chọn dữ liệu/time window; hệ thống hiển thị data preview và missing-data note.
3. Aggregator lấy dữ liệu theo repository, chuẩn hóa unit đã được duyệt và tính bộ thống kê xác định trước; AI chỉ nhận safe structured payload từ các thống kê này.
4. AI tạo bản mô tả xu hướng, nêu nguồn, time range, uncertainty và giới hạn.
5. Validator/normalizer chặn diagnosis, treatment, medication/dose, fertility, insulin và emergency clearance.
6. Nếu output không hợp lệ, app dùng deterministic fallback; quota chỉ commit theo contract M06/M07.
7. Báo cáo lưu version/model/prompt-policy reference và cho người dùng xóa/export theo policy.

### Ngoại lệ và state

- Data quá ít/incompatible: không gọi AI hoặc trả “chưa đủ dữ liệu”, không bịa trend.
- AI timeout/unsafe output: không commit report thành công; dùng fallback và safe error.
- Subject access bị revoke giữa request: hủy/không persist output và xóa temporary payload.
- State: requested → validating → generating → generated/rejected/failed → archived/deleted.

### Dữ liệu nhạy cảm, AI và dependency

- Sensitive mức rất cao: cross-module aggregate, inferred trend và AI output.
- AI role: mô tả/giải thích dữ liệu đã chọn; human remains decision-maker.
- Dependencies: M06 quota/access, M07 AI runtime/safety, M08 score ownership, M10 tracking, M11 subject, M19 consent/privacy/audit; M20–M28 as optional sources. M29 không thay dashboard hằng ngày, tổng kết thói quen/health score M08 hoặc goal tracking M10.

### Rule và acceptance

| ID | Nội dung |
|---|---|
| M29-BR01 | Chỉ dùng dữ liệu subject/date range/module mà người dùng đã chọn và consent. |
| M29-BR02 | Mọi output phải có provenance, period, completeness, uncertainty và disclaimer. |
| M29-BR03 | Không diagnosis/treatment/medication/fertility/insulin/emergency clearance. |
| M29-BR04 | Unsafe/invalid output bị reject; fallback không bịa dữ liệu. |
| M29-BR05 | AI call/quota/audit tuân thủ M06, M07 và M19. |
| M29-BR06 | AI chỉ diễn đạt thống kê xác định trước; không suy diễn nguyên nhân bệnh, tiên lượng hoặc tạo risk/health score mới. |
| M29-AC01 | Report hợp lệ trace được tới source modules, time range và policy/model version. |
| M29-AC02 | Insufficient/incompatible data không tạo fabricated trend. |
| M29-AC03 | Unsafe output bị chặn và không hiển thị raw model response. |
| M29-AC04 | Revoke subject access giữa request ngăn persist/delivery. |
| M29-AC05 | Cùng structured statistics tạo cùng numeric facts; AI wording không thay số liệu, dashboard hoặc health score nguồn. |

# 7. Use Case Registry UC-25–UC-34

| UC | Module | Actor | Trigger | Kết quả thành công tương lai |
|---|---|---|---|---|
| UC-25 | M20 | Free/Plus/FamilyPlus | Ghi một lần đo huyết áp | Record có unit/time/source/subject, không chẩn đoán. |
| UC-26 | M21 | Free/Plus/FamilyPlus | Ghi heart rate/SpO₂ | Record có context và limitation copy. |
| UC-27 | M22 | Free/Plus/FamilyPlus | Tạo lịch thuốc hoặc đánh dấu adherence | Version/event idempotent, không thay chỉ dẫn y tế. |
| UC-28 | M23 | Plus/FamilyPlus | Ghi glucose | Original value/unit/context được giữ nguyên. |
| UC-29 | M24 | Plus/FamilyPlus | Ghi symptom/pain entry | Timeline self-report, không symptom checker. |
| UC-30 | M25 | Plus/FamilyPlus | Ghi cycle/period event | Dữ liệu đúng subject với sensitive/full-sharing disclosure. |
| UC-31 | M26 | Plus/FamilyPlus | Ghi symptom/trigger hô hấp/dị ứng | Event có source/context, không đổi action plan. |
| UC-32 | M27 | Plus/FamilyPlus | Ghi kết quả xét nghiệm | Original value/unit/range/source được trace. |
| UC-33 | M28 | Plus/FamilyPlus | Tạo/hoàn tất mốc dự phòng | Item có source/version hoặc nhãn manual. |
| UC-34 | M29 | Plus/FamilyPlus | Yêu cầu AI trend report | Report có provenance/uncertainty hoặc safe fallback. |

# 8. Cross-cutting Business Rules

| ID | Rule |
|---|---|
| AHF-BR-007 | Health feature là wellness/logging support, không thay thế tư vấn, chẩn đoán hoặc điều trị. |
| AHF-BR-008 | Manual-entry-first; thiết bị, OCR và import tự động cần addendum/DD riêng. |
| AHF-BR-009 | Record bắt buộc tách actor và subject; FamilyPlus tuân thủ full sharing Q-15. |
| AHF-BR-010 | Revoke/expiry dừng quyền đọc/ghi mới ngay, vô hiệu cache/notification; deletion theo policy riêng. |
| AHF-BR-011 | M08 là owner của health score; module mới không tự thay công thức hoặc cộng điểm. |
| AHF-BR-012 | M09 là owner của notification delivery; module mới chỉ phát reminder intent. |
| AHF-BR-013 | M07/M06 là owner AI runtime/quota; M19 là owner privacy/audit. |
| AHF-BR-014 | Threshold, source, catalog, conversion và recommendation phải versioned và có owner/effective date. |
| AHF-BR-015 | Không ghi raw health values/free text/AI prompt/response vào logs hoặc analytics. |
| AHF-BR-016 | Correction/reversal giữ trace, không âm thầm ghi đè lịch sử health record. |
| AHF-BR-017 | Emergency/safety copy phải được clinical/local policy duyệt và không phụ thuộc AI. |
| AHF-BR-018 | Không dùng production mock/sample data như dữ liệu thật. |

# 9. Traceability Matrix

| Source | Module/UC | Business rules | Acceptance criteria | DD tương lai | Dependency owner |
|---|---|---|---|---|---|
| Module Registry, M20 section | M20 / UC-25 | AHF-BR-007..018, M20-BR01..03 | M20-AC01..03 | DD-BLOOD_PRESSURE_TRACKING-001 | M10, M11, M19 |
| Module Registry, M21 section | M21 / UC-26 | AHF-BR-007..018, M21-BR01..04 | M21-AC01..04 | DD-HEART_OXYGEN_TRACKING-001 | M10, M11, M19 |
| Module Registry, M22 section | M22 / UC-27 | AHF-BR-007..018, M22-BR01..03 | M22-AC01..03 | DD-MEDICATION_ADHERENCE-001 | M09, M10, M11, M19 |
| Module Registry, M23 section | M23 / UC-28 | AHF-BR-007..018, M23-BR01..03 | M23-AC01..03 | DD-GLUCOSE_TRACKING-001 | M08, M10, M11, M19 |
| Module Registry, M24 section | M24 / UC-29 | AHF-BR-007..018, M24-BR01..04 | M24-AC01..04 | DD-SYMPTOM_PAIN_JOURNAL-001 | M07, M10, M11, M19 |
| Module Registry, M25 section | M25 / UC-30 | AHF-BR-007..018, M25-BR01..03 | M25-AC01..03 | DD-WOMENS_CYCLE_HEALTH-001 | M11, M19, M24 |
| Module Registry, M26 section | M26 / UC-31 | AHF-BR-007..018, M26-BR01..03 | M26-AC01..03 | DD-RESPIRATORY_ALLERGY_TRACKING-001 | M11, M19, M21, M22, M24 |
| Module Registry, M27 section | M27 / UC-32 | AHF-BR-007..018, M27-BR01..04 | M27-AC01..04 | DD-LAB_RESULT_TRACKING-001 | M04, M07, M10, M11, M19 |
| Module Registry, M28 section | M28 / UC-33 | AHF-BR-007..018, M28-BR01..03 | M28-AC01..03 | DD-PREVENTIVE_CARE-001 | M09, M11, M19 |
| Module Registry, M29 section | M29 / UC-34 | AHF-BR-007..018, M29-BR01..06 | M29-AC01..05 | DD-AI_HEALTH_TRENDS-001 | M06, M07, M08, M10, M11, M19, M20–M28 |
| UI Catalog Shell Contract | M20–M29 | AHF-BR-001..006 | AHF-AC-001..005 | Shared catalog shell mapping in future DDs | Features Hub/UI domain |

# 10. Source Registry

Các link dưới đây là nguồn tham khảo chính thức để DD/clinical review đối chiếu. Không copy threshold hoặc recommendation vào production nếu chưa xác nhận locale, population, version và owner.

| ID | Chủ đề | Nguồn | Áp dụng |
|---|---|---|---|
| SRC-01 | AI health ethics/governance | WHO — https://www.who.int/publications/i/item/9789240029200 | M29 và cross-cutting |
| SRC-02 | General wellness/low-risk boundary | U.S. FDA — https://www.fda.gov/regulatory-information/search-fda-guidance-documents/general-wellness-policy-low-risk-devices | M20–M29 và cross-cutting |
| SRC-03 | Đo huyết áp và bối cảnh ảnh hưởng kết quả | CDC — https://www.cdc.gov/high-blood-pressure/measure/index.html | M20 |
| SRC-04 | Medication safety | WHO — https://www.who.int/initiatives/medication-without-harm | M22 |
| SRC-05 | Pulse oximeter và giới hạn độ chính xác | U.S. FDA — https://www.fda.gov/medical-devices/products-and-medical-procedures/pulse-oximeters | M21 |
| SRC-06 | Theo dõi blood sugar và bối cảnh đo | CDC — https://www.cdc.gov/diabetes/diabetes-testing/monitoring-blood-sugar.html | M23 |
| SRC-07 | Hiểu kết quả xét nghiệm và reference range | MedlinePlus/NLM — https://medlineplus.gov/lab-tests/how-to-understand-your-lab-results/ | M27 |
| SRC-08 | Đo huyết áp tại nhà — nguồn bổ sung | American Heart Association — https://www.heart.org/en/health-topics/high-blood-pressure/understanding-blood-pressure-readings/monitoring-your-blood-pressure-at-home | M20 |
| SRC-09 | Danh sách thuốc do người dùng duy trì — nguồn bổ sung | U.S. FDA — https://www.fda.gov/consumers/consumer-updates/create-and-keep-medication-list-your-health | M22 |
| SRC-10 | Glucose monitoring/diagnosis boundary — nguồn bổ sung | NIDDK — https://www.niddk.nih.gov/health-information/diabetes/overview/managing-diabetes và https://www.niddk.nih.gov/health-information/diabetes/overview/tests-diagnosis | M23 |
| SRC-11 | Pain self-report context | MedlinePlus/NLM — https://medlineplus.gov/pain.html | M24 |
| SRC-12 | Chu kỳ và theo dõi triệu chứng | Office on Women’s Health — https://womenshealth.gov/menstrual-cycle | M25 |
| SRC-13 | Asthma, symptom, trigger và action plan | NHLBI — https://www.nhlbi.nih.gov/health/asthma | M26 |
| SRC-14 | Preventive checkup/screening | CDC — https://www.cdc.gov/chronic-disease/prevention/preventive-care.html | M28 |
| SRC-15 | Health information privacy | HHS — https://www.hhs.gov/privacy/index.html | M20–M29/M19 |

# 11. Câu hỏi mở và coding blockers

## 11.1. Quyết định sản phẩm đã khóa

| ID | Quyết định | Hệ quả bắt buộc |
|---|---|---|
| AHF-D01 | FamilyPlus dùng full sharing theo Q-15: mọi active joined member trong cùng package có thể xem dữ liệu M20–M29 của nhau sau disclosure. | Không thiết kế selective per-record privacy trong DD M20–M29. Actor/subject phải tách biệt; remove/leave/revoke/expiry/suspend dừng quyền xem/ghi mới ngay. |

## 11.2. Câu hỏi mở

| ID | Câu hỏi/quyết định cần chốt | Blocker cho |
|---|---|---|
| AHF-Q01 | Clinical owner nào duyệt threshold, safety copy và source version cho từng module? | DD/production M20–M29 |
| AHF-Q02 | Retention, export, delete và correction policy cho từng loại health data là gì? | Schema/API/RLS |
| AHF-Q03 | Consent/version và xử lý minor/pregnancy/postpartum được thiết kế ra sao? | M25 và FamilyPlus |
| AHF-Q04 | Locale Việt Nam, nguồn preventive schedule và số/copy cấp cứu nào được phê duyệt? | M20–M28 safety/M28 |
| AHF-Q05 | Device/OCR/import nào được ưu tiên, duplicate/conflict/provenance policy là gì? | Phase device later |
| AHF-Q06 | AI model/prompt policy, evaluation set, human review, quota và retention được duyệt thế nào cho summary M24, extraction M27 và report M29? | M24/M27/M29 |
| AHF-Q07 | Dữ liệu nào M29 được phép tổng hợp mặc định và dữ liệu nào cần consent riêng mỗi lần? | M29/privacy |

# 12. Gate tạo DD, coding và production acceptance

## 12.1. Gate hiện tại

- Được phép: thêm 10 catalog cards, tier badge và shared development placeholder theo AHF-BR-001..006.
- Không được phép: form nhập, persistence, notification, AI call, score integration, device permission, schema/API/RLS hoặc production health recommendation.
- DD completeness M20–M29 = 0%; business coding progress M20–M29 = 0%.
- UI placeholder không được tính vào DD completeness hoặc business coding progress.

## 12.2. Definition of Ready cho từng DD

- Product Owner chốt scope, actor, tier, in/out, module boundary và câu hỏi mở liên quan.
- Clinical/privacy owner duyệt source policy, disclaimer, escalation, consent và sensitive data handling.
- Có mapping BR/AC/UC từ BD này, dependency owner và conflict resolution.
- Có quyết định manual schema, lifecycle, correction/delete/export, FamilyPlus actor-subject/RLS và notification/AI boundary.

## 12.3. Definition of Ready cho coding nghiệp vụ

- DD module có đủ README, Overall, List_Features, Function_List, Views, Import_File, diagrams/changelog và trạng thái Approved.
- API/schema/RLS/validation/error/idempotency/observability/test traceability đã được thiết kế.
- Không còn open question ảnh hưởng safety, privacy, access, medical interpretation hoặc acceptance.
- Test plan có unit, widget, integration, RLS/sandbox, privacy leak, FamilyPlus revoke, AI safety (nếu có) và accessibility.

## 12.4. Không được claim production-ready khi thiếu

- Clinical/source review và Vietnamese copy approval.
- Supabase sandbox/RLS evidence cho ít nhất hai users và hai family scopes.
- Real-device notification/device-import evidence khi các integration đó được thêm.
- AI safety/evaluation, provenance, user-confirmation/fallback, quota và privacy evidence cho M24, M27 và M29 khi từng vai trò AI được triển khai.
- Export/delete/retention/audit evidence đối với health data nhạy cảm.
