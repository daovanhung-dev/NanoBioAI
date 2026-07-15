Commit de xuat: test(real-device): kiem thu toan bo NanoBio 15-07-2026

# Kiểm thử toàn bộ NanoBio trên điện thoại thật — 15/07/2026

## Trạng thái chiến dịch

- Kết luận: CHƯA HOÀN TẤT.
- Tổng case kế thừa và bắt buộc chạy lại: 114.
- PASS: 2; FAIL: 0; BLOCKED: 0; PENDING: 112.
- Không tái sử dụng ảnh hoặc trạng thái PASS từ chiến dịch cũ.

## Thiết bị và môi trường

- Thiết bị: Xiaomi 220333QPG (`12b304f9`).
- Android: 11/API 30.
- Độ phân giải vật lý: 720x1650.
- Supabase: cấu hình có trong `assets/config/auth.env`; không ghi giá trị vào báo cáo.
- AI: BLOCKED ở preflight vì `GEMINI_API_KEY` là placeholder.

## Baseline kỹ thuật

- `flutter analyze`: PASS — không có issue.
- Full test lần 1: FAIL — 679 PASS, 8 FAIL.
- Full test lần 2 để lọc failure: FAIL — 678 PASS, 9 FAIL; có thêm failure flaky ở idempotency key.
- Device `flutter drive` PRE-02: TIMEOUT sau 304 giây.
- APK debug build/install trực tiếp: PASS; PRE-02 PASS sau khi thiết bị ổn định và ảnh được kiểm tra trực quan.
- Frame đen ban đầu được phân loại INCONCLUSIVE do thiết bị lag, không phải bug màn hình.

## Nguyên tắc bằng chứng

- Mỗi case chỉ được đổi trạng thái sau khi có ảnh mới từ đúng điện thoại thật.
- Log/test tự động chỉ là bằng chứng bổ trợ.
- Bug chỉ được đánh dấu đã fix sau ảnh FAIL, patch, regression test, retest thiết bị và ảnh PASS.

## Ma trận

