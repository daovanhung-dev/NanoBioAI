# BUSINESS DESIGN  
## HỆ THỐNG THÔNG BÁO TỪ NÚT NỔI NHÂN VẬT NABI

**Mã tài liệu:** BD-NABI-NOTIFICATION-001  
**Phiên bản:** 1.0  
**Phạm vi:** Ứng dụng NanoBio/Nabi  
**Đối tượng sử dụng:** BA, UI/UX, Flutter Developer, Backend Developer, Tester, Product Owner

---

# 1. Mục tiêu nghiệp vụ

Xây dựng hệ thống thông báo trong ứng dụng dưới hình thức **Nabi trực tiếp trò chuyện với người dùng từ nút nổi nhân vật Nabi**.

Hệ thống phải đạt các mục tiêu:

1. Giúp người dùng hiểu rõ trạng thái hành trình sức khỏe hiện tại.
2. Nhắc người dùng duy trì nhiệm vụ và chuỗi ngày sống khỏe.
3. Giới thiệu quyền lợi VIP đúng thời điểm, dựa trên hành vi thực tế.
4. Chuyển đổi người dùng:
   - Từ Free lên VIP 30 ngày.
   - Từ VIP 30 ngày lên VIP năm.
5. Tạo cảm giác Nabi là một người đồng hành có cảm xúc, không chỉ là một công cụ bán hàng.
6. Tránh hiển thị thông báo quá nhiều gây khó chịu.
7. Cho phép đo lường hiệu quả của từng thông báo.

---

# 2. Phạm vi chức năng

## 2.1. Trong phạm vi

- Thông báo xuất hiện từ nút nổi Nabi.
- Bong bóng hội thoại của Nabi.
- Điều kiện kích hoạt theo hành vi, trạng thái gói và thời gian.
- Thông báo giới thiệu nâng cấp gói.
- Thông báo nhiệm vụ, chuỗi ngày và phần thưởng.
- Thông báo báo cáo sức khỏe.
- Thông báo mời người thân.
- Thông báo quan tâm, động viên người dùng.
- Điều hướng từ CTA tới màn hình liên quan.
- Giới hạn tần suất và chống hiển thị lặp.
- Ghi nhận dữ liệu phân tích chuyển đổi.

## 2.2. Ngoài phạm vi

- Logic thanh toán chi tiết.
- Phương thức thanh toán.
- Quản lý chuyên gia và lịch tư vấn.
- Thuật toán tạo thực đơn.
- Thuật toán tính điểm sức khỏe.
- Thông báo cảnh báo y tế khẩn cấp.
- Chẩn đoán hoặc kết luận tình trạng bệnh.

---

# 3. Đối tượng người dùng

| Đối tượng | Mô tả |
|---|---|
| Người dùng Free | Đã tạo hồ sơ sức khỏe, được sử dụng các quyền lợi miễn phí giới hạn |
| Người dùng VIP 30 ngày | Đang sử dụng gói VIP có thời hạn 30 ngày |
| Người dùng VIP năm | Đang sử dụng gói VIP thời hạn một năm |
| Người dùng hết hạn | Đã từng sử dụng VIP nhưng gói hiện không còn hiệu lực |
| Người dùng quay lại | Không mở ứng dụng trong một khoảng thời gian và vừa quay lại |
| Người dùng đủ điều kiện nhận quà | Đạt chuỗi ngày, điểm hoặc mốc nhiệm vụ theo quy định |

---

# 4. Quyền lợi gói làm căn cứ hiển thị thông báo

## 4.1. Gói Free

Người dùng Free được sử dụng:

- Hồ sơ sức khỏe ban đầu.
- Thực đơn mẫu ba ngày.
- Tối đa năm câu hỏi với Nabi mỗi ngày.
- Nhiệm vụ sức khỏe cơ bản.
- Tích điểm từ nhiệm vụ.
- Xem trước Bản đồ 365 ở trạng thái khóa.
- Tham gia cộng đồng.

## 4.2. Gói VIP 30 ngày

Người dùng VIP 30 ngày được mở khóa:

- Thực đơn cá nhân hóa 30 ngày.
- Đổi món linh hoạt.
- Số lượt trò chuyện với Nabi cao hơn hoặc không giới hạn theo cấu hình.
- Báo cáo tuần đầy đủ.
- Gửi câu hỏi cho chuyên gia.
- Bản đồ hành trình 365.
- Nhiệm vụ nâng cao.
- Hộp quà VIP tháng.

## 4.3. Gói VIP năm

Người dùng VIP năm được mở khóa:

- Toàn bộ quyền lợi VIP 30 ngày.
- Hành trình sức khỏe 365 ngày.
- Điểm thưởng theo chương trình đang áp dụng.
- Quà định kỳ theo các mốc.
- Ưu tiên tham gia chương trình trực tuyến với chuyên gia.
- Báo cáo theo tháng và quý.
- Mã mời người thân.
- Chứng nhận hoàn thành hành trình.
- Các phần thưởng thành tích theo chính sách hiện hành.

Mọi quyền lợi, điểm thưởng hoặc quà tặng phải được lấy từ cấu hình chương trình. Không hiển thị quyền lợi đã hết hiệu lực.

---

