Commit de xuat: docs(test): them ma tran campaign full-project-2026-07-28

# Ma trận nghiệm thu toàn bộ NanoBio — 2026-07-28

## Trạng thái tài liệu

Đây là **ma trận lập kế hoạch duy nhất** của campaign. Mọi dòng bên dưới đang
ở `PENDING`, không phải kết quả chạy, không có asset/evidence thật và không
được dùng thay cho case record. Khi thực thi, tạo `cases/<CASE-ID>.md`, thay
cột Asset/Evidence bằng artifact mới, rồi đóng từng dòng bằng một trạng thái
cuối hợp lệ theo `README.md`.

`Asset` và `Evidence` ghi `Chưa có` có nghĩa là chưa có bằng chứng, không phải
là bằng chứng âm tính hay PASS. Mỗi case UI cần PNG mới từ thiết bị thật; case
RLS/race/ledger/retry cần thêm technical evidence an toàn.

## Quy ước persona và coverage

Persona được ghi bằng alias để không lộ email hoặc mật khẩu fixture. Alias
đối chiếu với `docs/supabase/19-dev-sandbox-accounts.md`. Có đủ 37 persona:

- `LEG-FREE` — legacy Free — `PF-001`.
- `LEG-PLUS` — legacy Plus — `PF-007`, `NBI-015`.
- `LEG-FAMILY` — legacy FamilyPlus — `PF-007`, `AH-004`.
- `LEG-ADMIN` — legacy super admin/both — `PF-032`, `PF-039`.
- `GST-ANON` — anonymous Guest — `PF-002` đến `PF-004`, `WR-006`, `AH-001`.
- `FREE-READY` — Free còn quota — `PF-006`, `PF-008`, `AH-002`.
- `FREE-EXHAUSTED` — Free hết quota — `PF-005`, `NBI-001`, `NBI-002`.
- `PLUS-ACTIVE` — Plus active — `PF-007`, `AH-003`.
- `PLUS-TRIAL` — Plus trialing — `NBI-008`, `NBI-009`.
- `PLUS-PASTDUE` — Plus past_due — `PF-010`, `NBI-018`.
- `PLUS-CANCELED` — Plus canceled — `PF-011`.
- `PLUS-EXPIRED` — Plus expired — `PF-012`.
- `WELLNESS` — Free cohort Wellness — `WR-001` đến `WR-011`, `NBI-014`.
- `FAM-OWNER` — Family owner active — `PF-014`, `AH-004`, `NBI-019`.
- `FAM-ADULT` — Family adult active — `PF-014`.
- `FAM-MEMBER` — Family member active — `PF-014`, `NBI-012`.
- `FAM-CHILD` — Family child active — `PF-014`, `NBI-013`.
- `FAM-VIEWER` — Family viewer active — `PF-014`.
- `FAM-INVITED` — Family invitation pending — `PF-015`.
- `FAM-REMOVED` — Family member removed — `PF-015`.
- `FAM-PAUSED` — Family group paused — `PF-016`.
- `FAM-CLOSED` — Family group closed — `PF-016`.
- `SALE-A` — Sale active with payout profile — `PF-018`, `PF-026`, `PF-028`.
- `SALE-B` — active direct Sale of A — `PF-023`.
- `SALE-C` — customer referred by B — `PF-023`.
- `SALE-PENDING` — Sale pending — `PF-029`.
- `SALE-SUSPENDED` — Sale/admin suspended — `PF-030`.
- `SALE-CLOSED` — Sale closed — `PF-031`.
- `SALE-A-READY` — direct customer of A with available-point history — `PF-022`, `PF-024`.
- `SALE-A-PENDING` — direct customer of A with pending-point history — `PF-020`, `PF-021`.
- `SALE-A-PROSPECT` — direct prospect of A — `PF-019`.
- `ADM-FINANCE` — active finance admin — `PF-009`, `PF-021` đến `PF-027`, `PF-036`.
- `ADM-SUPPORT` — active support admin — `PF-033`, `PF-038`.
- `ADM-CONTENT` — active content admin — `PF-035`, `NBI-024`.
- `ADM-OPERATIONS` — active operations admin — `PF-034`.
- `ADM-ONLY` — active super admin/admin-only surface — `PF-040`.
- `ADM-REVOKED` — revoked/inactive admin — `PF-041`.

