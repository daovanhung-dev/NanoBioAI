# Tài khoản fixture local/sandbox

> Khong dung bat ky tai khoan nao trong file nay tren production hoac shared
> staging. Tat ca danh tinh va du lieu lien quan deu la gia lap.
> Khong production.

Tài liệu này mô tả toàn bộ tài khoản `dev*.nanobio.local` được cấu hình bởi
`config.sql` và `19-dev-sandbox-comprehensive-seed.sql`. Mọi người, số điện
thoại, định danh và quan hệ dưới đây đều là hư cấu.

## Phạm vi và đăng nhập

- Chỉ dùng sau khi dựng lại database **local/sandbox** bằng `config.sql`.
- **Không bao giờ** chạy fixture hoặc dùng các tài khoản này trên production hay
  shared staging.
- Tất cả tài khoản email/password trong ma trận dùng mật khẩu fixture
  `NanoBio@123456`.
- `dev.fixture.guest@nanobio.local` là cohort **anonymous/guest**. Hãy kiểm thử
  nó bằng luồng `signInAnonymously`; không dùng nó như một tài khoản email/password
  bình thường, dù seed có email hư cấu để định danh fixture ổn định.
- Khi chạy lại `config.sql`, dữ liệu và mật khẩu fixture có thể được dựng lại.
  Không thay đổi chúng thành thông tin thật.

## Tài khoản legacy ổn định

| Email | Xác thực | Gói / quyền | Mục đích và liên kết |
| --- | --- | --- | --- |
| `dev.free@nanobio.local` | Email/password | Free, subscription active | Regression cho người dùng Free cơ bản. |
| `dev.plus@nanobio.local` | Email/password | Plus, subscription active | Regression cho quyền truy cập Plus hiệu lực. |
| `dev.family@nanobio.local` | Email/password | Family Plus, subscription active | Regression cho entitlement Family Plus độc lập; dùng cohort Family fixture bên dưới để kiểm thử thành viên/liên kết. |
| `dev.admin@nanobio.local` | Email/password | Free + `super_admin`, `app_access_mode=both` | Admin legacy ổn định; là tài khoản Admin dùng bởi Storage fixture để tải chứng từ payout Sale. |

## Guest, Free và Plus

| Email | Xác thực | Gói/trạng thái | Kịch bản chính |
| --- | --- | --- | --- |
| `dev.fixture.guest@nanobio.local` | Anonymous (`signInAnonymously`) | Guest / anonymous | Xác minh bề mặt Guest, không có entitlement thành viên. |
| `dev.fixture.free.ready@nanobio.local` | Email/password | Free active, quota AI còn 2/3 | Free sẵn sàng dùng; onboarding `not_started`. |
| `dev.fixture.free.exhausted@nanobio.local` | Email/password | Free active, quota AI đã 3/3 | Nhánh hết quota; onboarding `in_progress`, kèm một request Wellness lịch sử `initial_guest` đã hoàn tất sau khi tài khoản không còn anonymous. |
| `dev.fixture.plus.active@nanobio.local` | Email/password | Plus `active` | Quyền Plus đang hiệu lực. |
| `dev.fixture.plus.trial@nanobio.local` | Email/password | Plus `trialing` | Luồng dùng thử Plus. |
| `dev.fixture.plus.pastdue@nanobio.local` | Email/password | Plus `past_due` | Luồng quá hạn thanh toán nhưng subscription chưa hết kỳ. |
| `dev.fixture.plus.canceled@nanobio.local` | Email/password | Plus `canceled` | Luồng đã hủy. |
| `dev.fixture.plus.expired@nanobio.local` | Email/password | Plus `expired` | Luồng Plus đã hết hạn. |
| `dev.fixture.wellness@nanobio.local` | Email/password | Free active | Cohort Wellness: eligibility, completion attempt, proof, wallet, allocation, reward code và redemption. Storage runner dùng tài khoản này để tạo một proof active và một proof reversed. |

## Family Plus và liên kết thành viên

Nhóm fixture chính là Family Plus active do `dev.fixture.family.owner@nanobio.local`
sở hữu. Thành viên có tài khoản được liên kết với subject tương ứng để kiểm thử
RLS đọc/ghi; không có nhóm active nào vượt quá giới hạn năm thành viên.

