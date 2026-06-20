# BD - Cập nhật luồng sản phẩm, gói thành viên và cơ chế Sale / giới thiệu

> **Dự án:** BioAI / NanoBio  
> **Nguồn yêu cầu:** Mô tả nghiệp vụ do Product Owner cung cấp.

| Mã tài liệu | BD-BIOAI-PRODUCT-FLOW-001 |
| --- | --- |
| Phiên bản | 1.0 |
| Trạng thái | Bản mô tả nghiệp vụ để xác nhận và làm nguồn cho DD/Codex |
| Ngày lập | 20/06/2026 |
| Phạm vi | Onboarding, lịch trình AI, quyền khách, gói Free/Plus/FamilyPlus, Sale và hoa hồng 2 tầng |

---

## Kiểm soát tài liệu

| Thuộc tính | Giá trị |
| --- | --- |
| Tên tài liệu | BD - Cập nhật luồng sản phẩm, gói thành viên và cơ chế Sale / giới thiệu |
| Đối tượng sử dụng | Product Owner, Business Analyst, UI/UX, Mobile/Backend Developer, QA, Codex/AI Agent |
| Nguồn sự thật | Các quy tắc nghiệp vụ trong tài liệu này là nguồn yêu cầu cho DD và mọi task triển khai liên quan đến phạm vi nêu trên. |
| Nguyên tắc khi có mâu thuẫn | Không tự suy diễn hoặc mở rộng quyền. Báo lại điểm mâu thuẫn để Product Owner xác nhận; ưu tiên nội dung BD mới hơn trong cùng phạm vi. |

## Mục lục

- 1. Mục tiêu và phạm vi
- 2. Thuật ngữ và quy ước phiên bản
- 3. Mô hình sản phẩm và trạng thái người dùng
- 4. Luồng nghiệp vụ tổng thể
- 5. Yêu cầu nghiệp vụ chi tiết
- 6. Ma trận quyền và giới hạn sử dụng
- 7. Cơ chế Sale, giới thiệu và hoa hồng hai tầng
- 8. Mô hình dữ liệu nghiệp vụ mức khái niệm
- 9. Quy tắc kiểm soát quyền, quota và thông báo
- 10. Tiêu chí chấp nhận theo luồng
- 11. Yêu cầu cập nhật `.codex` cho các phiên sau
- 12. Điểm cần Product Owner xác nhận trước khi DD/coding
- Phụ lục A. Danh sách Use Case mức cao

> **Quy ước trọng tâm:** Khách chưa đăng nhập chỉ có quyền dùng nhóm chức năng V1 được liệt kê rõ trong BD. Mọi tính năng khác phải bị chặn cho tới khi người dùng đăng nhập và hệ thống xác định được gói thành viên.

---

# 1. Mục tiêu và phạm vi

## 1.1. Mục tiêu

Chuẩn hóa lại luồng sản phẩm BioAI / NanoBio theo mô hình **“khách trải nghiệm trước - đăng nhập để mở rộng - nâng cấp gói để dùng sâu hơn - Sale là lớp quyền độc lập”**. Tài liệu bảo đảm đội phát triển và Codex phân biệt đúng giữa quyền của khách chưa đăng nhập, gói thành viên và trạng thái Sale.

## 1.2. Phạm vi trong BD

- Onboarding, tiếp nhận dữ liệu cá nhân và dữ liệu sức khỏe của người dùng.
- Gemini AI nhận dữ liệu onboarding để sinh lịch trình cá nhân gồm thực đơn, bài tập và lịch theo ngày/mốc thời gian.
- Quyền dùng của khách chưa đăng nhập (V1).
- Xác thực, truy vấn gói thành viên trên Supabase và áp quyền sau đăng nhập.
- Gói Free, Plus, FamilyPlus và nguyên tắc kế thừa quyền.
- Hệ thống điểm dựa trên mức độ thực hiện lịch trình AI.
- Cơ chế Sale / mã giới thiệu / hoa hồng trực tiếp 10% và gián tiếp 5% tối đa hai tầng.
- Yêu cầu cập nhật context `.codex` để mọi phiên triển khai sau tuân thủ đúng luồng mới.

## 1.3. Ngoài phạm vi của BD này

- Thiết kế UI chi tiết, wireframe và nội dung hiển thị theo persona Nami.
- Thiết kế cơ sở dữ liệu vật lý, API contract, RLS Supabase, cơ chế thanh toán và đối soát kế toán chi tiết.
- Mức giá, chu kỳ gói (tháng/năm), phương thức thanh toán, quy trình hoàn tiền, rút tiền hoa hồng và các điều kiện pháp lý.
- Chi tiết thuật toán AI/Gemini, công thức tính điểm và mô hình y tế nâng cao.

> **Lưu ý:** Các nội dung ngoài phạm vi không được tự thêm vào code như một giả định nghiệp vụ. Chúng phải được xác nhận ở BD bổ sung hoặc DD trước khi triển khai.

---

# 2. Thuật ngữ và quy ước phiên bản

