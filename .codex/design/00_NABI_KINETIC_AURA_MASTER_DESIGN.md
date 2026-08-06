# Nabi Kinetic Aura — Master Design

## 1. Tuyên ngôn

**Nabi Kinetic Aura** là hệ thiết kế medical-wellness hiện đại, dùng ánh sáng xanh dương–cyan–mint, chiều sâu mềm và chuyển động liên tục để làm rõ trạng thái. Giao diện phải tạo cảm giác sống, phản hồi và cao cấp, nhưng dữ liệu sức khỏe luôn quan trọng hơn hiệu ứng.

```text
Clarity → Continuity → Tactility → Delight
```

## 2. Mục tiêu

- Đồng bộ màu, typography, geometry, motion, haptic và sound trên toàn app.
- Mỗi hành động có phản hồi thị giác tức thời.
- Chuyển đổi widget giải thích state change, không chỉ trang trí.
- Giữ spatial continuity khi mở chi tiết, modal, tab và route.
- Nabi là companion theo ngữ cảnh, không phải animation chạy độc lập.
- Có reduce motion, sound/haptic settings và performance budget.

## 3. Quy tắc bất biến

1. Không thay đổi business logic, persistence, access, quota hoặc trust boundary.
2. Không phát success feedback trước khi write/RPC thật sự thành công.
3. Không animate lại toàn view khi provider refresh cùng dữ liệu.
4. Không dùng màu hoặc motion để che loading/error/locked state.
5. Không phát sound cho generic tap mặc định.
6. Không có animation vô hạn ngoài whitelist và visibility control.
7. Presentation không gọi DAO/API; feedback không đặt trong repository/datasource.
8. User-facing copy giữ tiếng Việt, nhẹ nhàng, không phán xét.

## 4. Visual signature

- **Canvas:** trắng xanh rất nhạt, độ tương phản dịu.
- **Primary:** Aura Blue cho hành động chính và điều hướng.
- **Secondary:** Bio Cyan cho thông tin, tracking và active glow.
- **Wellness accent:** Mint cho hoàn thành/tích cực.
- **AI accent:** Violet giới hạn cho AI/Voice/Premium, không phủ toàn màn hình.
- **Depth:** border sáng + shadow ngắn + glow rất nhẹ; không dùng glassmorphism dày đặc.
- **Shape:** card mềm, button rõ, pill chỉ cho status/chip; không bo tròn mọi thứ giống nhau.

## 5. Motion signature

- Press có cảm giác nén vật lý nhỏ.
- Selection dùng indicator/shape morph thay vì đổi màu tức thời.
- State transition dùng fade-size hoặc fade-through.
- Detail navigation ưu tiên shared container/Hero có identity.
- Timeline và progress chuyển động theo dữ liệu thật.
- Celebration hiếm, ngắn, chỉ sau milestone thực.

## 6. Feedback signature

- Haptic selection cho lựa chọn, light cho action, medium/success cho commit quan trọng.
- Sound cue ngắn cho voice start/stop, plan ready, milestone và semantic error.
- Có Off/Subtle/Full; Admin mặc định sound Off.
- Một `AppFeedbackService` điều phối, widget không phát trực tiếp.

## 7. Surface differentiation

| Surface | Cường độ motion | Accent | Nabi | Sound mặc định |
|---|---:|---|---|---|
| Guest/V1 | Trung bình | Blue/Cyan/Mint | Có ngữ cảnh | Subtle |
| V2 Free | Trung bình | Blue/Cyan | Có | Subtle |
| V3 Plus/FamilyPlus | Trung bình, premium có giới hạn | Blue/Violet/Mint | Có | Subtle |
| Sale | Thấp–trung bình | Blue/Teal | Chỉ onboarding/status | Subtle |
| Admin | Thấp | Navy/Blue | Không ambient liên tục | Off |

## 8. Canonical theme architecture

```text
foundation/*        raw immutable values
    ↓
tokens/*            semantic mapping
    ↓
primitives/*        reusable interactive components
    ↓
medical_ui.dart     page/section compositions
    ↓
feature UI          only semantic tokens + primitives/compositions
```

`app_*` được giữ như compatibility facade trong quá trình migration nhưng không còn là nguồn giá trị độc lập. `app_animations.dart` và `app_motion.dart` phải được hợp nhất thành một motion API canonical.

## 9. Definition of done

- Mọi file trong matrix có design mapping và migration wave.
- Mọi primitive có state matrix và reduced-motion behavior.
- Mọi view có loading/empty/error/ready design.
- Sound/haptic không gọi trực tiếp ngoài feedback service.
- Route transition có push/back symmetry.
- Visual QA, text-scale QA, performance QA và device smoke có evidence.
