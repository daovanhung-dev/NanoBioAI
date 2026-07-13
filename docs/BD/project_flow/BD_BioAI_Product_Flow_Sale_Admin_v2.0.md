# BD — Luồng sản phẩm, gói thành viên, Sale trực tiếp và quản trị hệ thống

> **Dự án:** BioAI / NanoBio  
> **Mã tài liệu:** BD-BIOAI-PRODUCT-FLOW-002  
> **Phiên bản:** 2.0  
> **Trạng thái:** Bản cập nhật nghiệp vụ — dùng làm nguồn cho DD, API contract, database migration, UI/UX, test case và Codex/AI Agent.  
> **Ngày cập nhật:** 27/06/2026  
> **Thay thế:** Các nội dung Sale/giới thiệu trong BD-BIOAI-PRODUCT-FLOW-001.

---

## Kiểm soát thay đổi

| Hạng mục | Nội dung cập nhật |
|---|---|
| Sale | Loại bỏ toàn bộ logic hoa hồng theo cây nhiều tầng, bao gồm 10% tầng 1, 5% tầng 2, cây giới thiệu và các trường hợp đứt gãy chuỗi. |
| Sale mới | Chỉ áp dụng giới thiệu **trực tiếp**: một Sale giới thiệu một khách hàng; Sale nhận 10% giá trị thanh toán hợp lệ của khách hàng đó ở lần mua đầu và các kỳ thanh toán tiếp theo. |
| Phê duyệt | Thanh toán chỉ tạo quyền chờ duyệt. Sau khi Admin xác minh và duyệt, hệ thống mới cộng **Điểm Sale** cho Sale. |
| Admin | Bổ sung role Admin, dashboard View, module tính toán/đối soát, thống kê, quản trị người dùng/gói/Sale/thanh toán/điểm/hệ thống và audit log. |
| Độ chi tiết | Mở rộng mô tả module, trạng thái, dữ liệu, điều kiện, luồng chính, ngoại lệ, quyền hạn và tiêu chí chấp nhận. |
| Extension M20–M29 | Đăng ký tài liệu mở rộng `BD-BIOAI-ADVANCED-HEALTH-001` cho danh mục chức năng sức khỏe nâng cao. Thay đổi này chỉ tạo cross-reference, không thay baseline M01–M19. |

> **Quy tắc ưu tiên:** Khi BD cũ, code hiện tại hoặc tài liệu khác mâu thuẫn với tài liệu này, team phải dừng ở điểm mâu thuẫn, ghi issue và xin Product Owner xác nhận. Không được giữ lại logic Sale cũ chỉ để tương thích với code hiện có.

---

# Mục lục

1. Mục tiêu, phạm vi và nguyên tắc triển khai  
2. Thuật ngữ và quy ước  
3. Vai trò, mô hình quyền và trạng thái  
4. Danh mục module toàn hệ thống  
5. Ma trận quyền theo vai trò và gói thành viên  
6. Workflow chi tiết phía người dùng  
7. Module Sale — giới thiệu trực tiếp và Điểm Sale  
8. Module thanh toán, duyệt thanh toán và quyền gói  
9. Module điểm sức khỏe và theo dõi lịch trình  
10. Module FamilyPlus  
11. Role Admin và workflow quản trị  
12. Module tính toán, đối soát và thống kê  
13. Mô hình dữ liệu nghiệp vụ mức khái niệm  
14. Quy tắc kiểm soát, bảo mật và audit  
15. Ngoại lệ, xử lý lỗi nghiệp vụ và chống gian lận  
16. Tiêu chí chấp nhận  
17. Yêu cầu DD, test và cập nhật `.codex`  
18. Các đề xuất và câu hỏi bắt buộc cần Product Owner chốt  
Phụ lục A. Danh sách Use Case  
Phụ lục B. Danh sách trạng thái nghiệp vụ  
Phụ lục C. Hằng số/cấu hình cần quản lý

---

# 1. Mục tiêu, phạm vi và nguyên tắc triển khai

## 1.1. Mục tiêu

BioAI / NanoBio là hệ thống hỗ trợ người dùng xây dựng và theo dõi lịch trình sức khỏe cá nhân hóa. Người dùng có thể trải nghiệm giá trị cốt lõi trước khi đăng nhập, sau đó dùng các tính năng mở rộng theo gói thành viên. Hệ thống có thêm vai trò Sale để giới thiệu sản phẩm theo mô hình **hoa hồng trực tiếp, lặp lại theo các kỳ thanh toán hợp lệ của chính khách hàng được giới thiệu**.

Tài liệu này nhằm:

- Chuẩn hóa luồng từ Guest → đăng nhập → gói thành viên → sử dụng tính năng.
- Xác định ranh giới quyền của Guest, Free, Plus, FamilyPlus, Sale và Admin.
- Thay toàn bộ Sale logic cũ bằng mô hình giới thiệu trực tiếp 10%.
- Quy định điểm kiểm soát: thanh toán, xác minh Admin, cộng Điểm Sale, quy đổi Điểm Sale.
- Làm nguồn thống nhất để thiết kế DD, UI/UX, database, API, RLS, test case và tài liệu vận hành.

## 1.2. Phạm vi

BD này bao gồm:

- Onboarding và lưu dữ liệu đầu vào.
- AI tạo lịch trình: thực đơn, bài tập, mốc hoạt động và thông báo.
- Guest/V1, Free/V2, Plus/V3 và FamilyPlus.
- AI Chat, quota, lịch trình, điểm sức khỏe và FamilyPlus.
- Đăng ký/đăng nhập, gói thành viên, thanh toán và kích hoạt quyền.
- Sale trực tiếp, mã giới thiệu, điểm Sale, đối soát và quy đổi điểm.
- Vai trò Admin: View, quản lý, tính toán, phê duyệt, thống kê, cấu hình và audit.
- Kiểm soát quyền, dữ liệu cá nhân, chống trùng lặp và truy vết.

## 1.3. Ngoài phạm vi

Các nội dung sau cần BD/DD riêng trước khi coding chi tiết:

- Wireframe, UI kit và copywriting theo persona NaBi.
- Cổng thanh toán cụ thể, webhook nhà cung cấp và định dạng sao kê ngân hàng.
- Công thức y tế/chẩn đoán hoặc khuyến nghị điều trị.
- Chính sách thuế, hợp đồng cộng tác viên, điều kiện rút tiền và hồ sơ kế toán.
- RLS, schema vật lý, migration, endpoint và cơ chế mã hóa cụ thể.
- Quy tắc hoàn tiền/chargeback cuối cùng nếu Product Owner chưa chốt.

## 1.4. Nguyên tắc cứng

1. **Guest là allowlist đóng.** Guest chỉ dùng những chức năng ghi rõ trong BD; không được suy diễn quyền từ việc UI đang hiển thị.
2. **Gói và Sale là hai trục độc lập.** Có gói Plus không tự trở thành Sale; là Sale không tự có quyền Plus.
3. **Admin không chỉ là giao diện quản trị.** Mọi thao tác phê duyệt, điều chỉnh, tính toán và xuất báo cáo đều phải có quyền, dữ liệu nguồn và audit log.
4. **Không còn hoa hồng gián tiếp.** Không tạo, không hiển thị, không tính và không lưu nghiệp vụ hoa hồng tầng 2 hay sâu hơn.
5. **Không cộng Điểm Sale ngay khi khách bấm thanh toán.** Chỉ cộng sau khi có giao dịch hợp lệ và Admin duyệt.
6. **Không sửa trực tiếp bản ghi tài chính đã chốt.** Hoàn/hủy/điều chỉnh phải tạo bản ghi điều chỉnh có lý do và người thực hiện.
7. **Ẩn UI không thay thế cho kiểm soát quyền.** Route, use case, API và database policy phải đồng thời kiểm tra quyền.

---

# 2. Thuật ngữ và quy ước

| Thuật ngữ | Định nghĩa nghiệp vụ |
|---|---|
| Guest/V1 | Người dùng chưa đăng nhập. Có thể onboarding, nhận một lịch trình AI đầu tiên, dùng tính toán cơ bản và nhận thông báo lịch trình. |
| Member | Người dùng đã đăng nhập, được hệ thống xác định gói Free, Plus hoặc FamilyPlus. |
| Free/V2 | Gói cơ bản sau đăng nhập; có quota AI Chat và tạo lịch trình mới. |
| Plus/V3 | Gói nâng cao, kế thừa Free và mở các tính năng cá nhân hóa/theo dõi nâng cao. |
| FamilyPlus/V3 | Gói kế thừa Plus, hỗ trợ nhiều thành viên gia đình và dữ liệu riêng theo từng thành viên. |
| Sale | Người dùng có trạng thái Sale đang hoạt động, được cấp mã giới thiệu và được nhận Điểm Sale từ các thanh toán hợp lệ của khách do mình giới thiệu trực tiếp. |
| Khách được giới thiệu | Tài khoản đã gắn hợp lệ một mã Sale, tạo quan hệ giới thiệu trực tiếp với đúng một Sale. |
| Giới thiệu thành công | Khách được giới thiệu hoàn tất điều kiện đã chốt: có tài khoản hợp lệ, quan hệ giới thiệu hợp lệ và có thanh toán gói hợp lệ được Admin duyệt. |
| Điểm Sale | Đơn vị nội bộ ghi nhận hoa hồng của Sale. Điểm có thể được quy đổi thành tiền theo tỷ lệ/cấu hình được Admin quản lý và có lịch sử. |
| Hoa hồng Sale | Giá trị 10% tính từ khoản thanh toán đủ điều kiện của khách được Sale giới thiệu trực tiếp. Trong hệ thống, giá trị này được ghi nhận vào Điểm Sale sau khi Admin duyệt. |
| Kỳ thanh toán | Một lần khách hàng trả tiền cho gói, bao gồm mua mới, gia hạn hoặc thanh toán chu kỳ khác đã được cấu hình. |
| Thanh toán hợp lệ | Giao dịch có bằng chứng thanh toán, không bị từ chối/trùng/hủy/hoàn tại thời điểm duyệt và thỏa điều kiện của gói. |
| Duyệt thanh toán | Hành động Admin xác minh giao dịch trước khi kích hoạt quyền gói và cộng Điểm Sale. |
| Quyền hiệu lực | Tập quyền được dựng từ trạng thái đăng nhập + gói + trạng thái gói + trạng thái Sale + quyền Admin. |
| Audit log | Nhật ký bất biến mô tả ai đã làm gì, khi nào, trên dữ liệu nào, trước/sau thay đổi và lý do. |

> **Quy ước từ ngữ:** Trong tài liệu và màn hình nghiệp vụ, dùng “Hoa hồng Sale” hoặc “Điểm Sale”. Không gọi là “lương” trong logic hệ thống để tránh hiểu nhầm về bản chất của khoản chi trả. Product Owner/pháp chế quyết định cách diễn đạt cuối cùng trên hợp đồng hoặc chứng từ.

---

# 3. Vai trò, mô hình quyền và trạng thái

## 3.1. Các vai trò chính

