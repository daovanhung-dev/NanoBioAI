# Micro-interaction Specification

## 1. Button

1. Pointer down: scale 0.975, shadow giảm, highlight dịch 2 px.
2. Pointer up: spring về 1.0; icon dịch theo hướng action tối đa 2 px.
3. Loading: label fade/size out, loader fade in, giữ nguyên width/height.
4. Success: loader morph check; success haptic/sound sau commit.
5. Error: border/color change + shake 2 px tối đa 2 chu kỳ; không rung mạnh.
6. Disabled: không press motion, semantics disabled.

## 2. Card

- Press 0.988, elevation tween.
- Selected: border/indicator/color morph.
- Expand: `AnimatedSize` + content fade; summary giữ vị trí.
- Detail: shared container/Hero nếu cùng entity.
- Swipe: resistance, action reveal theo gesture, haptic ở threshold một lần.

## 3. Chip/selector

- Indicator fill từ center/tap origin.
- Check icon 0.78→1, label shift 2 px.
- Selection haptic một lần.
- Segmented control dùng một sliding indicator chung.

## 4. Input

- Focus border 140 ms, floating label 180 ms.
- Supporting/error text size+fade.
- Validation shake chỉ khi submit hoặc blur, không theo từng ký tự.
- Password icon morph/rotate nhỏ.
- Keyboard inset không làm content jump.

## 5. Switch/checkbox/radio

- Thumb position + color đồng bộ.
- Haptic selection.
- Checkbox path/check morph.
- Không sound mặc định.

## 6. List and timeline

- Initial stagger tối đa 4–6 item, chỉ lần đầu.
- Insert: size+fade; delete: shrink+fade.
- Timeline complete: circle→check, line fill, card emphasis giảm nhẹ.
- Skip: neutral state; không dùng sad/error animation.

## 7. Numbers/charts

- Count tween 240–450 ms theo độ lớn delta.
- Ring/path draw chỉ lần đầu hoặc formula version đổi.
- Chart reveal theo trục thời gian.
- Tooltip theo touch, không haptic liên tục.

## 8. Feedback cooldown

- Haptic selection: tối thiểu 80 ms giữa các cue.
- Sound: tối thiểu 250 ms; cùng semantic sound không chồng.
- Celebration: mỗi event ID chỉ một lần.
