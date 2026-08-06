# UI Design and Coding Acceptance Checklist

## Design coverage

- [ ] Mọi file trong `12_UI_FILE_DESIGN_MATRIX.md` có owner/wave/status.
- [ ] Mọi page có entrance, internal state, feedback và reduced-motion design.
- [ ] 12 group docs được cập nhật khi source path thay đổi.

## Foundation

- [ ] Một nguồn motion token canonical.
- [ ] Không symbol token trùng tên.
- [ ] `app_*` chỉ facade hoặc canonical role được ghi rõ.
- [ ] Primitive có full state matrix.

## Motion

- [ ] Push/back đối xứng.
- [ ] Stable keys cho switch/list/Hero.
- [ ] Refresh cùng data không replay.
- [ ] Không loop ngoài whitelist.
- [ ] Reduce motion hoạt động.

## Sound/haptic

- [ ] Không direct `HapticFeedback` ngoài adapter/service.
- [ ] Không audio package call ngoài sound adapter.
- [ ] Generic tap không sound.
- [ ] Success sau commit.
- [ ] Cooldown/dedup/lifecycle tests.
- [ ] Assets vật lý và license được xác minh.

## Visual/accessibility

- [ ] Không raw color/duration trong feature UI ngoài exception registry.
- [ ] Contrast đạt yêu cầu.
- [ ] Text scale không overflow.
- [ ] Semantics/focus order đúng.
- [ ] Color/sound/haptic không phải tín hiệu duy nhất.

## Performance

- [ ] ≤2 page-level controllers active.
- [ ] Một Nabi owner active.
- [ ] Ticker/audio pause background/offscreen.
- [ ] Scroll không bị blur/shimmer nặng.
- [ ] Frame/memory evidence trên thiết bị.

## Product integrity

- [ ] Không đổi logic/quota/access/schema.
- [ ] Không mock production data.
- [ ] Provider invalidation/notification/outbox giữ đúng.
- [ ] Pending payment không hiển thị như active.
- [ ] Critical health state rõ hơn hiệu ứng.

## Validation

- [ ] `dart format` touched paths.
- [ ] `flutter analyze` targeted.
- [ ] `flutter test` targeted.
- [ ] Architecture tests.
- [ ] Debug APK.
- [ ] Real-device screenshot/motion/audio matrix.