| Vai trò | Mô tả | Giới hạn chính |
|---|---|---|
| Guest | Chưa đăng nhập; chỉ trải nghiệm giá trị cốt lõi V1. | Không dùng AI Chat, không tạo lại lịch trình, không quản lý Sale, không dùng dữ liệu FamilyPlus. |
| Member Free | Đã đăng nhập, gói Free đang hiệu lực. | Bị quota AI Chat và tạo lịch trình mới. |
| Member Plus | Gói Plus đang hiệu lực. | Không tự có quyền quản trị/Sale nếu không được cấp. |
| Chủ FamilyPlus | Tài khoản sở hữu hoặc được cấp quản lý một nhóm gia đình. | Chỉ quản lý thành viên thuộc nhóm của mình và trong phạm vi đồng ý chia sẻ. |
| Thành viên Family | Người được thêm vào FamilyPlus. | Chỉ xem/sửa dữ liệu theo quyền được chủ gói hoặc chính sách nhóm cấp. |
| Sale | Tài khoản có trạng thái Sale đang hoạt động. | Chỉ xem dữ liệu giới thiệu/hoa hồng của chính mình; không được duyệt thanh toán hay tự cộng điểm. |
| Admin | Người quản trị hệ thống được cấp quyền quản trị. | Chỉ thao tác trong phạm vi permission; bắt buộc audit log. |
| Super Admin | Cấp Admin cao nhất. | Quản lý permission, cấu hình cốt lõi và các thao tác đặc biệt có kiểm soát. |

## 3.2. Hai trục trạng thái của người dùng

| Trục | Giá trị | Dùng để quyết định |
|---|---|---|
| Quyền sản phẩm | Guest, Free, Plus, FamilyPlus | Các module sức khỏe, quota, lịch trình, AI Chat, Family. |
| Vai trò vận hành | Không phải Sale, Sale chờ duyệt, Sale hoạt động, Sale tạm dừng, Admin | Mã giới thiệu, điểm Sale, quyền quản trị và phê duyệt. |

Hệ thống **không được** dùng một trường duy nhất để suy ra toàn bộ quyền. Ví dụ: `subscription_tier = plus` không có nghĩa `sale_status = active`; `sale_status = active` không có nghĩa khách được bỏ quota Free.

## 3.3. Trạng thái gói thành viên

| Trạng thái | Ý nghĩa | Quyền hiệu lực |
|---|---|---|
| guest | Chưa có tài khoản hoặc chưa đăng nhập. | V1 allowlist. |
| free_active | Tài khoản Free đang dùng bình thường. | Free. |
| paid_pending_approval | Khách đã gửi thông tin thanh toán, Admin chưa duyệt. | Giữ quyền gói trước đó; chưa nâng quyền mới. |
| plus_active | Plus đang hiệu lực. | Plus. |
| familyplus_active | FamilyPlus đang hiệu lực. | FamilyPlus. |
| expired | Gói trả phí hết hạn. | Hạ về Free hoặc trạng thái Product Owner quy định. |
| suspended | Tạm ngưng theo chính sách/vi phạm/thanh toán bất thường. | Chặn hoặc giới hạn theo lý do. |
| cancelled | Người dùng hoặc Admin đã hủy gói. | Quyền sau hủy theo chính sách chốt. |

## 3.4. Trạng thái Sale đề xuất

| Trạng thái | Ý nghĩa | Hành vi |
|---|---|---|
| none | Tài khoản chưa đăng ký/chưa được cấp Sale. | Không có mã giới thiệu, không có module Sale. |
| pending_review | Đã gửi yêu cầu trở thành Sale, chờ Admin xét duyệt. | Được xem trạng thái hồ sơ; chưa giới thiệu/nhận điểm. |
| active | Sale được kích hoạt. | Có mã giới thiệu, xem dashboard Sale và nhận Điểm Sale sau duyệt giao dịch. |
| suspended | Tạm dừng do kiểm tra, vi phạm hoặc theo quyết định Admin. | Không tạo quan hệ giới thiệu mới; khoản cũ xử lý theo chính sách. |
| closed | Chấm dứt vai trò Sale. | Không tạo mới; dữ liệu lịch sử được giữ để đối soát. |

> Trạng thái `pending_review`, `suspended`, `closed` là cấu trúc vận hành đề xuất. Product Owner cần chốt điều kiện đăng ký, điều kiện duyệt và quyền của Sale khi bị tạm dừng.

---

# 4. Danh mục module toàn hệ thống

| Mã | Module | Actor chính | Mục đích |
|---|---|---|---|
| M01 | Onboarding & Hồ sơ sức khỏe | Guest, Member | Thu thập đầu vào để cá nhân hóa. |
| M02 | AI Lịch trình cá nhân | Guest, Member | Sinh/thay đổi thực đơn, bài tập và mốc hoạt động. |
| M03 | Dashboard & Thực hiện lịch trình | Guest, Member, Family | Hiển thị việc cần làm, đánh dấu thực hiện và theo dõi tiến độ. |
| M04 | Tính toán sức khỏe cơ bản | Guest, Member | Cung cấp công cụ tính toán nền tảng theo dữ liệu người dùng nhập. |
| M05 | Xác thực, hồ sơ và đồng bộ | Guest, Member | Đăng ký/đăng nhập, liên kết dữ liệu local-cloud và dựng quyền. |
| M06 | Gói thành viên & quota | Member, Admin | Quản lý Free/Plus/FamilyPlus, entitlement và giới hạn dùng. |
| M07 | AI Chat | Free, Plus, FamilyPlus | Hỏi đáp AI theo gói và quota. |
| M08 | Điểm sức khỏe & thói quen | Free, Plus, FamilyPlus | Tính điểm theo lịch sử thực hiện lịch trình. |
| M09 | Thông báo lịch trình | Guest, Member, Family | Nhắc theo ngày/mốc thời gian. |
| M10 | Theo dõi nâng cao & mục tiêu | Plus, FamilyPlus | Theo dõi và lập lộ trình theo mục tiêu. |
| M11 | FamilyPlus | FamilyPlus | Quản lý nhiều thành viên và lịch trình riêng. |
| M12 | Sale & mã giới thiệu | Sale, Member, Admin | Đăng ký Sale, mã giới thiệu, quan hệ giới thiệu trực tiếp. |
| M13 | Thanh toán & xác minh | Member, Admin | Ghi nhận thanh toán, duyệt gói, hoàn/hủy và lịch sử. |
| M14 | Điểm Sale & quy đổi | Sale, Admin | Cộng điểm từ hoa hồng, đối soát, quy đổi điểm thành tiền. |
| M15 | Admin View / Dashboard | Admin | Quan sát toàn bộ vận hành dự án theo quyền. |
| M16 | Admin quản lý hệ thống | Admin, Super Admin | Quản trị người dùng, gói, Sale, nội dung, cấu hình, thông báo. |
| M17 | Tính toán & đối soát | Admin | Tính/quét dữ liệu gói, hoa hồng, điểm, quota và sai lệch. |
| M18 | Thống kê & báo cáo | Admin | Báo cáo sản phẩm, doanh thu, Sale, vận hành và xuất dữ liệu. |
| M19 | Audit, bảo mật & hỗ trợ | Admin, Super Admin | Theo dõi thay đổi, xử lý ticket/vi phạm và kiểm soát truy cập. |

## 4.1. Extension Registry — M20–M29

M20–M29 được đặc tả trong tài liệu riêng [BD — Danh mục chức năng sức khỏe nâng cao M20–M29](../advanced_health/BD_BioAI_Advanced_Health_Features_v1.0.md) (`BD-BIOAI-ADVANCED-HEALTH-001`). Registry này không thay thế hoặc làm giảm hiệu lực của M01–M19.

| Dải module | Tài liệu nguồn | Trạng thái | Phạm vi được phê duyệt |
|---|---|---|---|
| M20–M29 | `docs/BD/advanced_health/BD_BioAI_Advanced_Health_Features_v1.0.md` | `Draft - UI catalog shell approved` | Tên/thứ tự/tier của 10 catalog item và trang thông báo đang phát triển; DD và nghiệp vụ đầy đủ chưa được phê duyệt/coding. |

---

# 5. Ma trận quyền theo vai trò và gói

| Chức năng | Guest | Free | Plus | FamilyPlus | Sale active | Admin |
|---|---:|---:|---:|---:|---:|---:|
| Onboarding cá nhân | Có | Có | Có | Có | Theo gói | Xem/quản trị theo quyền |
| Sinh lịch trình AI đầu tiên | 1 lần | Có | Có | Có | Theo gói | Có thể hỗ trợ/kiểm tra |
| Sinh lịch trình AI mới | Không | 3 lần/tháng | Không giới hạn | Không giới hạn | Theo gói | Cấu hình/đối soát |
| Xem lịch trình đang có | Có | Có | Có | Có | Theo gói | Theo quyền hỗ trợ |
| Tính toán sức khỏe cơ bản | Có | Có | Có | Có | Theo gói | Quản lý cấu hình |
| AI Chat | Không | 3 lượt/ngày | Không giới hạn | Không giới hạn | Theo gói | Quản lý/giám sát |
| Điểm sức khỏe/thói quen | Không | Có | Có | Có | Theo gói | Xem báo cáo/điều chỉnh theo chính sách |
| Theo dõi nâng cao/mục tiêu | Không | Không | Có | Có | Theo gói | Cấu hình/giám sát |
| Quản lý gia đình | Không | Không | Không | Có | Theo gói | Hỗ trợ theo quyền |
| Đăng ký/hoạt động Sale | Không | Có nếu đủ điều kiện | Có nếu đủ điều kiện | Có nếu đủ điều kiện | Có | Duyệt/quản lý |
| Gắn mã giới thiệu | Trong lúc tạo tài khoản theo policy | Theo policy | Theo policy | Theo policy | Theo policy | Kiểm tra/điều chỉnh có audit |
| Xem dashboard Sale cá nhân | Không | Nếu Sale active | Nếu Sale active | Nếu Sale active | Có | Có |
| Duyệt thanh toán | Không | Không | Không | Không | Không | Có quyền Finance/Admin |
| Cộng/điều chỉnh Điểm Sale | Không | Không | Không | Không | Không | Có quyền Finance/Admin |
| View toàn dự án | Không | Không | Không | Không | Không | Có |
| Cấu hình hệ thống | Không | Không | Không | Không | Không | Super Admin hoặc quyền tương đương |

> **Ghi chú:** “Theo gói” nghĩa Sale vẫn chỉ được dùng các chức năng sức khỏe theo gói thành viên của chính Sale. Role Sale không tăng quota AI Chat, không mở FamilyPlus và không tự có quyền xem dữ liệu sức khỏe của người được giới thiệu.

---

# 6. Workflow chi tiết phía người dùng

## M01 — Onboarding & Hồ sơ sức khỏe

### Mục đích
Thu thập thông tin tối thiểu cần thiết để AI tạo lịch trình cá nhân và để các module tính toán/theo dõi dùng đúng dữ liệu.

