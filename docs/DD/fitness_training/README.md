# DD — Chế độ luyện tập

| Thuộc tính | Giá trị |
|---|---|
| Module Code | M32 FITNESS_TRAINING |
| Version | v1.0 |
| Lifecycle | Current |
| DD Decision | Draft |
| Implementation | In Progress (PO-directed pilot; not release-approved) |
| Verification | 28 M32/FeatureHub Flutter tests, 16 M05 sync tests, 12 Edge tests, targeted analyze and Android debug/release builds passed; real-device and Supabase sandbox unverified |
| Owner | M32 implementation; Tech, Privacy, Clinical and QA sign-off pending |
| Created / Updated | 2026-10-01 / 2026-10-05 |
| Source BD | [BD M32](../../BD/fitness_training/BD_NanoBio_Fitness_Training_M32_v1.0.md) |

## Mục đích

Định nghĩa chế độ tập Gym-first cho người trưởng thành, bao gồm catalog nội dung, chương trình 4 tuần, lịch 7 ngày, AI Gemini, quota, an toàn, quyền riêng tư và đồng bộ. PO đã chỉ đạo triển khai pilot ngày 2026-10-05 dù chưa có reviewer sign-off; DD vẫn Draft và chưa được duyệt phát hành.

## Tài liệu

- [Overall](./Overall.md)
- [Feature List](./List_Features.md)
- [Function List](./Function_List.md)
- [Views](./Views.md)
- [Import/File Map](./Import_File.md)
- [Diagrams](./diagrams/README.md)
- [Assets](./assets/README.md)
- [Cross-functional review packet](./Review_Packet.md)
- [Changelog](./history/CHANGELOG.md)

## Dependencies

M01 onboarding, M02 personal schedule AI, M03 schedule, M04 body metrics, M05 profile sync, M06 quota/entitlement, M09 notifications, M11 FamilyPlus, M19 audit/privacy, Gemini Edge Function và YouTube IFrame Player API.

## Approval Status

| Vai trò | Approver | Status | Date |
|---|---|---|---|
| PO | Người dùng trong phiên (tự xác nhận vai trò PO; tên hiển thị không được cung cấp) | Approved — BD/DD v1.0; hướng xác minh tuổi/lưu trữ/wellness/nền tảng-video được xác nhận bổ sung | 2026-10-01, 2026-10-05 |
| Tech Lead | Chưa ghi nhận | Pending | — |
| QA Lead | Chưa ghi nhận | Pending | — |
| Privacy | Chưa ghi nhận | Pending | — |
| Clinical | Chưa ghi nhận | Pending | — |

Runtime exception: theo chỉ đạo PO ngày 2026-10-05, coding pilot tiếp tục mà không chờ review packet. Không điền thay hoặc đánh dấu hoàn tất các sign-off Tech/Privacy, Clinical hay QA. Không công bố hoặc xem M32 là release-ready cho tới khi các reviewer hoàn tất và ghi bằng chứng.