# 5. Khái niệm nút nổi Nabi

## 5.1. Hình thức

Nút nổi Nabi là hình ảnh nhân vật Nabi được hiển thị đè trên giao diện ứng dụng.

Nút nổi có các trạng thái:

- Bình thường.
- Đang có thông báo mới.
- Đang nói.
- Vui mừng.
- Quan tâm.
- Khích lệ.
- Nhắc nhở nhẹ.
- Đang chờ người dùng phản hồi.

## 5.2. Vị trí

- Mặc định nằm ở góc dưới bên phải.
- Không che nút điều hướng chính.
- Có thể kéo sang mép trái hoặc mép phải.
- Vị trí cuối cùng được lưu cho lần mở ứng dụng tiếp theo.
- Tự động dịch chuyển khi bàn phím xuất hiện.

## 5.3. Bong bóng hội thoại

Khi có thông báo, một bong bóng hội thoại xuất hiện cạnh Nabi.

Bong bóng phải:

- Có phần mũi hướng về hình ảnh Nabi.
- Hiển thị tối đa một thông báo tại một thời điểm.
- Có nội dung ngắn, dễ đọc.
- Có một CTA chính.
- Có nút đóng.
- Có thể có CTA phụ “Để sau” đối với thông báo nâng gói.
- Không tự đóng khi người dùng đang đọc hoặc có CTA.
- Có thể thu gọn thành dấu chấm thông báo trên Nabi.

## 5.4. Hành vi khi chạm Nabi

- Nếu đang có thông báo chưa đọc: mở thông báo đó.
- Nếu không có thông báo: mở bảng tương tác nhanh với Nabi.
- Nếu có nhiều thông báo đang chờ: chỉ mở thông báo có độ ưu tiên cao nhất.
- Sau khi xử lý thông báo hiện tại, hệ thống mới được xét thông báo tiếp theo.

---

# 6. Nguyên tắc nội dung thông báo

1. Nabi xưng là “Nabi”.
2. Gọi người dùng là “bạn”.
3. Ngôn ngữ tích cực, gần gũi và không phán xét.
4. Không gây áp lực, đe dọa hoặc tạo cảm giác tội lỗi.
5. Không dùng nội dung như:
   - “Bạn đang thất bại.”
   - “Sức khỏe của bạn sẽ xấu đi nếu không mua VIP.”
   - “Bạn bắt buộc phải nâng cấp.”
6. Không kết luận bệnh hoặc tình trạng sức khỏe.
7. Nội dung nâng gói phải nói rõ giá trị người dùng nhận được.
8. Thông báo bán hàng phải được xen kẽ với thông báo hỗ trợ và động viên.
9. Không hiển thị quyền lợi mà người dùng đã sở hữu.
10. Nội dung có điểm thưởng phải lấy giá trị động từ hệ thống.

---

# 7. Phân loại thông báo

| Nhóm | Mục đích |
|---|---|
| Contextual | Xuất hiện khi người dùng thao tác vào tính năng bị giới hạn |
| Milestone | Xuất hiện khi đạt mốc nhiệm vụ hoặc chuỗi ngày |
| Subscription | Thông báo liên quan nâng cấp, gia hạn hoặc hết hạn |
| Retention | Giữ người dùng tiếp tục sử dụng ứng dụng |
| Reward | Thông báo về điểm, hộp quà, huy hiệu và thẻ cứu chuỗi |
| Report | Thông báo báo cáo sức khỏe đã sẵn sàng |
| Care | Thông báo quan tâm, động viên từ Nabi |
| Profile | Nhắc cập nhật hồ sơ sức khỏe |

---

# 8. Quy tắc hiển thị chung

## 8.1. Giới hạn toàn hệ thống

- Tối đa một thông báo chủ động từ Nabi trong một phiên sử dụng.
- Tối đa hai thông báo nâng gói trong một ngày.
- Tối đa năm thông báo nâng gói trong bảy ngày.
- Một nội dung nâng gói giống nhau không được chủ động lặp lại trong vòng 72 giờ.
- Thông báo do người dùng trực tiếp truy cập tính năng bị khóa có thể xuất hiện ngay.
- Trong cùng một màn hình, một thông báo không được xuất hiện lại sau khi người dùng đã đóng.

## 8.2. Không hiển thị thông báo khi

- Người dùng đang onboarding.
- Người dùng đang nhập liệu.
- Bàn phím đang mở và Nabi có thể che nội dung.
- Người dùng đang thanh toán.
- Người dùng đang thực hiện cuộc gọi hoặc tư vấn chuyên gia.
- Ứng dụng đang hiển thị lỗi hệ thống quan trọng.
- Người dùng vừa đóng thông báo trong khoảng thời gian dưới 30 giây.
- Người dùng đã mua quyền lợi được quảng bá.
- Gói hoặc chương trình khuyến mại không còn hiệu lực.

## 8.3. Thứ tự ưu tiên

1. Thông báo phản hồi trực tiếp thao tác của người dùng.
2. Thông báo gói sắp hết hạn.
3. Thông báo phần thưởng hoặc chuỗi ngày sắp đạt.
4. Thông báo báo cáo sức khỏe.
5. Thông báo động viên.
6. Thông báo nâng cấp chủ động.
7. Thông báo mời người thân.