### Dữ liệu đầu vào tối thiểu
- Thông tin cơ bản: tên hiển thị, năm sinh/nhóm tuổi, giới tính nếu sản phẩm cần.
- Chỉ số cơ thể: chiều cao, cân nặng và đơn vị.
- Mục tiêu: duy trì, giảm/tăng cân, vận động, dinh dưỡng hoặc mục tiêu được duyệt.
- Lối sống: mức vận động, giờ sinh hoạt, sở thích/không phù hợp trong ăn uống nếu có.
- Dữ liệu sức khỏe tự khai báo trong phạm vi sản phẩm cho phép.
- Đồng ý điều khoản xử lý dữ liệu cần thiết.

### Luồng chính
1. Người dùng mở ứng dụng lần đầu.
2. Hệ thống xác định người dùng là Guest hoặc Member chưa có onboarding hoàn tất.
3. Hệ thống hiển thị từng bước onboarding, kiểm tra dữ liệu bắt buộc và định dạng.
4. Người dùng xác nhận thông tin tại màn tổng rà soát.
5. Hệ thống lưu hồ sơ onboarding theo định danh Guest local hoặc tài khoản Member.
6. Hệ thống đánh dấu onboarding hoàn tất.
7. Hệ thống chuyển sang M02 để sinh lịch trình lần đầu.

### Ngoại lệ
- Dữ liệu thiếu/sai định dạng: không cho qua bước; chỉ rõ trường cần sửa.
- Người dùng thoát giữa chừng: lưu nháp cục bộ nếu thiết kế cho phép; không đánh dấu hoàn tất.
- Thành viên FamilyPlus: phải chọn đúng hồ sơ thành viên đang onboarding, không ghi đè dữ liệu của người khác.
- Người dùng không đồng ý điều khoản bắt buộc: không tạo lịch trình có sử dụng dữ liệu đó; UX xử lý theo chính sách được phê duyệt.

### Kết quả
Hồ sơ onboarding hợp lệ trở thành nguồn đầu vào cho AI và các module tính toán.

---

## M02 — AI Lịch trình cá nhân

### Mục đích
Tạo lịch trình gồm thực đơn, bài tập và các mốc hoạt động phù hợp dữ liệu đầu vào.

### Luồng Guest lần đầu
1. Guest hoàn tất M01.
2. Hệ thống kiểm tra cờ `guest_initial_plan_used`.
3. Nếu chưa dùng: tạo yêu cầu AI từ dữ liệu onboarding.
4. AI trả kết quả có cấu trúc: thực đơn, bài tập, mốc/lịch theo ngày.
5. Hệ thống kiểm tra cấu trúc, chuẩn hóa nội dung, lưu lịch trình.
6. Hệ thống tạo các mục lịch trình và lịch thông báo.
7. Hệ thống đánh dấu Guest đã dùng lần tạo đầu tiên.
8. Dashboard hiển thị lịch trình.

### Luồng Member tạo lịch trình mới
1. Member chọn tạo/điều chỉnh lịch trình.
2. Hệ thống xác định gói và quota.
3. Nếu Free: kiểm tra số lượt tạo trong kỳ tháng; trong giới hạn thì cho tạo.
4. Nếu Plus/FamilyPlus: cho tạo không giới hạn theo BD hiện hành.
5. Người dùng nhập/chọn mục tiêu và dữ liệu cần cập nhật.
6. Hệ thống gọi AI, kiểm tra kết quả và lưu thành một phiên bản lịch trình mới.
7. Người dùng chọn áp dụng ngay hoặc giữ lịch trình cũ nếu sản phẩm hỗ trợ.
8. Hệ thống tạo/cập nhật thông báo cho lịch trình đang hiệu lực.

### Quy tắc
- Lịch trình phải gắn với đúng một người: người dùng cá nhân hoặc thành viên gia đình.
- Không ghi đè lịch sử thực hiện của lịch trình cũ khi sinh lịch trình mới.
- Mỗi lần tạo phải có `request_id` để chống gọi lặp và đếm quota sai.
- Nếu AI thất bại trước khi sinh kết quả hợp lệ, không trừ quota; nếu có cơ chế retry phải idempotent.
- Guest đã dùng lần đầu yêu cầu tạo thêm phải được đưa đến đăng nhập, không chỉ ẩn nút.

### Ngoại lệ
- AI trả thiếu thành phần bắt buộc: hệ thống thử xử lý/fallback theo thiết kế kỹ thuật; không công bố lịch trình không hợp lệ.
- Mất mạng khi gọi AI: báo trạng thái rõ ràng, cho thử lại; không tạo bản ghi trùng.
- Member Free vượt quota: chặn ở UI, use-case và API; hiển thị kỳ reset/nâng cấp theo UX.

---

## M03 — Dashboard & Thực hiện lịch trình

### Mục đích
Cho người dùng xem hoạt động hiện tại, đánh dấu thực hiện và theo dõi tiến độ.

### Chức năng
- Xem lịch hôm nay/theo ngày.
- Xem thực đơn, bài tập, mốc việc cần làm.
- Đánh dấu: hoàn thành, bỏ qua hoặc trạng thái được phê duyệt.
- Xem lịch sử đã làm/chưa làm.
- Cập nhật dashboard theo đúng hồ sơ đang chọn.
- Với FamilyPlus: chuyển ngữ cảnh giữa các thành viên có quyền.

### Luồng đánh dấu thực hiện
1. Người dùng mở một mục lịch trình.
2. Hệ thống xác định người dùng có quyền thao tác với hồ sơ đó.
3. Người dùng chọn trạng thái thực hiện.
4. Hệ thống ghi nhận thời điểm, trạng thái, nguồn thao tác và ghi chú nếu có.
5. Hệ thống cập nhật tiến độ ngày.
6. Nếu là Member, đưa dữ liệu đầu vào cho M08 tính điểm sức khỏe.
7. Dashboard và thông báo tiếp theo được cập nhật theo quy tắc.

### Quy tắc
- Mọi thay đổi trạng thái phải lưu lịch sử; không chỉ cập nhật một cờ cuối cùng.
- Không cho người dùng thao tác lịch trình của người khác ngoài phạm vi FamilyPlus được cấp.
- Nếu người dùng sửa trạng thái sau khi điểm đã tính, hệ thống phải đánh dấu dữ liệu cần tính lại hoặc xử lý điều chỉnh minh bạch.

---

## M04 — Tính toán sức khỏe cơ bản

### Mục đích
Cung cấp các phép tính cơ bản theo dữ liệu người dùng nhập; Guest được dùng module này.

### Chức năng nghiệp vụ
- Nhập chỉ số cần tính.
- Kiểm tra đơn vị và phạm vi dữ liệu.
- Tính kết quả theo công thức đã được Product Owner/chuyên môn phê duyệt.
- Giải thích kết quả trong phạm vi thông tin tham khảo, không thay thế tư vấn y tế.
- Lưu lịch sử tính toán đối với Member nếu người dùng cho phép.

### Luồng
1. Người dùng chọn công cụ tính.
2. Hệ thống hiển thị dữ liệu có thể điền sẵn từ onboarding và cho phép chỉnh.
3. Người dùng xác nhận.
4. Hệ thống kiểm tra hợp lệ, thực hiện công thức.
5. Hiển thị kết quả và hướng dẫn phù hợp với mức độ sản phẩm.
6. Member có thể lưu lịch sử; Guest chỉ dùng trong phiên/cục bộ theo thiết kế.

### Lưu ý
Danh sách công cụ và công thức cụ thể là tài liệu chuyên môn riêng. Admin chỉ quản lý phiên bản công thức/cấu hình nếu Product Owner cho phép, không được tự sửa công thức trong production mà không có version và phê duyệt.

---

## M05 — Xác thực, hồ sơ và đồng bộ Guest → Member

### Mục đích
Tạo tài khoản, xác thực người dùng và xử lý dữ liệu đã tạo khi còn Guest.

### Luồng đăng ký/đăng nhập
1. Guest chọn đăng ký hoặc đăng nhập.
2. Hệ thống xác thực qua Supabase Auth hoặc phương án được phê duyệt.
3. Hệ thống lấy/tạo hồ sơ ứng dụng liên kết với `auth_user_id`.
4. Hệ thống truy vấn gói hiện hành, trạng thái Sale và các quyền liên quan.
5. Hệ thống dựng quyền hiệu lực.
6. Nếu có dữ liệu Guest local, hệ thống hiển thị/hỏi theo chính sách đồng bộ đã chốt.
7. Hệ thống chuyển đến dashboard phù hợp.

### Luồng gắn mã giới thiệu
1. Người dùng nhập mã giới thiệu tại đúng thời điểm được cho phép.
2. Hệ thống kiểm tra mã tồn tại, Sale sở hữu mã đang active và người dùng chưa có quan hệ giới thiệu khóa.
3. Hệ thống chống tự giới thiệu, trùng định danh hoặc quan hệ bất thường.
4. Hệ thống lưu quan hệ giới thiệu trực tiếp ở trạng thái hợp lệ/chờ xác thực tùy chính sách.
5. Sau khi lưu thành công, mã không được đổi tự do; mọi chỉnh sửa đặc biệt do Admin xử lý có audit.

### Quy tắc
- Đồng bộ Guest → Member không được làm mất lịch trình đầu tiên/hồ sơ hợp lệ.
- Không tạo hai hồ sơ ứng dụng cho cùng một `auth_user_id`.
- Không lấy quyền từ dữ liệu local; quyền cuối cùng phải xác định tại nguồn server tin cậy sau đăng nhập.
- Không gắn mã giới thiệu sau khi khách đã phát sinh giao dịch đầu tiên, trừ khi Product Owner cho phép bằng quy tắc rõ ràng.

---

## M06 — Gói thành viên & quota

### Mục đích
Dựng và áp quyền theo Free, Plus, FamilyPlus; kiểm soát các giới hạn dùng.

### Luồng dựng quyền hiệu lực
1. Người dùng đăng nhập hoặc ứng dụng cần kiểm tra quyền.
2. Hệ thống lấy trạng thái gói, ngày hiệu lực, ngày hết hạn và thông tin Family nếu có.
3. Hệ thống kiểm tra gói còn hoạt động.
4. Hệ thống tạo tập entitlement.
5. Hệ thống bổ sung quyền Sale/Admin độc lập nếu có.
6. UI, route, use-case, API sử dụng cùng tập entitlement này.

### Quota bắt buộc
| Quota | Đối tượng | Chu kỳ | Ngưỡng | Khi vượt |
|---|---|---|---|---|
| AI Chat | Free | Ngày theo múi giờ hệ thống chốt | 3 lượt hỏi/ngày | Chặn yêu cầu mới; thông báo quota và điểm nâng cấp. |
| Tạo lịch trình mới | Free | Tháng theo múi giờ hệ thống chốt | 3 lần/tháng | Chặn yêu cầu mới; không gọi AI. |
| Tạo lịch trình lần đầu | Guest | Vòng đời Guest theo chính sách kỹ thuật | 1 lần | Yêu cầu đăng nhập trước khi tạo lại. |
| AI Chat/tạo lịch trình | Plus, FamilyPlus | Không giới hạn trong BD hiện tại | Không giới hạn | Không chặn vì quota gói; vẫn áp dụng rate limit kỹ thuật/an toàn. |