Các chuỗi actor/target (đặc biệt Guest → Member, A → B → C, payment/reversal,
Family và two-client Wellness) không được thay bằng việc sửa trực tiếp state
fixture. Reset sandbox/app data phải được ghi trong case record.

## Ma trận M01–M19 — Product Flow

| Case | Persona | Scenario | BD / AC / BR refs | Asset | Evidence | Status |
| --- | --- | --- | --- | --- | --- | --- |
| PF-001 | LEG-FREE | Mở dashboard, thực hiện lịch, công cụ tính cơ bản, health-score/habit và reminder cơ sở; đối chiếu dữ liệu người dùng thấy được. | Product Flow M03, M04, M08, M09; §4 | Chưa có | Chưa có | PENDING |
| PF-002 | GST-ANON | Hoàn tất onboarding Guest và tạo lịch đầu tiên một lần; lưu/hiển thị thực đơn, bài tập và mốc lịch. | Product Flow M01, M02, M03, M05; AC-01 | assets/PF-002-pass.png | cases/PF-002.md | PASS |
| PF-003 | GST-ANON | Sau lần tạo đầu, yêu cầu tạo lịch thêm phải dẫn tới đăng nhập và không tạo lịch AI mới. | Product Flow M02, M05; AC-02 | assets/PF-003-fail.png | cases/PF-003.md | FAIL |
| PF-004 | GST-ANON | Mở AI Chat hoặc module ngoài allowlist Guest; xác minh chặn tại bề mặt/điều hướng. | Product Flow M05, M07; AC-03 | Chưa có | Chưa có | PENDING |
| PF-005 | FREE-EXHAUSTED | Thử yêu cầu AI Chat vượt giới hạn ngày; không tiêu/quét quota sai. | Product Flow M06, M07; AC-04 | Chưa có | Chưa có | PENDING |
| PF-006 | FREE-READY | Dùng/tái tạo lịch tới nhánh vượt quota tháng; không tạo hoặc trừ sai quota ở lần vượt giới hạn. | Product Flow M02, M06; AC-05 | Chưa có | Chưa có | PENDING |
| PF-007 | LEG-PLUS, LEG-FAMILY, PLUS-ACTIVE | Dùng AI Chat và lịch cá nhân theo quyền Plus/FamilyPlus; không bị chặn bởi quota Free. | Product Flow M06, M07, M10, M11; AC-06 | Chưa có | Chưa có | PENDING |
| PF-008 | FREE-READY → ADM-FINANCE | Tạo controlled payment Plus ở trạng thái chưa duyệt; entitlement Plus chưa được mở. | Product Flow M06, M13, M19; AC-07 | Chưa có | Chưa có | PENDING |
| PF-009 | ADM-FINANCE → FREE-READY | Duyệt controlled payment Plus; quyền có hiệu lực và có history/audit an toàn. | Product Flow M06, M13, M19; AC-08 | Chưa có | Chưa có | PENDING |
| PF-010 | PLUS-PASTDUE | Xác minh bề mặt/quyền của subscription past_due theo state fixture, không suy diễn active/expired. | Product Flow M06; §3.3 | Chưa có | Chưa có | PENDING |
| PF-011 | PLUS-CANCELED | Xác minh bề mặt/quyền của subscription canceled và thông tin người dùng thấy được. | Product Flow M06; §3.3 | Chưa có | Chưa có | PENDING |
| PF-012 | PLUS-EXPIRED | Xác minh fallback/chặn quyền Plus sau expiry, gồm điều hướng và không cấp quyền cũ. | Product Flow M06; §3.3 | Chưa có | Chưa có | PENDING |
| PF-013 | GST-ANON → FREE-EXHAUSTED | Kiểm thử chuỗi Guest → đăng ký/đăng nhập → đồng bộ local-cloud; giữ đúng state duy nhất của chuỗi. | Product Flow M05; §1.4, §16.1 | Chưa có | Chưa có | PENDING |
| PF-014 | FAM-OWNER, FAM-ADULT, FAM-MEMBER, FAM-CHILD, FAM-VIEWER | Kiểm thử FamilyPlus active: subject, xem/sửa theo role, viewer không sửa và giới hạn thành viên. | Product Flow M11; §10.2–§10.4 | Chưa có | Chưa có | PENDING |
| PF-015 | FAM-INVITED, FAM-REMOVED | Kiểm thử lời mời chưa nhận và thành viên removed không được xem như active/sửa dữ liệu. | Product Flow M11; §10.3–§10.4 | Chưa có | Chưa có | PENDING |
| PF-016 | FAM-PAUSED, FAM-CLOSED | Kiểm thử group paused/closed chặn chia sẻ/quyền mới và vẫn hiển thị trạng thái rõ ràng. | Product Flow M11, M19; §10.4, §14.1 | Chưa có | Chưa có | PENDING |
| PF-017 | LEG-FAMILY | Xác minh entitlement FamilyPlus độc lập và không coi Sale là tier thành viên. | Product Flow M06, M11, M12; §3.1–§3.3 | Chưa có | Chưa có | PENDING |
| PF-018 | SALE-A | Sale active có mã giới thiệu duy nhất và dùng được để tạo quan hệ trực tiếp. | Product Flow M12; AC-09 | Chưa có | Chưa có | PENDING |
| PF-019 | SALE-A → SALE-A-PROSPECT | Nhập mã Sale A hợp lệ cho khách direct; tạo đúng một quan hệ trực tiếp, không tạo cây/tầng. | Product Flow M12; AC-10 | Chưa có | Chưa có | PENDING |
| PF-020 | SALE-A, SALE-A-PENDING | Payment đang chờ xét duyệt không tạo Điểm Sale khả dụng trước quyết định Admin. | Product Flow M12, M13, M14; AC-11 | Chưa có | Chưa có | PENDING |
| PF-021 | ADM-FINANCE → SALE-A-PENDING → SALE-A | Duyệt payment đủ điều kiện và đối chiếu bản ghi Điểm Sale 10% của referrer trực tiếp. | Product Flow M12, M13, M14, M19; AC-12 | Chưa có | Chưa có | PENDING |
| PF-022 | ADM-FINANCE → SALE-A-READY → SALE-A | Duyệt payment gia hạn đủ điều kiện; điểm 10% mới được ghi đúng một lần. | Product Flow M12, M13, M14, M19; AC-13 | Chưa có | Chưa có | PENDING |
| PF-023 | SALE-A → SALE-B → SALE-C | A→B→C: payment của C chỉ tạo commission cho B, A không nhận upstream commission. | Product Flow M12, M13, M14; AC-14 | Chưa có | Chưa có | PENDING |
| PF-024 | ADM-FINANCE → SALE-A-READY → SALE-A | Hoàn payment đã cộng điểm tạo reversal/adjustment có audit, không xóa history. | Product Flow M13, M14, M19; AC-15 | Chưa có | Chưa có | PENDING |
| PF-025 | ADM-FINANCE, SALE-A | Retry job commission cho cùng payment không tạo Điểm Sale lần hai. | Product Flow M14, M17, M19; AC-16 | Chưa có | Chưa có | PENDING |
| PF-026 | SALE-A | Yêu cầu quy đổi vượt số dư khả dụng bị từ chối; số dư/history không đổi sai. | Product Flow M14; AC-17 | Chưa có | Chưa có | PENDING |
| PF-027 | ADM-FINANCE → SALE-A | Duyệt quy đổi điểm: giữ/trừ đúng một lần, trạng thái/history rõ ràng. | Product Flow M14, M16, M19; AC-18 | Chưa có | Chưa có | PENDING |
| PF-028 | SALE-A | Trên máy thật mở Tổng quan và Khách hàng trực tiếp Sale; refresh, số liệu và state lỗi/rỗng đúng theo fixture. | Product Flow M12, M14; §7.9 | assets/PF-028-pass.png | cases/PF-028.md | PASS |
| PF-029 | SALE-PENDING | Bề mặt Sale pending không được dùng như Sale active; thông báo/state không gây hiểu nhầm. | Product Flow M12; §3.4, §7.2 | Chưa có | Chưa có | PENDING |
| PF-030 | SALE-SUSPENDED | Sale/admin suspended bị chặn quyền/referral phù hợp, không lộ dữ liệu/quyền active. | Product Flow M12, M19; §3.4, §14.1 | Chưa có | Chưa có | PENDING |
| PF-031 | SALE-CLOSED | Sale closed giữ history cần thiết nhưng không mở luồng Sale/commission mới. | Product Flow M12, M14, M19; §3.4 | Chưa có | Chưa có | PENDING |
| PF-032 | LEG-ADMIN | Mở Admin View/Dashboard, kiểm tra metric/lọc thời gian theo permission. | Product Flow M15; AC-19 | Chưa có | Chưa có | PENDING |
| PF-033 | ADM-SUPPORT | Cố duyệt payment không có quyền Finance; backend/API phải từ chối, không chỉ ẩn UI. | Product Flow M16, M19; AC-20 | Chưa có | Chưa có | PENDING |
| PF-034 | ADM-OPERATIONS | Quản lý user/Family/Sale trong permission Operations; kiểm tra RBAC và audit bề mặt. | Product Flow M16-A, M16-C, M19; §11.3, §11.5, §11.8 | Chưa có | Chưa có | PENDING |
| PF-035 | ADM-CONTENT | Kiểm tra management nội dung, catalog, thông báo theo role Content, không cấp Finance/Ops ngoài scope. | Product Flow M16-E, M19; §11.7–§11.8 | Chưa có | Chưa có | PENDING |
| PF-036 | ADM-FINANCE | Duyệt/từ chối payment có lý do, actor, timestamp và audit; kiểm tra đối soát tài chính. | Product Flow M13, M16-D, M17, M19; AC-21 | Chưa có | Chưa có | PENDING |
| PF-037 | ADM-FINANCE | Thay đổi giá/tỷ lệ quy đổi tạo config version mới, không sửa lịch sử. | Product Flow M16-B, M17, M19; AC-22 | Chưa có | Chưa có | PENDING |
| PF-038 | ADM-SUPPORT | Mở Sale detail với scope hợp lệ; không hiển thị dữ liệu sức khỏe nhạy cảm khách. | Product Flow M15, M16, M19; AC-24 | Chưa có | Chưa có | PENDING |
| PF-039 | LEG-ADMIN | Xuất report theo permission, kiểm tra log export/audit và không lộ dữ liệu ngoài scope. | Product Flow M18, M19; AC-23 | Chưa có | Chưa có | PENDING |
| PF-040 | ADM-ONLY | Đăng nhập tài khoản admin-only: vào đúng bề mặt Admin, không dẫn sai sang user surface. | Product Flow M15, M16, M19; §3.1, §14.1 | Chưa có | Chưa có | PENDING |
| PF-041 | ADM-REVOKED | Tài khoản Admin revoked/closed không tạo phiên Admin hợp lệ hoặc truy cập endpoint protected. | Product Flow M15, M16, M19; §14.1 | Chưa có | Chưa có | PENDING |