---

# 9. Danh sách thông báo Free lên VIP 30 ngày

## 9.1. NBI-FREE-001 — Hết thực đơn miễn phí

**Điều kiện kích hoạt**

- Người dùng đang sử dụng gói Free.
- Người dùng đã sử dụng hết thực đơn mẫu ba ngày.
- Hoặc người dùng yêu cầu tạo thực đơn cho ngày thứ tư trở đi.
- Người dùng chưa có giao dịch nâng cấp đang chờ xử lý.

**Nội dung**

> Bạn đã hoàn thành bước khởi động của hành trình sống khỏe. Nabi có thể tạo cho bạn thực đơn cá nhân hóa 30 ngày, linh hoạt đổi món theo khẩu vị và mục tiêu sức khỏe.

**CTA chính:** `Mở khóa VIP 30 ngày`

**CTA phụ:** `Để sau`

**Điều hướng**

Mở màn hình so sánh gói:

- Mặc định chọn VIP 30 ngày.
- Đồng thời cho phép xem VIP năm.
- Hiển thị rõ quyền lợi thực đơn 30 ngày và đổi món linh hoạt.

**Tần suất**

- Hiển thị ngay khi người dùng yêu cầu tạo thêm thực đơn.
- Thông báo chủ động tối đa một lần trong 72 giờ.
- Không hiển thị lại sau khi người dùng đã mua VIP.

**Biểu cảm Nabi:** Hy vọng, khích lệ.

---

## 9.2. NBI-FREE-002 — Sắp hết hoặc hết lượt hỏi Nabi

**Điều kiện kích hoạt mức 1**

- Người dùng Free đã gửi câu hỏi thứ tư trong ngày.
- Giới hạn hiện tại là năm câu hỏi mỗi ngày.

**Nội dung mức 1**

> Hôm nay Nabi đã cùng bạn giải đáp khá nhiều điều rồi. Bạn còn 1 lượt hỏi miễn phí trong ngày.

**CTA:** `Xem quyền lợi VIP`

**Điều kiện kích hoạt mức 2**

- Người dùng đã sử dụng hết năm câu hỏi.
- Người dùng tiếp tục gửi câu hỏi mới.

**Nội dung mức 2**

> Có vẻ bạn đang có nhiều câu hỏi về ăn uống và sức khỏe. Với gói VIP, Nabi có thể đồng hành cùng bạn sâu hơn mỗi ngày.

**CTA chính:** `Chat thoải mái với Nabi`

**CTA phụ:** `Quay lại sau`

**Điều hướng**

Mở trang quyền lợi VIP, tập trung vào quyền trò chuyện với Nabi.

**Tần suất**

- Cảnh báo còn một lượt: tối đa một lần mỗi ngày.
- Thông báo hết lượt: được hiển thị khi người dùng tiếp tục gửi câu hỏi.
- Không tự động bật lặp lại trong cùng phiên chat.

**Biểu cảm Nabi:** Quan tâm, không thể hiện buồn hoặc thất vọng.

---

## 9.3. NBI-FREE-003 — Hoàn thành bảy ngày nhiệm vụ

**Điều kiện kích hoạt**

- Người dùng Free đã hoàn thành nhiệm vụ trong bảy ngày.
- Chỉ kích hoạt ở lần đầu đạt mốc.
- Chưa từng nhận thông báo này.

**Nội dung**

> Bạn đã duy trì rất tốt trong 7 ngày đầu. Đừng dừng lại ở đây. Hãy để Nabi xây dựng cho bạn hành trình 30 ngày tiếp theo.

**CTA chính:** `Tiếp tục với VIP 30 ngày`

**CTA phụ:** `Xem thành tích`

**Điều hướng**

- CTA chính: trang nâng cấp VIP 30 ngày.
- CTA phụ: trang chuỗi ngày và phần thưởng.

**Tần suất:** Một lần duy nhất tại mốc đầu tiên.

**Biểu cảm Nabi:** Vui mừng, chúc mừng.

---

## 9.4. NBI-FREE-004 — Truy cập mục chuyên gia

**Điều kiện kích hoạt**

- Người dùng Free mở màn hình chuyên gia.
- Quyền gửi câu hỏi hoặc đặt lịch đang bị khóa.

**Nội dung**

> Bạn có muốn đặt câu hỏi cho chuyên gia dinh dưỡng để hiểu rõ hơn tình trạng của mình không?

**CTA chính:** `Mở khóa quyền gặp chuyên gia`

**CTA phụ:** `Xem thông tin chuyên gia`

**Điều hướng**

- CTA chính: trang quyền lợi VIP.
- CTA phụ: cho phép xem hồ sơ, chuyên môn và giới thiệu chuyên gia.

**Quy tắc nghiệp vụ**

Người dùng Free vẫn được xem thông tin chuyên gia nhưng không được gửi câu hỏi chuyên sâu nếu quyền lợi chưa được mở khóa.

**Tần suất**

- Tối đa một lần trong mỗi phiên truy cập mục chuyên gia.
- Chủ động nhắc lại sau tối thiểu 72 giờ.

**Biểu cảm Nabi:** Giải thích, hỗ trợ.

---

## 9.5. NBI-FREE-005 — Xem Bản đồ 365

