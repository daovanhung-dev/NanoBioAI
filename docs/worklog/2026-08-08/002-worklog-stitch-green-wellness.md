# Worklog — Stitch Green Wellness foundation và gated UI refactor

## Metadata

- Ngày: 2026-08-08
- Workflow: `coding` + `docs`
- Domain chính: UI / Theme / Routing / Accessibility
- Domain liên quan: Auth, Wellness, FamilyPlus, Admin, Sale, Health, AI
- Nguồn thiết kế: `docs/refactor/stitch_nanobio_design_system`
- Trạng thái handoff: foundation và các lát cắt an toàn đã tích hợp; chưa production-ready

## Mục tiêu và ranh giới

Tích hợp nền tảng Green Wellness theo 76 cặp Stitch, giữ nguyên business contracts hiện hữu và fail closed cho mọi nghiệp vụ cần DD/Clinical/Privacy approval. Ảnh được dùng để đối chiếu layout, HTML để rút token/typography; runtime và DD luôn quyết định hành vi.

Không triển khai sớm health-record persistence, HealthKit/Health Connect, OCR, AI coaching/memory, FamilyPlus E2EE chat hoặc Sale care CRM. Không dùng dữ liệu mẫu, không hotlink và không mở quyền dựa trên presentation state.

## Thay đổi đã tích hợp

### 1. Source registry và design governance

- `docs/refactor/stitch_nanobio_design_system/IMPLEMENTATION_REGISTRY.md`: đủ 76 reference rows.
- `docs/refactor/stitch_nanobio_design_system/DD_READINESS.md`: gate pack cho DD/delta còn thiếu, không tự gắn trạng thái Approved.
- `tools/stitch/import_assets.py`, `tools/stitch/validate_registry.py`: import có kiểm soát và kiểm tra registry/manifest.
- `assets/config/stitch/manifest.json`: 90 asset, hash/MIME/kích thước/duplicate/license metadata.
- `.codex/design/**`: canonical Green token, route/surface matrix, status/handoff và `/today-tasks` spec được đồng bộ.

Toàn bộ asset Stitch hiện là reference/golden only vì `license_status=unverified` và `runtime_eligible=false`.

### 2. Theme, font và cutover

- `lib/core/theme/app_semantic_colors.dart`, `app_theme.dart`, `app_theme_flags.dart`: semantic colors, light/dark schemes literal và Green/Blue cutover facade.
- `lib/core/theme/medical_ui.dart`, `app_experience.dart`: shared primitives dùng semantic colors từ context.
- `assets/fonts/roboto/`: Roboto 400/500/600/700, OFL, source và SHA-256.
- `pubspec.yaml`: đăng ký font weights.
- V1/V2/V3 app roots và `lib/app/bio_ai_app.dart`: dùng theme setting hiện hữu, có light/dark theme.
- Admin: `AdminWorkspaceColors`, light/dark workspace theme và routed production surfaces dùng semantic workspace colors.

Cutover contract:

- Debug/profile không truyền define: Green bật để QA.
- Release không truyền define: Blue fail closed.
- Release chỉ bật Green khi truyền `--dart-define=STITCH_GREEN_UI_ENABLED=true`.
- `false` là rollback; business feature flags không được nhập chung vào cờ UI.

### 3. Baseline behavior

- Sửa Flutter contract `isSelected` từ nullable thành boolean.
- Auth fixture/back behavior dùng navigator contract tương thích.
- Sale không render cùng một message hai lần.
- AI input thất bại chỉ giữ ở UI draft, không ghi vào accepted history.

### 4. Wellness và routing an toàn

- Thêm `/water-tracking`, `/weekly-summary`, `/personal-goals`, `/quick-care`, `/gentle-care`, `/nami-care`.
- Thêm `/v3/familyplus` shell/effective-access gate nhưng không thêm FamilyPlus chat.
- Nami Care chỉ điều hướng tới năng lực runtime/local đã được phép; không có expert/booking/sample result.
- Water Tracking yêu cầu user tự chọn target, có non-medical copy, local daily persistence và loading/error/retry.
- Giữ `/health-tracking` là alias cho đến khi `DAILY_WELLNESS_JOURNAL` Approved.
- M20-M29 giữ catalog/placeholder; không thêm form, health persistence, permission, OCR, API hoặc AI call.