### Quy tắc
- Quota tăng **sau khi** use-case thành công, không tăng khi request bị lỗi/timeout trước kết quả hợp lệ.
- Quota có dữ liệu nguồn, kỳ tính và audit để có thể đối soát.
- Chuyển gói từ Free lên Plus có hiệu lực sau khi thanh toán được Admin duyệt.
- Khi gói hết hạn, hệ thống áp quyền mới ở lần kiểm tra tiếp theo; không chỉ dựa vào UI cache.

---

## M07 — AI Chat

### Mục đích
Cho phép Member hỏi đáp AI trong phạm vi sản phẩm.

### Luồng
1. Member mở AI Chat.
2. Hệ thống kiểm tra đăng nhập, entitlement và quota.
3. Free còn quota hoặc Plus/FamilyPlus đủ quyền: cho gửi câu hỏi.
4. Hệ thống ghi nhận yêu cầu AI với `request_id`.
5. AI phản hồi; hệ thống hiển thị nội dung an toàn theo quy tắc sản phẩm.
6. Nếu phản hồi được ghi nhận thành công, quota Free tăng một lượt.
7. Lịch sử chat được lưu/đồng bộ theo chính sách bảo mật.

### Quy tắc
- Một “lượt hỏi” cần được chốt rõ ở mục câu hỏi; mặc định đề xuất là một yêu cầu AI hoàn tất có phản hồi.
- Không cho Guest truy cập AI Chat qua deep link/API.
- Admin có thể xem số liệu tổng hợp, không mặc định đọc nội dung sức khỏe riêng tư của người dùng nếu không có quyền/chính sách hỗ trợ rõ ràng.

---

## M08 — Điểm sức khỏe & thói quen

### Mục đích
Đánh giá mức độ duy trì lịch trình của Member, dựa trên dữ liệu thực hiện thực tế.

### Luồng
1. Người dùng cập nhật trạng thái từng mục lịch trình tại M03.
2. Hệ thống lưu sự kiện thực hiện.
3. Job hoặc use-case tính điểm lấy dữ liệu trong kỳ.
4. Hệ thống áp công thức đã được phê duyệt: mức hoàn thành, tính đều đặn, dữ liệu bỏ qua, quy tắc ngoại lệ.
5. Hệ thống lưu điểm tổng, chi tiết nguồn dữ liệu và phiên bản công thức.
6. Dashboard hiển thị điểm/tiến độ cho đúng hồ sơ.
7. Nếu dữ liệu bị sửa, hệ thống tính lại hoặc tạo điều chỉnh theo quy tắc.

### Quy tắc
- Không dùng điểm sức khỏe để suy ra tình trạng bệnh hoặc đưa ra chẩn đoán.
- Công thức phải version hóa; Admin không thay đổi số điểm lịch sử bằng cách ghi đè không truy vết.
- FamilyPlus phải tách điểm từng thành viên; không gộp nhầm vào chủ gói.

---

## M09 — Thông báo lịch trình

### Mục đích
Nhắc người dùng theo từng mốc của lịch trình hiện hành.

### Luồng
1. Lịch trình được tạo hoặc người dùng thay đổi giờ/mốc.
2. Hệ thống tạo/cập nhật danh sách nhắc.
3. Hệ thống kiểm tra quyền notification của thiết bị.
4. Đến thời điểm phù hợp, hệ thống gửi thông báo.
5. Người dùng mở thông báo; hệ thống deep link đến đúng mục lịch trình/hồ sơ có quyền.
6. Người dùng hoàn thành/bỏ qua hoạt động; hệ thống cập nhật M03/M08.

### Quy tắc
- Guest vẫn nhận thông báo của lịch trình đầu tiên.
- Khi thay lịch trình, các nhắc cũ không còn hiệu lực phải được hủy/đánh dấu thay thế.
- FamilyPlus không gửi nhắc hoặc lộ dữ liệu của thành viên khác trái với quyền đồng ý/chính sách.

---

## M10 — Theo dõi nâng cao & mục tiêu (Plus/FamilyPlus)

### Mục đích
Cung cấp lộ trình và theo dõi nâng cao cho người dùng trả phí.

### Chức năng
- Tạo nhiều mục tiêu theo từng giai đoạn.
- Tạo lộ trình riêng cho mục tiêu.
- Theo dõi chỉ số/tiến độ nâng cao theo danh mục được phê duyệt.
- So sánh lịch sử và đưa gợi ý trong phạm vi sản phẩm.
- Điều chỉnh lịch trình theo mục tiêu và phản hồi người dùng.

### Luồng
1. Plus/FamilyPlus chọn mục tiêu.
2. Hệ thống kiểm tra entitlement.
3. Người dùng cập nhật dữ liệu đầu vào.
4. Hệ thống sinh/điều chỉnh lộ trình.
5. Lộ trình mới được liên kết với mục tiêu, hồ sơ đúng người và thông báo tương ứng.
6. Dashboard hiển thị tiến độ theo mục tiêu.

---

# 7. M12 — Module Sale: giới thiệu trực tiếp và Điểm Sale

## 7.1. Mục tiêu và ranh giới

Module Sale cho phép người có quyền Sale giới thiệu ứng dụng/gói thành viên. Mỗi khách được gắn tối đa một Sale giới thiệu trực tiếp. Sale nhận **10%** giá trị của mỗi khoản thanh toán hợp lệ do chính khách đó thanh toán, bao gồm mua lần đầu và các kỳ thanh toán tiếp theo, miễn là quan hệ giới thiệu còn hợp lệ theo chính sách.

### Quy tắc loại bỏ hoàn toàn
- Không có hoa hồng tầng 2, tầng 3 hoặc bất kỳ hoa hồng gián tiếp nào.
- Không tạo cây Sale để phân chia hoa hồng.
- Không hiển thị “người được giới thiệu của người được giới thiệu”.
- Không thưởng vì Sale mà khách giới thiệu trở thành Sale.
- Không có tỷ lệ 5% trong mô hình Sale này.

## 7.2. Điều kiện trở thành Sale

Điều kiện chính thức cần Product Owner chốt. Luồng đề xuất để vận hành an toàn:

1. Member vào “Đăng ký trở thành Sale”.
2. Hệ thống hiển thị điều kiện, chính sách, thông tin nhận quy đổi Điểm Sale và cam kết cần thiết.
3. Member gửi yêu cầu.
4. Hệ thống tạo trạng thái `pending_review`.
5. Admin kiểm tra hồ sơ và chọn duyệt/từ chối.
6. Nếu duyệt: trạng thái chuyển `active`, sinh/cấp mã giới thiệu duy nhất.
7. Nếu từ chối: lưu lý do hiển thị phù hợp cho người dùng.
8. Sale active thấy Dashboard Sale.

> Nếu Product Owner muốn tự động kích hoạt Sale không cần duyệt, phải ghi thành quy tắc riêng; hệ thống vẫn cần điều kiện chống gian lận và cơ chế khóa Sale.

## 7.3. Mã giới thiệu

### Yêu cầu
- Mỗi Sale active có ít nhất một mã giới thiệu hợp lệ, duy nhất toàn hệ thống.
- Mã có thể là mã cố định; nếu cho phép đổi mã phải giữ lịch sử và không làm thay đổi quan hệ đã gắn.
- Khách chỉ được gắn tối đa một mã giới thiệu.
- Không cho Sale dùng chính mã của mình; không cho gắn giữa các tài khoản cùng định danh bị hệ thống coi là trùng/bất thường.
- Mã chỉ có hiệu lực khi Sale active.
- Gắn mã sau thanh toán đầu tiên bị chặn, trừ quy trình Admin đặc biệt có lý do/audit.

## 7.4. Luồng gắn quan hệ giới thiệu trực tiếp

1. Khách tạo tài khoản hoặc đến bước nhập mã theo UX được phê duyệt.
2. Khách nhập mã Sale.
3. Hệ thống kiểm tra:
   - mã tồn tại;
   - Sale sở hữu mã active;
   - khách chưa bị khóa quan hệ giới thiệu;
   - không tự giới thiệu;
   - không vi phạm quy tắc chống trùng/gian lận;
   - không có thanh toán gói hợp lệ trước đó.
4. Hệ thống tạo `referral_relationship` gồm: Sale, khách, mã, thời điểm gắn, nguồn gắn và trạng thái.
5. Hệ thống trả kết quả thành công/không thành công; không tiết lộ dữ liệu nhạy cảm của Sale.
6. Quan hệ này trở thành dữ liệu nguồn cho M14 khi khách có thanh toán được Admin duyệt.

## 7.5. Định nghĩa giới thiệu thành công

Một quan hệ giới thiệu được coi là phát sinh hoa hồng khi **đồng thời** có đủ:

1. Quan hệ giới thiệu trực tiếp hợp lệ và chưa bị vô hiệu.
2. Khách có thanh toán gói hợp lệ.
3. Khoản thanh toán không phải bản ghi trùng, giả, đã hủy hoặc bị hoàn tại thời điểm duyệt.
4. Admin đã duyệt thanh toán.
5. Hệ thống tính được 10% trên giá trị thanh toán đủ điều kiện.
6. Hệ thống cộng Điểm Sale thành công, không trùng lần xử lý.

> Việc khách chỉ cài app, onboarding, đăng ký tài khoản hoặc nhập mã **chưa** làm Sale nhận Điểm Sale.

## 7.6. Luồng thanh toán lặp lại và hoa hồng 10%

### Luồng chuẩn
1. Khách do Sale A giới thiệu chọn mua/gia hạn gói.
2. Hệ thống tạo bản ghi thanh toán ở trạng thái chờ xác minh.
3. Admin xác minh giao dịch.
4. Admin duyệt thanh toán.
5. Hệ thống kích hoạt/gia hạn gói cho khách.
6. Hệ thống tìm quan hệ giới thiệu trực tiếp hợp lệ của khách.
7. Hệ thống tính hoa hồng: `điểm/quyền lợi Sale = 10% × giá trị thanh toán đủ điều kiện`.
8. Hệ thống tạo bản ghi hoa hồng/Điểm Sale liên kết duy nhất với giao dịch.
9. Hệ thống cộng Điểm Sale cho A.
10. Sale A nhìn thấy giao dịch ở trạng thái “đã duyệt/đã cộng điểm”.
11. Quy trình lặp lại ở mỗi lần khách tiếp tục thanh toán, chừng nào quan hệ giới thiệu và giao dịch còn hợp lệ.

### Ví dụ
- Sale A giới thiệu khách B.
- B mua gói với khoản thanh toán hợp lệ là `X`.
- Admin duyệt.
- A nhận Điểm Sale tương ứng `10% × X`.
- Tháng sau B gia hạn gói và thanh toán khoản hợp lệ `Y`.
- Admin duyệt.
- A tiếp tục nhận Điểm Sale tương ứng `10% × Y`.

Không có bất kỳ cá nhân nào khác nhận hoa hồng từ thanh toán của B.

## 7.7. Giá trị dùng để tính 10%

Giá trị tính hoa hồng phải được Product Owner chốt. Quy tắc đề xuất:

