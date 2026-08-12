Commit đề xuất: `feat(nabi): ship botanical v2 asset catalog and release bundle`

# Worklog - Nabi v2 botanical asset system

## Thời gian

- Ngày: 2026-08-12
- Timezone: Asia/Saigon

## Phạm vi

- Loại task: coding / visual asset integration
- Module chính: Nabi companion, V1 presentation, onboarding, AI chat/voice
- Yêu cầu gốc: tái định hình Nabi thành tinh linh mầm cây, làm lại toàn bộ
  asset library và chuyển tất cả renderer sang catalog thống nhất.

## Đã làm

- Tạo master Nabi v2 bằng ImageGen: thân hạt ngà matte, hai lá mint, chi tiết
  xanh rừng và một giọt aqua tiết chế; tạo thêm pose thinking, celebrate, calm
  và gentle prompt làm anchor.
- Thêm pipeline `tools/generate_nabi_v2_assets.py`; các asset triển khai được
  sinh xác định từ master/anchor đã duyệt, không tự nhận là 84 minh họa độc
  lập do ImageGen tạo riêng lẻ.
- Sinh và validate 84 static PNG 512x512, 10 expression PNG 512x512, 30 x 30
  frame PNG 384x384, 7 x 30 effect PNG 256x256, 30 + 7 spritesheet và contact
  sheet/preview sinh từ frame.
- Thêm catalog Dart `NabiAssetCatalog`, mặc định release v2; bảo toàn
  `NabiVisualState`, `NabiAnimationType` và legacy animation ID. V2 dùng
  filename/path lowercase; V1 còn là source-only rollback branch.
- Chuyển V1 overlay/fallback resolver, AI Voice player, onboarding avatar và
  avatar chat sang catalog chung. Thay Canvas humanoid `NabiCharacter` bằng
  wrapper tương thích dùng `NabiAnimationPlayer`.
- Giữ Future/FamilyPlus/Sale là asset inventory; không chỉnh gate, quota,
  route, quyền truy cập hoặc logic sức khỏe.
- Chỉ khai báo static/expression/runtime frame v2 vào release bundle. V1 vẫn
  nằm trong Git nhưng bị loại khỏi `pubspec.yaml`; sheet/effect/preview source
  được giữ ngoài Flutter bundle khi chưa có runtime consumer.

## File chính đã sửa/thêm

- `assets/nabi_v2/00_master/` - master character sheet và anchor source.
- `assets/images/nabi_v2/`, `assets/nabi_v2/`, `assets/config/nabi_v2/` -
  library v2 và metadata generated.
- `tools/generate_nabi_v2_assets.py` - sinh/validate deterministic asset pack.
- `tools/verify_nabi_v2_release_assets.py` - kiểm tra release pubspec/APK.
- `lib/features/nabi/data/nabi_asset_catalog.dart` - chọn root v2/v1.
- `lib/features/nabi/data/nabi_assets.dart` - giữ ID cũ, resolve layout frame
  v2 lowercase.
- `lib/features/nabi/presentation/widgets/nabi_character.dart` - compatibility
  wrapper thay cho Canvas humanoid.
- `lib/app_versions/v1/features/nabi/domain/nabi_asset_resolver.dart`,
  onboarding, AI chat và `pubspec.yaml` - runtime integration/release bundle.

## Kiểm chứng

- `python tools/generate_nabi_v2_assets.py validate --static-root assets/images/nabi_v2 --sprite-root assets/nabi_v2 --catalog-root assets/config/nabi_v2`: PASS
  - 84 static, 10 expressions, 900 character frames, 210 effect frames.
- `python tools/verify_nabi_v2_release_assets.py --apk build/app/outputs/flutter-apk/app-debug.apk`: PASS.
- `flutter analyze` các source/test Nabi, onboarding, chat đã sửa: PASS.
- `flutter test` bộ Nabi + resolver/onboarding/chat avatar: PASS, 18 tests.
- `flutter test --dart-define=NABI_V2_ASSETS_ENABLED=false` catalog/resolver/onboarding path tests: PASS, 8 tests.
- `flutter test` AI Voice + toàn bộ onboarding + overlay owner: PASS, 20 tests.
- `flutter build apk --debug`: PASS.
  - APK QA hai pack: 349.0 MiB.
  - APK release v2-only: 319.2 MiB; archive inspection xác nhận 84 static và
    900 v2 frames có mặt, v1 static/frame bằng 0.
- `git diff --check`: chạy ở bước bàn giao cuối.

## Rủi ro / việc tiếp theo

- Không có thiết bị Android/iOS kết nối trong phiên này, nên smoke trực quan
  trên safe area/keyboard/light-dark thật cần được QA trên thiết bị trước khi
  phát hành store.
- Rollback v1 yêu cầu khôi phục asset declarations v1 từ Git và build với
  `NABI_V2_ASSETS_ENABLED=false`; không có migration dữ liệu hay entitlement.
- Không commit các thay đổi Green Wellness đã có sẵn trong worktree.

## Tự đánh giá

- Hoàn thành: visual asset contract, catalog/runtime integration, release
  bundle isolation, kiểm thử path/fallback/reduced-motion/owner và APK proof.
- Tối ưu phiên sau: sau visual QA thiết bị, cân nhắc nén/atlas các frame nếu
  cần giảm thêm kích thước v2 mà vẫn giữ cùng runtime path contract.
- Task-skill nên đọc lại: `.codex/task-skills/coding.md`.
