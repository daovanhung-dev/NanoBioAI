Commit de xuat: docs(bd): chot nhiem vu co bang chung va Diem cham soc

# BD — Nhiệm vụ hằng ngày, bằng chứng, Điểm chăm sóc và voucher

| Thuộc tính | Giá trị |
|---|---|
| Mã tài liệu | `BD-BIOAI-WELLNESS-REWARDS-001` |
| Phiên bản | v1.0 |
| Trạng thái | Approved — user decision 2026-07-13 |
| Phạm vi module | M03, M08 (ranh giới hệ điểm), M09, M15, M16 |
| Nguồn | Kế hoạch triển khai được người dùng chốt ngày 2026-07-13 |
| Múi giờ nghiệp vụ | `Asia/Ho_Chi_Minh` |

## 1. Mục tiêu và ranh giới

Đợt thay đổi này chuẩn hóa việc hoàn thành nhiệm vụ hằng ngày bằng ảnh chụp
trực tiếp, tạo hệ `Điểm chăm sóc` có thể đổi voucher và bổ sung khu quản trị
riêng. `Điểm chăm sóc` là hệ điểm thứ ba, độc lập hoàn toàn với Điểm sức khỏe
và Điểm Sale.

Trong phạm vi:

- Cửa sổ thực hiện nhiệm vụ, bằng chứng ảnh và hoàn tác.
- Eligibility do máy chủ cấp, hoàn thành online có kiểm chứng và cộng điểm.
- Ví Điểm chăm sóc, lịch sử, hết hạn và quy tắc tiêu điểm.
- Catalog ưu đãi, kho mã dùng một lần, đổi voucher và hủy giao dịch.
- Quyền và giao diện Quản trị viên cho chương trình.
- Việt hóa mọi bề mặt production do NanoBio kiểm soát.

Ngoài phạm vi:

- Tích hợp API nhà cung cấp voucher.
- Xuất ảnh bằng chứng ra thư viện ảnh công khai.
- Gộp ví giữa các thành viên FamilyPlus.
- Guest hoặc thao tác offline nhận điểm có thể đổi voucher.

## 2. Quy tắc nhiệm vụ và bằng chứng

| ID | Quy tắc đã chốt |
|---|---|
| WR-BR-001 | Một mốc chỉ thao tác trong cửa sổ đóng `[start_time, start_time + 30 phút]` theo `Asia/Ho_Chi_Minh`. Trước giờ là `Chưa mở`; đúng phút 30 vẫn hợp lệ và chỉ khóa sau mốc đó. |
| WR-BR-002 | Parser chấp nhận `HH:mm`, `HH:mm:ss` và phần giây. Giá trị ngày/giờ không hợp lệ phải khóa an toàn, không được mở nhầm nhiệm vụ. |
| WR-BR-003 | Có thể xem ngày tương lai nhưng không được thao tác. Trạng thái phải tự làm mới ở mốc mở, mốc khóa và khi ứng dụng resume. |
| WR-BR-004 | Hoàn thành bắt buộc chụp trực tiếp từ camera. Hủy camera, từ chối quyền hoặc lỗi xử lý ảnh không thay đổi nhiệm vụ. |
| WR-BR-005 | Ảnh tối đa 5 MB, được chuẩn hóa JPEG, hướng xoay và loại metadata vị trí trước khi lưu hoặc tải lên. |
| WR-BR-006 | Ảnh local nằm trong thư mục app-private `schedule_proofs`; cơ sở dữ liệu chỉ lưu đường dẫn tương đối và metadata sidecar để cloud pull không làm mất liên kết. |
| WR-BR-007 | Ứng dụng có khu `Bằng chứng nhiệm vụ` và trang xem tất cả, gồm thumbnail, thời gian, nhiệm vụ, trạng thái `Đang hiệu lực`, `Đã hoàn tác` hoặc `Không nhận điểm`, xem toàn màn hình và tải lại cloud khi local thiếu. |
| WR-BR-008 | Hoàn tác được phép đến hết `window_end`. Ảnh được giữ với nhãn `Đã hoàn tác`; khoản `+10` đang chờ bị đảo. Sau `window_end` không được hoàn tác. |
| WR-BR-009 | Notification không hoàn thành nền. Hành động là `Mở để chụp ảnh` và deep-link đúng nhiệm vụ vào use case hoàn thành dùng chung. |

## 3. Eligibility, xác nhận online và Điểm chăm sóc

