# Design Principles

## P1 — Motion explains change
Mọi animation phải trả lời được: trạng thái nào đổi, nguồn ở đâu và đích ở đâu. Không trả lời được thì bỏ animation.

## P2 — Calm base, vivid moments
80% trải nghiệm dùng motion tinh tế; 15% emphasized; tối đa 5% celebration.

## P3 — Identity before animation
Widget/list item cần stable key và semantic identity trước khi thêm transition. Không dùng `AnimatedSwitcher` với child không có key rõ.

## P4 — Commit before celebration
Chỉ phát success visual/haptic/sound sau repository/RPC/local transaction thành công.

## P5 — Nabi reacts, never competes
Nabi không che CTA, không chạy cùng lúc với chart/celebration quan trọng và không phát cue riêng ngoài orchestrator.

## P6 — Accessibility is canonical
`MediaQuery.disableAnimations`, text scale, contrast, semantics và focus order là một phần của design, không phải phụ lục.

## P7 — Performance is a token
Mỗi motion có duration, visibility rule, maximum controller count và fallback tier.

## P8 — One design language, different density
User, Premium, Sale và Admin dùng cùng token/primitive; khác nhau ở density, accent và motion intensity.

## P9 — Health clarity overrides delight
Critical/warning/medical values không dùng celebration, bouncing hoặc ambient glow gây hiểu sai.

## P10 — Sound is semantic
Không phát tiếng cho mọi tap. Sound chỉ xác nhận event có ý nghĩa hoặc trạng thái voice/AI.