- Dùng **số tiền thực thu hợp lệ** của giao dịch sau khuyến mại/chiết khấu hợp lệ.
- Không tính phí bị hoàn, giao dịch lỗi, giao dịch bị từ chối hoặc giao dịch trùng.
- Thuế, phí cổng thanh toán, voucher, credit nội bộ có được tính hay không phải là cấu hình/điều khoản chốt rõ.
- Hệ thống phải lưu `commission_rate = 10%` và `commission_base_amount` ngay tại thời điểm tạo bản ghi để bảo toàn lịch sử khi cấu hình tương lai thay đổi.

## 7.8. Trạng thái giao dịch hoa hồng/Điểm Sale

| Trạng thái | Ý nghĩa | Ai tác động |
|---|---|---|
| pending_payment_verification | Khách đã gửi thông tin thanh toán; chưa được Admin duyệt. | System/Admin |
| payment_rejected | Admin xác minh và từ chối thanh toán. | Admin |
| payment_approved | Admin đã duyệt thanh toán; có thể kích hoạt gói và tính điểm. | Admin |
| commission_calculating | Hệ thống đang xử lý tạo Điểm Sale. | System |
| points_credited | Điểm Sale đã cộng thành công. | System |
| points_reversed | Điểm đã bị đảo do hoàn/hủy/gian lận; tạo bản ghi điều chỉnh. | System/Admin theo policy |
| conversion_pending | Sale yêu cầu quy đổi điểm thành tiền, chờ xử lý. | Sale/Admin |
| conversion_approved | Quy đổi điểm đã được Admin duyệt. | Admin |
| conversion_paid | Khoản quy đổi đã chi trả/xác nhận chi trả. | Admin |
| conversion_rejected | Yêu cầu quy đổi bị từ chối. | Admin |

## 7.9. Dashboard Sale

### Sale được xem
- Trạng thái Sale và lý do nếu bị tạm dừng/từ chối.
- Mã giới thiệu và cách chia sẻ.
- Số khách trực tiếp đã gắn mã hợp lệ.
- Số khách đã thanh toán được duyệt.
- Điểm Sale theo: chờ duyệt, đã cộng, đã quy đổi, bị điều chỉnh.
- Lịch sử từng giao dịch: ngày, gói, giá trị hoa hồng/điểm, trạng thái, lý do từ chối/điều chỉnh nếu được phép hiển thị.
- Yêu cầu quy đổi điểm và trạng thái xử lý.

### Sale không được xem
- Thông tin sức khỏe, lịch trình, nội dung chat, dữ liệu gia đình hoặc dữ liệu nhạy cảm của khách được giới thiệu.
- Toàn bộ dữ liệu thanh toán thô không cần thiết.
- Dữ liệu Sale khác.
- Quyết định/ghi chú nội bộ của Admin ngoài phần được phép công bố.

## 7.10. Quy đổi Điểm Sale thành tiền

### Luồng đề xuất
1. Sale mở ví Điểm Sale.
2. Hệ thống hiển thị số điểm khả dụng, điểm đang chờ duyệt, điểm đã quy đổi và tỷ lệ quy đổi đang hiệu lực.
3. Sale nhập số điểm muốn quy đổi, trong giới hạn tối thiểu/tối đa nếu có.
4. Hệ thống kiểm tra:
   - Sale active;
   - đủ số điểm khả dụng;
   - thông tin nhận tiền hợp lệ;
   - không có cờ rủi ro/khóa quy đổi.
5. Hệ thống tạo yêu cầu `conversion_pending`, đồng thời giữ số điểm đó để không yêu cầu trùng.
6. Admin đối soát, duyệt hoặc từ chối.
7. Nếu duyệt: hệ thống tạo chứng từ/lịch sử quy đổi, giảm điểm khả dụng theo số điểm đã chốt.
8. Sau khi xác nhận chi trả: chuyển `conversion_paid`.
9. Nếu từ chối: giải phóng số điểm đã giữ và lưu lý do.

### Quy tắc
- Tỷ lệ quy đổi điểm → tiền phải nằm trong cấu hình version hóa, có thời điểm hiệu lực.
- Không xóa bản ghi điểm hay quy đổi sau khi tạo; sửa bằng nghiệp vụ điều chỉnh.
- Chỉ điểm ở trạng thái `points_credited` và chưa bị khóa/đảo mới được quy đổi.
- Ngưỡng tối thiểu, lịch quy đổi, thông tin nhận tiền và thuế là các điểm cần chốt.

---

# 8. M13 — Module thanh toán, xác minh và quyền gói

## 8.1. Mục đích
Ghi nhận giao dịch mua/gia hạn, xác minh qua Admin và chỉ kích hoạt quyền cũng như Điểm Sale sau khi duyệt.

## 8.2. Luồng thanh toán của khách

1. Member chọn gói Plus/FamilyPlus hoặc gia hạn.
2. Hệ thống hiển thị giá, chu kỳ, lợi ích, điều kiện và phương thức thanh toán.
3. Người dùng tạo yêu cầu thanh toán.
4. Hệ thống tạo bản ghi `payment_pending`.
5. Người dùng hoàn tất thao tác thanh toán/gửi bằng chứng theo phương thức.
6. Hệ thống gắn thông tin đối soát, tránh trùng `transaction_reference`.
7. Admin thấy giao dịch trong hàng chờ duyệt.
8. Admin kiểm tra thông tin.
9. Nếu duyệt:
   - giao dịch chuyển `approved`;
   - entitlement gói được tạo/gia hạn;
   - nếu có quan hệ Sale trực tiếp hợp lệ, tạo/cộng Điểm Sale;
   - gửi thông báo cho khách và Sale.
10. Nếu từ chối:
   - giao dịch chuyển `rejected`;
   - không kích hoạt quyền mới;
   - không cộng Điểm Sale;
   - gửi lý do ở mức phù hợp cho khách.
11. Nếu hoàn/hủy sau duyệt:
   - cập nhật trạng thái giao dịch;
   - điều chỉnh quyền gói theo chính sách;
   - tạo điều chỉnh/đảo Điểm Sale theo chính sách;
   - mọi bước có audit.

## 8.3. Quy tắc kích hoạt gói

- Không kích hoạt Plus/FamilyPlus chỉ vì khách tạo yêu cầu thanh toán.
- Chỉ `payment_approved` mới làm quyền gói hiệu lực.
- Gói phải có thời gian bắt đầu/kết thúc rõ ràng.
- Gia hạn không được tạo nhiều entitlement chồng chéo sai; cần có chính sách cộng dồn/kế thừa.
- Chuyển Plus ↔ FamilyPlus cần xác định rõ cách xử lý thời gian còn lại, số tiền chênh lệch và dữ liệu Family.

## 8.4. Admin duyệt thanh toán

Admin cần thao tác:
- Xem thông tin giao dịch, thông tin xác minh, lịch sử gói của khách và cờ rủi ro.
- Duyệt/từ chối với lý do bắt buộc.
- Duyệt hàng loạt chỉ khi có điều kiện an toàn, preview và audit.
- Không được duyệt giao dịch của chính Admin nếu chính sách tách nhiệm vụ yêu cầu.
- Không tự sửa số tiền giao dịch nguồn sau duyệt; dùng điều chỉnh.

---

# 9. M08 — Điểm sức khỏe và M14 — Điểm Sale: tách biệt bắt buộc

Hai loại điểm có mục đích khác nhau, phải tách dữ liệu, tính toán và UI.

| Tiêu chí | Điểm sức khỏe | Điểm Sale |
|---|---|---|
| Người nhận | Member/Family member | Sale active |
| Nguồn | Thực hiện lịch trình, thói quen | Giao dịch gói hợp lệ của khách do Sale giới thiệu trực tiếp |
| Dùng để | Phản ánh tiến độ/thói quen | Quy đổi thành tiền hoặc quyền lợi Sale theo chính sách |
| Điều kiện phê duyệt | Theo công thức sức khỏe | Bắt buộc sau Admin duyệt thanh toán |
| Có thể quy đổi tiền | Không theo BD này | Có, theo cấu hình và duyệt Admin |
| Dữ liệu nhạy cảm | Có thể liên quan sức khỏe | Liên quan tài chính/quan hệ giới thiệu |
| Bản ghi điều chỉnh | Theo phiên bản công thức | Theo hoàn/hủy/gian lận/quyết định có audit |

Không được:
- Cộng Điểm Sale vào bảng/logic Điểm sức khỏe.
- Dùng Điểm sức khỏe thay tiền hoặc thay hoa hồng.
- Để Sale xem Điểm sức khỏe của khách được giới thiệu.
- Để Admin dùng một phép tính chung không phân loại loại điểm.

---

# 10. M11 — Module FamilyPlus

## 10.1. Mục tiêu
Cho phép một nhóm gia đình quản lý nhiều hồ sơ riêng, lịch trình riêng và phạm vi chia sẻ được kiểm soát.

## 10.2. Chức năng
- Tạo nhóm gia đình.
- Thêm/xóa/thay đổi vai trò thành viên.
- Onboarding riêng cho từng thành viên.
- Tạo lịch trình riêng cho từng thành viên.
- Xem dashboard theo từng thành viên.
- Tạo thực đơn/mục tiêu gia đình nếu tính năng được phê duyệt.
- Kiểm soát quyền xem/sửa theo quan hệ và sự đồng ý.

## 10.3. Luồng thêm thành viên
1. Chủ FamilyPlus chọn “Thêm thành viên”.
2. Hệ thống kiểm tra gói FamilyPlus còn hiệu lực và quota số thành viên.
3. Chủ gói chọn tạo hồ sơ phụ hoặc gửi lời mời tài khoản.
4. Hệ thống tạo thành viên ở trạng thái phù hợp.
5. Thành viên/Chủ gói hoàn tất onboarding riêng.
6. Hệ thống tạo lịch trình và thông báo theo đúng hồ sơ.
7. Dashboard hiển thị dữ liệu tách biệt.

## 10.4. Quy tắc dữ liệu
- Mỗi dữ liệu sức khỏe/lịch trình phải có `subject_member_id` rõ ràng.
- Chủ gói không mặc định có toàn quyền xem mọi dữ liệu nếu chính sách đồng ý không cho phép.
- Khi gói FamilyPlus hết hạn, cách giữ/xóa/quyền truy cập dữ liệu thành viên phải được Product Owner chốt.
- Sale/Referral không được tạo quyền xem dữ liệu Family.

---

# 11. Role Admin và workflow quản trị toàn dự án

## 11.1. Mục tiêu của Admin

Admin là lớp quản trị vận hành toàn dự án, gồm:
- View tình hình hệ thống.
- Quản lý dữ liệu và người dùng.
- Duyệt thanh toán, kích hoạt gói, đối soát Sale.
- Tính toán và điều chỉnh có kiểm soát.
- Thống kê/báo cáo.
- Quản lý cấu hình dự án.
- Giám sát log, xử lý sự cố và phân quyền.

## 11.2. M15 — Admin View / Dashboard