| Email | Xác thực | Vai trò / trạng thái | Liên kết hoặc kịch bản |
| --- | --- | --- | --- |
| `dev.fixture.family.owner@nanobio.local` | Email/password | Family Plus active, `owner` active | Chủ nhóm active; có quyền xem/sửa và là điểm bắt đầu để kiểm thử Family Plus. |
| `dev.fixture.family.adult@nanobio.local` | Email/password | `adult` active | Thành viên đã liên kết trong nhóm của owner; có quyền xem/sửa. |
| `dev.fixture.family.member@nanobio.local` | Email/password | `member` active | Thành viên thường đã liên kết trong nhóm owner; dùng cho quyền xem mặc định. |
| `dev.fixture.family.child@nanobio.local` | Email/password | `child` active | Thành viên trẻ em trong nhóm owner; dùng để kiểm thử subject Family. |
| `dev.fixture.family.viewer@nanobio.local` | Email/password | `viewer` active | Thành viên đã liên kết trong nhóm owner; chỉ xem, `can_edit=false`. |
| `dev.fixture.family.invited@nanobio.local` | Email/password | `member` invited | Lời mời chưa chấp nhận trong cohort Family; không được coi là thành viên active. |
| `dev.fixture.family.removed@nanobio.local` | Email/password | `member` removed | Thành viên đã bị xóa khỏi cohort Family; kiểm thử quyền bị thu hồi. |
| `dev.fixture.family.paused@nanobio.local` | Email/password | Family Plus, nhóm `paused` | Chủ/case nhóm tạm dừng để kiểm thử chặn chia sẻ khi group không active. |
| `dev.fixture.family.closed@nanobio.local` | Email/password | Family Plus, nhóm `closed` | Chủ/case nhóm đã đóng để kiểm thử trạng thái cuối vòng đời. |

## Sale, referral, thanh toán và payout

Chuỗi referral trực tiếp là **A → B → C**. Khi khách C có payment thành công,
commission 10% chỉ thuộc Sale B (người giới thiệu trực tiếp); Sale A không nhận
commission upstream.

| Email | Xác thực | Sale / gói | Liên kết hoặc kịch bản |
| --- | --- | --- | --- |
| `dev.fixture.sale.active@nanobio.local` | Email/password | Sale `active`, Plus active | Sale A; có payout profile hoàn chỉnh và conversion `approved` chuyên dụng cho Storage fixture tải chứng từ payout. Một conversion `approved` khác được giữ lại để không mất nhánh trạng thái khi tùy chọn đánh dấu payout là `paid`. |
| `dev.fixture.sale.direct@nanobio.local` | Email/password | Sale `active`, Plus active | Sale B, được Sale A giới thiệu; là referrer trực tiếp của khách C và nhận commission trực tiếp. |
| `dev.fixture.sale.customer@nanobio.local` | Email/password | Plus active, khách hàng Sale | Sale C, được Sale B giới thiệu; có payment thành công và các trạng thái payment/commission liên quan. |
| `dev.fixture.sale.pending@nanobio.local` | Email/password | Sale `pending` | Chờ xét duyệt tham gia Sale. |
| `dev.fixture.sale.suspended@nanobio.local` | Email/password | Sale `suspended`, `admin_status=suspended` | Sale bị tạm ngưng; đồng thời là fixture trạng thái người dùng Admin `suspended` để kiểm thử quyền/referral bị hạn chế. |
| `dev.fixture.sale.closed@nanobio.local` | Email/password | Sale `closed` | Sale đã đóng; kiểm thử trạng thái cuối vòng đời và dữ liệu lịch sử. |

## Admin

| Email | Xác thực | Vai trò Admin | Bề mặt truy cập / kịch bản |
| --- | --- | --- | --- |
| `dev.fixture.admin.finance@nanobio.local` | Email/password | `finance_admin` active | `app_access_mode=both`; payment, reconciliation, payout và Sale point. |
| `dev.fixture.admin.support@nanobio.local` | Email/password | `support_admin` active | `app_access_mode=both`; hỗ trợ khách hàng và audit. |
| `dev.fixture.admin.content@nanobio.local` | Email/password | `content_admin` active | `app_access_mode=both`; nội dung, catalog và Nabi. |
| `dev.fixture.admin.operations@nanobio.local` | Email/password | `operations_admin` active | `app_access_mode=both`; vận hành người dùng, Family và Sale. |
| `dev.fixture.admin.only@nanobio.local` | Email/password | `super_admin` active | `app_access_mode=admin`; kiểm thử tài khoản chỉ có bề mặt Admin. |
| `dev.fixture.admin.revoked@nanobio.local` | Email/password | Role Admin đã revoked/inactive, `admin_status=closed` | Negative case: không được dùng như một phiên Admin hiệu lực. |

## Ghi chú kiểm thử

- Tài khoản cùng tên ở bảng trên là các persona fixture, không phải danh tính
  người dùng thật và không được cấp ra ngoài môi trường local/sandbox.
- Để kiểm thử quyền dựa trên quan hệ, hãy đăng nhập đúng persona thay vì sửa
  trực tiếp `public.users`, `family_members`, `sale_profiles` hay role Admin.
- Storage proof không được seed bằng SQL: chạy
  `tools/supabase/Seed-StorageFixtures.ps1` sau khi áp dụng config/demo profile
  nếu cần chứng từ Storage thật.