| Thuật ngữ | Định nghĩa trong BD này |
| --- | --- |
| Onboarding | Luồng người dùng nhập thông tin cá nhân và dữ liệu cá nhân/sức khỏe ban đầu để hệ thống cá nhân hóa trải nghiệm. |
| Lịch trình cá nhân | Kết quả Gemini AI tạo từ dữ liệu onboarding, gồm thực đơn, bài tập và các mốc/lịch hoạt động cá nhân. |
| Khách / Guest | Người đã onboarding hoặc đang dùng ứng dụng nhưng chưa đăng nhập tài khoản. |
| V1 | Tập chức năng nền tảng cho Guest: tạo lịch trình cá nhân một lần sau onboarding, tính toán sức khỏe cơ bản và thông báo theo lịch trình. |
| Free | Gói thành viên sau khi đăng nhập. Trong định hướng phát triển, đây là tập quyền tương ứng V2. |
| Plus | Gói thành viên cao hơn Free; kế thừa Free và bổ sung quyền tương ứng định hướng V3. |
| FamilyPlus | Gói thành viên cao hơn Plus; kế thừa Plus/Free và bổ sung trải nghiệm gia đình. |
| Sale | Trạng thái độc lập với gói thành viên. Người dùng vừa dùng ứng dụng vừa có quyền giới thiệu ứng dụng để nhận hoa hồng theo cây giới thiệu tối đa hai tầng. |
| Tầng 1 | Quan hệ người Sale giới thiệu trực tiếp một người dùng khác bằng mã giới thiệu. |
| Tầng 2 | Quan hệ người Sale ở tầng 1 giới thiệu thêm người dùng khác; Sale cấp trên nhận hoa hồng gián tiếp 5% từ các khoản thanh toán hợp lệ của người tầng 2. |

## 2.1. Quy ước để loại bỏ nhầm lẫn giữa “version” và “gói”

Trong yêu cầu gốc có hai cách gọi song song: V1/V2/V3 và Free/Plus/FamilyPlus. BD chính thức hóa cách hiểu sau để team có một nguồn thống nhất:

| Lớp phân loại | Tên | Ý nghĩa |
| --- | --- | --- |
| Trạng thái truy cập | Guest / V1 | Không đăng nhập. Chỉ dùng allowlist chức năng V1. Không phải gói trả phí. |
| Gói thành viên | Free / V2 | Sau đăng nhập, có quyền của gói Free và các giới hạn quota Free. |
| Gói thành viên | Plus / V3 | Kế thừa Free, thêm chức năng nâng cao và bỏ các giới hạn đã nêu. |
| Gói thành viên | FamilyPlus / V3 | Kế thừa Plus/Free, thêm quản lý và theo dõi sức khỏe nhiều thành viên trong gia đình. |
| Trạng thái song song | Sale | Có hoặc không, độc lập với Guest/Free/Plus/FamilyPlus. Không thay thế gói thành viên. |

---

# 3. Mô hình sản phẩm và trạng thái người dùng

## 3.1. Hai trục trạng thái bắt buộc

Mỗi người dùng được đánh giá trên hai trục độc lập. Hệ thống không được dùng một thuộc tính duy nhất để suy ra cả quyền gói và quyền Sale.

| Trục | Giá trị hợp lệ | Tác dụng |
| --- | --- | --- |
| Trục A - Quyền sản phẩm | Guest; Free; Plus; FamilyPlus | Quyết định người dùng được sử dụng module nào, quota nào và có thể truy cập dữ liệu của ai. |
| Trục B - Trạng thái Sale | Không phải Sale; Sale đang hoạt động | Quyết định người dùng có mã giới thiệu, cây giới thiệu, lịch sử hoa hồng và quyền nhận hoa hồng hay không. |

## 3.2. Nguyên tắc kế thừa quyền gói

- Plus kế thừa toàn bộ quyền của Free, trừ các giới hạn được Plus mở hoặc thay đổi rõ trong BD.
- FamilyPlus kế thừa toàn bộ quyền của Plus và Free, sau đó cộng thêm các quyền gia đình.
- Guest/V1 không phải một thành viên Free. Guest chỉ được dùng allowlist V1 và phải bị chặn với tất cả chức năng không nằm trong allowlist.
- Sale không tự cấp thêm quyền về lịch trình, chat AI, theo dõi hay quản lý gia đình. Sale chỉ mở nhóm chức năng giới thiệu/hoa hồng.

---

# 4. Luồng nghiệp vụ tổng thể

## 4.1. Luồng từ cài ứng dụng đến sử dụng V1

| Bước | Sự kiện | Kết quả nghiệp vụ |
| --- | --- | --- |
| Bước 1 | Người dùng mở ứng dụng | Người dùng chưa cần đăng nhập để bắt đầu. |
| Bước 2 | Onboarding | Người dùng nhập thông tin cá nhân và dữ liệu cá nhân/sức khỏe cần thiết. |
| Bước 3 | Gemini AI tạo lịch trình cá nhân | AI nhận dữ liệu onboarding và tạo thực đơn, bài tập, lịch trình theo ngày/mốc. Đây là lần tạo miễn phí duy nhất của Guest. |
| Bước 4 | Guest dùng V1 | Xem và thực hiện lịch trình cá nhân; dùng các module tính toán sức khỏe cơ bản; nhận thông báo theo lịch trình. |
| Bước 5 | Guest yêu cầu chức năng ngoài V1 | Hệ thống chặn chức năng và điều hướng/tạo điểm vào đăng nhập hoặc đăng ký. |

