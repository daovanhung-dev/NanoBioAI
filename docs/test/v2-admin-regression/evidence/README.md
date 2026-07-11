# Evidence notes - v2 + Admin regression

Thư mục này chỉ chứa note được sinh cho case canonical trong
`001-test-v2-admin-regression.md`.

- Không đổi case sang `PASS` nếu thiếu `assets/<CASE-ID>-pass.png`, command ID,
  BD/DD reference, actual result và xác nhận artifact đã che dữ liệu.
- Ảnh legacy hiện có trong `assets/` chỉ là tham khảo và không được gắn vào
  note PASS mới.
- Dùng `tools/regression/New-RegressionEvidence.ps1` để tạo/cập nhật note và
  `tools/regression/Test-RegressionEvidence.ps1` để kiểm tra tính nhất quán.
- Run manifest đã được rút gọn nằm trong `evidence/runs/`; không lưu console
  log thô, credential, raw AI payload, PII hoặc dữ liệu sức khỏe nhạy cảm.