## Ma trận M20–M29 — Advanced Health

Các case `AH-020` đến `AH-029` là đánh giá gate nghiệp vụ Draft. Chúng chỉ có
thể đóng `N/A`/`GAP` khi evidence nêu rõ module/AC và rationale theo BD; không
được suy diễn PASS từ UI placeholder.

| Case | Persona | Scenario | BD / AC / BR refs | Asset | Evidence | Status |
| --- | --- | --- | --- | --- | --- | --- |
| AH-001 | GST-ANON | Mở catalog từ Guest và chọn module bất kỳ: login gate, back navigation, copy/accessibility. | Advanced Health M20–M29; AHF-AC-001, AHF-AC-004, AHF-AC-005 | assets/AH-001-pass.png | cases/AH-001.md | PASS |
| AH-002 | FREE-READY | Catalog Free: đủ mười card, thứ tự/tier; M20–M22 mở placeholder, M23–M29 upgrade gate, không side effect. | Advanced Health M20–M29; AHF-AC-001..005 | Chưa có | Chưa có | PENDING |
| AH-003 | PLUS-ACTIVE | Catalog Plus: đúng mười card, nhãn gói, placeholder, copy/accessibility; không health write/AI/quota/reminder/permission side effect. | Advanced Health M20–M29; AHF-AC-001..003, AHF-AC-005 | Chưa có | Chưa có | PENDING |
| AH-004 | LEG-FAMILY, FAM-OWNER | Catalog FamilyPlus và lựa chọn subject/điều hướng placeholder đúng scope, không tự cấp entitlement/dữ liệu. | Advanced Health M20–M29; AHF-AC-002..005, AHF-BR-001..006 | Chưa có | Chưa có | PENDING |
| AH-020 | PLUS-ACTIVE | Đánh giá gate nghiệp vụ Draft cho Blood Pressure; không chạy record/clinical workflow chưa approved. | Advanced Health M20; M20-AC01..03, §12 | Chưa có | Chưa có | PENDING |
| AH-021 | PLUS-ACTIVE | Đánh giá gate nghiệp vụ Draft cho Heart Rate/SpO₂. | Advanced Health M21; M21-AC01..04, §12 | Chưa có | Chưa có | PENDING |
| AH-022 | PLUS-ACTIVE | Đánh giá gate nghiệp vụ Draft cho Medication Adherence và M09 ownership. | Advanced Health M22; M22-AC01..03, AHF-BR-012, §12 | Chưa có | Chưa có | PENDING |
| AH-023 | FREE-READY, PLUS-ACTIVE | Đánh giá gate nghiệp vụ Draft cho Glucose và entitlement khác nhau. | Advanced Health M23; M23-AC01..03, §12 | Chưa có | Chưa có | PENDING |
| AH-024 | PLUS-ACTIVE | Đánh giá gate nghiệp vụ Draft cho Symptom/Pain và AI safety. | Advanced Health M24; M24-AC01..04, §12 | Chưa có | Chưa có | PENDING |
| AH-025 | FAM-OWNER | Đánh giá gate nghiệp vụ Draft cho Women's Cycle/Family privacy. | Advanced Health M25; M25-AC01..03, §12 | Chưa có | Chưa có | PENDING |
| AH-026 | PLUS-ACTIVE | Đánh giá gate nghiệp vụ Draft cho Respiratory/Allergy. | Advanced Health M26; M26-AC01..03, §12 | Chưa có | Chưa có | PENDING |
| AH-027 | PLUS-ACTIVE | Đánh giá gate nghiệp vụ Draft cho Lab Result và AI extraction. | Advanced Health M27; M27-AC01..04, §12 | Chưa có | Chưa có | PENDING |
| AH-028 | PLUS-ACTIVE | Đánh giá gate nghiệp vụ Draft cho Preventive Care và M09 ownership. | Advanced Health M28; M28-AC01..03, AHF-BR-012, §12 | Chưa có | Chưa có | PENDING |
| AH-029 | PLUS-ACTIVE | Đánh giá gate nghiệp vụ Draft cho AI Health Trends/quota/audit/safety. | Advanced Health M29; M29-AC01..05, AHF-BR-013, §12 | Chưa có | Chưa có | PENDING |

