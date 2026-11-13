# NABI — DANH SÁCH TASK CHỈNH SỬA ỨNG DỤNG

> **Ngày tổng hợp:** 13/11/2026  
> **Nguồn:** Ghi chú viết tay do người dùng cung cấp  
> **Phạm vi:** UI/UX và luồng Onboarding  
> **Trạng thái:** Đã triển khai và kiểm tra bằng widget test trên Flutter Linux; ảnh thiết bị chưa xác minh

## 1. Mục tiêu

- Giảm nội dung chữ thừa và điều chỉnh kích thước hình ảnh để màn hình dễ đọc hơn.
- Tối ưu trải nghiệm Onboarding: dễ hiểu, dễ thao tác, nhất quán giữa các bước.
- Rà soát nội dung của bước 5 và thiết kế phần kết thúc Onboarding theo hướng tích cực, thân thiện với người dùng.
- Giữ nguyên các logic và dữ liệu đang hoạt động tốt, trừ phần được chỉ định thay đổi.

## 2. Danh sách công việc

| ID | Khu vực | Nội dung cần sửa | Ưu tiên | Trạng thái |
|---|---|---|---|---|
| NABI-01 | UI tổng thể trong onboarding | Giảm chữ lặp và chỉ thu nhỏ minh họa khi chúng chiếm chỗ nội dung hoặc CTA. | P1 | [x] |
| NABI-02 | Onboarding | Rút gọn nội dung chữ, chỉ giữ thông tin cần thiết cho người dùng. | P1 | [x] |
| NABI-03 | Onboarding | Rà soát các điểm khó sử dụng; cải thiện hướng dẫn, bố cục và thao tác chuyển bước. | P1 | [x] |
| NABI-04 | Onboarding — bước 5/9 | Giữ ba dữ liệu ngủ, vận động, nước uống trong `LifestyleStep` (“Nhịp sống của bạn”); chỉ chỉnh copy và bố cục. | P1 | [x] |
| NABI-05 | Onboarding — nội dung | Ưu tiên mở đầu các mục bằng câu hỏi dẫn dắt ngắn gọn, rõ ràng. | P1 | [x] |
| NABI-06 | Onboarding — bước 7/9 | Bỏ heading bên trong `DailyRoutineStep`; giữ tiến độ, quay lại, Nabi và xác nhận. | P2 | [x] |
| NABI-07 | Onboarding — phần cuối | Chỉ hiện `ResultStep` sau khi lưu hồ sơ và hoàn tất onboarding thành công; lỗi/chờ duyệt giữ luồng hiện tại. Quay lại từ màn hoàn tất mở Menu. | P1 | [x] |
| NABI-08 | Onboarding — màn hình kết thúc | Dùng tiêu đề **“Bạn đã sẵn sàng đồng hành cùng Nabi chưa?”** và CTA **“Vào ứng dụng”**. | P1 | [x] |

> **Đối chiếu source:** Bước 5/9 là `LifestyleStep`; bước 7/9 là `DailyRoutineStep`. Giữ nguyên đủ 9 bước và dữ liệu đã chọn.

## 3. Yêu cầu triển khai theo nhóm

### 3.1. Giao diện và nội dung

- [x] Kiểm tra đủ 9 màn hình ở 320×640 (text scale 1.3) và 390×844; kiểm tra bàn phím mở tại phần thông tin cơ bản.
- [x] Loại bỏ phần chữ trùng lặp, dài dòng; giữ các lưu ý quyền riêng tư/y tế và dữ liệu hiện có.
- [x] Giảm minh họa mở đầu và bố cục minh họa ở nơi chúng chiếm chỗ nội dung.
- [x] Duy trì hệ thống typography, spacing, màu sắc, icon, nút CTA nhất quán.
- [x] Widget layout checks không báo tràn chữ, che nút hoặc lỗi bố cục tại hai kích thước đã kiểm tra.

### 3.2. Luồng Onboarding

- [x] Đối chiếu thứ tự và tên gọi của đủ 9 bước trong source.
- [x] Rút gọn copy và cải thiện thao tác trên các bước có nội dung dày.
- [x] Điều chỉnh các heading thành câu hỏi ngắn theo ngữ cảnh.
- [x] Rà soát bước 5/9; giữ ba mục ngủ, vận động, nước uống.
- [x] Bỏ heading nội dung ở bước 7/9, giữ thanh tiến độ, nút quay lại và CTA xác nhận.
- [x] Thêm trạng thái kết thúc sau khi hoàn tất lưu thành công; copy phụ theo trạng thái thực tế.
- [x] CTA và thao tác quay lại từ màn kết thúc mở Menu.

