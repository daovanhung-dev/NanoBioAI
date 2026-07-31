# AH M20–M29 — audit ranh giới catalog shell và Draft

- Campaign: `full-project-2026-07-28`
- Run ID: `FP-20260728-AH-SOURCE-AUDIT-001`
- Command ID: `CMD-20260728-AH-SOURCE-AUDIT-001`
- Entry point được đối chiếu: `lib/main.dart` → `BioAIApp` → `BioAIV2App`
- Source revision: `9e81b08b9ae2aab4e1c263f99b044002059b4bb0`
- Loại evidence: audit mã/BD đọc-only. File này **không** khẳng định đã chạy trên thiết bị, không chứa ảnh, credential, email fixture, dữ liệu sức khỏe hay payload.

## Kết luận dùng cho campaign

BD Advanced Health vẫn là `Draft - UI catalog shell approved`. Phạm vi được
duyệt chỉ là tên, thứ tự, nhãn gói và điều hướng của 10 card; ghi nhận dữ liệu,
AI, cảnh báo, đồng bộ, thiết bị và chia sẻ chưa được duyệt để coding.

Vì vậy:

- `AH-001` đến `AH-004` là **shell cases phải có evidence thiết bị thật**.
- `AH-020` đến `AH-029` là kiểm tra nghiệp vụ sâu chưa thể thực thi. Ghi
  `N/A` (hoặc `GAP` khi case trộn assertion shell với phạm vi Draft), trích
  đúng §12; không tạo dữ liệu sức khỏe giả và không mở issue implementation
  chỉ vì không có form Draft.
- Không dùng route `/v3/advanced-tracking` thay cho M20–M29. Đây là roadmap
  hydration riêng, không phải catalog/route Advanced Health của BD này.

## Contract shell đã xác minh từ nguồn

Điểm vào trên giao diện người dùng là tab **Tiện ích** của `MainNavigationPage`
→ section **Theo dõi chuyên sâu** → card →
`/v2/health-modules/<Mxx>`.

Catalog có đúng 10 card theo thứ tự sau; ba card đầu nhãn **Miễn phí**, bảy
card sau nhãn **Plus**, và tất cả đều có trạng thái **Đang phát triển**:

| Module | Tên trên card | Nhãn minimum access | Kết quả gate mong đợi |
| --- | --- | --- | --- |
| M20 | Nhật ký huyết áp | Miễn phí | Free/Plus/FamilyPlus → placeholder |
| M21 | Nhịp tim & SpO₂ | Miễn phí | Free/Plus/FamilyPlus → placeholder |
| M22 | Lịch dùng thuốc | Miễn phí | Free/Plus/FamilyPlus → placeholder |
| M23 | Theo dõi đường huyết | Plus | Free → nâng cấp; Plus/FamilyPlus → placeholder |
| M24 | Nhật ký triệu chứng & cơn đau | Plus | Free → nâng cấp; Plus/FamilyPlus → placeholder |
| M25 | Chu kỳ & sức khỏe nữ | Plus | Free → nâng cấp; Plus/FamilyPlus → placeholder |
| M26 | Hô hấp & dị ứng | Plus | Free → nâng cấp; Plus/FamilyPlus → placeholder |
| M27 | Xét nghiệm & chỉ số y khoa | Plus | Free → nâng cấp; Plus/FamilyPlus → placeholder |
| M28 | Lịch chăm sóc dự phòng | Plus | Free → nâng cấp; Plus/FamilyPlus → placeholder |
| M29 | Xu hướng sức khỏe cùng Nabi | Plus | Free → nâng cấp; Plus/FamilyPlus → placeholder |

Resolver hiện hành fail-closed khi access thiếu/lỗi/không hợp lệ. Placeholder
chỉ là `MedicalComingSoonPage`: tiêu đề module, copy đang phát triển và ba
mục preview; không có form record trong page này.

## Luồng thiết bị bắt buộc cho từng shell case

Không dùng deep link hay test route ẩn. Với mỗi persona hợp lệ, đợi auth/sync
ổn định, mở **Tiện ích**, cuộn tới **Theo dõi chuyên sâu**, rồi thao tác card.
Ảnh thiết bị chỉ được đưa vào campaign sau khi kiểm tra không có PII.