## 4.2. Luồng sau đăng nhập

| Bước | Sự kiện | Kết quả nghiệp vụ |
| --- | --- | --- |
| Bước 1 | Đăng nhập thành công | Hệ thống xác thực người dùng bằng Supabase Auth. |
| Bước 2 | Truy vấn gói | Hệ thống truy vấn Supabase để xác định gói thành viên hiện hành của người dùng: Free, Plus hoặc FamilyPlus. |
| Bước 3 | Dựng quyền hiệu lực | Hệ thống áp quyền kế thừa theo gói và kiểm tra trạng thái Sale độc lập. |
| Bước 4 | Kiểm tra quota | Mọi lần dùng tính năng bị giới hạn phải kiểm tra quota trước khi cho thực hiện. |
| Bước 5 | Mở module đúng quyền | Người dùng chỉ thấy/dùng được đúng module thuộc gói và trạng thái Sale của mình. |

> **Quy tắc chặn bắt buộc:** Không được chỉ ẩn nút ở giao diện. Route, controller/use-case, API/datasource liên quan đến chức năng có giới hạn đều phải kiểm tra quyền hiệu lực và quota ở tầng phù hợp.

---

# 5. Yêu cầu nghiệp vụ chi tiết

## BR-01 — Onboarding và lưu dữ liệu đầu vào

**Mục đích:** Thu thập thông tin cá nhân và dữ liệu cá nhân/sức khỏe để hình thành hồ sơ đầu vào cho cá nhân hóa.

- Người dùng phải có thể hoàn tất onboarding mà chưa cần đăng nhập.
- Dữ liệu onboarding là đầu vào để Gemini AI tạo lịch trình cá nhân.
- Sau khi onboarding thành công, hệ thống chuyển người dùng sang bước tạo lịch trình cá nhân lần đầu.

**Tiêu chí chấp nhận:** Guest có thể hoàn tất onboarding mà không bị buộc đăng nhập; dữ liệu vừa nhập được dùng cho lần sinh lịch trình đầu tiên.

## BR-02 — Gemini AI tạo lịch trình cá nhân

**Mục đích:** Tạo một lịch trình cá nhân hóa từ dữ liệu onboarding.

- Gemini AI nhận dữ liệu onboarding của người dùng.
- Kết quả bắt buộc bao gồm: thực đơn, bài tập và lịch trình cá nhân theo ngày/mốc thời gian.
- Trong BD này, toàn bộ kết quả trên được gọi chung là “lịch trình cá nhân”.
- Hệ thống phải lưu/truy xuất được lịch trình để hiển thị và tạo thông báo theo từng ngày/mốc.

**Tiêu chí chấp nhận:** Sau onboarding, người dùng nhận được lịch trình chứa đủ ba thành phần: thực đơn, bài tập và các mốc lịch trình.

## BR-03 — Quyền Guest/V1 - dùng trước khi đăng nhập

**Mục đích:** Cho phép người dùng trải nghiệm giá trị cốt lõi nhưng giới hạn rõ phạm vi.

- Guest được phép tạo lịch trình cá nhân đúng một lần duy nhất, ngay sau onboarding.
- Nếu Guest muốn tạo lịch trình cá nhân thêm lần nữa, hệ thống phải yêu cầu đăng nhập trước.
- Guest được dùng các module tính toán dữ liệu sức khỏe cơ bản.
- Guest được nhận thông báo theo lịch trình cá nhân, theo từng ngày và từng mốc thời gian.
- Ngoài các chức năng trên và luồng xác thực, Guest không được dùng bất kỳ module/tính năng nào khác.

**Tiêu chí chấp nhận:** Sau lần sinh lịch trình đầu tiên, mọi yêu cầu tạo thêm của Guest hiển thị/điều hướng sang đăng nhập; các module ngoài V1 không mở được bằng UI, deep-link hay gọi trực tiếp use-case.

## BR-04 — Đăng nhập và xác định gói thành viên

**Mục đích:** Sau đăng nhập, cấp đúng quyền dựa trên gói thành viên của tài khoản.

- Khi đăng nhập thành công, hệ thống phải truy vấn dữ liệu gói thành viên của người đó trên Supabase.
- Giá trị gói chính hợp lệ là: Free, Plus hoặc FamilyPlus.
- Hệ thống phải tạo một “quyền hiệu lực” dùng chung cho điều hướng, hiển thị module, use-case và quota.
- Gói cao hơn phải kế thừa các quyền của gói thấp hơn theo quy tắc trong BD.

**Tiêu chí chấp nhận:** Đăng nhập bằng các tài khoản thuộc từng gói cho ra đúng danh sách quyền và giới hạn tương ứng.

## BR-05 — Gói Free

**Mục đích:** Cung cấp bộ tính năng thành viên cơ bản sau khi đăng nhập; tương ứng định hướng V2.