| Case | Hồ sơ | Trạng thái |
| --- | --- | --- |
| PRE-01 | [cases/PRE-01.md](cases/PRE-01.md) | PASS |
| PRE-02 | [cases/PRE-02.md](cases/PRE-02.md) | PASS |
| PRE-03 | [cases/PRE-03.md](cases/PRE-03.md) | PENDING |
| PRE-04 | [cases/PRE-04.md](cases/PRE-04.md) | PENDING |
| PRE-05 | [cases/PRE-05.md](cases/PRE-05.md) | PENDING |
| PRE-06 | [cases/PRE-06.md](cases/PRE-06.md) | PENDING |
| V2-M01-01 | [cases/V2-M01-01.md](cases/V2-M01-01.md) | PENDING |
| V2-M01-02 | [cases/V2-M01-02.md](cases/V2-M01-02.md) | PENDING |
| V2-M01-03 | [cases/V2-M01-03.md](cases/V2-M01-03.md) | PENDING |
| V2-M01-04 | [cases/V2-M01-04.md](cases/V2-M01-04.md) | PENDING |
| V2-M01-05 | [cases/V2-M01-05.md](cases/V2-M01-05.md) | PENDING |
| V2-M02-01 | [cases/V2-M02-01.md](cases/V2-M02-01.md) | PENDING |
| V2-M02-02 | [cases/V2-M02-02.md](cases/V2-M02-02.md) | PENDING |
| V2-M02-03 | [cases/V2-M02-03.md](cases/V2-M02-03.md) | PENDING |
| V2-M02-04 | [cases/V2-M02-04.md](cases/V2-M02-04.md) | PENDING |
| V2-M02-05 | [cases/V2-M02-05.md](cases/V2-M02-05.md) | PENDING |
| V2-M02-06 | [cases/V2-M02-06.md](cases/V2-M02-06.md) | PENDING |
| V2-M03-01 | [cases/V2-M03-01.md](cases/V2-M03-01.md) | PENDING |
| V2-M03-02 | [cases/V2-M03-02.md](cases/V2-M03-02.md) | PENDING |
| V2-M03-03 | [cases/V2-M03-03.md](cases/V2-M03-03.md) | PENDING |
| V2-M03-04 | [cases/V2-M03-04.md](cases/V2-M03-04.md) | PENDING |
| V2-M03-05 | [cases/V2-M03-05.md](cases/V2-M03-05.md) | PENDING |
| V2-M04-01 | [cases/V2-M04-01.md](cases/V2-M04-01.md) | PENDING |
| V2-M04-02 | [cases/V2-M04-02.md](cases/V2-M04-02.md) | PENDING |
| V2-M04-03 | [cases/V2-M04-03.md](cases/V2-M04-03.md) | PENDING |
| V2-M04-04 | [cases/V2-M04-04.md](cases/V2-M04-04.md) | PENDING |
| V2-M05-01 | [cases/V2-M05-01.md](cases/V2-M05-01.md) | PENDING |
| V2-M05-02 | [cases/V2-M05-02.md](cases/V2-M05-02.md) | PENDING |
| V2-M05-03 | [cases/V2-M05-03.md](cases/V2-M05-03.md) | PENDING |
| V2-M05-04 | [cases/V2-M05-04.md](cases/V2-M05-04.md) | PENDING |
| V2-M05-05 | [cases/V2-M05-05.md](cases/V2-M05-05.md) | PENDING |
| V2-M05-06 | [cases/V2-M05-06.md](cases/V2-M05-06.md) | PENDING |
| V2-M06-01 | [cases/V2-M06-01.md](cases/V2-M06-01.md) | PENDING |
| V2-M06-02 | [cases/V2-M06-02.md](cases/V2-M06-02.md) | PENDING |
| V2-M06-03 | [cases/V2-M06-03.md](cases/V2-M06-03.md) | PENDING |
| V2-M06-04 | [cases/V2-M06-04.md](cases/V2-M06-04.md) | PENDING |
| V2-M06-05 | [cases/V2-M06-05.md](cases/V2-M06-05.md) | PENDING |
| V2-M06-06 | [cases/V2-M06-06.md](cases/V2-M06-06.md) | PENDING |
| V2-M07-01 | [cases/V2-M07-01.md](cases/V2-M07-01.md) | PENDING |
| V2-M07-02 | [cases/V2-M07-02.md](cases/V2-M07-02.md) | PENDING |
| V2-M07-03 | [cases/V2-M07-03.md](cases/V2-M07-03.md) | PENDING |
| V2-M07-04 | [cases/V2-M07-04.md](cases/V2-M07-04.md) | PENDING |
| V2-M07-05 | [cases/V2-M07-05.md](cases/V2-M07-05.md) | PENDING |
| V2-M08-01 | [cases/V2-M08-01.md](cases/V2-M08-01.md) | PENDING |
| V2-M08-02 | [cases/V2-M08-02.md](cases/V2-M08-02.md) | PENDING |
| V2-M08-03 | [cases/V2-M08-03.md](cases/V2-M08-03.md) | PENDING |
| V2-M08-04 | [cases/V2-M08-04.md](cases/V2-M08-04.md) | PENDING |
| V2-M08-05 | [cases/V2-M08-05.md](cases/V2-M08-05.md) | PENDING |
| V2-M09-01 | [cases/V2-M09-01.md](cases/V2-M09-01.md) | PENDING |
| V2-M09-02 | [cases/V2-M09-02.md](cases/V2-M09-02.md) | PENDING |
| V2-M09-03 | [cases/V2-M09-03.md](cases/V2-M09-03.md) | PENDING |
| V2-M09-04 | [cases/V2-M09-04.md](cases/V2-M09-04.md) | PENDING |
| V2-M09-05 | [cases/V2-M09-05.md](cases/V2-M09-05.md) | PENDING |
| V2-M12-01 | [cases/V2-M12-01.md](cases/V2-M12-01.md) | PENDING |
| V2-M12-02 | [cases/V2-M12-02.md](cases/V2-M12-02.md) | PENDING |
| V2-M12-03 | [cases/V2-M12-03.md](cases/V2-M12-03.md) | PENDING |
| V2-M12-04 | [cases/V2-M12-04.md](cases/V2-M12-04.md) | PENDING |
| V2-M12-05 | [cases/V2-M12-05.md](cases/V2-M12-05.md) | PENDING |
| V2-M12-06 | [cases/V2-M12-06.md](cases/V2-M12-06.md) | PENDING |
| V2-M13-01 | [cases/V2-M13-01.md](cases/V2-M13-01.md) | PENDING |
| V2-M13-02 | [cases/V2-M13-02.md](cases/V2-M13-02.md) | PENDING |
| V2-M13-03 | [cases/V2-M13-03.md](cases/V2-M13-03.md) | PENDING |
| V2-M13-04 | [cases/V2-M13-04.md](cases/V2-M13-04.md) | PENDING |
| V2-M13-05 | [cases/V2-M13-05.md](cases/V2-M13-05.md) | PENDING |
| V2-M13-06 | [cases/V2-M13-06.md](cases/V2-M13-06.md) | PENDING |
| V2-M14-01 | [cases/V2-M14-01.md](cases/V2-M14-01.md) | PENDING |
| V2-M14-02 | [cases/V2-M14-02.md](cases/V2-M14-02.md) | PENDING |
| V2-M14-03 | [cases/V2-M14-03.md](cases/V2-M14-03.md) | PENDING |
| V2-M14-04 | [cases/V2-M14-04.md](cases/V2-M14-04.md) | PENDING |
| V2-M14-05 | [cases/V2-M14-05.md](cases/V2-M14-05.md) | PENDING |
| V2-M14-06 | [cases/V2-M14-06.md](cases/V2-M14-06.md) | PENDING |
| V2-M14-07 | [cases/V2-M14-07.md](cases/V2-M14-07.md) | PENDING |
| ADM-AUTH-01 | [cases/ADM-AUTH-01.md](cases/ADM-AUTH-01.md) | PENDING |
| ADM-AUTH-02 | [cases/ADM-AUTH-02.md](cases/ADM-AUTH-02.md) | PENDING |
| ADM-AUTH-03 | [cases/ADM-AUTH-03.md](cases/ADM-AUTH-03.md) | PENDING |
| ADM-M15-01 | [cases/ADM-M15-01.md](cases/ADM-M15-01.md) | PENDING |
| ADM-M15-02 | [cases/ADM-M15-02.md](cases/ADM-M15-02.md) | PENDING |
| ADM-M15-03 | [cases/ADM-M15-03.md](cases/ADM-M15-03.md) | PENDING |
| ADM-M15-04 | [cases/ADM-M15-04.md](cases/ADM-M15-04.md) | PENDING |
| ADM-M16A-01 | [cases/ADM-M16A-01.md](cases/ADM-M16A-01.md) | PENDING |
| ADM-M16A-02 | [cases/ADM-M16A-02.md](cases/ADM-M16A-02.md) | PENDING |
| ADM-M16B-01 | [cases/ADM-M16B-01.md](cases/ADM-M16B-01.md) | PENDING |
| ADM-M16B-02 | [cases/ADM-M16B-02.md](cases/ADM-M16B-02.md) | PENDING |
| ADM-M16C-01 | [cases/ADM-M16C-01.md](cases/ADM-M16C-01.md) | PENDING |
| ADM-M16C-02 | [cases/ADM-M16C-02.md](cases/ADM-M16C-02.md) | PENDING |
| ADM-M16D-01 | [cases/ADM-M16D-01.md](cases/ADM-M16D-01.md) | PENDING |
| ADM-M16D-02 | [cases/ADM-M16D-02.md](cases/ADM-M16D-02.md) | PENDING |
| ADM-M16E-01 | [cases/ADM-M16E-01.md](cases/ADM-M16E-01.md) | PENDING |
| ADM-M16E-02 | [cases/ADM-M16E-02.md](cases/ADM-M16E-02.md) | PENDING |
| ADM-M17-01 | [cases/ADM-M17-01.md](cases/ADM-M17-01.md) | PENDING |
| ADM-M17-02 | [cases/ADM-M17-02.md](cases/ADM-M17-02.md) | PENDING |
| ADM-M17-03 | [cases/ADM-M17-03.md](cases/ADM-M17-03.md) | PENDING |
| ADM-M17-04 | [cases/ADM-M17-04.md](cases/ADM-M17-04.md) | PENDING |
| ADM-M17-05 | [cases/ADM-M17-05.md](cases/ADM-M17-05.md) | PENDING |
| ADM-M18-01 | [cases/ADM-M18-01.md](cases/ADM-M18-01.md) | PENDING |
| ADM-M18-02 | [cases/ADM-M18-02.md](cases/ADM-M18-02.md) | PENDING |
| ADM-M18-03 | [cases/ADM-M18-03.md](cases/ADM-M18-03.md) | PENDING |
| ADM-M18-04 | [cases/ADM-M18-04.md](cases/ADM-M18-04.md) | PENDING |
| ADM-M18-05 | [cases/ADM-M18-05.md](cases/ADM-M18-05.md) | PENDING |
| ADM-M19-01 | [cases/ADM-M19-01.md](cases/ADM-M19-01.md) | PENDING |
| ADM-M19-02 | [cases/ADM-M19-02.md](cases/ADM-M19-02.md) | PENDING |
| ADM-M19-03 | [cases/ADM-M19-03.md](cases/ADM-M19-03.md) | PENDING |
| ADM-M19-04 | [cases/ADM-M19-04.md](cases/ADM-M19-04.md) | PENDING |
| ADM-M19-05 | [cases/ADM-M19-05.md](cases/ADM-M19-05.md) | PENDING |
| AUT-M10-01 | [cases/AUT-M10-01.md](cases/AUT-M10-01.md) | PENDING |
| AUT-M10-02 | [cases/AUT-M10-02.md](cases/AUT-M10-02.md) | PENDING |
| AUT-M10-03 | [cases/AUT-M10-03.md](cases/AUT-M10-03.md) | PENDING |
| AUT-M10-04 | [cases/AUT-M10-04.md](cases/AUT-M10-04.md) | PENDING |
| AUT-M10-05 | [cases/AUT-M10-05.md](cases/AUT-M10-05.md) | PENDING |
| AUT-M11-01 | [cases/AUT-M11-01.md](cases/AUT-M11-01.md) | PENDING |
| AUT-M11-02 | [cases/AUT-M11-02.md](cases/AUT-M11-02.md) | PENDING |
| AUT-M11-03 | [cases/AUT-M11-03.md](cases/AUT-M11-03.md) | PENDING |
| AUT-M11-04 | [cases/AUT-M11-04.md](cases/AUT-M11-04.md) | PENDING |
| AUT-M11-05 | [cases/AUT-M11-05.md](cases/AUT-M11-05.md) | PENDING |
