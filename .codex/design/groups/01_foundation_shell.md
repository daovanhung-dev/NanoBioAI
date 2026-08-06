# Foundation, app shell và navigation

## Goal

Thiết lập nguồn token canonical, route motion, feedback scope và primitive dùng chung.

## Current evidence

- Files: **55**.
- Page/screen: **0**.
- Files có motion: **9**.
- Files dùng duration raw: **6**.
- Files dùng color trực tiếp: **12**.
- Files gọi haptic trực tiếp: **0**.

## Group design rules

- Một nguồn token canonical; `app_*` chỉ facade migration.
- Một route-motion registry cho toàn User/V1/V2/V3/Admin.
- Một AppExperienceScope giải quyết motion/sound/haptic/text scale/performance.
- Primitive sở hữu interaction visuals; feature không tự tạo press effect.

## File-by-file design

| File | Kind | Role | Current evidence | Target design | Transition contract | Wave |
| --- | --- | --- | --- | --- | --- | --- |
| lib/app/app_surface_controller.dart | app_shell | AppSurfaceController | Chưa có motion/feedback đáng kể | Cài MotionScope và FeedbackScope một lần ở composition root; tránh mỗi surface tự tạo policy; giữ User/Admin selection và lifecycle hiện tại. | Loading/empty/error/ready và action result | W2 Shell/Navigation |
| lib/app/bio_ai_app.dart | app_shell | BioAIApp / _AccessResolvingApp | Nabi×1 | Cài MotionScope và FeedbackScope một lần ở composition root; tránh mỗi surface tự tạo policy; giữ User/Admin selection và lifecycle hiện tại. | Loading/empty/error/ready và action result | W2 Shell/Navigation |
| lib/app_versions/admin/app/bio_ai_admin_app.dart | app_shell | BioAIAdminApp | Chưa có motion/feedback đáng kể | Cài MotionScope và FeedbackScope một lần ở composition root; tránh mỗi surface tự tạo policy; giữ User/Admin selection và lifecycle hiện tại. | Loading/empty/error/ready và action result | W2 Shell/Navigation |
| lib/app_versions/admin/router/admin_route_paths.dart | router | AdminRoutePaths | Chưa có motion/feedback đáng kể | Không thay đổi path contract; chỉ dùng làm source cho route-motion registry và coverage test. | Shared-axis / fade-through / container transform registry | W2 Shell/Navigation |
| lib/app_versions/admin/router/admin_router.dart | router | admin_router | Chưa có motion/feedback đáng kể | Áp dụng route-motion registry theo archetype, chiều push/back đối xứng, reduced-motion fallback và không animate auth redirect trung gian. | Shared-axis / fade-through / container transform registry | W2 Shell/Navigation |
| lib/app_versions/v1/app/bio_ai_v1_app.dart | app_shell | BioAIV1App / _BioAIV1AppState | Chưa có motion/feedback đáng kể | Cài MotionScope và FeedbackScope một lần ở composition root; tránh mỗi surface tự tạo policy; giữ User/Admin selection và lifecycle hiện tại. | Loading/empty/error/ready và action result | W2 Shell/Navigation |
| lib/app_versions/v1/router/router.dart | router | router | Chưa có motion/feedback đáng kể | Không thay đổi path contract; chỉ dùng làm source cho route-motion registry và coverage test. | Shared-axis / fade-through / container transform registry | W2 Shell/Navigation |
| lib/app_versions/v1/router/transitions.dart | router | AppTransitions | Chưa có motion/feedback đáng kể | Áp dụng route-motion registry theo archetype, chiều push/back đối xứng, reduced-motion fallback và không animate auth redirect trung gian. | Shared-axis / fade-through / container transform registry | W2 Shell/Navigation |
| lib/app_versions/v1/router/v1_navigation_service.dart | router | V1AppNavigator | Chưa có motion/feedback đáng kể | Giữ access/navigation behavior; không phát feedback trước khi điều hướng được chấp nhận; ánh xạ fallback/back transition thống nhất. | Shared-axis / fade-through / container transform registry | W2 Shell/Navigation |
| lib/app_versions/v1/router/v1_route_guards.dart | router | V1RouteGuards | Chưa có motion/feedback đáng kể | Giữ access/navigation behavior; không phát feedback trước khi điều hướng được chấp nhận; ánh xạ fallback/back transition thống nhất. | Shared-axis / fade-through / container transform registry | W2 Shell/Navigation |
| lib/app_versions/v1/router/v1_route_paths.dart | router | V1RoutePaths | Chưa có motion/feedback đáng kể | Không thay đổi path contract; chỉ dùng làm source cho route-motion registry và coverage test. | Shared-axis / fade-through / container transform registry | W2 Shell/Navigation |
| lib/app_versions/v1/router/v1_router.dart | router | v1_router | Chưa có motion/feedback đáng kể | Áp dụng route-motion registry theo archetype, chiều push/back đối xứng, reduced-motion fallback và không animate auth redirect trung gian. | Shared-axis / fade-through / container transform registry | W2 Shell/Navigation |
| lib/app_versions/v2/app/bio_ai_v2_app.dart | app_shell | BioAIV2App / _BioAIV2AppState | Chưa có motion/feedback đáng kể | Cài MotionScope và FeedbackScope một lần ở composition root; tránh mỗi surface tự tạo policy; giữ User/Admin selection và lifecycle hiện tại. | Loading/empty/error/ready và action result | W2 Shell/Navigation |
| lib/app_versions/v2/router/v2_route_paths.dart | router | V2RoutePaths | Chưa có motion/feedback đáng kể | Không thay đổi path contract; chỉ dùng làm source cho route-motion registry và coverage test. | Shared-axis / fade-through / container transform registry | W2 Shell/Navigation |
| lib/app_versions/v2/router/v2_router.dart | router | V2RouteGuards / _RouterRefreshNotifier | Chưa có motion/feedback đáng kể | Áp dụng route-motion registry theo archetype, chiều push/back đối xứng, reduced-motion fallback và không animate auth redirect trung gian. | Shared-axis / fade-through / container transform registry | W2 Shell/Navigation |
| lib/app_versions/v3/app/bio_ai_v3_app.dart | app_shell | BioAIV3App / _BioAIV3AppState | Chưa có motion/feedback đáng kể | Cài MotionScope và FeedbackScope một lần ở composition root; tránh mỗi surface tự tạo policy; giữ User/Admin selection và lifecycle hiện tại. | Loading/empty/error/ready và action result | W2 Shell/Navigation |
| lib/app_versions/v3/router/v3_route_paths.dart | router | V3RoutePaths | Chưa có motion/feedback đáng kể | Không thay đổi path contract; chỉ dùng làm source cho route-motion registry và coverage test. | Shared-axis / fade-through / container transform registry | W2 Shell/Navigation |
| lib/app_versions/v3/router/v3_router.dart | router | v3_router | Chưa có motion/feedback đáng kể | Áp dụng route-motion registry theo archetype, chiều push/back đối xứng, reduced-motion fallback và không animate auth redirect trung gian. | Shared-axis / fade-through / container transform registry | W2 Shell/Navigation |
| lib/core/theme/app_animations.dart | theme | AppAnimations | AnimatedContainer×1, AnimatedSwitcher×1, AnimatedOpacity×1, AnimatedScale×1, duration raw×1, motion token×6 | Thu hẹp thành compatibility wrappers hoặc hợp nhất vào app_motion.dart; không duy trì hai API cạnh tranh. | Token tween/policy only | W1 Foundation |
| lib/core/theme/app_colors.dart | theme | AppColors | Color raw×88 | Biến thành compatibility facade của semantic color tokens; không thêm màu raw mới; ghi deprecation cho alias cũ. | Token tween/policy only | W1 Foundation |
| lib/core/theme/app_decoration.dart | theme | AppDecoration | Color raw×2, Colors.*×2 | Chuyển decoration thành composition từ token; tránh màu raw/Colors.*. | Token tween/policy only | W1 Foundation |
| lib/core/theme/app_duration.dart | theme | AppDuration | duration raw×37, motion token×2 | Giữ public facade nhưng map 1:1 sang motion token canonical; bỏ các duration chồng nghĩa. | Token tween/policy only | W1 Foundation |
| lib/core/theme/app_experience.dart | theme | AppExperience / _NanoBioScrollBehavior | Chưa có motion/feedback đáng kể | Cấp AppExperienceScope cho motion, haptic, sound, text scale và performance tier; không đọc setting rải rác. | Token tween/policy only | W1 Foundation |
| lib/core/theme/app_gradients.dart | theme | AppGradients | Color raw×58 | Chuẩn hóa Aura Blue/Cyan/Mint gradients theo semantic role; critical state không dùng gradient trang trí. | Token tween/policy only | W1 Foundation |
| lib/core/theme/app_icons.dart | theme | AppIcons | Chưa có motion/feedback đáng kể | Chuẩn hóa theme API và chuyển toàn bộ giá trị sang token canonical; giữ compatibility trong giai đoạn migration. | Token tween/policy only | W1 Foundation |
| lib/core/theme/app_motion.dart | theme | AppPageTransitionsBuilder / AppViewMotion / _AppViewMotionState / AppPressScale | controller×2, AnimatedScale×1, motion token×2 | Trở thành entrypoint motion widget canonical: press, state switch, reveal, shared-axis và reduced motion. | Token tween/policy only | W1 Foundation |
| lib/core/theme/app_radius.dart | theme | AppRadius | Chưa có motion/feedback đáng kể | Chuẩn hóa theme API và chuyển toàn bộ giá trị sang token canonical; giữ compatibility trong giai đoạn migration. | Token tween/policy only | W1 Foundation |
| lib/core/theme/app_shadows.dart | theme | AppShadows | Color raw×26 | Chuẩn hóa elevation và glow budgets; không dùng shadow đậm trên mọi card. | Token tween/policy only | W1 Foundation |
| lib/core/theme/app_spacing.dart | theme | AppSpacing | Chưa có motion/feedback đáng kể | Chuẩn hóa theme API và chuyển toàn bộ giá trị sang token canonical; giữ compatibility trong giai đoạn migration. | Token tween/policy only | W1 Foundation |
| lib/core/theme/app_text_scale.dart | theme | AppTextScaleState / AppTextScaleController | Chưa có motion/feedback đáng kể | Kết hợp system TextScaler và preference app một lần; không scale kép. | Token tween/policy only | W1 Foundation |
| lib/core/theme/app_text_styles.dart | theme | AppTextStyles | Chưa có motion/feedback đáng kể | Public typography facade; loại bỏ AppTextStyles trùng trong component_tokens.dart. | Token tween/policy only | W1 Foundation |
| lib/core/theme/app_theme.dart | theme | AppTheme | duration raw×1, Color raw×2, Colors.*×15, motion token×4 | Cấu hình page transition, component theme, focus/hover/pressed state và high-contrast behavior từ token. | Token tween/policy only | W1 Foundation |
| lib/core/theme/app_typography.dart | theme | AppTypography | Chưa có motion/feedback đáng kể | Chỉ xử lý responsive/type scale helpers; không định nghĩa style cạnh tranh. | Token tween/policy only | W1 Foundation |
| lib/core/theme/design_system.dart | theme | design_system | motion token×2 | Canonical export barrel; export đúng foundation → semantic → primitives → compositions. | Token tween/policy only | W1 Foundation |
| lib/core/theme/design_system_demo_page.dart | demo | DesignSystemDemoPage / _DesignSystemDemoPageState | Chưa có motion/feedback đáng kể | Mở rộng thành motion laboratory: tất cả primitive/state, sound/haptic toggle, reduce motion và performance tier preview. | Loading/empty/error/ready và action result | W1 Foundation |
| lib/core/theme/foundation/colors.dart | token | ColorFoundation / GradientFoundation | Color raw×33, Colors.*×2 | Giữ vai trò foundation/semantic token; loại bỏ giá trị trùng với app_*; không để feature import foundation trực tiếp. | Stable state/identity contract | W1 Foundation |
| lib/core/theme/foundation/motion.dart | token | MotionFoundation | AnimatedContainer×1, duration raw×3, motion token×5 | Trở thành lớp giá trị motion primitive duy nhất; không chứa widget; cung cấp duration, curve, distance, scale và spring presets. | Stable state/identity contract | W1 Foundation |
| lib/core/theme/foundation/radius.dart | token | RadiusFoundation | Chưa có motion/feedback đáng kể | Giữ vai trò foundation/semantic token; loại bỏ giá trị trùng với app_*; không để feature import foundation trực tiếp. | Stable state/identity contract | W1 Foundation |
| lib/core/theme/foundation/shadows.dart | token | defines / ShadowFoundation | Color raw×5 | Giữ vai trò foundation/semantic token; loại bỏ giá trị trùng với app_*; không để feature import foundation trực tiếp. | Stable state/identity contract | W1 Foundation |
| lib/core/theme/foundation/spacing.dart | token | provides / SpacingFoundation | Chưa có motion/feedback đáng kể | Giữ vai trò foundation/semantic token; loại bỏ giá trị trùng với app_*; không để feature import foundation trực tiếp. | Stable state/identity contract | W1 Foundation |
| lib/core/theme/foundation/typography.dart | token | TypographyFoundation | Chưa có motion/feedback đáng kể | Giữ vai trò foundation/semantic token; loại bỏ giá trị trùng với app_*; không để feature import foundation trực tiếp. | Stable state/identity contract | W1 Foundation |
| lib/core/theme/medical_ui.dart | theme | MedicalPageScaffold / MedicalScrollPage / MedicalAmbientBackground / _AmbientGlow | duration raw×1, Colors.*×1, Semantics×1, Nabi×1 | Làm composition layer cho medical surfaces, ambient backdrop và page scaffolds; animation nền chỉ chạy khi visible. | Token tween/policy only | W1 Foundation |
| lib/core/theme/primitives/badge.dart | primitive | AppBadge | Semantics×1 | Badge chỉ animate khi semantic status thực sự đổi; pulse chỉ cho trạng thái live có giới hạn. | State matrix: rest/press/focus/loading/success/error/disabled | W1 Foundation |
| lib/core/theme/primitives/button.dart | primitive | AppButton | AnimatedContainer×2, Colors.*×3, motion token×5, Semantics×1 | Thiết kế KineticButton: press 0.975, highlight shift, loading morph giữ kích thước, success/error feedback semantic, haptic/sound qua service. | State matrix: rest/press/focus/loading/success/error/disabled | W1 Foundation |
| lib/core/theme/primitives/card.dart | primitive | AppCard | AnimatedContainer×1, Colors.*×1, motion token×3, Semantics×1 | Thiết kế KineticCard: press 0.988, elevation tween, selected color morph, expand/shared-container hooks và swipe resistance. | State matrix: rest/press/focus/loading/success/error/disabled | W1 Foundation |
| lib/core/theme/primitives/chip.dart | primitive | AppChip | AnimatedContainer×1, Colors.*×1, motion token×2, Semantics×2 | Thiết kế KineticChip: indicator fill, check morph, label shift, selection haptic và group identity. | State matrix: rest/press/focus/loading/success/error/disabled | W1 Foundation |
| lib/core/theme/primitives/input.dart | primitive | AppInput | Chưa có motion/feedback đáng kể | Thiết kế KineticInput: focus border/label morph, validation size+fade, password icon morph, không shake lặp. | State matrix: rest/press/focus/loading/success/error/disabled | W1 Foundation |
| lib/core/theme/primitives/section_header.dart | primitive | SectionHeader | Chưa có motion/feedback đáng kể | Section header hỗ trợ trailing action transition và collapsing hierarchy, không animate chỉ vì rebuild. | State matrix: rest/press/focus/loading/success/error/disabled | W1 Foundation |
| lib/core/theme/primitives/states/empty_state.dart | primitive | EmptyState | Semantics×1 | Illustration/Nabi reveal một lần; CTA delayed nhẹ; không loop vô hạn. | State matrix: rest/press/focus/loading/success/error/disabled | W1 Foundation |
| lib/core/theme/primitives/states/error_state.dart | primitive | ErrorState | Semantics×1, Nabi×1 | Error reveal mềm, retry feedback rõ, không lộ thuật ngữ kỹ thuật và không dùng animation hoảng loạn. | State matrix: rest/press/focus/loading/success/error/disabled | W1 Foundation |
| lib/core/theme/primitives/states/loading_state.dart | primitive | LoadingState / _LoadingStateState / _SkeletonPanel | controller×2, motion token×1, Semantics×1, Nabi×1 | Thống nhất skeleton/shimmer/AI loading; pause ticker ngoài viewport và tắt shimmer khi reduced motion. | State matrix: rest/press/focus/loading/success/error/disabled | W1 Foundation |
| lib/core/theme/theme.dart | theme | theme | Chưa có motion/feedback đáng kể | Compatibility barrel; không export symbol trùng tên gây ambiguous import. | Token tween/policy only | W1 Foundation |
| lib/core/theme/tokens/color_tokens.dart | token | AppColorTokens | Color raw×8 | Giữ vai trò foundation/semantic token; loại bỏ giá trị trùng với app_*; không để feature import foundation trực tiếp. | Stable state/identity contract | W1 Foundation |
| lib/core/theme/tokens/component_tokens.dart | token | AppRadiusTokens / AppShadowTokens / AppMotionTokens / AppTextStyles | AnimatedContainer×1, duration raw×4, motion token×9 | Giữ vai trò foundation/semantic token; loại bỏ giá trị trùng với app_*; không để feature import foundation trực tiếp. | Stable state/identity contract | W1 Foundation |
| lib/core/theme/tokens/spacing_tokens.dart | token | defines / AppSpacingTokens | Chưa có motion/feedback đáng kể | Giữ vai trò foundation/semantic token; loại bỏ giá trị trùng với app_*; không để feature import foundation trực tiếp. | Stable state/identity contract | W1 Foundation |

## Acceptance

- Không raw sound/haptic call ngoài feedback service.
- Không motion replay khi state không đổi.
- Có reduced-motion behavior.
- Có loading/empty/error/ready hoặc lý do không áp dụng.
- Targeted widget/route/state test được bổ sung trong coding wave.