## Ma trận Wellness Rewards

| Case | Persona | Scenario | BD / AC / BR refs | Asset | Evidence | Status |
| --- | --- | --- | --- | --- | --- | --- |
| WR-001 | WELLNESS | Kiểm thử trước giờ, đúng giờ, trước/đúng/sau phút 30 theo Asia/Ho_Chi_Minh; UI state và evidence kỹ thuật thời gian. | Wellness Rewards; WR-AC-001 | Chưa có | Chưa có | PENDING |
| WR-002 | WELLNESS | Hủy camera, từ chối quyền, file sai loại/quá 5 MB hoặc lỗi thời gian không đổi task/điểm. | Wellness Rewards; WR-AC-002 | Chưa có | Chưa có | PENDING |
| WR-003 | WELLNESS | Completion/proof/task/meal/health-score projection commit atomically; kiểm orphan reconcile/dọn an toàn. | Wellness Rewards; WR-AC-003 | Chưa có | Chưa có | PENDING |
| WR-004 | WELLNESS + session kỹ thuật độc lập | Double tap, retry, mất response và two-client chỉ tạo một completion/proof/`+10`; có ảnh kết quả thiết bị thật. | Wellness Rewards; WR-AC-004 | Chưa có | Chưa có | PENDING |
| WR-005 | WELLNESS | Upload trước hạn rồi finalize sau hạn được thưởng; upload sau hạn không thưởng. | Wellness Rewards; WR-AC-005 | Chưa có | Chưa có | PENDING |
| WR-006 | GST-ANON | Guest/offline giữ proof local nhưng không có số dư đổi voucher; không làm hỏng chuỗi Guest → Member nếu dùng. | Wellness Rewards; WR-AC-006 | Chưa có | Chưa có | PENDING |
| WR-007 | WELLNESS | Pending → available sau window_end, expiry 180 ngày, config không hồi tố và FEFO khi tiêu. | Wellness Rewards; WR-AC-007 | Chưa có | Chưa có | PENDING |
| WR-008 | WELLNESS + FREE-READY + session kỹ thuật độc lập | RLS/Storage: user A không đọc/upload path B; MIME/size/path/upsert giả và direct DML bị chặn. | Wellness Rewards; WR-AC-008 | Chưa có | Chưa có | PENDING |
| WR-009 | WELLNESS | Đổi voucher atomic: thiếu điểm, hết kho và conflict không đổi sai balance/inventory. | Wellness Rewards; WR-AC-009 | Chưa có | Chưa có | PENDING |
| WR-010 | ADM-FINANCE → WELLNESS | Admin hủy redemption idempotently: hoàn điểm đúng một lần, không trả mã về kho, có audit. | Wellness Rewards; WR-AC-010 | Chưa có | Chưa có | PENDING |
| WR-011 | WELLNESS | UI production-controlled tiếng Việt khi host en_US; không mojibake/raw exception/UI code ngoài allowlist. | Wellness Rewards; WR-AC-011 | Chưa có | Chưa có | PENDING |