- Thêm AI Chat.
- AI Chat bị giới hạn tối đa 3 lượt hỏi trong mỗi ngày theo tài khoản.
- Tạo lịch trình cá nhân mới bị giới hạn tối đa 3 lần trong mỗi tháng theo tài khoản.
- Thêm cơ chế tính điểm dựa trên lịch sử sử dụng ứng dụng, đặc biệt là mức độ thực hiện các lịch trình cá nhân do AI tạo.
- Người dùng thực hiện càng nhiều và càng đều các hoạt động trong lịch trình thì điểm đánh giá càng cao; công thức cụ thể được đặc tả sau ở DD/BD điểm.

**Tiêu chí chấp nhận:** Tài khoản Free hỏi chat lần thứ 4 trong cùng ngày bị chặn; tạo lịch trình lần thứ 4 trong cùng tháng bị chặn; điểm thay đổi theo lịch sử thực hiện lịch trình.

## BR-06 — Gói Plus

**Mục đích:** Mở rộng toàn bộ Free bằng các trải nghiệm cá nhân hóa và theo dõi nâng cao; định hướng phát triển V3.

- Kế thừa toàn bộ tính năng của gói Free.
- Cho phép tạo các lộ trình riêng cho từng mục tiêu sau onboarding.
- Bổ sung các module tính toán cao hơn.
- Bổ sung nhiều tính năng theo dõi sức khỏe tốt hơn.
- Mở giới hạn AI Chat: không giới hạn số lượt hỏi.
- Mở giới hạn tạo thực đơn/lịch trình cá nhân: không giới hạn số lần tạo.

**Tiêu chí chấp nhận:** Tài khoản Plus không bị chặn bởi quota chat 3 lượt/ngày hay quota tạo lịch trình 3 lần/tháng; có thể tạo lộ trình theo mục tiêu sau onboarding.

## BR-07 — Gói FamilyPlus

**Mục đích:** Mở rộng Plus để phục vụ quản lý sức khỏe nhiều thành viên trong một gia đình.

- Kế thừa toàn bộ quyền của Plus và Free.
- Hỗ trợ onboarding cho cả gia đình, tức có thể tạo/cập nhật dữ liệu onboarding cho nhiều thành viên.
- Tạo menu/thực đơn cho cả gia đình.
- Theo dõi sức khỏe cho tất cả thành viên trong gia đình.
- Cho phép thêm thành viên vào gói gia đình.
- Các thành viên trong gia đình có thể xem và theo dõi sức khỏe, lịch trình của nhau theo quan hệ FamilyPlus.
- Hỗ trợ thành viên gia đình tạo lịch trình, cá nhân hóa và tinh chỉnh bữa ăn, bài tập, lịch trình cá nhân.

**Tiêu chí chấp nhận:** FamilyPlus quản lý được nhiều thành viên, có dữ liệu/lịch trình riêng từng thành viên và có khả năng xem/theo dõi chéo trong phạm vi gia đình.

## BR-08 — Điểm thực hiện lịch trình

**Mục đích:** Khuyến khích người dùng duy trì thói quen bằng cơ chế điểm ở gói Free và các gói kế thừa.

- Điểm được tính từ lịch sử dùng ứng dụng liên quan đến các lịch trình cá nhân do AI tạo.
- Dữ liệu đầu vào tối thiểu là trạng thái thực hiện/không thực hiện các mốc, bữa ăn, bài tập hoặc nhiệm vụ trong lịch trình.
- Điểm phản ánh cả mức độ hoàn thành và tính đều đặn theo thời gian.
- Plus và FamilyPlus kế thừa cơ chế điểm của Free.

**Tiêu chí chấp nhận:** Khi người dùng đánh dấu mức độ thực hiện lịch trình ở nhiều ngày, hệ thống có dữ liệu để tính/cập nhật điểm theo đúng công thức được phê duyệt sau này.

---

# 6. Ma trận quyền và giới hạn sử dụng

| Chức năng | Guest / V1 | Free / V2 | Plus / V3 | FamilyPlus / V3 |
| --- | --- | --- | --- | --- |
| Onboarding cá nhân | Có | Có | Có | Có |
| Sinh lịch trình AI lần đầu sau onboarding | Có - đúng 1 lần | Có | Có | Có |
| Sinh lịch trình AI mới | Không - phải đăng nhập | Tối đa 3 lần/tháng | Không giới hạn | Không giới hạn |
| Thực đơn/bài tập/lịch trình đã có | Có | Có | Có | Có |
| Tính toán sức khỏe cơ bản | Có | Có | Có | Có |
| Thông báo theo lịch trình cá nhân | Có | Có | Có | Có |
| AI Chat | Không | Tối đa 3 lượt/ngày | Không giới hạn | Không giới hạn (kế thừa Plus) |
| Điểm theo lịch sử thực hiện lịch trình | Không nêu trong V1 | Có | Có (kế thừa) | Có (kế thừa) |
| Lộ trình riêng theo từng mục tiêu | Không | Không | Có | Có (kế thừa) |
| Module tính toán nâng cao / theo dõi sức khỏe nâng cao | Không | Không | Có | Có (kế thừa) |
| Onboarding nhiều thành viên gia đình | Không | Không | Không | Có |
| Menu gia đình / theo dõi thành viên / tinh chỉnh cho thành viên | Không | Không | Không | Có |

