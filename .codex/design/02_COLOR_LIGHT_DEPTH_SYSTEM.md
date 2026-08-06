# Color, Light and Depth System

## 1. Palette direction

| Role | Màu đề xuất | Dùng cho |
|---|---|---|
| Aura Blue 600 | `#2878F0` | Primary action, active navigation |
| Aura Blue 800 | `#174A8B` | Headline, high-emphasis control |
| Bio Cyan 500 | `#22B8CF` | Tracking, information, voice/listening |
| Wellness Mint 500 | `#31C99B` | Completion, positive progress |
| AI Violet 500 | `#7868E6` | AI/Voice/Premium accent có giới hạn |
| Canvas Light | `#F5F9FE` | App background |
| Surface | `#FFFFFF` | Cards, sheets, dialogs |
| Ink 900 | `#102A43` | Primary text |
| Ink 600 | `#52667A` | Supporting text |
| Critical | `#D64550` | Error/critical |
| Warning | `#D98E22` | Warning/pending |

Các giá trị cuối phải được kiểm tra contrast và map vào semantic token. Feature không dùng hex trực tiếp.

## 2. Distribution

- 70% neutral canvas/surface.
- 20% blue/cyan brand.
- 10% mint/violet/status accent.
- Một view chỉ có một vùng gradient dominant.

## 3. Gradients

- `auraPrimary`: Blue 600 → Cyan 500.
- `auraCalm`: Canvas → pale cyan.
- `auraAI`: Blue 600 → Violet 500, chỉ AI/Voice/Premium.
- `auraSuccess`: Cyan 500 → Mint 500, chỉ success/milestone.
- Critical/pending không dùng gradient trang trí.

## 4. Depth

| Level | Shadow | Border | Use |
|---|---|---|---|
| 0 | none | subtle | canvas/flat section |
| 1 | 0/2/8, low alpha | optional | standard card |
| 2 | 0/6/18 | highlighted card/sheet |
| 3 | 0/12/32 | dialog/floating control |
| Glow | 0/0/18 brand alpha | none | active voice/progress only |

## 5. State color motion

- Color tween chỉ chạy khi semantic state đổi.
- Selected: neutral surface → primary container trong 140–180 ms.
- Success: action surface → success container sau commit.
- Error: border/supporting text đổi trước; không flash nền đỏ toàn card.
- Locked: giảm chroma/contrast nhưng vẫn đạt readability.

## 6. Dark mode direction

- Không đảo màu máy móc.
- Canvas deep navy; surface nâng nhẹ; glow giảm alpha.
- Text/critical contrast được kiểm tra riêng.
- Illustration/Nabi cần dark-safe edge/halo.