| ID | Quy tắc đã chốt |
|---|---|
| WR-BR-010 | Khi lịch Member được kích hoạt, máy chủ cấp eligibility bất biến cho request/quota hợp lệ, ngày tương lai, không trùng và đúng cấu trúc 10 mốc/ngày. Chỉ eligibility này được thưởng. |
| WR-BR-011 | Luồng online là `begin` → mở camera → lưu local → upload private → `finalize`. Máy chủ dùng thời gian của mình, khóa eligibility và xác nhận proof/completion/`+10` trong transaction idempotent. |
| WR-BR-012 | Nếu object được Storage ghi trước hạn nhưng `finalize` mất response, reconciler được hoàn tất sau hạn theo `storage.objects.created_at`. Upload đến máy chủ sau hạn không được thưởng. |
| WR-BR-013 | Guest hoặc người dùng offline vẫn được hoàn thành và giữ ảnh local nhưng không nhận điểm đổi voucher; UI phải cảnh báo trước. Sau đăng nhập chỉ nhiệm vụ Guest chưa đến giờ mới có thể được đăng ký eligibility. |
| WR-BR-014 | Mỗi eligibility hợp lệ tạo đúng một khoản `+10 Điểm chăm sóc`. Khoản này khả dụng sau `window_end` và hết hạn tại `window_end + 180 ngày` theo cấu hình version hóa. |
| WR-BR-015 | Thay đổi thời hạn chỉ áp dụng cho khoản phát sinh sau phiên bản cấu hình mới; không hồi tố. Điểm được tiêu theo khoản sắp hết hạn trước. |
| WR-BR-016 | Không có trần điểm theo ngày ngoài số eligibility hợp lệ. Một eligibility không được thưởng hai lần dù double tap, retry hoặc hai thiết bị. |
| WR-BR-017 | Dữ liệu legacy `+1/-1` được hiển thị thành `+10/-10` có nhãn lịch sử nhưng không tham gia số dư đổi voucher. |
| WR-BR-018 | Ví thuộc từng tài khoản, không gộp FamilyPlus. `Điểm chăm sóc`, Điểm sức khỏe và Điểm Sale dùng ledger, số dư, UI và mục đích khác nhau. |

## 4. Voucher và giao dịch đổi điểm

| ID | Quy tắc đã chốt |
|---|---|
| WR-BR-019 | Trang `Ưu đãi` hiển thị điểm đang chờ, khả dụng, sắp hết hạn, catalog, lịch sử điểm, lịch sử đổi và `Voucher của tôi`. |
| WR-BR-020 | Đổi voucher chỉ thực hiện online và nguyên tử: khóa ví, chọn một mã còn tồn, tiêu các allocation sắp hết hạn trước, trừ điểm và cấp mã trong cùng transaction. Thiếu điểm, hết kho hoặc conflict không được trừ điểm. |
| WR-BR-021 | Mã voucher dùng một lần được hiển thị dạng chữ và QR. Mã đã cấp được lưu trong secure storage của hệ điều hành để xem lại; cache SQLite không lưu mã rõ. |
| WR-BR-022 | Catalog có tiêu đề/mô tả tiếng Việt có dấu, nhà cung cấp, giá điểm, cửa sổ mở, hạn voucher và gói `Free`, `Plus`, `FamilyPlus` được phép. Mặc định mọi tài khoản đăng nhập đủ điều kiện. |
| WR-BR-023 | Không giới hạn số lần đổi theo tài khoản; giới hạn chỉ đến từ điểm khả dụng, eligibility của ưu đãi và tồn kho. |
| WR-BR-024 | Mã chưa cấp không được trả qua API/UI. Mã trùng hoặc sai định dạng bị từ chối và kết quả nhập phải có thống kê. |
| WR-BR-025 | Trạng thái giao dịch chỉ là `Đã cấp` hoặc `Đã hủy`; hệ thống không tự nhận là `Đã sử dụng`. |
| WR-BR-026 | Hủy giao dịch cần lý do, xác nhận mã đã được xử lý bên ngoài, idempotency và audit. Mã bị loại vĩnh viễn; điểm được hoàn đúng một lần thành allocation mới theo chính sách hiện hành. |

## 5. Quản trị, bảo mật và dữ liệu

| ID | Quy tắc đã chốt |
|---|---|
| WR-BR-027 | Khu quản trị dùng quyền riêng `wellness_rewards.read` và `wellness_rewards.write`; UI ẩn/khóa đúng quyền nhưng backend vẫn là lớp quyết định. |
| WR-BR-028 | Client không được DML trực tiếp ledger/kho mã. Ledger là append-only, server-owned; điểm không được push/delete qua snapshot giả. |
| WR-BR-029 | Bucket `schedule-completion-proofs` là private; path `<owner>/<eligibility>/<attempt>.jpg`, `upsert:false`; owner chỉ đọc/upload đúng path, không có quyền client update/delete. Ảnh giữ đến khi xóa tài khoản. |
| WR-BR-030 | Mọi RPC dùng `auth.uid()`, `search_path` cố định, idempotency key, row lock khi cần, stable error code và audit cho thao tác nhạy cảm. |

### RPC người dùng

- `register_my_schedule_reward_eligibilities`
- `begin_my_schedule_completion`
- `finalize_my_schedule_completion`
- `undo_my_schedule_completion`
- `get_my_wellness_reward_summary`
- `list_my_wellness_point_history`
- `list_my_reward_offers`
- `redeem_my_reward_offer`
- `list_my_reward_redemptions`
- `get_my_reward_code`