**Điều kiện kích hoạt**

- Người dùng Free mở Bản đồ 365.
- Bản đồ được hiển thị dạng xem trước hoặc màu xám.
- Người dùng chạm vào một mốc đang khóa.

**Nội dung**

> Bạn mới chỉ mở khóa những bước đầu tiên. Hành trình Sức khỏe 365 sẽ giúp bạn đi xa hơn, đều hơn và có mục tiêu rõ ràng hơn.

**CTA chính:** `Mở khóa Bản đồ 365`

**CTA phụ:** `Xem trước hành trình`

**Điều hướng**

Mở trang so sánh VIP 30 ngày và VIP năm, tập trung vào quyền lợi hành trình sức khỏe.

**Tần suất**

- Có thể hiển thị khi người dùng chạm mốc khóa.
- Chỉ hiển thị một lần trong một phiên.
- Chủ động nhắc lại sau tối thiểu 72 giờ.

**Biểu cảm Nabi:** Khám phá, mời gọi nhẹ nhàng.

---

## 9.6. NBI-FREE-006 — Báo cáo tuần đầy đủ bị khóa

**Điều kiện kích hoạt**

- Báo cáo sức khỏe tuần đã được tạo.
- Người dùng Free chỉ được xem bản tóm tắt.
- Người dùng chọn xem chi tiết.

**Nội dung**

> Nabi đã hoàn thành báo cáo tuần của bạn. Bản đầy đủ sẽ cho bạn biết thói quen tốt nhất, điều cần cải thiện và gợi ý cho tuần tiếp theo.

**CTA chính:** `Xem báo cáo đầy đủ với VIP`

**CTA phụ:** `Xem bản tóm tắt`

**Điều hướng**

- CTA chính: trang nâng cấp VIP.
- CTA phụ: trang báo cáo miễn phí.

**Tần suất:** Tối đa một lần cho mỗi báo cáo tuần.

**Biểu cảm Nabi:** Phân tích, quan tâm.

---

## 9.7. NBI-FREE-007 — Câu hỏi cần chuyên gia

**Điều kiện kích hoạt**

- Người dùng gửi câu hỏi thuộc nhóm cần chuyên gia hỗ trợ.
- Người dùng đang sử dụng gói Free.
- Hệ thống không được tự động đưa ra kết luận y tế.

**Nội dung**

> Câu hỏi này cần chuyên gia dinh dưỡng hỗ trợ để trả lời phù hợp hơn. Bạn có muốn mở khóa quyền gửi câu hỏi cho chuyên gia không?

**CTA chính:** `Gặp chuyên gia cùng VIP`

**CTA phụ:** `Để sau`

**Điều hướng:** Trang quyền lợi chuyên gia trong gói VIP.

**Tần suất**

- Hiển thị theo câu hỏi cần chuyên gia.
- Không lặp lại nhiều lần với cùng một câu hỏi.
- Sau khi đóng, câu hỏi được giữ ở trạng thái nháp nếu có thể.

**Biểu cảm Nabi:** Nghiêm túc, quan tâm.

---

# 10. Danh sách thông báo VIP 30 ngày lên VIP năm

## 10.1. NBI-ANNUAL-001 — Sau bảy ngày sử dụng VIP

**Điều kiện kích hoạt**

- Người dùng đang có VIP 30 ngày.
- Đã sử dụng gói đủ bảy ngày.
- Chưa sở hữu VIP năm.

**Nội dung**

> Bạn đã bắt đầu có nhịp sống khỏe hơn. Nhưng một thói quen bền vững cần nhiều hơn 30 ngày. VIP năm giúp Nabi đồng hành cùng bạn trọn vẹn 365 ngày.

**CTA chính:** `Nâng cấp VIP năm`

**CTA phụ:** `Xem hành trình hiện tại`

**Điều hướng**

Trang quyền lợi VIP năm, hiển thị:

- Hành trình 365 ngày.
- Quà và điểm thưởng.
- Báo cáo dài hạn.
- Quyền lợi chuyên gia.
- Quyền lợi mời người thân.

**Tần suất:** Một lần tại ngày sử dụng thứ bảy.

**Biểu cảm Nabi:** Khích lệ, hướng tới mục tiêu dài hạn.

---

## 10.2. NBI-ANNUAL-002 — Sau 15 ngày sử dụng VIP

**Điều kiện kích hoạt**

- Người dùng đã sử dụng VIP 30 ngày đủ 15 ngày.
- Có đủ dữ liệu hoạt động để cá nhân hóa.
- Chưa nâng lên VIP năm.

**Nội dung**

> Nabi đã có thêm dữ liệu để hiểu bạn tốt hơn. Nếu tiếp tục hành trình 365 ngày, các gợi ý sẽ ngày càng phù hợp với thói quen và mục tiêu của bạn.

**CTA chính:** `Mở khóa hành trình dài hạn`

**CTA phụ:** `Xem Nabi đã hiểu gì`

**Điều hướng**

- CTA chính: trang VIP năm.
- CTA phụ: trang tổng hợp dữ liệu và tiến trình cá nhân.

**Tần suất:** Một lần tại ngày thứ 15.

**Biểu cảm Nabi:** Thấu hiểu, thân thiện.

