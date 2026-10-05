# BD — M32 Chế độ luyện tập (Gym-first)

| Thuộc tính | Giá trị |
|---|---|
| Mã tài liệu | BD-NANOBIO-FITNESS-TRAINING-001 |
| Module | M32 FITNESS_TRAINING |
| Phiên bản | 1.0 — Draft |
| Ngày | 2026-10-01; định hướng sản phẩm được PO xác nhận bổ sung ngày 2026-10-05 |
| Nguồn | Yêu cầu triển khai của người dùng ngày 2026-10-01; lựa chọn phạm vi sản phẩm được xác nhận ngày 2026-10-05 |
| Phạm vi | Tập gym và tập tại nhà cho người trưởng thành; Gym-first |
| Trạng thái sign-off | PO: Approved qua xác nhận rõ của người dùng; Tech Lead, QA, Clinical và Privacy: Pending |

## 1. Mục tiêu

Giúp người trưởng thành lập và theo dõi một chương trình tập luyện 4 tuần được cá nhân hóa theo hồ sơ, mục tiêu, nơi tập, thiết bị sẵn có, thực phẩm, lịch sinh hoạt và phản hồi hằng tuần. Chương trình kết hợp tập luyện, ăn uống và ngủ nghỉ; đây là công cụ wellness, không chẩn đoán hoặc điều trị.

## 2. Phạm vi v1

- Tập Gym và tập tại nhà; không gồm Yoga, Boxing hoặc môn khác trong bản đầu.
- Hỏi người dùng rà soát dữ liệu onboarding, sau đó bổ sung mục tiêu, kinh nghiệm, thời lượng/ngày tập, lịch rảnh, giờ ngủ, hạn chế vận động, dị ứng và nhóm thực phẩm.
- Gym: chọn thiết bị từ catalog có minh họa. Tại nhà: chỉ đề xuất bài tập được gắn nhãn phù hợp tại nhà.
- Sinh và lưu chương trình 28 ngày; đưa tuần hiện tại vào lịch 7 ngày. Check-in cuối tuần cho phép đề xuất cập nhật các tuần còn lại.
- Xem trước trước khi áp dụng. Chỉ thay các mục tập, ăn và ngủ chưa hoàn thành trong tương lai; giữ lịch sử đã hoàn thành và nhiệm vụ sức khỏe khác.
- Tính BMI/BMR/TDEE bằng M04; không dùng kết quả để chẩn đoán.

## 3. Nguồn dữ liệu và nội dung

Catalog pilot hiện có 24 bài tập (16 Gym, 8 tại nhà), 10 thiết bị, 35 món ăn và 47 ứng viên nguyên liệu. Nội dung mô tả tiếng Việt và hình minh họa được tạo riêng cho sản phẩm; không sao chép văn bản hoặc hình ảnh từ web/cookbook. Mỗi bản ghi phải có ID ổn định, nhãn phù hợp, hướng dẫn/safety note và metadata nguồn. Các bản ghi và giá trị dinh dưỡng vẫn cần reviewer duyệt trước khi đưa vào runtime.

Giá trị dinh dưỡng của nguyên liệu lấy từ USDA FoodData Central, lưu bản tĩnh cùng FDC ID, phiên bản/ngày truy xuất và đơn vị. Món ăn và khẩu phần là nội dung NanoBio biên soạn, không được mô tả là thực đơn y khoa. Video bài tập chỉ dùng YouTube embed chính thức khi video công khai và chủ kênh cho phép nhúng; không tải hoặc lưu trữ video/thumbnail. Nếu video lỗi, vẫn phải có hướng dẫn và hình minh họa gốc.