### 3.3. Kiểm thử và nghiệm thu

- [x] Widget test đi qua đủ 9 bước bằng CTA, quay lại/tiếp tục và giữ dữ liệu đã chọn.
- [x] Kiểm tra nút tiếp tục, quay lại, trạng thái lưu thành công, lỗi và chờ duyệt món.
- [x] Dữ liệu hồ sơ và mục tiêu vẫn được giữ khi quay lại/tiếp tục.
- [x] Không phát sinh lỗi UI khi bàn phím mở hoặc ở 320×640 và 390×844.
- [ ] Chụp ảnh trước/sau trên thiết bị Android để đối chiếu — chưa xác minh vì môi trường chỉ có Flutter Linux, không có thiết bị Android.

### Bằng chứng xác minh

- `flutter test test/widget_test.dart test/app_versions/v1/features/onboarding/onboarding_result_flow_widget_test.dart test/app_versions/v1/features/onboarding/onboarding_completion_flow_test.dart test/app_versions/v1/features/onboarding/onboarding_selection_exclusivity_test.dart test/app_versions/v1/router/v1_route_guards_test.dart` — PASS.
- `flutter analyze` trên các source/test đã sửa và `dart format --set-exit-if-changed` — PASS.
- `python3 iot/tools/generate_nabi_esp_contract.py --check` — PASS sau khi tạo output Dart bị thiếu; output `.g.dart` được ignore theo quy ước repo.
- Screenshot Android — chưa xác minh; không ghi nhận ảnh nghiệm thu.

## 4. Tiêu chí hoàn thành (Acceptance Criteria)

1. [x] Các bước mở đầu dùng câu hỏi ngắn theo ngữ cảnh và giữ thông tin cần thiết.
2. [x] Nội dung gọn hơn, hình ảnh cân đối, CTA dễ nhìn ở layout test đã chạy.
3. [x] Bước 5/9 giữ ba mục ngủ, vận động và nước uống với copy/bố cục được chỉnh.
4. [x] Chỉ bỏ heading nội dung tại `DailyRoutineStep`; thanh tiến độ và điều hướng vẫn còn.
5. [x] Màn kết thúc có tiêu đề chúc mừng và CTA **“Vào ứng dụng”**.
6. [x] Lưu lỗi và trạng thái chờ duyệt không hiển thị màn kết thúc; các widget/route tests liên quan pass.

## 5. Quy trình đề xuất cho AI Agent

1. **Khảo sát:** Đọc cấu trúc dự án, xác định source của các màn hình Onboarding, các component dùng chung và luồng điều hướng.
2. **Đối chiếu:** Map ghi chú với từng màn hình thực tế; đánh dấu điểm chưa rõ thay vì tự suy diễn.
3. **Lập kế hoạch:** Đề xuất phạm vi thay đổi theo từng task ID, file cần sửa và rủi ro.
4. **Triển khai:** Sửa UI/content từng màn hình; hạn chế chỉnh sửa logic ngoài phạm vi.
5. **Kiểm thử:** Format/analyze/test theo công cụ dự án hiện có; chạy thử luồng Onboarding.
6. **Báo cáo:** Liệt kê task hoàn thành, file thay đổi, ảnh trước/sau, kết quả test và phần còn cần xác nhận.

## 6. Các điểm đã đối chiếu khi triển khai

- **NABI-04:** Áp dụng cho `LifestyleStep` ở bước 5/9; giữ nguyên ba dữ liệu ngủ, vận động và nước uống, chỉ rút gọn copy và chỉnh bố cục.
- **NABI-06:** “7/9” là bước thứ bảy trong tổng số chín bước; bỏ heading trong nội dung, giữ thanh tiến độ, nút quay lại, Nabi và thao tác xác nhận.
- **NABI-08:** Dùng đúng tiêu đề “Bạn đã sẵn sàng đồng hành cùng Nabi chưa?” và CTA “Vào ứng dụng” theo kế hoạch đã duyệt.

---

**Quy ước:** `[ ]` chưa hoàn thành · `[x]` đã hoàn thành. Chỉ đánh dấu sau khi thay đổi đã được kiểm tra.