### RPC Quản trị viên

- `admin_list_wellness_rewards`
- `admin_upsert_reward_offer`
- `admin_import_reward_codes`
- `admin_cancel_reward_redemption`

## 6. Việt hóa production

| ID | Quy tắc đã chốt |
|---|---|
| WR-L10N-001 | Bốn app root V1/V2/V3/Admin dùng locale `vi_VN`, Flutter localization delegates và ARB tiếng Việt; preference `en` cũ được chuẩn hóa thành `vi` và không còn lựa chọn English. |
| WR-L10N-002 | Mọi text, dialog, tooltip, semantics, lỗi, status, plan/permission code và nội dung động do NanoBio kiểm soát phải có tiếng Việt có dấu hoặc fallback tiếng Việt an toàn. |
| WR-L10N-003 | Giữ nguyên brand/thuật ngữ NanoBio, Nabi, BioAI, Plus, FamilyPlus, AI, BMI, SpO₂, Face ID, VietQR, VND và đơn vị đo. `Free` hiển thị `Miễn phí`; `Admin` và `Sale` trong câu văn hiển thị `Quản trị viên` và `Cộng tác viên bán hàng`. |
| WR-L10N-004 | Không dịch dữ liệu thật do người dùng nhập như tên, email, ghi chú hoặc mã voucher. Nút thuộc permission dialog của hệ điều hành phụ thuộc ngôn ngữ thiết bị. |

## 7. Mô hình dữ liệu khái niệm

| Nhóm | Dữ liệu chính |
|---|---|
| Schedule Reward Eligibility | owner, subject, schedule item, snapshot, window, status, immutable source request |
| Completion Attempt / Proof | attempt, eligibility, path private, capture/upload time, MIME/size, proof/reward status |
| Wellness Wallet / Ledger / Allocation | owner, event, delta, available/expiry time, remaining points, program version |
| Reward Offer | Vietnamese content, provider, point cost, eligible plans, availability, voucher expiry, active state |
| Reward Code Inventory | offer, secret code, hash/normalization, state, issued redemption, expiry |
| Reward Redemption / Spend | wallet, offer, allocated code, spent allocations, status, cancel/refund audit |
| Program Configuration | contract version, reward points, expiry days, timezone, rollout feature flag, effective time |

SQLite nâng lên v14 để lưu proof sidecar, eligibility/reward projection, catalog,
redemption cache và sync state. Mã voucher rõ chỉ được lưu trong secure storage.

## 8. Tiêu chí chấp nhận tối thiểu

| ID | Kết quả phải đạt |
|---|---|
| WR-AC-001 | Biên trước giờ, đúng giờ, ngay trước phút 30, đúng phút 30 và ngay sau phút 30 cho trạng thái chính xác theo `Asia/Ho_Chi_Minh`. |
| WR-AC-002 | Hủy camera, từ chối quyền, ảnh sai loại/quá 5 MB hoặc time lỗi không thay đổi nhiệm vụ và không tạo điểm. |
| WR-AC-003 | Local completion, proof, linked task/meal và health-score projection commit nguyên tử; ảnh orphan được reconcile hoặc dọn an toàn. |
| WR-AC-004 | Double tap, retry, hai thiết bị hoặc mất response chỉ tạo một completion/proof thưởng và một khoản `+10`. |
| WR-AC-005 | Upload trước hạn có thể finalize sau hạn; upload sau hạn không được thưởng. |
| WR-AC-006 | Guest/offline được giữ ảnh local nhưng không có số dư đổi voucher. |
| WR-AC-007 | `+10` chuyển pending → available sau `window_end`, hết hạn sau 180 ngày; cấu hình mới không hồi tố và FEFO tiêu đúng. |
| WR-AC-008 | User A không đọc/upload path user B; chặn MIME/size/path/upsert giả và direct ledger/inventory DML. |
| WR-AC-009 | Đổi voucher atomic; thiếu điểm, hết kho hoặc conflict không làm thay đổi số dư. |
| WR-AC-010 | Hủy giao dịch Admin idempotent, hoàn điểm đúng một lần, không trả mã về kho và có audit. |
| WR-AC-011 | Production UI do NanoBio kiểm soát hiển thị tiếng Việt khi host là `en_US`; scanner không còn mojibake/raw exception/UI code ngoài allowlist. |

## 9. Triển khai và bằng chứng còn thiếu

Thứ tự rollout bắt buộc:

1. Deploy migration/RLS/Storage với `wellness_rewards_rollout.enabled = false`.
2. Ship client và Admin.
3. Quản trị viên nhập catalog và kho mã.
4. Chạy smoke sandbox cho proof, RLS, ledger, concurrency và voucher.
5. Bật feature flag sau khi acceptance pass và theo dõi lỗi proof, duplicate,
   reconciliation, tồn kho và hủy voucher.

Code, SQL và static/targeted test là bằng chứng source-ready, không phải bằng
chứng migration 16 đã được deploy hoặc RLS/Storage đã pass trong sandbox.
