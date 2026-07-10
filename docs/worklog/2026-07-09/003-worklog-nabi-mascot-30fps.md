Commit de xuat: feat(nabi): trien khai mascot 30fps cho trigger AI v1

# Worklog - Nabi mascot 30fps

## Thoi gian

- Ngay: 2026-07-09
- Bat dau: 21:30
- Ket thuc: 23:15
- Timezone: Asia/Saigon

## Pham vi

- Loai task: code + asset integration + test
- Module chinh: `lib/features/nabi/`, `lib/app_versions/v1/features/nabi/`, AI chat v1
- Yeu cau goc: thay nut noi AI/chat hien tai bang NaBi mascot 30fps, giu nguyen flow mo AI chat hien co.

## Da lam

- Chuyen asset pack tu `assets/NaBi_virtual_character/` sang `assets/nabi/`.
- Cap nhat `pubspec.yaml` de dang ky asset NaBi 30fps va bo cac asset directory khong ton tai gay fail `flutter pub get`.
- Tao shared NaBi primitives: animation type, view context, asset registry, view mapper, animation player, floating mascot.
- Wire `NabiFloatingOverlay` v1 sang `NaBiFloatingMascot` khi `NABI_SPRITE_MASCOT_ENABLED=true`; giu `NabiCharacterWidget`/legacy FAB trong nhanh rollback.
- Thay standalone dashboard AI trigger bang `NabiFloatingOverlay` shared v1/30fps, fallback ve `DraggableAIChatButton` khi tat flag.
- Hook AI chat controller/screen vao `NabiContextProvider` cho typing, answer ready, error va route context.
- Them `NabiVisualAnimationMapper` v1 de map `NabiVisualState` cu sang animation sprite moi.
- Sua fallback precache de asset thieu khong crash va khong report Flutter image error.
- Them test cho asset specs, frame path builder, view mapper, v1 visual mapper va fallback render.

## File code/docs da sua

- `pubspec.yaml` - sua - dang ky `assets/nabi/` va don asset dir khong ton tai.
- `assets/nabi/` - tao/move - dat asset pack NaBi 30fps vao thu muc runtime chuan.
- `lib/features/nabi/data/nabi_assets.dart` - tao - registry asset/spec/precache/fallback.
- `lib/features/nabi/data/nabi_feature_flags.dart` - tao - dart-define rollback flag.
- `lib/features/nabi/data/nabi_view_animation_mapper.dart` - tao - map route/view sang animation.
- `lib/features/nabi/domain/nabi_animation_type.dart` - tao - enum animation sprite.
- `lib/features/nabi/domain/nabi_view_context.dart` - tao - enum context UI.
- `lib/features/nabi/presentation/widgets/nabi_animation_player.dart` - tao - player PNG sequence 30fps.
- `lib/features/nabi/presentation/widgets/nabi_floating_mascot.dart` - tao - mascot tap/scale/preload/fallback.
- `lib/features/nabi/nabi.dart` va cac import `lib/features/nabi/**` - sua - export API moi va chuan hoa import casing.
- `lib/app_versions/v1/features/nabi/application/nabi_visual_animation_mapper.dart` - tao - adapter v1 visual state.
- `lib/app_versions/v1/features/nabi/presentation/widgets/nabi_floating_overlay.dart` - sua - render mascot sprite va giu fallback cu.
- `lib/app_versions/v1/features/dashboard/presentation/pages/dashboard_page.dart` - sua - dung overlay NaBi cho standalone trigger.
- `lib/app_versions/v1/features/dashboard/presentation/pages/menu_page.dart` - sua - import casing v1 NaBi.
- `lib/app_versions/v1/features/ai_chat/presentation/controllers/ai_chat_controller.dart` - sua - signal typing/success/error cho NaBi.
- `lib/app_versions/v1/features/ai_chat/presentation/pages/ai_chat_screen.dart` - sua - set route context chat.
- `lib/app_versions/v1/features/nabi/domain/nabi_context.dart` - sua - them `clearForceState`.
- `lib/app_versions/v1/features/nabi/providers/nabi_provider.dart` - sua - transient chat animation state.
- `test/features/nabi/**`, `test/app_versions/v1/features/nabi/**` - tao/sua - test NaBi 30fps va adapter.

## Tai lieu lien quan

- `.codex/AGENTS.md`
- `.codex/PROJECT_MAP.md`
- `.codex/history/LEARNED_SKILLS.md`
- `.codex/workflows/coding.md`
- `.codex/task-skills/README.md`
- `.codex/domains/ui-nabi.md`

## Commands

- `flutter pub get`: PASS - asset declarations hop le.
- `dart format ...`: PASS - format cac file Dart da cham.
- `flutter test test\features\nabi test\app_versions\v1\features\nabi test\app_versions\v1\features\ai_chat\ai_chat_quota_test.dart`: PASS - 14 tests passed.
- `flutter analyze`: FAIL - con 38 issue nen repo; warning con lai nam o onboarding va info naming/deprecation cu, khong phat sinh tu implementation NaBi 30fps.
- `git diff --check`: PASS - chi co warning LF/CRLF.
- `flutter devices`: PASS - thay Windows, Chrome, Edge.
- `flutter run -d windows -t lib\main.dart`: FAIL - thieu Visual Studio toolchain.
- `flutter run -d chrome -t lib\main.dart`: PASS - app start toi debug service/main; co exception tool-side khi quit session.
- `flutter build web --debug -t lib\main.dart`: PASS - build web debug thanh cong.

## Loi/Rui ro

- Da fix: `precacheImage` asset thieu report loi trong test/runtime; them `onError` va fallback icon.
- Da fix: `NabiContext.copyWith(forceState: null)` khong clear duoc override; them `clearForceState`.
- Chua fix: `flutter analyze` van fail vi warning/info nen repo khong lien quan truc tiep den thay doi nay.
- Can kiem tra tiep: UI tap/drag tren thiet bi mobile that, vi hien moi smoke run tren Chrome va build web debug.

## Ty le hoan thanh

- Hoan thanh: 90% - code, asset, tests, web build, rollback flag da co.
- Dang do: 10% - can manual QA tren mobile/emulator va xu ly warning analyzer nen neu muon `flutter analyze` pass tuyet doi.

## Tu danh gia va toi uu phien sau

- Chat luong dau ra: tot - giu logic AI/chat cu, them adapter hep va test dung diem rui ro.
- Muc do hoan thanh task: gan day du; con gioi han boi analyzer nen va Windows toolchain.
- Bang chung kiem chung: pub get pass, targeted tests pass, git diff check pass, Chrome run start, web debug build pass.
- Diem ton token/chua toi uu: can run analyzer som hon de tach ro warning nen truoc khi code.
- Cach toi uu cho phien sau: chay baseline `flutter analyze` truoc khi sua de co bang chung pre-existing clean hon.
- Task-skill can doc lan sau: `.codex/task-skills/README.md`