Tham khảo: [USDA FoodData Central API Guide](https://fdc.nal.usda.gov/api-guide/), [YouTube IFrame Player API](https://developers.google.com/youtube/iframe_api_reference), [YouTube API Terms](https://developers.google.com/youtube/terms/api-services-terms-of-service), [Wikimedia Commons reuse guidance](https://commons.wikimedia.org/wiki/Commons:Reusing_content_outside_Wikimedia).

## 4. Actors và quyền

| Actor | Quyền |
|---|---|
| Guest | Chỉ dùng quyền tạo lịch ban đầu một lần theo M02; dữ liệu Guest lưu cục bộ theo chính sách hiện hành. |
| Member Free | Tạo/điều chỉnh theo quota lịch M02 hiện hành; chương trình đồng bộ theo hướng sở hữu dữ liệu M05 sau khi Tech/Privacy duyệt hợp đồng. |
| Plus / FamilyPlus | Theo entitlement và quota trusted hiện hành; đồng bộ FamilyPlus chỉ theo subject/consent được M05/M11 cho phép và sau khi Tech/Privacy duyệt. |
| Gemini backend | Chỉ chọn và sắp xếp dữ liệu từ catalog đã duyệt; không tạo nội dung catalog mới. |

Mỗi lần gọi Gemini để tạo hoặc điều chỉnh được tính là một lần tạo lịch M02. Không bypass quota. Request lỗi hoặc kết quả không hợp lệ không được ghi lịch và không được commit quota theo quy tắc M02.

## 5. Luồng chính

1. Người dùng mở Chế độ luyện tập từ FeatureHub.
2. App xác minh người dùng đủ 18 tuổi, rà soát hồ sơ onboarding và cho sửa thông tin trước khi tiếp tục.
3. Người dùng khai mục tiêu/kinh nghiệm/lịch tập, chọn Gym hoặc tại nhà, thiết bị hoặc giới hạn tại nhà, nhóm thực phẩm, dị ứng và giờ sinh hoạt.
4. App tính chỉ số M04 cục bộ và lọc catalog đủ điều kiện.
5. Sau khi kiểm tra quyền/quota, backend gọi Gemini với dữ liệu tối thiểu và catalog đã lọc.
6. App kiểm tra response theo schema, ID catalog, điều kiện vận động/thực phẩm và phạm vi số liệu; hiển thị bản xem trước 4 tuần.
7. Sau xác nhận, lưu chương trình và thay các mục tương lai tập/ăn/ngủ của tuần hiện tại một cách nguyên tử.
8. Sau mỗi tuần, hỏi check-in. Gemini có thể đề xuất điều chỉnh phần còn lại nếu còn quota; xem trước và xác nhận trước khi áp dụng tuần kế tiếp.

## 6. Business rules

| ID | Quy tắc |
|---|---|
| M32-BR01 | Chặn tạo chương trình nếu tuổi chính xác dưới 18 hoặc chưa xác minh tuổi. |
| M32-BR02 | Pilot theo chỉ đạo PO: kiểm tra ngày sinh đầy đủ tự khai trên thiết bị, chặn nếu thiếu hoặc dưới 18 tuổi. Cách này có thể bị giả mạo và không phải attestation tin cậy. DOB không gửi cho Gemini hoặc ghi log; Tech/Privacy phải chốt adult proof, consent, nơi lưu, retention và xóa trước phát hành. |
| M32-BR03 | Tuân thủ quyền Guest/Member/Plus/FamilyPlus và quota M02/M06; mỗi lần sinh hoặc điều chỉnh bằng AI tính một lượt. |
| M32-BR04 | Gemini chỉ tham chiếu ID có trong catalog được lọc và duyệt; ID lạ, cấu trúc sai hoặc vượt giới hạn thì từ chối toàn bộ response. |
| M32-BR05 | Không đề xuất bài tập trái nơi tập/thiết bị, dị ứng hoặc hạn chế đã khai báo. Nếu catalog không có phương án phù hợp, dừng và báo người dùng. |
| M32-BR06 | Preview và xác nhận là bắt buộc trước mọi lần áp dụng/thay lịch. |
| M32-BR07 | Cập nhật lịch giữ nguyên mục đã hoàn thành, lịch sử và các mục không thuộc tập/ăn/ngủ; thao tác phải atomic và idempotent. |
| M32-BR08 | Chỉ cung cấp wellness information; không chẩn đoán, kê điều trị hoặc khuyến nghị thay tư vấn chuyên môn. |
| M32-BR09 | Không đặt Gemini/USDA secret trong Flutter, không log raw profile/prompt/response hoặc secret. |
| M32-BR10 | Nội dung media bên thứ ba chỉ phát qua YouTube embed; không download/rehost. Ảnh minh họa v1 phải là nội dung tạo riêng và có manifest provenance. |

## 7. Dữ liệu và tích hợp

- M01: hồ sơ onboarding; bổ sung ngày sinh đầy đủ chỉ sau khi có chính sách lưu/đồng bộ được duyệt.
- M02/M06: tạo lịch, quota, idempotency, entitlement.
- M03/M09: thay mục lịch 7 ngày và đồng bộ notification.
- M04: BMI/BMR/TDEE cục bộ.
- M05/M11: xác định owner/subject và quy tắc Guest/member/FamilyPlus.
- Gemini: dùng luồng backend hiện hữu; Edge Function giữ GEMINI_API_KEY. Client không gọi Gemini trực tiếp.
- M19: consent, privacy, audit/retention theo hợp đồng được duyệt.
- YouTube IFrame Player API: video tùy chọn, có fallback mở YouTube.

## 8. Tiêu chí chấp nhận

- Người dưới 18 tuổi không thể bắt đầu hoặc tạo chương trình.
- Hồ sơ được rà soát trước khi gửi; ngày sinh không có trong payload Gemini/log.
- Kết quả chỉ dùng bài tập, thiết bị, món ăn từ catalog; Gym/tại nhà và restriction được áp đúng.
- Lưu đủ 4 tuần nhưng lịch hoạt động chỉ ghi tuần đang áp dụng trong cửa sổ 7 ngày.
- Confirm cập nhật lịch không xóa mục hoàn thành hoặc task sức khỏe khác.
- Quota M02 được dùng đúng cho khởi tạo/replan; lỗi AI không làm đổi lịch hoặc trừ lượt.
- Video không khả dụng vẫn có hướng dẫn và fallback; catalog có nguồn/provenance.

## 9. Sign-off cần có trước phát hành

| Vai trò | Trạng thái | Bằng chứng |
|---|---|---|
| PO | Approved | Xác nhận rõ của người dùng tự xác nhận là PO cho BD/DD v1.0 ngày 2026-10-01; hướng sản phẩm bổ sung được xác nhận ngày 2026-10-05; tên hiển thị không được cung cấp |
| Tech Lead | Pending | Cần duyệt hợp đồng age proof, storage/sync, Edge Function và transaction lịch |
| QA Lead | Pending | Cần duyệt acceptance matrix và test strategy |
| Clinical | Pending | Cần duyệt sàng lọc, an toàn bài tập/dinh dưỡng và hướng dẫn dừng/hỏi chuyên gia |
| Privacy | Pending | Cần duyệt age proof, health payload, consent, retention và xóa |

Không đánh dấu M32 Approved hoặc đưa pilot thành tính năng phát hành rộng trước khi các sign-off này được ghi nhận. PO đã chỉ đạo pilot source/runtime tiếp tục ngày 2026-10-05; chỉ đạo đó không thay thế reviewer approval.

## 10. Định hướng sản phẩm được PO xác nhận ngày 2026-10-05

- Bản pilot kiểm tra DOB tự khai trên thiết bị và có thể bị sửa/vượt qua; Gemini không nhận DOB. Tech/Privacy vẫn phải duyệt adult proof cho phát hành, consent, lưu trữ và xóa.
- Guest tiếp tục lưu cục bộ; Member hiện đồng bộ theo subject self của M05/RLS. FamilyPlus dependent-subject selection/consent chưa được triển khai và cần quyết định Tech/Privacy trước khi coi phạm vi đó là hoàn tất. Schema, retention, xóa và audit vẫn cần duyệt.
- Phạm vi là wellness: không chẩn đoán/điều trị, lọc cứng dị ứng và tôn trọng hạn chế vận động. Clinical phải chốt sàng lọc, dấu hiệu cần dừng/hỏi chuyên gia và nội dung dinh dưỡng trước khi bật.
- Nền tảng phát hành đầu tiên hướng tới Android/iOS. Video là tùy chọn, chỉ nhúng bằng YouTube IFrame chính thức sau khi kiểm tra; nếu không phát được thì dùng minh họa, hướng dẫn và nút mở YouTube. QA/Tech xác nhận ma trận cuối.