**Lưu ý**

Không sử dụng nội dung “Nabi đã hiểu hoàn toàn về sức khỏe của bạn”. Chỉ được nói Nabi có thêm dữ liệu để cá nhân hóa gợi ý.

---

## 10.3. NBI-ANNUAL-003 — Còn năm ngày VIP

**Điều kiện kích hoạt**

- Gói VIP 30 ngày còn đúng năm ngày.
- Chưa có giao dịch gia hạn hoặc nâng cấp thành công.

**Nội dung**

> Gói VIP 30 ngày của bạn còn 5 ngày. Đừng để hành trình sống khỏe đang duy trì bị gián đoạn.

**CTA chính:** `Tiếp tục với VIP năm`

**CTA phụ:** `Xem ngày hết hạn`

**Điều hướng:** Trang nâng cấp VIP năm.

**Tần suất:** Một lần tại mốc còn năm ngày.

**Biểu cảm Nabi:** Nhắc nhở nhẹ nhàng.

---

## 10.4. NBI-ANNUAL-004 — Còn một ngày VIP

**Điều kiện kích hoạt**

- Gói VIP 30 ngày còn đúng một ngày.
- Chưa gia hạn.
- Chương trình tặng điểm vẫn còn hiệu lực.

**Nội dung có ưu đãi**

> Chỉ còn 1 ngày VIP. Nếu nâng cấp VIP năm hôm nay, bạn sẽ nhận thêm {reward_points} điểm thưởng để sử dụng trong hệ sinh thái Nabi.

**Nội dung không có ưu đãi**

> Chỉ còn 1 ngày VIP. Bạn có thể nâng cấp VIP năm để tiếp tục hành trình cùng Nabi mà không bị gián đoạn.

**CTA chính:** `Gia hạn ngay`

**CTA phụ:** `Để sau`

**Điều hướng:** Trang thanh toán VIP năm.

**Tần suất**

- Tối đa một lần trong ngày cuối.
- Có thể hiển thị lại khi người dùng chủ động mở trang gói cước.
- Không hiển thị sau khi thanh toán thành công.

**Biểu cảm Nabi:** Quan tâm, nhắc thời hạn.

---

# 11. Thông báo nhiệm vụ, chuỗi ngày và phần thưởng

## 11.1. NBI-STREAK-001 — Sắp đạt chuỗi bảy ngày

**Điều kiện kích hoạt**

- Người dùng đã hoàn thành nhiệm vụ sáu ngày liên tiếp.
- Ngày hiện tại chưa hoàn thành đủ điều kiện duy trì chuỗi.

**Nội dung**

> Bạn đã duy trì 6 ngày liên tiếp. Chỉ còn 1 ngày nữa để mở Hộp quà 7 ngày!

**CTA:** `Hoàn thành nhiệm vụ hôm nay`

**Điều hướng:** Danh sách nhiệm vụ còn lại trong ngày.

**Tần suất:** Một lần tại mốc sáu ngày.

**Biểu cảm Nabi:** Hào hứng.

---

## 11.2. NBI-STREAK-002 — Nhận Thẻ cứu chuỗi

**Điều kiện kích hoạt**

- Người dùng bỏ lỡ một ngày.
- Người dùng có Thẻ cứu chuỗi miễn phí hoặc quyền lợi tương ứng.
- Chuỗi đủ điều kiện được khôi phục.

**Nội dung**

> Không sao, ai cũng có lúc bận. Nabi tặng bạn 1 Thẻ cứu chuỗi để tiếp tục hành trình.

**CTA chính:** `Dùng Thẻ cứu chuỗi`

**CTA phụ:** `Để sau`

**Quy tắc nghiệp vụ**

- Phải hiển thị thời hạn sử dụng thẻ.
- Không tự động sử dụng thẻ khi chưa có sự đồng ý.
- Sau khi sử dụng thành công, cập nhật lại chuỗi ngay.
- Nếu thẻ là quyền lợi VIP, phải hiển thị rõ điều kiện trước khi điều hướng nâng cấp.

**Biểu cảm Nabi:** An ủi, không phán xét.

---

## 11.3. NBI-REWARD-001 — Mở hộp quà

**Điều kiện kích hoạt**

Người dùng đạt một trong các mốc:

- Ba ngày liên tiếp.
- Bảy ngày liên tiếp.
- 15 ngày liên tiếp.
- 30 ngày liên tiếp.
- Mốc khác do hệ thống cấu hình.

**Nội dung mẫu**

> Bạn đã đạt chuỗi {streak_days} ngày. Hộp quà {reward_name} đang chờ bạn mở!

**CTA:** `Mở hộp quà`

**Điều hướng:** Màn hình phần thưởng.

**Tần suất:** Một lần cho mỗi phần thưởng.

**Biểu cảm Nabi:** Chúc mừng, vui mừng.

---

# 12. Thông báo báo cáo sức khỏe

## 12.1. NBI-REPORT-001 — Báo cáo tuần đã sẵn sàng

**Điều kiện kích hoạt**

- Đã đủ dữ liệu tạo báo cáo tuần.
- Báo cáo đã được hệ thống tạo thành công.
- Người dùng chưa xem báo cáo.

**Nội dung**