> **Nguyên tắc allowlist của V1:** Cột Guest/V1 là danh sách quyền đóng. Dù một module hiện có trong code, nếu không nằm trong danh sách này thì Guest không được sử dụng cho đến khi đăng nhập và có quyền gói phù hợp.

---

# 7. Cơ chế Sale, giới thiệu và hoa hồng hai tầng

## 7.1. Bản chất vai trò Sale

Sale là một vai trò đặc biệt độc lập với gói thành viên. Một người có thể đồng thời là người dùng ứng dụng với gói Free/Plus/FamilyPlus và là Sale. Quyền Sale không kế thừa từ V1/V2/V3 và cũng không thay đổi quyền sử dụng tính năng sức khỏe của gói thành viên.

## 7.2. Điều kiện tạo quan hệ giới thiệu

- Người được giới thiệu phải hoàn thành các bước: tải ứng dụng, onboarding thành công, tạo tài khoản thành công và thêm mã giới thiệu.
- Mã giới thiệu xác định người giới thiệu (Sale) trong cây giới thiệu.
- Quan hệ giới thiệu được sử dụng để tính hoa hồng khi người được giới thiệu mua gói và khoản chuyển khoản/thanh toán được xác nhận thành công.

## 7.3. Cây giới thiệu và giới hạn độ sâu

Mỗi Sale có thể giới thiệu không giới hạn số người trực tiếp. Mỗi người trực tiếp, nếu trở thành Sale, có thể tiếp tục giới thiệu không giới hạn người khác. Tuy nhiên, hệ thống chỉ tính hoa hồng tối đa hai tầng tính từ mỗi Sale.

```text
A (Sale)
├── B (được A giới thiệu; có thể trở thành Sale) → A hưởng 10% từ các khoản B thanh toán thành công
│   └── C (được B giới thiệu) → B hưởng 10%, A hưởng 5% từ các khoản C thanh toán thành công
├── D (tầng 1 khác)
├── E (tầng 1 khác)
└── F (tầng 1 khác)
```

> **Quy tắc:** Số nhánh cùng tầng không giới hạn; độ sâu nhận hoa hồng tối đa 2 tầng.

## 7.4. Quy tắc hoa hồng

| Tình huống thanh toán | Người nhận hoa hồng | Tỷ lệ | Thời điểm ghi nhận |
| --- | --- | --- | --- |
| B do A giới thiệu mua gói/đóng phí thành công | A | 10% | Ngay sau khi khoản thanh toán/chuyển khoản của B được xác nhận thành công; áp dụng cho lần mua ban đầu và mỗi kỳ B tiếp tục thanh toán thành công. |
| C do B giới thiệu mua gói/đóng phí thành công | B | 10% | Ngay sau khi khoản thanh toán/chuyển khoản của C được xác nhận thành công; áp dụng cho các kỳ C tiếp tục thanh toán thành công. |
| C do B giới thiệu mua gói/đóng phí thành công | A | 5% | Ngay sau khi khoản thanh toán/chuyển khoản của C được xác nhận thành công; đây là hoa hồng tầng 2 của A. |
| Người ở tầng 3 hoặc sâu hơn thanh toán | Không có người trên tầng 2 nhận hoa hồng từ giao dịch đó | 0% ngoài tầng 2 | Không phát sinh hoa hồng vượt quá hai tầng. |

## 7.5. Trường hợp “đứt gãy chuỗi” theo yêu cầu

Ví dụ: A giới thiệu B; B giới thiệu C. B đột ngột không mua/không tiếp tục đóng gói ứng dụng.

| Sự kiện | Kết quả hoa hồng |
| --- | --- |
| B không có khoản thanh toán thành công trong kỳ | A không nhận 10% từ B trong kỳ đó vì không có giao dịch B để tính hoa hồng. |
| C vẫn có khoản thanh toán thành công trong kỳ | B vẫn hưởng 10% từ khoản C thanh toán thành công và A vẫn hưởng 5% từ khoản C thanh toán thành công. |
| C không thanh toán thành công | Không phát sinh 10% cho B và 5% cho A từ C trong kỳ đó. |

> **Diễn giải chính thức:** Hoa hồng bám theo từng khoản thanh toán thành công của người nằm trong cây hai tầng, không phụ thuộc vào việc người giới thiệu trung gian có tự mua gói trong cùng kỳ hay không. Khi không có khoản thanh toán thành công, không có hoa hồng phát sinh cho khoản đó.

## 7.6. Dữ liệu và màn hình tối thiểu của Sale

- Trạng thái Sale của tài khoản.
- Mã giới thiệu của Sale.
- Thông tin người được giới thiệu trực tiếp (tầng 1) và gián tiếp (tầng 2) theo quyền hiển thị đã được chính sách riêng phê duyệt.
- Lịch sử khoản thanh toán đủ điều kiện phát sinh hoa hồng.
- Lịch sử hoa hồng: nguồn giao dịch, tầng nhận hoa hồng, tỷ lệ và trạng thái ghi nhận.
- Tổng quan hoa hồng đã phát sinh theo kỳ/giai đoạn.

---

# 8. Mô hình dữ liệu nghiệp vụ mức khái niệm