### 5. Semantic dark migration

- Shared medical components, routed Admin workspace và các production presentation surface trọng yếu chuyển từ static palette sang `context.semanticColors`/Admin workspace extension.
- Dark scheme không có pixel reference Stitch; acceptance dựa trên semantic parity, contrast và component states.
- Legacy presentation chưa nằm trong routed production path không được dùng làm bằng chứng 76/76 visual completion.

## Validation evidence đã có trước handoff cuối

| Lệnh/nhóm | Kết quả |
|---|---|
| `flutter pub get` | PASS |
| `python tools/stitch/validate_registry.py` | PASS: 76 pairs, 76 registry rows, 90 assets |
| `.codex/tools/validate_codex_integrity.ps1` tại mốc canonical/DD | PASS |
| Targeted theme suite tại mốc foundation | 51 tests PASS; Roboto, semantic dark và flag tests bổ sung PASS riêng |
| Green/rollback flag tests | Default và `STITCH_GREEN_UI_ENABLED=false`: 2 tests mỗi cấu hình, PASS |
| Auth + Sale + AI quota + router bundle | 55 tests PASS |
| Water Tracking + wellness routes | 9 tests PASS |
| Admin targeted analyze/tests | Analyze PASS; 54 tests PASS |
| App roots + Nami Care + Water + Features Hub targeted analyze | PASS |

Các con số trên là focused evidence của từng mốc. Chúng không thay cho full suite sau khi hợp nhất toàn bộ semantic presentation migration.

## Final validation — root cập nhật sau merge

- [ ] `dart format` cho toàn bộ Dart thay đổi — kết quả: _pending_.
- [ ] `flutter analyze` toàn repository — kết quả: _pending_.
- [ ] `flutter test` toàn repository — kết quả/số test: _pending_.
- [ ] `flutter build apk --debug` — artifact/kết quả: _pending_.
- [ ] `python tools/stitch/validate_registry.py` sau merge — kết quả: _pending_.
- [ ] `.codex/tools/validate_codex_integrity.ps1` sau docs/worklog refresh — kết quả: _pending_.
- [ ] `git diff --check` toàn patch — kết quả: _pending_.
- [ ] Golden/integration screenshot suite 76 surface — kết quả: _pending_.
- [ ] Supabase sandbox/RLS và Android/iOS real-device acceptance — kết quả: _pending_.

## Gate và rủi ro còn lại

1. Chưa có đủ 76/76 golden light/dark và adaptive/accessibility evidence; registry hoàn chỉnh không đồng nghĩa visual acceptance hoàn chỉnh.
2. Asset Stitch chưa xác minh license nên không được bật runtime.
3. DD cho daily journal/reports/self-care/sleep/stress, M20-M29 và các delta enterprise còn cần PO/Tech/QA/Clinical/Privacy approval.
4. AI coaching/memory, FamilyPlus chat/E2EE/escrow, health hubs/OCR/device sync và Sale CRM chưa được code; đây là gate có chủ đích.
5. Release Green phải opt-in tường minh và chỉ được bật sau gate; không xóa rollback Blue trong lượt này.
6. Chưa có store health-permission review, clinical/privacy acceptance, asset license clearance, Supabase sandbox matrix hoặc escrow key ceremony.

## Next session

1. Hợp nhất các lát cắt presentation, format rồi chạy full analyzer/test/build; ghi bằng chứng vào mục Final validation.
2. Tạo golden 76 surface theo viewport/text scale/light-dark matrix và sửa overflow/contrast/focus issues.
3. Trình duyệt DD/Clinical/Privacy theo `DD_READINESS.md`; chỉ mở business implementation module đã Approved.
4. Xác minh asset license trước khi đổi bất kỳ manifest row nào sang `runtime_eligible=true`.
5. Giữ release mặc định Blue cho đến cutover review; nếu rollout Green, giữ `false` làm rollback ít nhất một release.