> Báo cáo tuần của bạn đã sẵn sàng. Bạn có muốn xem Nabi nhận ra điều gì về thói quen của bạn không?

**CTA:** `Xem báo cáo`

**Nội dung báo cáo có thể gồm**

- Số ngày uống đủ nước.
- Số nhiệm vụ đã hoàn thành.
- Thói quen được duy trì tốt nhất.
- Nội dung nên cải thiện trong tuần tới.
- Gợi ý thực đơn tuần tiếp theo.

**Phân quyền**

- Free: chỉ xem bản tóm tắt.
- VIP: xem báo cáo đầy đủ.

**Tần suất:** Một lần cho mỗi báo cáo.

**Biểu cảm Nabi:** Quan tâm, phân tích tích cực.

---

# 13. Thông báo mời người thân

## 13.1. NBI-REFERRAL-001 — Mời người thân trải nghiệm

**Điều kiện kích hoạt**

- Người dùng có quyền tạo mã mời.
- Chưa vượt giới hạn số mã mời.
- Chương trình giới thiệu đang hoạt động.

**Nội dung**

> Bạn có muốn mời người thân cùng bắt đầu hành trình sống khỏe với Nabi không?

**CTA chính:** `Tặng trải nghiệm 3 ngày`

**CTA phụ:** `Xem quyền lợi`

**Điều hướng:** Màn hình tạo và chia sẻ mã mời.

**Quy tắc nghiệp vụ**

- Người được mời nhận quyền trải nghiệm ba ngày.
- Người mời nhận điểm theo chính sách hiện hành.
- Nếu có thưởng khi người được mời nâng cấp, phải hiển thị rõ điều kiện.
- Chương trình chỉ có một tầng giới thiệu.
- Không cho phép mô hình thưởng nhiều tầng.
- Không thông báo lặp lại nếu người dùng đã hết lượt mời.

**Biểu cảm Nabi:** Vui vẻ, kết nối.

---

# 14. Khoảnh khắc Nabi quan tâm

Các thông báo này không nhằm bán gói. Mục tiêu là tạo cảm giác Nabi thực sự đồng hành với người dùng.

## 14.1. NBI-CARE-001 — Người dùng bận, chưa hoàn thành nhiệm vụ

**Điều kiện kích hoạt**

- Đã gần cuối ngày.
- Người dùng còn nhiều nhiệm vụ chưa hoàn thành.
- Không có dấu hiệu người dùng đã tắt nhắc nhở.
- Không hiển thị quá muộn theo khung giờ ngủ cá nhân.

**Nội dung**

> Hôm nay bạn bận lắm phải không? Không sao, chỉ cần uống thêm một cốc nước và hoàn thành 1 nhiệm vụ nhỏ thôi.

**CTA:** `Làm một nhiệm vụ nhỏ`

**Điều hướng:** Nhiệm vụ dễ hoàn thành nhất còn lại.

**Biểu cảm Nabi:** Quan tâm.

---

## 14.2. NBI-CARE-002 — Người dùng quay lại

**Điều kiện kích hoạt**

- Người dùng không mở ứng dụng từ ba ngày trở lên.
- Vừa mở lại ứng dụng.
- Không có thông báo ưu tiên cao hơn.

**Nội dung**

> Nabi thấy bạn đã quay lại. Mình tiếp tục từ một bước nhỏ hôm nay nhé?

**CTA:** `Tiếp tục hành trình`

**Điều hướng:** Dashboard hoặc nhiệm vụ hôm nay.

**Tần suất:** Một lần sau mỗi giai đoạn gián đoạn.

**Biểu cảm Nabi:** Vui vì người dùng quay lại.

---

## 14.3. NBI-CARE-003 — Động viên sau ngày chưa hoàn hảo

**Điều kiện kích hoạt**

- Người dùng chỉ hoàn thành một phần nhiệm vụ.
- Hoặc người dùng bị mất chuỗi.
- Không hiển thị cùng lúc với Thẻ cứu chuỗi.

**Nội dung**

> Bạn không cần hoàn hảo. Bạn chỉ cần tốt hơn hôm qua một chút.

**CTA:** `Bắt đầu lại hôm nay`

**Điều hướng:** Nhiệm vụ hôm nay.

**Tần suất:** Tối đa một lần trong 24 giờ.

**Biểu cảm Nabi:** Khích lệ.

---

# 15. Nhắc cập nhật hồ sơ sức khỏe

## 15.1. NBI-PROFILE-001 — Hồ sơ cần cập nhật

**Điều kiện kích hoạt đề xuất**

Một trong các điều kiện sau xảy ra:

- Hồ sơ sức khỏe chưa được cập nhật trong 30 ngày.
- Người dùng vừa có kết quả kiểm tra sức khỏe định kỳ.
- Người dùng thay đổi cân nặng, mục tiêu hoặc lịch sinh hoạt.
- Hệ thống phát hiện dữ liệu hồ sơ thiếu trường bắt buộc để cá nhân hóa.

**Nội dung**

> Đã đến lúc cập nhật hồ sơ sức khỏe để Nabi điều chỉnh thực đơn và lịch trình phù hợp hơn với bạn.

**CTA chính:** `Cập nhật hồ sơ`