Phần này không phải thiết kế database vật lý. Đây là danh sách thực thể nghiệp vụ tối thiểu để DD, API và migration sau này không bỏ sót dữ liệu cần cho các luồng đã mô tả.

| Thực thể | Mục đích nghiệp vụ | Liên hệ chính |
| --- | --- | --- |
| Hồ sơ onboarding | Lưu dữ liệu cá nhân/sức khỏe ban đầu làm đầu vào cá nhân hóa. | Thuộc người dùng/Guest; được dùng để sinh lịch trình. |
| Lịch trình cá nhân | Lưu thực đơn, bài tập, mốc lịch theo kết quả Gemini AI. | Thuộc một người; có nhiều mục và thông báo. |
| Mục lịch trình / trạng thái thực hiện | Ghi nhận đã làm/chưa làm/bỏ qua hoặc trạng thái được hệ thống hỗ trợ. | Dùng để tính điểm và theo dõi sức khỏe. |
| Thông báo lịch trình | Lưu/lập lịch nhắc theo từng ngày, từng mốc của lịch trình. | Gắn với lịch trình và mục lịch trình. |
| Tài khoản / gói thành viên | Xác định định danh Supabase và gói Free/Plus/FamilyPlus. | Dùng để dựng quyền và quota. |
| Quota sử dụng | Theo dõi lượt AI Chat/ngày, lượt tạo lịch trình/tháng hoặc quota khác. | Gắn với tài khoản và kỳ tính quota. |
| Điểm / lịch sử tính điểm | Lưu điểm đánh giá dựa trên mức độ hoàn thành và đều đặn. | Gắn với lịch sử thực hiện lịch trình. |
| Nhóm gia đình | Đại diện phạm vi FamilyPlus. | Có chủ gói và nhiều thành viên. |
| Thành viên gia đình | Đại diện từng người trong nhóm; có hồ sơ, lịch trình và sức khỏe riêng. | Thuộc nhóm gia đình. |
| Trạng thái Sale / mã giới thiệu | Đánh dấu quyền Sale và mã dùng để giới thiệu. | Gắn với một tài khoản. |
| Quan hệ giới thiệu | Lưu người giới thiệu - người được giới thiệu và cấp tầng trong cây. | Dùng để xác định 10%/5%. |
| Khoản thanh toán gói | Nguồn sự kiện xác nhận mua/duy trì gói. | Dùng để tính hoa hồng theo giao dịch thành công. |
| Bản ghi hoa hồng | Ghi nhận hoa hồng phát sinh từ từng khoản thanh toán. | Gắn với sale nhận, người trả, tầng, tỷ lệ và giao dịch nguồn. |

---

# 9. Quy tắc kiểm soát quyền, quota và thông báo

## 9.1. Kiểm soát quyền

- Mọi điểm truy cập tính năng phải dựa trên “quyền hiệu lực” được xác định từ trạng thái đăng nhập + gói thành viên + trạng thái Sale.
- Ẩn UI không thay thế cho kiểm soát nghiệp vụ. Hệ thống phải kiểm tra khi mở route, khi gọi use-case/controller và trước thao tác có tính phí/giới hạn.
- Guest chỉ được đi qua các route/module thuộc V1; mọi route ngoài V1 phải yêu cầu đăng nhập.
- FamilyPlus chỉ mở dữ liệu và thao tác của thành viên nằm trong cùng nhóm gia đình; chi tiết cơ chế đồng ý/quyền riêng tư cần được xác nhận riêng trước DD.

## 9.2. Kiểm soát quota

| Quota | Đối tượng | Chu kỳ | Ngưỡng | Hành vi khi vượt ngưỡng |
| --- | --- | --- | --- | --- |
| AI Chat | Free | Theo ngày | 3 lượt hỏi/ngày | Chặn lượt hỏi tiếp theo trong ngày và hiển thị lý do/điểm nâng cấp phù hợp. |
| Tạo lịch trình cá nhân mới | Free | Theo tháng | 3 lần/tháng | Chặn lần tạo tiếp theo trong tháng và hiển thị lý do/điểm nâng cấp phù hợp. |
| Sinh lịch trình sau onboarding | Guest | Trọn vòng đời Guest trên thiết bị/tài khoản theo thiết kế kỹ thuật | 1 lần duy nhất | Yêu cầu đăng nhập trước khi tạo thêm. |
| AI Chat và tạo lịch trình | Plus/FamilyPlus | Không giới hạn theo BD | Không giới hạn | Không chặn vì quota; vẫn áp dụng bảo vệ kỹ thuật/an toàn hệ thống ngoài phạm vi BD. |

## 9.3. Thông báo theo lịch trình

- Thông báo được lập dựa trên lịch trình cá nhân đã tạo.
- Thông báo phải hỗ trợ nhắc theo từng ngày và từng mốc thời gian trong lịch trình.
- Guest/V1 được nhận thông báo này mà không cần đăng nhập.
- Các gói thành viên kế thừa thông báo theo lịch trình; FamilyPlus sẽ có dữ liệu lịch trình cho nhiều thành viên, còn quy tắc gửi/nhận chéo cần DD riêng.

---

# 10. Tiêu chí chấp nhận theo luồng