| Case | Persona alias | Thao tác thiết bị và assertion | Evidence tối thiểu | Disposition trước khi chạy |
| --- | --- | --- | --- | --- |
| AH-001 | `GST-ANON` | Thiết lập phiên anonymous theo fixture contract, mở catalog, chọn M20 và kiểm tra chuyển tới login; Back phải không làm phát sinh dữ liệu. | Catalog và landing login/back, nếu session thiết lập được. | Cần kiểm tra thực tế; xem caveat anonymous bên dưới. |
| AH-002 | `FREE-READY` | Xác nhận 10 card/thứ tự/nhãn; mở từng M20–M22 và thấy placeholder đúng title; mở từng M23–M29 và tới trang **Thanh toán gói thành viên**. Không bấm tạo yêu cầu thanh toán. | Catalog đủ hai vị trí cuộn, một placeholder Free và trang upgrade; ảnh thêm nếu cần chứng minh từng title. | Bị chặn nếu fixture còn `not_started` và không có reset được phép sau onboarding. |
| AH-003 | `PLUS-ACTIVE` | Xác nhận catalog; mở lần lượt M20–M29, mỗi route phải hiển thị placeholder đúng title/copy, quay lại được. Không xuất hiện permission, form input, AI/quota/reminder action. | Catalog và ảnh placeholder đã kiểm tra cho các route đã mở. | Có thể chạy sau khi xác nhận fixture/sync hoàn tất. |
| AH-004 | `LEG-FAMILY`, `FAM-OWNER` | Với từng alias, xác nhận FamilyPlus vào placeholder cho M20 và một card Plus (M29); không tự thay đổi gói hay tạo dữ liệu. | Catalog/placeholder mỗi persona nếu surface khác nhau. | Phần catalog/gate phải chạy; phần “chọn subject” là Draft N/A/GAP, không phải assertion PASS/FAIL của shell. |

Kiểm tra accessibility trên máy thật: dùng TalkBack hoặc inspection Android để
xác nhận card công bố tên, trạng thái đang phát triển và nhãn gói bằng text,
và có thể focus/tap. Mã đặt `Semantics(button: true, label: ...)`, nhưng việc
label cuối cùng được đọc bởi thiết bị phải được ghi từ quan sát thực tế, không
suy diễn PASS chỉ từ source.

## Hai caveat chặn/đòi hỏi evidence riêng

### AH-001 anonymous login escalation

Fixture contract yêu cầu `signInAnonymously`, nhưng không có lời gọi
`signInAnonymously` trong runtime app. Hơn nữa, snapshot/auth-route hiện chỉ
mang user ID, email và email-confirmed, không mang cờ anonymous. Một profile
anonymous đã completed vì thế có thể được phân loại `authenticatedReady`.

Health-module resolver sau đó đúng là trả `loginRequired`, nhưng forwarder đẩy
`/auth/login`; router lại chuyển mọi session không `unauthenticated` sang
AuthGate, rồi AuthGate đưa trạng thái `authenticatedReady` về `/menu`. Đây là
nguy cơ bounce về catalog thay vì landing login, trái AHF-AC-004. Cần một run
thiết bị với phiên anonymous thật để kết luận `PASS` hay `FAIL`; không thay nó
bằng guest chưa có phiên mà vẫn ghi là `GST-ANON`.

### AH-002 Free fixture onboarding

`FREE-READY` được seed `onboarding_status=not_started`. AuthGate chuyển
`not_started`/`in_progress` vào onboarding thay vì menu; hoàn tất onboarding
là mutation, cần sandbox reset sau cluster theo plan. Khi không có đường reset
admin được cấp, không được hoàn tất onboarding rồi để fixture drift. Case phải
ghi `BLOCKED` cho đến khi có reset/reseed được ủy quyền, hoặc được chạy trong
cluster có reset ngay sau đó.

## Phân loại 10 case nghiệp vụ Draft