### Màn hình View tổng quan
Admin nhìn thấy các chỉ số trong phạm vi quyền:
- Tổng số tài khoản; Guest/Member; người dùng hoạt động theo ngày/tuần/tháng.
- Tỷ lệ onboarding hoàn tất.
- Số lịch trình AI tạo mới; tỷ lệ thực hiện lịch trình.
- Phân bố gói Free/Plus/FamilyPlus; gói sắp hết hạn/hết hạn.
- Doanh thu theo ngày/tháng/gói/phương thức thanh toán.
- Số giao dịch chờ duyệt, đã duyệt, từ chối, hoàn/hủy.
- Số Sale theo trạng thái; số mã giới thiệu có hiệu lực.
- Điểm Sale chờ duyệt, đã cộng, chờ quy đổi, đã chi trả, bị điều chỉnh.
- Chỉ số FamilyPlus: số nhóm, số thành viên, quota/sự cố dữ liệu.
- Cảnh báo: giao dịch nghi trùng, tỷ lệ lỗi AI, lỗi đồng bộ, quota bất thường, các thao tác Admin cần xử lý.

### Workflow
1. Admin đăng nhập.
2. Hệ thống kiểm tra permission.
3. Hệ thống tải dashboard theo phạm vi dữ liệu Admin được xem.
4. Admin chọn khoảng thời gian/bộ lọc.
5. Hệ thống hiển thị chỉ số và cho drill-down vào module tương ứng.
6. Admin chỉ có thể thực hiện thao tác sau khi vào màn module có đúng quyền.
7. Các hành động từ dashboard đều ghi audit.

## 11.3. M16-A — Quản lý người dùng và hồ sơ

### Chức năng
- Tìm/lọc người dùng theo mã, email, số điện thoại, trạng thái gói, trạng thái Sale, thời gian hoạt động.
- Xem hồ sơ ứng dụng và lịch sử gói/thanh toán/quota trong phạm vi cần thiết.
- Khóa/mở khóa tài khoản theo lý do.
- Hỗ trợ đồng bộ Guest → Member nếu có quy trình.
- Xử lý yêu cầu xóa dữ liệu/tài khoản theo chính sách.
- Không được sửa dữ liệu sức khỏe nhạy cảm tùy tiện; mọi hỗ trợ dữ liệu phải có lý do/audit.

### Workflow khóa tài khoản
1. Admin tìm người dùng.
2. Admin xem thông tin rủi ro/lịch sử cần thiết.
3. Admin chọn tạm dừng/khóa.
4. Nhập lý do và thời hạn nếu có.
5. Hệ thống yêu cầu xác nhận.
6. Hệ thống thay đổi trạng thái, thu hồi/tạm dừng quyền theo rule.
7. Hệ thống ghi audit và gửi thông báo phù hợp.

## 11.4. M16-B — Quản lý gói, giá và entitlement

### Chức năng
- Tạo/sửa phiên bản cấu hình gói Free/Plus/FamilyPlus.
- Quản lý quyền, quota, chu kỳ, giá và ngày hiệu lực.
- Bật/tắt gói theo trạng thái triển khai.
- Xem lịch sử thay đổi cấu hình.
- Kiểm tra ảnh hưởng trước khi áp dụng cấu hình mới.

### Quy tắc
- Không sửa giá/quota đang áp dụng theo cách làm thay đổi giao dịch/quyền lịch sử.
- Cấu hình mới phải có `effective_from`, người tạo, người duyệt nếu cần và audit.
- Cần tách quyền “soạn cấu hình” và “duyệt áp dụng” khi hệ thống vận hành tài chính lớn.

## 11.5. M16-C — Quản lý Sale và mã giới thiệu

### Chức năng
- Duyệt/từ chối hồ sơ Sale.
- Kích hoạt/tạm dừng/chấm dứt Sale.
- Quản lý mã giới thiệu, cấp lại/khóa mã theo chính sách.
- Xem danh sách khách trực tiếp, không hiển thị dữ liệu sức khỏe không cần thiết.
- Kiểm tra quan hệ giới thiệu có dấu hiệu bất thường.
- Xử lý yêu cầu điều chỉnh quan hệ giới thiệu theo quyền đặc biệt.

### Workflow duyệt Sale
1. Admin mở danh sách Sale `pending_review`.
2. Chọn hồ sơ.
3. Kiểm tra điều kiện/hồ sơ theo policy.
4. Chọn duyệt hoặc từ chối; nhập lý do.
5. Nếu duyệt: hệ thống chuyển `active`, sinh/cấp mã giới thiệu và audit.
6. Sale nhận thông báo kết quả.

## 11.6. M16-D — Quản lý thanh toán, quy đổi và hỗ trợ tài chính

### Chức năng
- Duyệt/từ chối thanh toán.
- Xem/gắn bằng chứng đối soát.
- Xử lý hoàn/hủy/điều chỉnh theo quyền.
- Duyệt/từ chối yêu cầu quy đổi Điểm Sale.
- Xác nhận đã chi trả.
- Xuất danh sách đối soát theo kỳ.

### Quy tắc
- Các thao tác tài chính yêu cầu lý do, timestamp và người thao tác.
- Trạng thái sau duyệt không bị ghi đè trực tiếp.
- Một Admin không nên vừa tạo giao dịch điều chỉnh vừa tự duyệt nếu Product Owner áp dụng nguyên tắc phân tách nhiệm vụ.

## 11.7. M16-E — Quản lý nội dung, thông báo và vận hành sản phẩm

### Chức năng
- Quản lý nội dung hướng dẫn, FAQ, thông báo hệ thống.
- Tạo thông báo broadcast theo segment được phép.
- Quản lý cấu hình hiển thị gói/feature flag theo môi trường.
- Quản lý template thông báo thanh toán, gói, Sale và lịch trình.
- Theo dõi tình trạng AI, notification, đồng bộ mà không lộ dữ liệu nhạy cảm quá mức.

## 11.8. M19 — Audit, bảo mật và hỗ trợ

### Chức năng
- Xem audit log theo thời gian, actor, hành động, đối tượng, module.
- Theo dõi login bất thường, lỗi quyền, giao dịch nghi trùng.
- Mở ticket hỗ trợ/vi phạm nếu có workflow.
- Lưu lịch sử xử lý ticket và bằng chứng cần thiết.
- Quản lý role/permission Admin ở cấp Super Admin.

### Audit bắt buộc cho
- Duyệt/từ chối payment.
- Kích hoạt/tạm dừng/đóng Sale.
- Cộng/đảo/điều chỉnh Điểm Sale.
- Duyệt/từ chối/chi trả quy đổi điểm.
- Thay đổi cấu hình gói, giá, tỷ lệ 10%, tỷ lệ đổi điểm.
- Khóa/mở khóa người dùng.
- Thao tác đặc biệt với quan hệ giới thiệu.

---

# 12. M17 — Module tính toán, đối soát và M18 — thống kê/báo cáo

## 12.1. M17 — Tính toán & đối soát

### Mục tiêu
Đảm bảo dữ liệu gói, thanh toán, hoa hồng, Điểm Sale, quota và điểm sức khỏe nhất quán, có thể kiểm tra lại.

### Nhóm tính toán
| Nhóm | Đầu vào | Kết quả |
|---|---|---|
| Quyền gói | Thanh toán duyệt, entitlement, ngày hiệu lực | Quyền Free/Plus/FamilyPlus hiện hành |
| Hoa hồng Sale | Payment approved + quan hệ trực tiếp hợp lệ | 10% giá trị đủ điều kiện, bản ghi Điểm Sale |
| Điểm Sale khả dụng | Điểm đã cộng, điểm giữ quy đổi, điểm đã đảo | Số điểm có thể quy đổi |
| Quy đổi điểm | Tỷ lệ đổi điểm, yêu cầu quy đổi, trạng thái duyệt | Số tiền/điểm đã chốt và lịch sử |
| Quota | Lịch sử request AI/lịch trình và gói | Số lượt đã dùng/còn lại |
| Điểm sức khỏe | Lịch sử thực hiện, công thức phiên bản | Điểm và tiến độ từng hồ sơ |
| Đối soát sai lệch | Dữ liệu nguồn và dữ liệu tổng hợp | Danh sách lỗi/cờ cần Admin xử lý |

### Luồng tính hoa hồng Sale có idempotency
1. Sự kiện `payment_approved` được phát ra.
2. Job/use-case lấy khóa duy nhất của giao dịch.
3. Kiểm tra đã có bản ghi hoa hồng cho giao dịch đó chưa.
4. Nếu có: kết thúc an toàn, không cộng lại.
5. Nếu chưa: tìm quan hệ giới thiệu trực tiếp hợp lệ.
6. Nếu không có: đánh dấu “không có Sale hợp lệ”, kết thúc.
7. Nếu có: lấy giá trị tính hoa hồng và tỷ lệ 10% đã version hóa.
8. Tạo ledger Điểm Sale.
9. Cộng số dư điểm bằng giao dịch nguyên tử.
10. Ghi audit/sự kiện thông báo.
11. Nếu lỗi giữa chừng: retry an toàn theo cùng khóa giao dịch; không nhân đôi điểm.

### Luồng đối soát định kỳ
1. Admin chọn kỳ đối soát hoặc job chạy định kỳ.
2. Hệ thống lấy danh sách thanh toán đã duyệt.
3. Đối chiếu từng giao dịch với entitlement, quan hệ Sale, ledger Điểm Sale và số dư.
4. Tạo báo cáo sai lệch: thiếu điểm, thừa điểm, sai trạng thái, giao dịch trùng, gói không khớp.
5. Admin xem, phân loại và xử lý.
6. Việc xử lý tạo adjustment, không sửa mất lịch sử.

## 12.2. M18 — Thống kê & báo cáo

### Nhóm báo cáo
- **Sản phẩm:** onboarding completion, DAU/WAU/MAU, số lịch trình tạo, retention, quota usage.
- **Gói:** tỷ lệ Free → Plus/FamilyPlus, gia hạn, hết hạn, hủy, doanh thu theo gói.
- **Sale:** số Sale active, hiệu quả mã giới thiệu, số khách trực tiếp, doanh thu do Sale, Điểm Sale theo trạng thái.
- **Thanh toán:** số tiền chờ duyệt/đã duyệt/từ chối/hoàn, thời gian xử lý duyệt.
- **Family:** nhóm active, thành viên trung bình, mức sử dụng FamilyPlus.
- **Vận hành:** lỗi AI, notification failure, sync failure, ticket, hành động Admin.
- **Tuân thủ/audit:** thay đổi cấu hình, điều chỉnh điểm, thao tác tài chính.

### Quy tắc báo cáo
- Có bộ lọc thời gian, gói, Sale, trạng thái giao dịch và phạm vi quyền.
- Dữ liệu sức khỏe nhạy cảm dùng dạng tổng hợp/ẩn danh khi không cần nhận diện.
- Xuất Excel/CSV/PDF phải có quyền export và log.
- Báo cáo tài chính lấy từ ledger/giao dịch nguồn, không tính chỉ từ số hiển thị UI cache.

---

# 13. Mô hình dữ liệu nghiệp vụ mức khái niệm