| Mã AC | Tình huống | Kết quả phải đạt |
| --- | --- | --- |
| AC-01 | Guest hoàn tất onboarding | Gemini AI được gọi theo luồng và lịch trình cá nhân gồm thực đơn, bài tập, mốc lịch được tạo/hiển thị. |
| AC-02 | Guest đã có lịch trình lần đầu, yêu cầu tạo thêm | Không tạo mới; hệ thống yêu cầu người dùng đăng nhập. |
| AC-03 | Guest mở module ngoài V1 | Bị chặn và có điểm vào đăng nhập/đăng ký; không thể vượt chặn bằng điều hướng trực tiếp. |
| AC-04 | Free dùng AI Chat lần 4 trong ngày | Bị chặn do vượt quota 3 lượt/ngày. |
| AC-05 | Free tạo lịch trình lần 4 trong tháng | Bị chặn do vượt quota 3 lần/tháng. |
| AC-06 | Plus dùng AI Chat/tạo lịch trình | Không bị chặn bởi hai quota của Free. |
| AC-07 | FamilyPlus thêm thành viên và tạo lịch trình cho thành viên | Có thể quản lý dữ liệu/lịch trình theo từng thành viên trong cùng gia đình. |
| AC-08 | A giới thiệu B; B thanh toán gói thành công | A có bản ghi hoa hồng 10% cho giao dịch B. |
| AC-09 | B là Sale, giới thiệu C; C thanh toán gói thành công | B có bản ghi hoa hồng 10%; A có bản ghi hoa hồng 5% cho cùng giao dịch C. |
| AC-10 | B không thanh toán kỳ này nhưng C thanh toán thành công | Không có hoa hồng từ B; vẫn phát sinh 10% cho B và 5% cho A từ giao dịch C. |
| AC-11 | Người ở tầng 3 thanh toán | Không tạo hoa hồng cho các Sale nằm ngoài hai tầng tính từ người thanh toán. |

---

# 11. Yêu cầu cập nhật `.codex` cho các phiên sau

Mục này là nội dung bắt buộc để cập nhật context dự án. Mục tiêu là mọi AI Agent/Codex đọc đúng sản phẩm trước khi sửa code, tránh mở sai quyền Guest, nhầm Sale là gói thành viên hoặc triển khai sai quota.

## 11.1. Bổ sung nguồn BD và thứ tự đọc

- Thêm tài liệu BD này vào `docs/BD/` theo một tên ổn định, ví dụ: `docs/BD/BD_Product_Flow_Membership_Sale.md` hoặc bản Word kèm Markdown nguồn.
- Trong `.codex/AGENTS.md` và/hoặc `.codex/DOCS_WORKFLOW.md`, bắt buộc đọc BD này trước khi làm các task thuộc onboarding, auth, gói thành viên, AI chat, tạo lịch trình, notification, family hoặc referral/sale.
- Khi BD và code hiện tại mâu thuẫn, agent phải báo rõ phạm vi mâu thuẫn; không tự mở rộng quyền Guest hoặc thay quota chỉ để khớp code cũ.

## 11.2. Nội dung sản phẩm phải ghi vào `.codex`

| File `.codex` đề xuất | Nội dung bắt buộc bổ sung |
| --- | --- |
| AGENTS.md | Quy tắc cứng: Guest/V1 dùng allowlist; Free/Plus/FamilyPlus là gói sau đăng nhập; Sale là trạng thái độc lập. Không triển khai tính năng ngoài gói/role. |
| PROJECT_MAP.md | Bổ sung các domain/module: membership_entitlement, usage_quota, health_scoring, family, referral, sale_commission, payment_event. |
| DOCS_WORKFLOW.md | Khi làm feature mới phải xác định đúng gói/role, cập nhật BD/DD/feature docs/test/worklog theo workflow. |
| playbooks/onboarding.md | Onboarding -> Gemini tạo lịch trình lần đầu -> Guest chỉ dùng V1; không làm phát sinh tính năng đăng nhập bắt buộc. |
| playbooks/auth_membership.md (mới) | Login -> Supabase -> truy vấn gói -> dựng quyền hiệu lực -> kiểm tra quota tại route/use-case. |
| playbooks/referral_sale.md (mới) | Sale độc lập; cây 2 tầng; 10% trực tiếp, 5% gián tiếp; hoa hồng theo thanh toán thành công. |
| playbooks/family.md (mới) | FamilyPlus kế thừa Plus/Free; dữ liệu và lịch trình theo từng thành viên; không lẫn hồ sơ của các thành viên. |
| TEST_WORKFLOW.md | Thêm test matrix cho Guest gate, Free quota, Plus unlimited, FamilyPlus member boundary, referral 2 tầng và đứt gãy chuỗi. |

## 11.3. Quy tắc bắt buộc cho mọi task liên quan