**CTA phụ:** `Để sau`

**Điều hướng:** Màn hình cập nhật hồ sơ sức khỏe.

**Quy tắc nghiệp vụ**

- Không yêu cầu người dùng nhập lại toàn bộ dữ liệu.
- Hiển thị trước thông tin hiện tại.
- Chỉ yêu cầu cập nhật trường thay đổi.
- Sau khi cập nhật, các đề xuất mới phải sử dụng dữ liệu mới nhất.
- Không tự động thay đổi lịch trình hiện hành nếu chưa thông báo cho người dùng.

**Biểu cảm Nabi:** Nhắc nhở, hỗ trợ.

---

# 16. Luồng hiển thị thông báo

## 16.1. Luồng thông báo chủ động

1. Người dùng mở hoặc đang sử dụng ứng dụng.
2. Hệ thống phát sinh sự kiện nghiệp vụ.
3. Notification Engine kiểm tra:
   - Gói hiện tại.
   - Điều kiện kích hoạt.
   - Lịch sử đã hiển thị.
   - Thời gian cooldown.
   - Trạng thái màn hình.
   - Độ ưu tiên.
4. Nếu đủ điều kiện:
   - Nabi chuyển sang biểu cảm tương ứng.
   - Hiển thị dấu hiệu có tin mới.
   - Bong bóng hội thoại xuất hiện.
5. Người dùng có thể:
   - Chọn CTA.
   - Chọn “Để sau”.
   - Đóng thông báo.
   - Chạm Nabi để mở lại.
6. Hệ thống ghi nhận kết quả tương tác.

## 16.2. Luồng khi truy cập tính năng bị khóa

1. Người dùng chạm vào tính năng bị khóa.
2. Hệ thống kiểm tra quyền gói.
3. Nếu chưa có quyền:
   - Không thực hiện chức năng.
   - Nabi xuất hiện với nội dung giải thích.
   - Hiển thị CTA nâng cấp.
4. Nếu người dùng nâng cấp thành công:
   - Cập nhật quyền ngay.
   - Đóng thông báo nâng cấp.
   - Quay lại chức năng người dùng vừa yêu cầu.
5. Nếu người dùng đóng:
   - Giữ nguyên màn hình hiện tại.
   - Không tự động mở trang thanh toán.

## 16.3. Luồng sau thanh toán

1. Nhận kết quả thanh toán thành công.
2. Đồng bộ trạng thái gói.
3. Xóa toàn bộ thông báo nâng cấp không còn phù hợp.
4. Hiển thị thông báo chúc mừng từ Nabi.
5. Điều hướng người dùng tới quyền lợi vừa mở khóa.
6. Ghi nhận sự kiện chuyển đổi.

---

# 17. Quy tắc chống hiển thị sai

Hệ thống phải đảm bảo:

- Không hiển thị thông báo Free lên VIP cho người đang có VIP.
- Không hiển thị nâng VIP năm cho người đã có VIP năm.
- Không hiển thị thông báo hết lượt hỏi nếu người dùng vẫn còn lượt.
- Không hiển thị báo cáo sẵn sàng nếu báo cáo tạo thất bại.
- Không hiển thị điểm thưởng cố định nếu chương trình đã thay đổi.
- Không hiển thị mã mời nếu người dùng không có quyền mời.
- Không hiển thị Thẻ cứu chuỗi nếu người dùng không sở hữu thẻ.
- Không hiển thị thông báo sắp hết hạn sau khi người dùng gia hạn.
- Không hiển thị lại thông báo đã hoàn tất hành động.
- Không hiển thị cùng lúc bong bóng Nabi và popup thanh toán.
- Không đưa ra nội dung chẩn đoán hoặc cam kết kết quả sức khỏe.

---

# 18. Xử lý trạng thái ngoại lệ

## 18.1. Mất kết nối mạng

Nếu CTA cần Internet:

- Giữ lại thông báo.
- Hiển thị trạng thái không có kết nối.
- Không đánh dấu CTA đã hoàn thành.
- Cho phép thử lại.

Nội dung:

> Nabi chưa thể kết nối lúc này. Bạn kiểm tra mạng rồi thử lại nhé.

## 18.2. Quyền lợi chưa đồng bộ

Nếu thanh toán thành công nhưng quyền lợi chưa cập nhật:

- Hiển thị trạng thái đang xác minh.
- Không yêu cầu người dùng thanh toán lại.
- Cho phép làm mới trạng thái.

## 18.3. Chương trình khuyến mại hết hạn

- Bỏ nội dung điểm thưởng hoặc quà tặng.
- Sử dụng nội dung nâng cấp mặc định.
- Không hiển thị quyền lợi cũ từ bộ nhớ đệm.

## 18.4. Deep link không hợp lệ

- Điều hướng về trang gói cước hoặc dashboard tương ứng.
- Ghi log lỗi.
- Không làm đóng ứng dụng.

---

# 19. Dữ liệu cần quản lý

## 19.1. Cấu hình thông báo

Mỗi thông báo cần có:

- Mã thông báo.
- Tên thông báo.
- Nhóm thông báo.
- Gói mục tiêu.
- Sự kiện kích hoạt.
- Điều kiện bổ sung.
- Mức ưu tiên.
- Nội dung.
- CTA chính.
- CTA phụ.
- Đường dẫn điều hướng.
- Biểu cảm Nabi.
- Thời gian bắt đầu hiệu lực.
- Thời gian kết thúc hiệu lực.
- Cooldown.
- Số lần hiển thị tối đa.
- Trạng thái kích hoạt.

## 19.2. Trạng thái theo người dùng

Cần lưu:

- Người dùng.
- Mã thông báo.
- Thời điểm đủ điều kiện.
- Thời điểm hiển thị gần nhất.
- Tổng số lần hiển thị.
- Tổng số lần đóng.
- Tổng số lần nhấn CTA.
- Trạng thái đã đọc.
- Trạng thái đã chuyển đổi.
- Phiên bản nội dung đã hiển thị.
- Gói của người dùng tại thời điểm hiển thị.

---

# 20. Sự kiện phân tích

Hệ thống phải ghi nhận tối thiểu:

| Sự kiện | Ý nghĩa |
|---|---|
| `nabi_notification_eligible` | Người dùng đủ điều kiện nhận thông báo |
| `nabi_notification_shown` | Bong bóng Nabi đã được hiển thị |
| `nabi_notification_opened` | Người dùng mở thông báo từ nút Nabi |
| `nabi_notification_dismissed` | Người dùng đóng thông báo |
| `nabi_notification_primary_clicked` | Người dùng nhấn CTA chính |
| `nabi_notification_secondary_clicked` | Người dùng nhấn CTA phụ |
| `nabi_upgrade_page_viewed` | Người dùng đã vào trang nâng cấp |
| `nabi_checkout_started` | Người dùng bắt đầu thanh toán |
| `nabi_conversion_completed` | Người dùng mua hoặc gia hạn thành công |
| `nabi_notification_failed` | Thông báo không thể hiển thị hoặc điều hướng lỗi |

Mỗi sự kiện nên kèm:

- Notification ID.
- User ID.
- Gói hiện tại.
- Màn hình hiện tại.
- Thời gian.
- Phiên ứng dụng.
- Phiên bản ứng dụng.
- Kết quả thao tác.

---

# 21. Tiêu chí nghiệm thu

## AC-01 — Hiển thị từ Nabi

Thông báo phải xuất hiện dưới dạng bong bóng hội thoại gắn trực tiếp với hình ảnh nút nổi Nabi.

## AC-02 — Đúng đối tượng

Mỗi thông báo chỉ hiển thị cho đúng nhóm gói và trạng thái người dùng.

## AC-03 — Đúng điều kiện

Thông báo chỉ được hiển thị khi toàn bộ điều kiện kích hoạt đã được đáp ứng.

## AC-04 — Không lặp quá mức

Hệ thống tuân thủ giới hạn số lần hiển thị và thời gian cooldown.

## AC-05 — CTA đúng điều hướng

Mỗi CTA phải mở đúng màn hình hoặc chức năng được mô tả.

## AC-06 — Không mất ngữ cảnh

Sau khi nâng cấp thành công từ một tính năng bị khóa, người dùng được quay lại đúng tính năng vừa yêu cầu.

## AC-07 — Cập nhật gói ngay

Sau thanh toán thành công, toàn bộ thông báo không còn phù hợp phải ngừng hiển thị.

## AC-08 — Nội dung động

Điểm thưởng, thời hạn và quyền lợi phải lấy từ dữ liệu cấu hình hiện hành.

## AC-09 — Hoạt động khi offline

Thông báo vẫn có thể đóng hoặc mở lại; CTA cần mạng phải có xử lý thử lại.

## AC-10 — Không che nội dung

Nút nổi và bong bóng Nabi không được che nút điều hướng, ô nhập hoặc nội dung quan trọng.

## AC-11 — Có thể truy cập

Nội dung phải hỗ trợ phóng to chữ, trình đọc màn hình và độ tương phản phù hợp.

## AC-12 — Ghi nhận analytics

Mọi lần hiển thị, đóng, nhấn CTA và chuyển đổi phải được ghi nhận.

## AC-13 — Không chẩn đoán y tế

Nội dung Nabi không được kết luận bệnh, kê đơn hoặc cam kết kết quả sức khỏe.

## AC-14 — Có thông báo hỗ trợ

Hệ thống không được chỉ hiển thị thông báo bán gói; phải có thông báo động viên, báo cáo và phần thưởng xen kẽ.

## AC-15 — Không hiển thị sai quyền lợi

Một quyền lợi hết hiệu lực hoặc không tồn tại không được xuất hiện trong nội dung thông báo.

---

# 22. Kết quả nghiệp vụ mong đợi

Sau khi triển khai:

- Người dùng nhận được thông báo đúng theo hành vi.
- Người dùng hiểu lý do tính năng đang bị giới hạn.
- Việc nâng cấp không làm gián đoạn luồng đang sử dụng.
- Nabi thể hiện vai trò người đồng hành thay vì chỉ là nút chat.
- Thông báo nâng gói được cá nhân hóa theo tiến trình.
- Hệ thống có dữ liệu để đánh giá tỷ lệ mở, nhấn CTA và chuyển đổi.
- Người dùng không bị làm phiền bởi các thông báo lặp lại quá nhiều.