| Thực thể | Mục đích | Trường/hành vi quan trọng |
|---|---|---|
| App User | Hồ sơ ứng dụng liên kết Supabase Auth | `auth_user_id`, trạng thái tài khoản, gói hiện hành, trạng thái Sale |
| Guest Profile | Hồ sơ local trước đăng nhập | khóa cục bộ, cờ đã tạo lịch trình đầu tiên, dữ liệu onboarding |
| Onboarding Profile | Dữ liệu đầu vào cá nhân hóa | owner/subject, version, trạng thái hoàn tất |
| Family Group | Nhóm FamilyPlus | chủ nhóm, trạng thái, quota thành viên |
| Family Member | Một người trong Family | `subject_member_id`, vai trò, quyền chia sẻ |
| Personal Plan | Lịch trình AI | owner/subject, phiên bản, trạng thái hiệu lực, nguồn AI |
| Plan Item | Bữa ăn/bài tập/mốc lịch | lịch trình cha, thời điểm, loại, trạng thái |
| Plan Completion Event | Lịch sử thực hiện | item, trạng thái, thời gian, actor, ghi chú |
| Notification Schedule | Lịch nhắc | plan/item, thời điểm, thiết bị, trạng thái gửi |
| Membership Product | Cấu hình gói | mã gói, giá, quota, version, hiệu lực |
| Membership Entitlement | Quyền gói của một tài khoản | gói, thời gian bắt đầu/kết thúc, nguồn payment |
| Usage Quota Ledger | Lịch sử quota | loại quota, kỳ, request id, trạng thái |
| AI Request | Yêu cầu AI | loại yêu cầu, request id, trạng thái, quota impact |
| Health Score Ledger | Điểm sức khỏe | subject, nguồn event, công thức version, số điểm |
| Sale Profile | Quyền Sale | trạng thái, mã, ngày kích hoạt/tạm dừng |
| Referral Relationship | Quan hệ Sale → khách trực tiếp | sale_id, customer_id, referral_code, locked_at, status |
| Payment Transaction | Giao dịch gói | user, gói, tiền, trạng thái, chứng từ, transaction reference |
| Payment Approval | Lịch sử duyệt payment | payment, Admin, quyết định, lý do, thời gian |
| Sale Commission Ledger | Ledger hoa hồng/Điểm Sale | payment, sale, tỷ lệ 10%, base amount, điểm, trạng thái |
| Sale Point Balance | Số dư tính toán | available, held, converted, reversed; không là nguồn duy nhất |
| Sale Point Conversion | Yêu cầu đổi điểm | sale, điểm, tỷ lệ, tiền, trạng thái, thông tin chi trả |
| Commission/Conversion Adjustment | Điều chỉnh tài chính | tham chiếu bản ghi gốc, lý do, actor, số điều chỉnh |
| Admin Role/Permission | Phân quyền quản trị | role, permission, scope |
| Audit Log | Truy vết | actor, action, entity, before/after, reason, timestamp |
| System Configuration | Hằng số/cấu hình version hóa | key, value, effective time, approval/audit |

> Cấu trúc vật lý, khóa ngoại, RLS, index, partition, trigger và API phải được đặc tả trong DD/database design. Các bảng ledger tài chính không được được thiết kế theo kiểu chỉ lưu “số dư cuối” mà thiếu bản ghi nguồn.

---

# 14. Quy tắc kiểm soát, bảo mật và audit

## 14.1. Kiểm soát quyền nhiều lớp
- UI: ẩn/hiển thị đúng quyền để trải nghiệm rõ ràng.
- Route: chặn deep link vào module không được phép.
- Use-case/controller: kiểm tra quyền trước nghiệp vụ.
- API/backend: xác thực token, kiểm tra entitlement/role/scope.
- Database/RLS: không trả dữ liệu ngoài owner/family/admin scope.
- Job nền: chỉ xử lý sự kiện hợp lệ, có idempotency và audit.

## 14.2. Dữ liệu nhạy cảm
- Dữ liệu sức khỏe được coi là nhạy cảm nội bộ; chỉ thu thập phần thực sự cần.
- Sale không xem dữ liệu sức khỏe/AI Chat/lịch trình của khách.
- Admin chỉ xem dữ liệu cần cho mục đích quản trị/hỗ trợ; quyền xem sâu cần hạn chế và log.
- Export dữ liệu phải có permission, lý do nếu cần và audit.
- FamilyPlus phải có cơ chế consent/phân quyền phù hợp trước khi cho xem chéo.

## 14.3. Audit bắt buộc
Mọi thay đổi có ảnh hưởng tiền, điểm, quyền, gói, Sale, referral, dữ liệu gia đình hoặc cấu hình phải lưu:
- actor;
- hành động;
- entity và định danh;
- dữ liệu trước/sau ở mức phù hợp;
- lý do;
- thời điểm;
- nguồn thao tác (UI/API/job);
- request/correlation id.

## 14.4. Tính nhất quán tài chính
- Mỗi payment chỉ tạo tối đa một entitlement hiệu lực theo rule.
- Mỗi `payment_transaction_id` chỉ tạo tối đa một `Sale Commission Ledger` chính.
- Không cộng điểm khi payment chưa `approved`.
- Hoàn/hủy phải tạo adjustment/reversal; không xóa ledger.
- Quy đổi phải giữ điểm trước khi Admin duyệt để chống quy đổi nhiều lần.
- Các thao tác Admin quan trọng cần chống double-click/retry trùng bằng idempotency key.

---

# 15. Ngoại lệ, xử lý lỗi nghiệp vụ và chống gian lận

| Tình huống | Hành vi bắt buộc |
|---|---|
| Khách nhập mã không tồn tại | Báo mã không hợp lệ; không tạo quan hệ. |
| Sale bị tạm dừng | Không cho gắn mã mới; các quan hệ cũ/điểm chưa duyệt xử lý theo chính sách chốt. |
| Khách tự nhập mã của mình | Từ chối; ghi sự kiện rủi ro nếu cần. |
| Khách đã có mã Sale | Không cho gắn/đổi bình thường; chỉ Admin đặc biệt xử lý với audit. |
| Khách đã thanh toán rồi mới nhập mã | Từ chối theo mặc định; tránh gắn hậu kiểm. |
| Payment trùng mã giao dịch | Khóa xử lý, đưa vào hàng chờ kiểm tra; không kích hoạt gói/điểm lại. |
| Admin duyệt payment hai lần | Chỉ lần đầu có hiệu lực; lần sau idempotent/hiển thị đã duyệt. |
| Job tính commission chạy lại | Không tạo/cộng điểm trùng nhờ khóa payment. |
| Payment đã duyệt nhưng sau đó hoàn/hủy | Cập nhật entitlement theo policy và tạo reversal/adjustment Điểm Sale, có audit. |
| Sale yêu cầu đổi điểm lớn hơn khả dụng | Từ chối; không thay đổi số dư. |
| AI lỗi khi tạo lịch trình | Không trừ quota nếu chưa có kết quả hợp lệ; cho retry có kiểm soát. |
| Mất quyền FamilyPlus | Không truy cập dữ liệu ngoài phạm vi còn hiệu lực; giữ dữ liệu theo chính sách lưu trữ. |
| Admin không đủ quyền | API/backend từ chối, không chỉ ẩn nút. |
| Nghi ngờ giả mạo/referral bất thường | Gắn cờ, có thể giữ payment/điểm ở trạng thái kiểm tra; không tự động chi trả. |

---

# 16. Tiêu chí chấp nhận

## 16.1. Guest, gói và lịch trình

| Mã AC | Tình huống | Kết quả phải đạt |
|---|---|---|
| AC-01 | Guest hoàn tất onboarding | AI tạo lịch trình có thực đơn, bài tập và mốc lịch; lịch được lưu/hiển thị. |
| AC-02 | Guest đã dùng lần tạo đầu yêu cầu tạo thêm | Không gọi AI tạo mới; yêu cầu đăng nhập. |
| AC-03 | Guest mở AI Chat hoặc module ngoài allowlist | Bị chặn ở UI/route/use-case/API. |
| AC-04 | Free hỏi AI Chat lần thứ 4 trong ngày | Bị chặn do vượt quota. |
| AC-05 | Free tạo lịch trình lần thứ 4 trong tháng | Bị chặn, không trừ/quét sai quota. |
| AC-06 | Plus/FamilyPlus dùng AI Chat và tạo lịch trình | Không bị chặn bởi quota Free. |
| AC-07 | Gói Plus thanh toán nhưng chưa Admin duyệt | Chưa được mở entitlement Plus. |
| AC-08 | Admin duyệt payment Plus | Quyền Plus có hiệu lực và được ghi lịch sử. |

## 16.2. Sale trực tiếp và Điểm Sale

| Mã AC | Tình huống | Kết quả phải đạt |
|---|---|---|
| AC-09 | Sale active có mã giới thiệu | Mã duy nhất, có thể dùng để tạo quan hệ giới thiệu trực tiếp. |
| AC-10 | Khách B nhập mã của Sale A hợp lệ | Tạo đúng một quan hệ A → B; không tạo cây/tầng. |
| AC-11 | B thanh toán gói nhưng chờ Admin duyệt | A chưa nhận Điểm Sale. |
| AC-12 | Admin duyệt payment X của B | A nhận bản ghi Điểm Sale bằng 10% giá trị thanh toán đủ điều kiện X. |
| AC-13 | B tiếp tục gia hạn và payment Y được Admin duyệt | A tiếp tục nhận 10% của Y. |
| AC-14 | Một tài khoản khác do B giới thiệu thanh toán | A không nhận bất kỳ hoa hồng nào từ giao dịch đó. |
| AC-15 | Payment X bị hoàn sau khi đã cộng điểm | Hệ thống tạo reversal/adjustment có audit; không xóa lịch sử. |
| AC-16 | Job commission retry cùng payment X | Không cộng Điểm Sale lần hai. |
| AC-17 | Sale yêu cầu đổi điểm vượt số dư khả dụng | Bị từ chối, số dư không thay đổi. |
| AC-18 | Admin duyệt đổi điểm | Điểm bị giữ/trừ đúng một lần, trạng thái và lịch sử rõ ràng. |

## 16.3. Admin

| Mã AC | Tình huống | Kết quả phải đạt |
|---|---|---|
| AC-19 | Admin mở View Dashboard | Thấy chỉ số theo đúng permission và lọc thời gian. |
| AC-20 | Admin không có quyền Finance cố duyệt payment | Bị từ chối ở backend/API. |
| AC-21 | Admin duyệt/từ chối payment | Có lý do, timestamp, actor và audit log. |
| AC-22 | Admin thay đổi giá/tỷ lệ quy đổi | Tạo phiên bản cấu hình mới, không sửa lịch sử. |
| AC-23 | Admin xuất báo cáo | Chỉ xuất khi có permission, có log export. |
| AC-24 | Admin xem Sale detail | Không thấy dữ liệu sức khỏe nhạy cảm của khách nếu không có scope hợp lệ. |

---

# 17. Yêu cầu DD, test và cập nhật `.codex`

## 17.1. DD bắt buộc phải có trước coding phần Sale/Admin
- ERD/schema vật lý cho payment, referral trực tiếp, commission ledger, Sale point ledger, conversion, adjustment, audit.
- State machine chi tiết cho payment, entitlement, Sale, commission và conversion.
- API contract: request/response/error code/idempotency.
- RLS/Supabase policy cho owner, family member, Sale và Admin.
- Sequence diagram cho:
  - nhập mã giới thiệu;
  - payment → Admin approval → entitlement → Sale points;
  - recurring payment;
  - refund/reversal;
  - conversion points → tiền;
  - Admin suspend Sale.