## Ma trận Nabi M30 — 20 notification ID

Oracle package/quota là Product Flow hiện hành. Mọi chênh lệch thuật ngữ cũ
trong BD Nabi phải ghi thành gap tài liệu, không được kết luận lỗi app chỉ vì
khác tên gói/quota.

| Case | Persona | Scenario | BD / AC / BR refs | Asset | Evidence | Status |
| --- | --- | --- | --- | --- | --- | --- |
| NBI-001 | FREE-EXHAUSTED | Trigger/suppression/CTA của hết thực đơn miễn phí theo quyền Free hiện hành. | Nabi NBI-FREE-001; Nabi AC-01..05, AC-15; Product Flow M06 | Không có — M30 chưa được mount | cases/NBI-001.md | FAIL |
| NBI-002 | FREE-EXHAUSTED | Trigger/suppression/CTA của sắp hết hoặc hết lượt hỏi Nabi theo quota hiện hành. | Nabi NBI-FREE-002; Nabi AC-01..05, AC-15; Product Flow M06, M07 | Không có — M30 chưa được mount | cases/NBI-002.md | FAIL |
| NBI-003 | FREE-READY | Trigger/CTA sau bảy ngày nhiệm vụ, không che nội dung và không chẩn đoán. | Nabi NBI-FREE-003; Nabi AC-01..06, AC-10, AC-13 | Không có — M30 chưa được mount | cases/NBI-003.md | FAIL |
| NBI-004 | FREE-READY | Trigger/CTA khi truy cập mục chuyên gia bị khóa, đúng user/state. | Nabi NBI-FREE-004; Nabi AC-01..06, AC-15 | Không có — M30 chưa được mount | cases/NBI-004.md | FAIL |
| NBI-005 | FREE-READY | Trigger/CTA Bản đồ 365 bị khóa và không mở quyền sai. | Nabi NBI-FREE-005; Nabi AC-01..06, AC-15 | Không có — M30 chưa được mount | cases/NBI-005.md | FAIL |
| NBI-006 | FREE-READY | Trigger/CTA báo cáo tuần đầy đủ bị khóa, giữ ngữ cảnh màn hình. | Nabi NBI-FREE-006; Nabi AC-01..06, AC-15 | Không có — M30 chưa được mount | cases/NBI-006.md | FAIL |
| NBI-007 | FREE-READY | Trigger/CTA câu hỏi cần chuyên gia, copy hỗ trợ an toàn. | Nabi NBI-FREE-007; Nabi AC-01..06, AC-13, AC-14 | Không có — M30 chưa được mount | cases/NBI-007.md | FAIL |
| NBI-008 | PLUS-TRIAL | Trigger/CTA annual sau bảy ngày dùng gói, áp oracle package hiện hành. | Nabi NBI-ANNUAL-001; Nabi AC-01..08, AC-15; Product Flow M06 | Không có — M30 chưa được mount | cases/NBI-008.md | FAIL |
| NBI-009 | PLUS-TRIAL | Trigger/CTA annual sau 15 ngày dùng gói, áp oracle package hiện hành. | Nabi NBI-ANNUAL-002; Nabi AC-01..08, AC-15; Product Flow M06 | Không có — M30 chưa được mount | cases/NBI-009.md | FAIL |
| NBI-010 | PLUS-ACTIVE | Trigger/CTA annual còn năm ngày, không dùng entitlement/quota cũ. | Nabi NBI-ANNUAL-003; Nabi AC-01..08, AC-15; Product Flow M06 | Không có — M30 chưa được mount | cases/NBI-010.md | FAIL |
| NBI-011 | PLUS-ACTIVE | Trigger/CTA annual còn một ngày, priority/cooldown đúng. | Nabi NBI-ANNUAL-004; Nabi AC-01..08, AC-15; Product Flow M06 | Không có — M30 chưa được mount | cases/NBI-011.md | FAIL |
| NBI-012 | FAM-MEMBER | Trigger/CTA sắp đạt chuỗi bảy ngày, không che task/schedule. | Nabi NBI-STREAK-001; Nabi AC-01..06, AC-10, AC-13 | Không có — M30 chưa được mount | cases/NBI-012.md | FAIL |
| NBI-013 | FAM-CHILD | Trigger/CTA nhận thẻ cứu chuỗi theo scope subject/Family phù hợp. | Nabi NBI-STREAK-002; Nabi AC-01..06, AC-13, AC-15 | Không có — M30 chưa được mount | cases/NBI-013.md | FAIL |
| NBI-014 | WELLNESS | Trigger/CTA mở hộp quà, liên kết reward không tạo giao dịch trùng. | Nabi NBI-REWARD-001; Nabi AC-01..06, AC-08, AC-12 | Không có — M30 chưa được mount | cases/NBI-014.md | FAIL |
| NBI-015 | LEG-PLUS | Trigger/CTA báo cáo tuần sẵn sàng, content động và copy không chẩn đoán. | Nabi NBI-REPORT-001; Nabi AC-01..06, AC-08, AC-13 | Không có — M30 chưa được mount | cases/NBI-015.md | FAIL |
| NBI-016 | SALE-A | Trigger/CTA mời người thân/referral, không tạo relation/permission sai. | Nabi NBI-REFERRAL-001; Nabi AC-01..06, AC-15; Product Flow M12 | Không có — M30 chưa được mount | cases/NBI-016.md | FAIL |
| NBI-017 | GST-ANON | Trigger/CTA care khi chưa hoàn thành nhiệm vụ, Guest-safe và không che onboarding. | Nabi NBI-CARE-001; Nabi AC-01..06, AC-10, AC-13 | Không có — M30 chưa được mount | cases/NBI-017.md | FAIL |
| NBI-018 | PLUS-PASTDUE | Trigger/CTA care khi quay lại, đúng trạng thái entitlement chưa đồng bộ/ngoại lệ. | Nabi NBI-CARE-002; Nabi AC-01..09, AC-15; Product Flow M06 | Không có — M30 chưa được mount | cases/NBI-018.md | FAIL |
| NBI-019 | FAM-OWNER | Trigger/CTA động viên sau ngày chưa hoàn hảo, theo Nabitone/an toàn. | Nabi NBI-CARE-003; Nabi AC-01..06, AC-10, AC-13 | Không có — M30 chưa được mount | cases/NBI-019.md | FAIL |
| NBI-020 | FREE-READY | Trigger/CTA nhắc cập nhật hồ sơ sức khỏe, giữ context và không medical diagnosis. | Nabi NBI-PROFILE-001; Nabi AC-01..06, AC-13 | Không có — M30 chưa được mount | cases/NBI-020.md | FAIL |

