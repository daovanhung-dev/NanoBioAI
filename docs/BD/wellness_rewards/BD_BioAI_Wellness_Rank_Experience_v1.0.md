Commit de xuat: docs(bd): bo sung dac ta hang EXP ca nhan

# BD BioAI — Hạng cá nhân theo EXP nhiệm vụ v1.0

| Thuộc tính | Giá trị |
|---|---|
| Mã BD | BD-BIOAI-WELLNESS-RANK-EXPERIENCE-001 |
| Phiên bản | 1.0 |
| Trạng thái | Được chấp thuận cho triển khai theo yêu cầu người dùng ngày 2026-10-15 |
| Phạm vi | Hạng cá nhân từ nhiệm vụ lịch trình được máy chủ xác nhận |
| Tài liệu nền | `BD_BioAI_Daily_Proof_Wellness_Rewards_v1.1.md`; M03 Dashboard/Schedule; M08 Health Score/Habits |

## Quy tắc nghiệp vụ

- Một nhiệm vụ lịch trình chỉ được máy chủ xác nhận mới cộng 10 EXP.
- Mỗi tài khoản bắt đầu một chu kỳ khi có EXP lần đầu. Cứ đủ 7 ngày, máy chủ trừ 100 EXP, sàn bằng 0. Các kỳ quá hạn được áp dụng tuần tự một lần khi phát sinh sự kiện máy chủ hoặc đọc tóm tắt hạng.
- Hạng được tính theo EXP hiện có và có thể giảm khi EXP giảm.
- Ngưỡng cố định: hạng 1 `Mầm An Nhiên` từ 0; hạng 2 `Người Ươm Nếp Lành` từ 600; hạng 3 `Người Gìn Giữ Nhịp Sống` từ 1.200; hạng 4 `Hộ Vệ Sức Sống` từ 2.600; hạng 5 `Tinh Tú Hộ Mệnh` từ 5.200.
- Undo nhiệm vụ thu hồi tối đa 10 EXP của lần hoàn thành đó. Xử lý lặp không thay đổi kết quả lần đầu.
- Các nhiệm vụ thuộc mọi chủ thể của tài khoản FamilyPlus được cộng vào cùng hạng cá nhân của tài khoản thao tác.
- EXP độc lập với Health Score, Điểm chăm sóc, điểm đổi quà và Điểm Sale. Chi tiêu một loại điểm không thay đổi EXP.
- Thứ hạng chỉ là thành tích cá nhân; phiên bản này không có bảng xếp hạng và chưa dùng hạng để lọc quà.

## Mốc khi hoàn thành đủ lịch chuẩn

Lịch chuẩn hiện có 10 nhiệm vụ mỗi ngày. Mỗi tuần hoàn thành đủ đem lại 700 EXP trước khi trừ 100 EXP. Theo các mốc đã duyệt, sau 7, 14, 30 và 60 ngày chăm chỉ liên tục, EXP sau điều chỉnh lần lượt đạt 600, 1.200, 2.600 và 5.200. Nhiệm vụ phát sinh như ngủ trưa vẫn cộng 10 EXP và có thể rút ngắn thời gian đạt mốc.

## Trình bày và dữ liệu

Thẻ hạng xuất hiện trên Dashboard và Settings, gồm danh hiệu, EXP hiện có, tiến độ đến hạng sau và thời điểm điều chỉnh tiếp theo. Khách được mời đăng nhập. Khi ngoại tuyến, ứng dụng chỉ hiển thị snapshot đã đồng bộ gần nhất và thời điểm đồng bộ, không tự ước tính EXP.

Mã ổn định `wellness_rank_1` đến `wellness_rank_5` dành cho phân loại quà trong giai đoạn sau. Hạng cao hơn sẽ thừa hưởng quà đặt ngưỡng hạng thấp hơn khi catalog triển khai điều kiện tối thiểu.