| Case | Module / phạm vi chưa được duyệt | Kết quả ghi campaign đúng |
| --- | --- | --- |
| AH-020 | M20 record huyết áp, validation, history, disclaimer lâm sàng | `N/A` — §12 cấm form/persistence. Chỉ dùng placeholder shell từ AH-003 làm boundary evidence. |
| AH-021 | M21 heart-rate/SpO₂ record, context/source, device import | `N/A` — chưa có DD/clinical/device contract. |
| AH-022 | M22 medication schedule/adherence và M09 reminder ownership | `N/A` — không tạo medication/reminder. |
| AH-023 | M23 glucose record/validation/history | `N/A` cho nghiệp vụ sâu; gate Free→upgrade và Plus→placeholder phải được chạy trong AH-002/AH-003. |
| AH-024 | M24 symptom/pain record và AI safety | `N/A` — không nhập symptom hay gọi AI. |
| AH-025 | M25 cycle, consent, Family actor/subject/full-sharing | `N/A/GAP` — subject selector/consent không thuộc shell; không báo thiếu selector là bug. |
| AH-026 | M26 respiratory/allergy record và exposure | `N/A` — không tạo event hay action plan. |
| AH-027 | M27 lab result, OCR/extraction và user confirmation | `N/A` — không upload/nhập lab result hay gọi AI. |
| AH-028 | M28 preventive item và reminder intent/M09 | `N/A` — không tạo preventive item/reminder. |
| AH-029 | M29 trend statistics, consent, AI quota/audit/provenance | `N/A` — không gọi AI/đọc raw health data. |

## Static validation result

Lệnh đọc-only đã chạy:

```text
flutter test test/shared/health_features/health_feature_catalog_test.dart \
  test/app_versions/v2/features/health_modules/domain/health_module_access_resolver_test.dart \
  test/app_versions/v2/features/health_modules/presentation/health_module_access_page_test.dart \
  test/features/features_hub/features_hub_page_test.dart
```

Kết quả: **FAIL** sau 18.8 giây. Resolver/domain và access-page tests đi qua,
nhưng còn hai regression cần ghi nhận riêng nếu tái hiện trên thiết bị:

1. Catalog test kỳ vọng copy nêu AI đúng M24/M27/M29 nhưng mã hiện tại không
   có token `AI` trong các copy đó. Đây là test/copy-contract drift; chưa đủ để
   tuyên bố lỗi UX nếu chưa đối chiếu Product Owner.
2. `features_hub_page_test.dart` có expectation hero/copy cũ và phát hiện
   `RenderFlex` overflow tại `features_hub_page.dart:309` (6 px) và `:407`
   (tới 29 px) ở các size test, bao gồm width 360 logical px. Thiết bị campaign
   rộng 720 physical px có thể tương ứng width 360 logical px; phải chụp lại
   trên thiết bị thật trước khi tạo finding UI/UX.

## Source references

- `docs/BD/advanced_health/BD_BioAI_Advanced_Health_Features_v1.0.md:6,9,125-166,719-745` — trạng thái, shell AC/BR và gate Draft.
- `lib/app_versions/v1/features/features_hub/presentation/pages/features_hub_page.dart:61-78,377-469` — catalog, card/semantics/badge và dynamic navigation.
- `lib/shared/health_features/health_feature_catalog.dart:33-190` — registry/card order và copy.
- `lib/core/constants/routes/health_module_route_paths.dart:3-15`; `lib/app_versions/v2/router/v2_router.dart:72-76,113-145` — route và auth protection.
- `lib/app_versions/v2/features/health_modules/domain/health_module_access_resolver.dart:14-41`; `.../presentation/pages/health_module_access_page.dart:17-55` — effective-access gate và destinations.
- `lib/core/theme/medical_ui.dart:709-763` — placeholder has no business form.
- `lib/app_versions/v2/features/auth/data/datasources/supabase_auth_remote_datasource.dart:31-50`; `.../domain/services/auth_route_state_resolver.dart:13-56`; `.../presentation/pages/auth_gate_page.dart:111-117` — anonymous-session caveat and onboarding routing.
- `docs/supabase/19-dev-sandbox-accounts.md:37-40,49-56`; `docs/supabase/config.sql:10870-10879` — fixture role and onboarding state.