- UI state: empty/loading/error/permission denied/pending approval/rejected.
- Test case mức unit, integration, E2E và test dữ liệu đối soát.

## 17.2. Test matrix tối thiểu
- Guest gate: route, deep link, API bypass.
- Quota: dưới ngưỡng, đúng ngưỡng, vượt ngưỡng, reset kỳ, chuyển gói.
- Membership: payment pending/approved/rejected/expired/refund.
- Referral: mã hợp lệ/sai/tự giới thiệu/đổi mã/trùng account.
- Commission: payment approved, recurring, retry/idempotency, refund/reversal, không có tầng gián tiếp.
- Sale points: số dư, giữ điểm, conversion approve/reject/paid.
- Admin: permission, audit, separation of duties, export.
- Family: boundary theo thành viên, consent, gói hết hạn.
- Security: RLS/data leakage/token đổi quyền.

## 17.3. Cập nhật `.codex`
| File | Nội dung cần bổ sung |
|---|---|
| `.codex/AGENTS.md` | Sale chỉ trực tiếp 10%; không có tier 2/5%; Điểm Sale chỉ cộng sau `payment_approved` bởi Admin. |
| `.codex/PROJECT_MAP.md` | Bổ sung `admin`, `payments`, `membership_entitlement`, `referral_direct`, `sale_points`, `commission_ledger`, `conversion`, `audit`. |
| `.codex/DOCS_WORKFLOW.md` | Khi làm task phải xác định actor, entitlement, state transition, audit và test trước code. |
| `.codex/playbooks/referral_sale.md` | Luồng đầy đủ code/mã/relationship/payment approval/commission/points/reversal. |
| `.codex/playbooks/admin.md` | Permission matrix, dashboard, approval, audit, export và cấu hình version hóa. |
| `.codex/playbooks/payment_membership.md` | Payment state machine, entitlement, recurring payment, refund/chargeback. |
| `docs/test/` | Test matrix theo M01–M19 và evidence theo ngày/module. |
| `docs/issues/` | Ghi mọi mâu thuẫn giữa code cũ có 2 tầng và BD 2.0 trước khi fix. |

---

# 18. Đề xuất và câu hỏi bắt buộc cần Product Owner chốt

## 18.1. Đề xuất nghiệp vụ

1. **Dùng thuật ngữ “Hoa hồng Sale/Điểm Sale”, không dùng “lương”.** Điều này giúp hệ thống, báo cáo và điều khoản vận hành rõ bản chất khoản tiền.
2. **Giữ mô hình Sale trực tiếp 1 tầng.** Thiết kế này đơn giản hơn để kiểm toán, giảm tranh chấp và dễ giải thích với người dùng.
3. **Tách quyền Admin theo permission, không dùng một tài khoản full quyền cho mọi người.** Tối thiểu tách Admin vận hành, Admin tài chính và Super Admin.
4. **Ledger thay vì chỉ số dư.** Mọi điểm/tiền/quy đổi cần có giao dịch nguồn để đối soát.
5. **Có quy trình hoàn/hủy trước khi triển khai.** Không chốt phần này sẽ làm sai quyền gói và Điểm Sale.
6. **Khóa quan hệ giới thiệu sớm.** Nên chỉ cho nhập mã trước giao dịch đầu tiên, không đổi tùy ý.
7. **Cấu hình tỷ lệ/giá/quy đổi có version.** Khi thay đổi về sau không được làm sai dữ liệu quá khứ.
8. **Giới hạn tối thiểu việc Admin xem dữ liệu sức khỏe.** Dashboard ưu tiên số liệu tổng hợp/ẩn danh.

## 18.2. Câu hỏi cần Product Owner trả lời trước DD/coding

| Mã | Câu hỏi cần chốt | Ảnh hưởng |
|---|---|---|
| Q-01 | Ai được trở thành Sale: tất cả Member, chỉ Member mua gói, hay cần hồ sơ/duyệt? | Flow đăng ký, trạng thái Sale, UI/Admin. |
| Q-02 | “Giới thiệu thành công” có cần khách thanh toán lần đầu hay cần thêm điều kiện như qua thời gian hoàn tiền? | Thời điểm cộng Điểm Sale. |
| Q-03 | 10% tính trên giá niêm yết hay số tiền thực thu sau giảm giá/voucher/thuế/phí? | Công thức commission và báo cáo tài chính. |
| Q-04 | Các gói thanh toán theo tháng, năm hay một lần; gia hạn sớm/trễ xử lý ra sao? | Entitlement và recurring commission. |
| Q-05 | Khi payment hoàn/hủy/chargeback sau khi đã cộng điểm, có đảo điểm ngay không? Nếu Sale đã đổi điểm thì xử lý thế nào? | Ledger, số dư âm/điều chỉnh. |
| Q-06 | Tỷ lệ quy đổi Điểm Sale → tiền là bao nhiêu, có thay đổi theo thời gian không, mức tối thiểu quy đổi là bao nhiêu? | Cấu hình, conversion, UI. |
| Q-07 | Sale nhận tiền bằng phương thức nào, chu kỳ chi trả, yêu cầu hồ sơ/tax/invoice nào? | Quy trình vận hành và chứng từ. |
| Q-08 | Mã giới thiệu được nhập ở bước đăng ký, sau onboarding hay trước payment? Có cho Admin sửa hậu kiểm không? | Referral locking và chống gian lận. |
| Q-09 | Tiêu chí phát hiện tự giới thiệu/tài khoản trùng là gì? | Kiểm tra fraud và quyền từ chối. |
| Q-10 | Sale bị suspended/closed thì các khách đã giới thiệu có còn làm phát sinh điểm không? | State machine và tranh chấp. |
| Q-11 | Khi FamilyPlus thanh toán, 10% tính theo toàn bộ gói hay chỉ phần của chủ gói? | Commission base. |
| Q-12 | Admin có bao nhiêu nhóm: Super Admin, Finance Admin, Support Admin, Content Admin? | Permission matrix và UI. |
| Q-13 | Admin có được sửa/điều chỉnh thủ công điểm Sale không? Nếu có, cần hai người duyệt không? | Audit, separation of duties. |
| Q-14 | Danh sách module tính toán sức khỏe cụ thể là gì, công thức nào đã được phê duyệt? | M04, M08 và trách nhiệm chuyên môn. |
| Q-15 | Số thành viên tối đa FamilyPlus, quyền xem/sửa và consent theo độ tuổi/quan hệ như thế nào? | Data model, privacy, UI. |
| Q-16 | Múi giờ chuẩn cho reset quota, thời hạn gói, báo cáo và duyệt payment là gì? | Quota, entitlement, statistics. |
| Q-17 | Cần duyệt thủ công toàn bộ payment hay webhook tự động cũng có thể tạo `payment_approved` dưới quy tắc nào? | Payment architecture và vận hành. |
| Q-18 | Có cho phép sale xem tên/định danh nào của khách hay chỉ số liệu tổng hợp? | Privacy, Dashboard Sale. |

> **Điểm chặn coding:** Q-02 đến Q-10 và Q-17 phải được Product Owner chốt trước khi triển khai payment, commission, Sale point conversion hoặc đối soát tài chính.

---

# Phụ lục A. Use Case mức cao

| Mã UC | Use Case | Actor |
|---|---|---|
| UC-01 | Hoàn tất onboarding Guest | Guest |
| UC-02 | Sinh lịch trình AI đầu tiên | Guest |
| UC-03 | Dùng tính toán sức khỏe cơ bản | Guest/Member |
| UC-04 | Nhận và thao tác thông báo lịch trình | Guest/Member |
| UC-05 | Đăng ký/đăng nhập và đồng bộ dữ liệu Guest | Guest/Member |
| UC-06 | Dựng entitlement theo gói | System/Member |
| UC-07 | Dùng AI Chat theo quota | Free/Plus/FamilyPlus |
| UC-08 | Tạo lịch trình mới theo quota | Free/Plus/FamilyPlus |
| UC-09 | Theo dõi/tính điểm sức khỏe | Member/Family Member |
| UC-10 | Quản lý mục tiêu nâng cao | Plus/FamilyPlus |
| UC-11 | Quản lý nhóm và thành viên FamilyPlus | FamilyPlus |
| UC-12 | Gửi yêu cầu trở thành Sale | Member |
| UC-13 | Duyệt/từ chối Sale | Admin |
| UC-14 | Gắn mã giới thiệu trực tiếp | Guest/Member |
| UC-15 | Tạo thanh toán mua/gia hạn gói | Member |
| UC-16 | Duyệt/từ chối payment | Admin |
| UC-17 | Cộng Điểm Sale 10% sau payment approved | System |
| UC-18 | Yêu cầu quy đổi Điểm Sale | Sale |
| UC-19 | Duyệt/chi trả quy đổi Điểm Sale | Admin |
| UC-20 | View dashboard vận hành | Admin |
| UC-21 | Quản lý user/gói/Sale/config | Admin |
| UC-22 | Đối soát payment/commission/points | Admin/System |
| UC-23 | Xem audit log và xử lý bất thường | Admin/Super Admin |
| UC-24 | Xuất báo cáo | Admin có quyền export |

---

# Phụ lục B. Trạng thái nghiệp vụ cần thiết

| Nhóm | Trạng thái tối thiểu |
|---|---|
| Onboarding | not_started, in_progress, completed |
| Personal Plan | draft, generating, active, archived, failed |
| Plan Item | pending, completed, skipped, expired |
| Payment | created, pending_verification, approved, rejected, cancelled, refunded, chargeback_review |
| Entitlement | pending, active, expired, suspended, cancelled |
| Sale Profile | none, pending_review, active, suspended, closed |
| Referral Relationship | pending, active, invalid, locked, reversed |
| Commission/Point | pending_payment_verification, payment_approved, commission_calculating, points_credited, points_reversed |
| Conversion | requested, pending_review, approved, paid, rejected, cancelled |
| Admin Action | initiated, confirmed, failed, rolled_back (nếu có workflow) |

---

# Phụ lục C. Hằng số/cấu hình phải quản lý tập trung

| Nhóm | Cấu hình |
|---|---|
| Gói | tên gói, giá, chu kỳ, thời hạn, quota, ngày hiệu lực |
| Quota | chat Free/ngày, tạo lịch trình Free/tháng, timezone reset |
| Sale | tỷ lệ hoa hồng trực tiếp `10%`, điều kiện đủ điều kiện, thời điểm khóa mã, chống self-referral |
| Điểm Sale | công thức điểm từ hoa hồng, tỷ lệ đổi tiền, điểm tối thiểu/tối đa quy đổi, lịch chi trả |
| Payment | phương thức, thời hạn chờ duyệt, quy tắc trùng giao dịch, refund/chargeback |
| Family | số thành viên tối đa, vai trò, quyền chia sẻ, retention khi hết gói |
| AI | rate limit kỹ thuật, timeout, retry, xử lý lỗi/không trừ quota |
| Audit | thời gian lưu log, quyền xem, export policy |
| Notification | timezone, số lần retry, quyền thiết bị, template |
