# NaBi Virtual Character Assets v2 Enhanced – 30fps

Gói này nâng cấp NaBi theo hướng **đẹp hơn, dễ thương hơn và mượt hơn**. Tất cả animation chính chạy ở **30fps**, mỗi animation có 30 frame PNG nền trong suốt, kèm spritesheet, preview GIF, SFX và manifest Flutter.

## Nội dung

- 10 biểu cảm tĩnh 512px.
- 30 animation 30fps, chia module: core, emotion, daily, system, views.
- 7 hiệu ứng phụ 30fps.
- 12 file âm thanh WAV.
- Mapping animation theo từng view Flutter.

## Cài vào Flutter

1. Giải nén thư mục `NaBi_virtual_character_assets_v2_30fps_enhanced` vào `assets/nabi/`.
2. Copy `05_flutter_integration/pubspec_snippet.yaml` vào `pubspec.yaml`.
3. Chạy `flutter pub get`.
4. Copy file Dart trong `05_flutter_integration/lib/` vào project.

```dart
NabiViewMascot(
  animationId: 'NABI_ANIM_002_happy_wave_right',
  module: '01_core',
  size: 180,
)
```

## Gợi ý hiệu năng

- Mỗi frame tương ứng khoảng 33ms.
- Nên precache frame trước khi show.
- Với dashboard/chat, nên hiển thị 120–220px.
- Đây là bản 2D sprite-frame 30fps; nếu cần nhẹ hơn cho production lớn, có thể chuyển concept sang Rive/Spine/Live2D.
