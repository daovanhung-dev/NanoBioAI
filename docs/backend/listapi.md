| STT | Endpoint | Mục đích |
|---:|---|---|
| 1 | GET /health/live | Kiểm tra tiến trình API còn hoạt động. |
| 2 | GET /health/ready | Kiểm tra API và kết nối PostgreSQL sẵn sàng. |
| 3 | POST /api/v1/auth/phone-signup | Đăng ký tài khoản bằng số điện thoại. |
| 4 | POST /api/v1/auth/login | Đăng nhập bằng username, email hoặc số điện thoại và mật khẩu. |
| 5 | POST /api/v1/auth/refresh | Làm mới access token và xoay refresh token. |
| 6 | POST /api/v1/auth/change-password | Đổi mật khẩu tài khoản đang đăng nhập. |
| 7 | POST /api/v1/auth/logout | Đăng xuất và thu hồi refresh token. |
| 8 | GET /api/v1/account/me | Lấy thông tin tài khoản hiện tại. |
| 9 | DELETE /api/v1/account | Xóa tài khoản sau khi xác nhận. |
| 10 | GET /api/v1/admin/session | Lấy thông tin phiên và quyền quản trị hiện tại. |
| 11 | GET /api/v1/admin/users/search | Tìm kiếm tài khoản người dùng cho quản trị. |
| 12 | POST /api/v1/admin/accounts | Tạo tài khoản người dùng. |
| 13 | POST /api/v1/admin/memberships/grant | Cấp gói thành viên cho người dùng. |
| 14 | POST /api/v1/admin/memberships/adjust-period | Điều chỉnh thời hạn gói thành viên. |
| 15 | POST /api/v1/admin/memberships/bulk-grant | Cấp gói thành viên cho nhiều người dùng. |
| 16 | POST /api/v1/admin/accounts/bulk-provision/preview | Kiểm tra trước danh sách tạo tài khoản hàng loạt. |
| 17 | POST /api/v1/admin/accounts/bulk-provision | Tạo hàng loạt tài khoản từ danh sách đã kiểm tra. |
| 18 | GET /api/v1/admin/users/{user_id} | Xem chi tiết tài khoản người dùng. |
| 19 | PATCH /api/v1/admin/users/{user_id}/profile | Cập nhật hồ sơ người dùng. |
| 20 | PATCH /api/v1/admin/users/{user_id}/status | Cập nhật trạng thái tài khoản người dùng. |
| 21 | POST /api/v1/admin/users/{user_id}/password-reset | Đặt lại mật khẩu cho người dùng. |
| 22 | GET /api/v1/admin/audit-events | Tra cứu sự kiện kiểm toán. |
| 23 | GET /api/v1/admin/payments/review-alert | Lấy số lượng giao dịch đang chờ duyệt. |
| 24 | GET /api/v1/admin/payments | Liệt kê yêu cầu thanh toán để quản trị. |
| 25 | POST /api/v1/admin/payments/{payment_id}/review | Duyệt hoặc từ chối yêu cầu thanh toán. |
| 26 | POST /api/v1/admin/payments/{payment_id}/reversal | Ghi nhận hoàn tác giao dịch thanh toán. |
| 27 | GET /api/v1/admin/early-access/leads | Liệt kê đăng ký Early Access. |
| 28 | PATCH /api/v1/admin/early-access/leads/{lead_id} | Cập nhật trạng thái đăng ký Early Access. |
| 29 | GET /api/v1/admin/files/{bucket}/{file_id} | Tải tệp được phép truy cập trong luồng quản trị. |
| 30 | POST /api/v1/ai/generate | Tạo câu trả lời AI dạng văn bản. |
| 31 | POST /api/v1/food/scan/analyze | Phân tích ảnh món ăn bằng AI. |
| 32 | POST /api/v1/ai/generate/stream | Tạo câu trả lời AI và gửi nội dung theo luồng. |
| 33 | POST /api/v1/early-access | Gửi đăng ký tham gia Early Access. |
| 34 | POST /api/v1/ai-content-reports | Gửi báo cáo về nội dung AI. |
| 35 | POST /api/v1/food/evidence | Tra cứu bằng chứng và dữ liệu thực phẩm. |
| 36 | POST /api/v1/payments/google-play/verify | Xác minh giao dịch đăng ký qua Google Play. |
| 37 | POST /api/v1/files/{bucket} | Tải tệp lên kho lưu trữ theo bucket. |
| 38 | GET /api/v1/files/{bucket}/{file_id} | Tải tệp theo bucket và mã tệp. |
| 39 | DELETE /api/v1/files/{bucket}/{file_id} | Xóa tệp theo bucket và mã tệp. |
| 40 | GET /api/v1/sleep-safety/runtime-config | Lấy cấu hình chạy tính năng Sleep Safety. |
| 41 | GET /api/v1/sleep-safety/history | Lấy lịch sử phiên và sự kiện Sleep Safety. |
| 42 | PUT /api/v1/sleep-safety/preferences | Cập nhật tùy chọn Sleep Safety. |
| 43 | PUT /api/v1/sleep-safety/sessions/{session_id} | Đồng bộ phiên Sleep Safety. |
| 44 | PUT /api/v1/sleep-safety/events/{event_id} | Đồng bộ sự kiện của phiên Sleep Safety. |
| 45 | GET /api/v1/sleep-safety/contacts | Liệt kê liên hệ an toàn. |
| 46 | POST /api/v1/sleep-safety/contacts | Thêm liên hệ an toàn. |
| 47 | PUT /api/v1/sleep-safety/contacts/{contact_id} | Cập nhật liên hệ an toàn. |
| 48 | DELETE /api/v1/sleep-safety/contacts/{contact_id} | Xóa liên hệ an toàn. |
| 49 | POST /api/v1/sleep-safety/contacts/verification | Gửi yêu cầu xác minh liên hệ an toàn. |
| 50 | POST /api/v1/sleep-safety/dispatch | Gửi yêu cầu điều phối cảnh báo Sleep Safety. |
| 51 | POST /api/v1/webhooks/sleep-safety/{provider} | Nhận webhook từ nhà cung cấp Sleep Safety. |
| 52 | GET /api/v1/profile/me | Lấy hồ sơ cá nhân. |
| 53 | PATCH /api/v1/profile/me | Cập nhật hồ sơ cá nhân. |
| 54 | GET /api/v1/membership/me | Lấy trạng thái gói thành viên hiện tại. |
| 55 | GET /api/v1/cloud-sync/snapshot | Lấy snapshot dữ liệu đồng bộ của người dùng. |
| 56 | PUT /api/v1/cloud-sync/snapshot | Ghi hoặc cập nhật snapshot dữ liệu đồng bộ. |
| 57 | POST /api/v1/payments/membership-requests | Tạo yêu cầu thanh toán gói thành viên. |
| 58 | GET /api/v1/payments/membership-requests/me | Liệt kê yêu cầu thanh toán của người dùng hiện tại. |
| 59 | POST /api/v1/payments/membership-requests/{payment_id}/confirm | Xác nhận yêu cầu thanh toán. |
| 60 | POST /api/v1/payments/membership-requests/{payment_id}/cancel | Hủy yêu cầu thanh toán. |
| 61 | GET /api/v1/family-plus/context | Lấy thông tin nhóm FamilyPlus và quyền lợi hiện tại. |
| 62 | PUT /api/v1/family-plus/group | Tạo hoặc cập nhật nhóm FamilyPlus. |
| 63 | PUT /api/v1/family-plus/members | Cập nhật thành viên nhóm FamilyPlus. |
| 64 | DELETE /api/v1/family-plus/members/{member_id} | Xóa thành viên khỏi nhóm FamilyPlus. |
| 65 | POST /api/v1/usage-quota/check | Kiểm tra hạn mức sử dụng. |
| 66 | POST /api/v1/usage-quota/commit | Ghi nhận lượt sử dụng vào hạn mức. |
| 67 | GET /api/v1/sale/me | Lấy hồ sơ Sale của người dùng hiện tại. |
| 68 | POST /api/v1/sale/participation | Đăng ký tham gia chương trình Sale. |
| 69 | POST /api/v1/sale/referrals/attach | Gắn mã giới thiệu vào tài khoản. |
| 70 | GET /api/v1/sale/payout-profile | Lấy hồ sơ nhận thanh toán Sale. |
| 71 | PUT /api/v1/sale/payout-profile | Tạo hoặc cập nhật hồ sơ nhận thanh toán Sale. |
| 72 | GET /api/v1/sale/dashboard | Lấy số liệu tổng quan hoạt động Sale. |
| 73 | GET /api/v1/sale/customers | Liệt kê khách hàng được giới thiệu. |
| 74 | GET /api/v1/sale/point-ledger | Lấy sổ giao dịch điểm Sale. |
| 75 | GET /api/v1/sale/conversions | Liệt kê chuyển đổi Sale. |
| 76 | POST /api/v1/sale/conversions | Tạo yêu cầu chuyển đổi Sale. |
| 77 | GET /api/v1/wellness/rewards/summary | Lấy tổng quan điểm thưởng sức khỏe. |
| 78 | GET /api/v1/wellness/rewards/history | Lấy lịch sử điểm thưởng sức khỏe. |
| 79 | GET /api/v1/wellness/rewards/offers | Liệt kê phần thưởng có thể đổi. |
| 80 | GET /api/v1/wellness/rewards/redemptions | Liệt kê yêu cầu đổi thưởng. |
| 81 | POST /api/v1/wellness/rewards/redemptions | Tạo yêu cầu đổi thưởng. |
| 82 | GET /api/v1/wellness/rewards/redemptions/{redemption_id}/code | Lấy mã xác nhận đổi thưởng. |
| 83 | GET /api/v1/wellness/rank/summary | Lấy tổng quan thứ hạng sức khỏe. |
| 84 | GET /api/v1/admin/dashboard | Lấy các chỉ số tổng quan quản trị. |
| 85 | GET /api/v1/admin/business/{section} | Liệt kê dữ liệu của một phân hệ quản trị kinh doanh. |
| 86 | POST /api/v1/admin/business/{section} | Thực hiện thao tác quản trị trên một phân hệ kinh doanh. |
| 87 | POST /api/v1/schedule-rewards/eligibilities | Kiểm tra điều kiện nhận thưởng lịch trình. |
| 88 | POST /api/v1/schedule-rewards/completions/begin | Bắt đầu ghi nhận hoàn thành hoạt động lịch trình. |
| 89 | POST /api/v1/schedule-rewards/completions/{attempt_id}/proof | Tải minh chứng hoàn thành hoạt động lên. |
| 90 | GET /api/v1/schedule-rewards/completions/{attempt_id}/proof | Tải minh chứng hoàn thành của người dùng. |
| 91 | GET /api/v1/schedule-rewards/completions/{attempt_id}/proof/admin | Tải minh chứng hoàn thành theo quyền quản trị. |
| 92 | POST /api/v1/schedule-rewards/completions/{attempt_id}/finalize | Chốt kết quả hoàn thành và xử lý điểm thưởng. |
| 93 | POST /api/v1/schedule-rewards/completions/undo | Hủy ghi nhận hoàn thành hoạt động lịch trình. |
| 94 | POST /api/v1/schedule-rewards/health-checkins | Ghi nhận check-in sức khỏe. |
| 95 | POST /api/v1/schedule-rewards/health-checkins/undo | Hủy check-in sức khỏe đã ghi nhận. |