## Ma trận Nabi M30 — hành vi chéo

| Case | Persona | Scenario | BD / AC / BR refs | Asset | Evidence | Status |
| --- | --- | --- | --- | --- | --- | --- |
| NBI-021 | FREE-EXHAUSTED | Nhiều trigger đồng thời: kiểm priority, suppression và cooldown toàn hệ thống; không lặp quá mức. | Nabi §8, §17; Nabi AC-02..04, AC-15 | Không có — M30 chưa được mount | cases/NBI-021.md | FAIL |
| NBI-022 | FREE-READY, PLUS-ACTIVE | Chạm Nabi/CTA, deep-link và back navigation; không mất context hoặc điều hướng vào quyền sai. | Nabi §5.4, §16; Nabi AC-05..07, AC-15 | Không có — M30 chưa được mount | cases/NBI-022.md | FAIL |
| NBI-023 | PLUS-CANCELED, PLUS-EXPIRED | Offline/retry, entitlement chưa đồng bộ, promo hết hạn và deep link không hợp lệ có fallback an toàn. | Nabi §18; Nabi AC-07, AC-09, AC-14, AC-15; Product Flow M06 | Không có — M30 chưa được mount | cases/NBI-023.md | FAIL |
| NBI-024 | ADM-CONTENT | Accessibility/semantic label, không che nội dung và analytics event được ghi an toàn cho notification configuration/surface. | Nabi §19–§20; Nabi AC-10..12 | Không có — M30 chưa được mount | cases/NBI-024.md | FAIL |

## Cổng đóng ma trận

1. Mỗi row có file evidence riêng với front matter chuẩn, command ID, actual,
   artifact và reset/build/device.
2. Screenshots chỉ được thêm sau khi đã được xem/redact; không tái sử dụng asset
   hoặc PASS cũ.
3. Failure đã xác minh có finding riêng; blocker/gap có rationale rõ ràng.
4. Validator campaign phải báo không còn `PENDING`, trace được toàn bộ M01–M30,
   AC Product Flow, AHF-AC, WR-AC và 20 NBI ID.