- Trước khi coding, xác định rõ task thuộc Guest/V1, Free, Plus, FamilyPlus, Sale hoặc nhiều trạng thái kết hợp.
- Không thêm nút/module cho Guest nếu BD không cho phép; không “mở thử” bằng flag UI.
- Mọi quota phải có test cho: trong giới hạn, đúng ngưỡng, vượt ngưỡng, reset sang kỳ mới và chuyển gói.
- Mọi logic Sale phải có test tối thiểu cho: tầng 1, tầng 2, nhiều nhánh cùng tầng, không phát sinh tầng 3 và trường hợp B không thanh toán nhưng C vẫn thanh toán.
- Task triển khai phải ghi rõ file docs, test và worklog được cập nhật để truy vết sau này.

---

# 12. Điểm cần Product Owner xác nhận trước khi DD/coding

Các điểm sau chưa có thông tin đủ trong yêu cầu hiện tại. BD không tự đặt ra luật mới. Chúng cần được xác nhận trước khi đi vào thiết kế kỹ thuật hoặc vận hành thực tế.

| Mã | Điểm cần xác nhận | Lý do cần chốt |
| --- | --- | --- |
| Q-01 | Guest được xác định “1 lần tạo lịch trình” theo thiết bị, cài đặt ứng dụng, hồ sơ local hay tài khoản sau khi đăng nhập? | Quyết định cách chống tạo lại khi xóa app/đổi thiết bị và cách chuyển dữ liệu Guest sang tài khoản. |
| Q-02 | Khi Guest đăng ký/đăng nhập, lịch trình và dữ liệu onboarding local có được đồng bộ/gắn với tài khoản Supabase không? | Cần xác định luồng migration dữ liệu và tránh mất lịch trình đã tạo. |
| Q-03 | Thế nào là một “lượt hỏi AI Chat”: một tin nhắn, một phiên chat hay một yêu cầu AI thành công? | Cần tiêu chí đo quota chính xác. |
| Q-04 | Mốc reset quota ngày/tháng theo múi giờ nào và cách xử lý khi người dùng đổi múi giờ? | Tránh quota bị tính sai hoặc bị khai thác. |
| Q-05 | Công thức điểm, trọng số đều đặn, cách xử lý bỏ qua/không thực hiện và cách hiển thị điểm? | Không thể triển khai “điểm” chính xác khi chưa có công thức. |
| Q-06 | Plus/FamilyPlus là gói theo tháng, năm hay hình thức khác; quá hạn gói thì quyền thay đổi thế nào? | Ảnh hưởng entitlement, payment event và quota. |
| Q-07 | Mức giới hạn số thành viên FamilyPlus, quyền thêm/xóa, quyền xem/sửa và cơ chế đồng ý chia sẻ sức khỏe? | Ảnh hưởng phạm vi dữ liệu cá nhân và quyền riêng tư. |
| Q-08 | Điều kiện để người dùng trở thành Sale và điều kiện duy trì/khóa trạng thái Sale? | Yêu cầu gốc nêu B có thể đăng ký làm Sale nhưng chưa định nghĩa quy trình, duyệt hay điều kiện. |
| Q-09 | Mã giới thiệu có thể thay đổi sau khi gắn không? Có cấm tự giới thiệu, tài khoản trùng, hoàn tiền/chargeback không? | Bắt buộc để chống gian lận và đảm bảo cây giới thiệu nhất quán. |
| Q-10 | Cơ chế ghi nhận chuyển khoản thành công, đối soát, điều chỉnh/hủy hoa hồng, rút tiền và báo cáo doanh thu? | Cần thiết cho vận hành tài chính; ngoài phạm vi BD hiện tại. |

> **Kết luận nghiệp vụ:** Tài liệu này đã chốt quyền theo gói, luồng Guest/V1, Sale độc lập và công thức phân bổ hoa hồng 10%/5% tối đa hai tầng theo khoản thanh toán thành công. Các câu Q-01 đến Q-10 chỉ là điểm cần chốt thêm để thiết kế DD/API/database không phải suy đoán.

---

# Phụ lục A. Danh sách Use Case mức cao

| Mã UC | Tên Use Case | Actor chính |
| --- | --- | --- |
| UC-01 | Onboarding người dùng chưa đăng nhập | Guest |
| UC-02 | Sinh lịch trình cá nhân lần đầu bằng Gemini AI | Guest |
| UC-03 | Dùng tính toán sức khỏe cơ bản | Guest/Member |
| UC-04 | Nhận thông báo theo lịch trình cá nhân | Guest/Member |
| UC-05 | Đăng ký/đăng nhập và nhận quyền gói | Guest/Member |
| UC-06 | AI Chat có quota Free | Free |
| UC-07 | Tạo lịch trình mới có quota Free | Free |
| UC-08 | Theo dõi và tính điểm thực hiện lịch trình | Free/Plus/FamilyPlus |
| UC-09 | Tạo lộ trình theo mục tiêu | Plus/FamilyPlus |
| UC-10 | Theo dõi sức khỏe nâng cao | Plus/FamilyPlus |
| UC-11 | Quản lý thành viên gia đình và lịch trình từng thành viên | FamilyPlus |
| UC-12 | Gắn mã giới thiệu khi tạo tài khoản | Người được giới thiệu |
| UC-13 | Đăng ký/hoạt động với vai trò Sale | Member/Sale |
| UC-14 | Ghi nhận hoa hồng tầng 1 | Sale/System |
| UC-15 | Ghi nhận hoa hồng tầng 2 | Sale/System |
