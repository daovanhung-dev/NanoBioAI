# Stitch Green Wellness implementation registry

Registry này khóa phạm vi cho **76** cặp `code.html` + `screen.png`. Ảnh là
chuẩn bố cục, HTML là chuẩn token/typography, còn runtime và DD hiện hữu là
chuẩn cho route, dữ liệu, quyền truy cập và hành vi. Prototype không được dùng
để tạo dữ liệu mẫu, hotlink ảnh hoặc tự bổ sung nghiệp vụ.

## Trạng thái và cổng nghiệm thu

- `active-route`: có GoRoute trực tiếp trong runtime hiện tại.
- `embedded`: tab, step, sheet hoặc component được mở từ một surface cha.
- `source-only`: đã có Dart source nhưng chưa có route production.
- `alias`: route hiện tại cố ý dùng lại một surface khác.
- `placeholder`: runtime chỉ cho phép trạng thái sắp ra mắt/khóa tính năng.
- `visual-reference`: prototype chỉ là tham chiếu để hợp nhất component.
- `GREEN_QA_PENDING`: refactor visual/state/accessibility chưa được chứng nhận.
- `PLACEHOLDER_QA_PENDING`: chỉ nghiệm thu placeholder; không mở nghiệp vụ.
- `DD_BLOCKED`: không được kích hoạt nghiệp vụ/route mới trước DD Approved.
- `REFERENCE_ONLY`: không tạo route hay contract production từ prototype.

## Runtime owner catalog

| Owner | Runtime source |
|---|---|
| `NABI_GLOBAL` | `lib/app_versions/v1/features/nabi/`, `lib/app_versions/v1/shared/widgets/ai_chat_fab.dart` |
| `NABI_LOADING` | `lib/shared/widgets/loading_gen_ai.dart` |
| `V1_NAV` | `lib/app_versions/v1/features/dashboard/presentation/pages/menu_page.dart` |
| `V1_AUTH_ENTRY` | `lib/app_versions/v1/features/auth/presentation/pages/v1_auth_entry_page.dart` |
| `V1_ONBOARDING` | `lib/app_versions/v1/features/onboarding/presentation/` |
| `V1_DASHBOARD` | `lib/app_versions/v1/features/dashboard/presentation/pages/dashboard_page.dart` |
| `V1_TODAY_TASKS` | `lib/app_versions/v1/features/today_tasks/presentation/` |
| `V1_FEATURES` | `lib/app_versions/v1/features/features_hub/presentation/` |
| `V1_INSIGHTS` | `lib/app_versions/v1/features/other/presentation/pages/other_page.dart` |
| `V1_SETTINGS` | `lib/app_versions/v1/features/settings/presentation/` |
| `V1_PROFILE` | `lib/app_versions/v1/features/profile/presentation/pages/profile_page.dart` |
| `V1_BODY` | `lib/app_versions/v1/features/body_metrics/presentation/pages/body_metrics_page.dart` |
| `V1_MEAL` | `lib/app_versions/v1/features/meal_plan/presentation/pages/meal_plan_page.dart` |
| `V1_NUTRITION` | `lib/app_versions/v1/features/nutrition/presentation/` |
| `V1_SCHEDULE` | `lib/app_versions/v1/features/lifestyle_schedule/presentation/` |
| `V1_ROUTINE` | `lib/app_versions/v1/features/daily_routine/presentation/` |
| `V1_HEALTH_JOURNAL` | `lib/app_versions/v1/features/daily_health_tracking/presentation/` |
| `V1_WELLNESS` | `lib/app_versions/v1/features/{water_tracking,weekly_summary,quick_care,gentle_care_mode,personal_goals}/presentation/` |
| `V1_PREVIEWS` | `lib/app_versions/v1/features/{sleep_tracking,stress_tracking,community}/presentation/` |
| `V1_AI_CHAT` | `lib/app_versions/v1/features/ai_chat/presentation/` |
| `V1_AI_VOICE` | `lib/app_versions/v1/features/ai_voice/presentation/` |
| `V2_AUTH` | `lib/app_versions/v2/features/auth/presentation/` |
| `V2_HOME` | `lib/app_versions/v2/features/home/presentation/` |
| `V2_HEALTH` | `lib/app_versions/v2/features/{health_scoring,health_modules}/presentation/` |
| `V2_PAYMENT` | `lib/app_versions/v2/features/payments/presentation/` |
| `V2_REWARDS` | `lib/app_versions/v2/features/wellness_rewards/presentation/` |
| `V3_HOME` | `lib/app_versions/v3/features/home/presentation/` |
| `V3_ADVANCED` | `lib/app_versions/v3/features/advanced_tracking/presentation/` |
| `V3_FAMILY` | `lib/app_versions/v3/features/family_plus/presentation/` |
| `SALE` | `lib/sale_referral/presentation/pages/` |

## Surface registry (76/76)

`Class` chỉ nhận `page`, `component`, `state`, hoặc `placeholder`. `Route/surface`
ghi đúng entrypoint hiện hữu; giá trị “không có route” không phải quyền tạo route
trước khi qua cổng DD.

| ID | Stitch folder / intent | Class | Owner | Route / parent surface | Runtime status | Acceptance | Evidence |
|---|---|---|---|---|---|---|---|
| ST-001 | `ai_chat_fab_states` — trạng thái FAB Nabi | component | `NABI_GLOBAL` | overlay toàn app | visual-reference (legacy FAB + overlay) | `REFERENCE_ONLY` | [HTML](./ai_chat_fab_states/code.html) · [PNG](./ai_chat_fab_states/screen.png) |
| ST-002 | `auth_callback` — callback xác thực | state | `V2_AUTH` | `/auth/callback` | active-route | `GREEN_QA_PENDING` | [HTML](./auth_callback/code.html) · [PNG](./auth_callback/screen.png) |
| ST-003 | `basic_info_step` — thông tin cơ bản | component | `V1_ONBOARDING` | `/onboarding`, internal step | embedded | `GREEN_QA_PENDING` | [HTML](./basic_info_step/code.html) · [PNG](./basic_info_step/screen.png) |
| ST-004 | `c_ch_v_h_tr_ti_p_c_n` — cỡ chữ và trợ tiếp cận | component | `V1_SETTINGS` | `/menu`, Settings sheet | embedded | `GREEN_QA_PENDING` | [HTML](./c_ch_v_h_tr_ti_p_c_n/code.html) · [PNG](./c_ch_v_h_tr_ti_p_c_n/screen.png) |
| ST-005 | `c_i_t` — Cài đặt | page | `V1_SETTINGS` | `/menu`, Settings tab | embedded | `GREEN_QA_PENDING` | [HTML](./c_i_t/code.html) · [PNG](./c_i_t/screen.png) |
| ST-006 | `c_ng_c_ng_t_c_vi_n` — Sale workspace shell | page | `SALE` | `/v2/sale` | active-route | `GREEN_QA_PENDING` | [HTML](./c_ng_c_ng_t_c_vi_n/code.html) · [PNG](./c_ng_c_ng_t_c_vi_n/screen.png) |
| ST-007 | `c_ng_c_quy_i_hoa_h_ng` — công cụ quy đổi | component | `SALE` | `/v2/sale`, Conversion Tools tab | embedded | `GREEN_QA_PENDING` | [HTML](./c_ng_c_quy_i_hoa_h_ng/code.html) · [PNG](./c_ng_c_quy_i_hoa_h_ng/screen.png) |
| ST-008 | `ch_nh_s_a_h_s` — chỉnh sửa hồ sơ | component | `V1_PROFILE` | `/profile`, edit sheet | embedded | `GREEN_QA_PENDING` | [HTML](./ch_nh_s_a_h_s/code.html) · [PNG](./ch_nh_s_a_h_s/screen.png) |
| ST-009 | `ch_s_c_th` — chỉ số cơ thể | page | `V1_BODY` | `/body-metrics` | active-route | `GREEN_QA_PENDING` | [HTML](./ch_s_c_th/code.html) · [PNG](./ch_s_c_th/screen.png) |
| ST-010 | `chi_ti_t_m_n_n` — chi tiết món ăn | component | `V1_MEAL` | `/meal-plan`, meal detail sheet | embedded | `GREEN_QA_PENDING` | [HTML](./chi_ti_t_m_n_n/code.html) · [PNG](./chi_ti_t_m_n_n/screen.png) |
| ST-011 | `community_preview` — cộng đồng | placeholder | `V1_PREVIEWS` | `/community` | placeholder | `PLACEHOLDER_QA_PENDING` | [HTML](./community_preview/code.html) · [PNG](./community_preview/screen.png) |
| ST-012 | `conditions_step` — tình trạng sức khỏe | component | `V1_ONBOARDING` | `/onboarding`, internal step | embedded | `GREEN_QA_PENDING` | [HTML](./conditions_step/code.html) · [PNG](./conditions_step/screen.png) |
| ST-013 | `consent_step` — đồng thuận | component | `V1_ONBOARDING` | `/onboarding`, internal step | embedded | `GREEN_QA_PENDING` | [HTML](./consent_step/code.html) · [PNG](./consent_step/screen.png) |
| ST-014 | `daily_routine_step` — nhịp sinh hoạt onboarding | component | `V1_ONBOARDING` | `/onboarding`, internal step | embedded | `GREEN_QA_PENDING` | [HTML](./daily_routine_step/code.html) · [PNG](./daily_routine_step/screen.png) |
| ST-015 | `dashboard_h_m_nay` — Dashboard Hôm nay | page | `V1_DASHBOARD` | `/dashboard` | active-route | `GREEN_QA_PENDING` | [HTML](./dashboard_h_m_nay/code.html) · [PNG](./dashboard_h_m_nay/screen.png) |
| ST-016 | `database_viewer_dev` — database viewer dev | page | `V1_SETTINGS` | Settings debug entry | embedded, debug-only | `GREEN_QA_PENDING` | [HTML](./database_viewer_dev/code.html) · [PNG](./database_viewer_dev/screen.png) |
| ST-017 | `dinh_d_ng_h_ng_ng_y` — Dinh dưỡng | page | `V1_NUTRITION` | `/nutrition` | active-route, auth-gated | `GREEN_QA_PENDING` | [HTML](./dinh_d_ng_h_ng_ng_y/code.html) · [PNG](./dinh_d_ng_h_ng_ng_y/screen.png) |
| ST-018 | `extras_step` — thông tin bổ sung | component | `V1_ONBOARDING` | `/onboarding`, internal step | embedded | `GREEN_QA_PENDING` | [HTML](./extras_step/code.html) · [PNG](./extras_step/screen.png) |
| ST-019 | `familyplus_qu_n_l_gia_nh` — FamilyPlus | page | `V3_FAMILY` | `/v3/familyplus` | active-route; auth + effective-access gated | `GREEN_QA_PENDING` | [HTML](./familyplus_qu_n_l_gia_nh/code.html) · [PNG](./familyplus_qu_n_l_gia_nh/screen.png) |
| ST-020 | `features_hub` — hub tính năng | page | `V1_FEATURES` | `/menu`, Features tab | embedded | `GREEN_QA_PENDING` | [HTML](./features_hub/code.html) · [PNG](./features_hub/screen.png) |
| ST-021 | `forgot_password` — quên mật khẩu | page | `V2_AUTH` | `/v2/auth/forgot-password` | active-route | `GREEN_QA_PENDING` | [HTML](./forgot_password/code.html) · [PNG](./forgot_password/screen.png) |
| ST-022 | `gentle_care_mode` — chế độ nhẹ nhàng | page | `V1_WELLNESS` | `/gentle-care` | active-route; deterministic local UI | `GREEN_QA_PENDING` | [HTML](./gentle_care_mode/code.html) · [PNG](./gentle_care_mode/screen.png) |
| ST-023 | `goals_step` — mục tiêu onboarding | component | `V1_ONBOARDING` | `/onboarding`, internal step | embedded | `GREEN_QA_PENDING` | [HTML](./goals_step/code.html) · [PNG](./goals_step/screen.png) |
| ST-024 | `h_s_c_a_b_n` — hồ sơ cá nhân | page | `V1_PROFILE` | `/profile` | active-route, auth-gated | `GREEN_QA_PENDING` | [HTML](./h_s_c_a_b_n/code.html) · [PNG](./h_s_c_a_b_n/screen.png) |
| ST-025 | `h_s_dinh_d_ng` — hồ sơ dinh dưỡng | page | `V1_NUTRITION` | `/nutrition-profile` | active-route, auth-gated | `GREEN_QA_PENDING` | [HTML](./h_s_dinh_d_ng/code.html) · [PNG](./h_s_dinh_d_ng/screen.png) |
| ST-026 | `h_s_thanh_to_n_ctv` — hồ sơ thanh toán Sale | state | `SALE` | `/v2/sale`, payout profile gate | embedded | `GREEN_QA_PENDING` | [HTML](./h_s_thanh_to_n_ctv/code.html) · [PNG](./h_s_thanh_to_n_ctv/screen.png) |
| ST-027 | `health_insights_g_c_nabi` — Góc Nabi | page | `V1_INSIGHTS` | `/menu`, Góc Nabi tab | embedded | `GREEN_QA_PENDING` | [HTML](./health_insights_g_c_nabi/code.html) · [PNG](./health_insights_g_c_nabi/screen.png) |
| ST-028 | `health_module_access` — truy cập module sức khỏe | page | `V2_HEALTH` | `/v2/health-modules/:moduleId` | active-route; M20–M29 catalog/placeholder only | `GREEN_QA_PENDING` | [HTML](./health_module_access/code.html) · [PNG](./health_module_access/screen.png) |
| ST-029 | `health_score` — điểm sức khỏe | page | `V2_HEALTH` | `/v2/health-score` | active-route | `GREEN_QA_PENDING` | [HTML](./health_score/code.html) · [PNG](./health_score/screen.png) |
| ST-030 | `i_m_n_n` — đổi bữa ăn | component | `V1_MEAL` | `/meal-plan`, replace-meal flow | embedded | `GREEN_QA_PENDING` | [HTML](./i_m_n_n/code.html) · [PNG](./i_m_n_n/screen.png) |
| ST-031 | `k_ho_ch_n_u_ng` — kế hoạch ăn uống | page | `V1_MEAL` | `/meal-plan` | active-route | `GREEN_QA_PENDING` | [HTML](./k_ho_ch_n_u_ng/code.html) · [PNG](./k_ho_ch_n_u_ng/screen.png) |
| ST-032 | `kh_ch_h_ng_c_a_b_n` — khách hàng trực tiếp | component | `SALE` | `/v2/sale`, Direct Customers tab | embedded | `GREEN_QA_PENDING` | [HTML](./kh_ch_h_ng_c_a_b_n/code.html) · [PNG](./kh_ch_h_ng_c_a_b_n/screen.png) |
| ST-033 | `kho_b_ng_ch_ng` — thư viện bằng chứng | page | `V1_SCHEDULE` | mở từ `/lifestyle-schedule` bằng Material route | embedded | `GREEN_QA_PENDING` | [HTML](./kho_b_ng_ch_ng/code.html) · [PNG](./kho_b_ng_ch_ng/screen.png) |
| ST-034 | `l_ch_s_i_m_th_ng` — lịch sử điểm Sale | component | `SALE` | `/v2/sale`, Point Ledger tab | embedded | `GREEN_QA_PENDING` | [HTML](./l_ch_s_i_m_th_ng/code.html) · [PNG](./l_ch_s_i_m_th_ng/screen.png) |
| ST-035 | `l_ch_tr_nh_c_a_b_n` — lịch trình lối sống | page | `V1_SCHEDULE` | `/lifestyle-schedule` | active-route | `GREEN_QA_PENDING` | [HTML](./l_ch_tr_nh_c_a_b_n/code.html) · [PNG](./l_ch_tr_nh_c_a_b_n/screen.png) |
| ST-036 | `lifestyle_step` — lối sống onboarding | component | `V1_ONBOARDING` | `/onboarding`, internal step | embedded | `GREEN_QA_PENDING` | [HTML](./lifestyle_step/code.html) · [PNG](./lifestyle_step/screen.png) |
| ST-037 | `login_entry` — đăng nhập V1 entry | page | `V1_AUTH_ENTRY` | `/login`, chuyển tiếp auth V2 | active-route | `GREEN_QA_PENDING` | [HTML](./login_entry/code.html) · [PNG](./login_entry/screen.png) |
| ST-038 | `m_gi_i_thi_u_ctv` — mã giới thiệu | component | `SALE` | `/v2/sale`, Referral Code panel | embedded | `GREEN_QA_PENDING` | [HTML](./m_gi_i_thi_u_ctv/code.html) · [PNG](./m_gi_i_thi_u_ctv/screen.png) |
| ST-039 | `main_navigation_shell` — navigation shell | component | `V1_NAV` | `/menu` | active-route shell | `GREEN_QA_PENDING` | [HTML](./main_navigation_shell/code.html) · [PNG](./main_navigation_shell/screen.png) |
| ST-040 | `nabi_ang_chu_n_b.._` — Nabi đang chuẩn bị | state | `NABI_LOADING` | onboarding/generation parent flow | embedded | `GREEN_QA_PENDING` | [HTML](./nabi_ang_chu_n_b.._/code.html) · [PNG](./nabi_ang_chu_n_b.._/screen.png) |
| ST-041 | `nabi_animation_fallback` — fallback chuyển động | component | `NABI_GLOBAL` | mọi surface có Nabi | embedded | `GREEN_QA_PENDING` | [HTML](./nabi_animation_fallback/code.html) · [PNG](./nabi_animation_fallback/screen.png) |
| ST-042 | `nabi_app_shell` — demo app shell | component | `V1_NAV` | `/menu` reference | visual-reference | `REFERENCE_ONLY` | [HTML](./nabi_app_shell/code.html) · [PNG](./nabi_app_shell/screen.png) |
| ST-043 | `nabi_assistant_overlay` — assistant overlay | component | `NABI_GLOBAL` | overlay toàn app | embedded | `GREEN_QA_PENDING` | [HTML](./nabi_assistant_overlay/code.html) · [PNG](./nabi_assistant_overlay/screen.png) |
| ST-044 | `nabi_floating_mascot` — mascot nổi | component | `NABI_GLOBAL` | overlay toàn app | embedded | `GREEN_QA_PENDING` | [HTML](./nabi_floating_mascot/code.html) · [PNG](./nabi_floating_mascot/screen.png) |
| ST-045 | `nabi_speech_bubble` — speech bubble | component | `NABI_GLOBAL` | overlay/onboarding message reference | visual-reference | `REFERENCE_ONLY` | [HTML](./nabi_speech_bubble/code.html) · [PNG](./nabi_speech_bubble/screen.png) |
| ST-046 | `nabi_voice` — trợ lý giọng nói | page | `V1_AI_VOICE` | `/ai-voice` | active-route, auth-gated | `GREEN_QA_PENDING` | [HTML](./nabi_voice/code.html) · [PNG](./nabi_voice/screen.png) |
| ST-047 | `nami_care` — hub Nami Care | page | `V1_FEATURES` | `/nami-care` | active-route; chỉ link năng lực runtime đã sẵn sàng | `GREEN_QA_PENDING` | [HTML](./nami_care/code.html) · [PNG](./nami_care/screen.png) |
| ST-048 | `ng_k_c_ng_t_c_vi_n` — tham gia CTV | page | `SALE` | mở từ Settings bằng Material route | embedded | `GREEN_QA_PENDING` | [HTML](./ng_k_c_ng_t_c_vi_n/code.html) · [PNG](./ng_k_c_ng_t_c_vi_n/screen.png) |
| ST-049 | `nhi_m_v_h_m_nay` — nhiệm vụ hôm nay | page | `V1_TODAY_TASKS` | `/today-tasks` | active-route | `GREEN_QA_PENDING` | [HTML](./nhi_m_v_h_m_nay/code.html) · [PNG](./nhi_m_v_h_m_nay/screen.png) |
| ST-050 | `onboarding_entry` — onboarding entry | page | `V1_ONBOARDING` | `/start` | active-route | `GREEN_QA_PENDING` | [HTML](./onboarding_entry/code.html) · [PNG](./onboarding_entry/screen.png) |
| ST-051 | `onboarding_shell` — onboarding journey shell | page | `V1_ONBOARDING` | `/onboarding` | active-route | `GREEN_QA_PENDING` | [HTML](./onboarding_shell/code.html) · [PNG](./onboarding_shell/screen.png) |
| ST-052 | `personal_goals` — mục tiêu cá nhân | page | `V1_WELLNESS` | `/personal-goals` | active-route; local basic UI | `GREEN_QA_PENDING` | [HTML](./personal_goals/code.html) · [PNG](./personal_goals/screen.png) |
| ST-053 | `ph_n_th_ng_s_c_kh_e` — Wellness Rewards | page | `V2_REWARDS` | `/v2/wellness-rewards` | active-route | `GREEN_QA_PENDING` | [HTML](./ph_n_th_ng_s_c_kh_e/code.html) · [PNG](./ph_n_th_ng_s_c_kh_e/screen.png) |
| ST-054 | `quick_care` — chăm sóc nhanh | page | `V1_WELLNESS` | `/quick-care` | active-route; deterministic local UI | `GREEN_QA_PENDING` | [HTML](./quick_care/code.html) · [PNG](./quick_care/screen.png) |
| ST-055 | `register_entry` — đăng ký V1 entry | page | `V1_AUTH_ENTRY` | `/register`, chuyển tiếp auth V2 | active-route | `GREEN_QA_PENDING` | [HTML](./register_entry/code.html) · [PNG](./register_entry/screen.png) |
| ST-056 | `reset_password` — đặt lại mật khẩu | page | `V2_AUTH` | `/v2/auth/reset-password` | active-route | `GREEN_QA_PENDING` | [HTML](./reset_password/code.html) · [PNG](./reset_password/screen.png) |
| ST-057 | `result_step` — kết quả onboarding | component | `V1_ONBOARDING` | không được nối vào journey hiện tại | source-only | `GREEN_QA_PENDING` | [HTML](./result_step/code.html) · [PNG](./result_step/screen.png) |
| ST-058 | `review_step` — rà soát onboarding | component | `V1_ONBOARDING` | `/onboarding`, internal step | embedded | `GREEN_QA_PENDING` | [HTML](./review_step/code.html) · [PNG](./review_step/screen.png) |
| ST-059 | `sleep_tracking_preview` — giấc ngủ | placeholder | `V1_PREVIEWS` | `/sleep-tracking` | placeholder | `PLACEHOLDER_QA_PENDING` | [HTML](./sleep_tracking_preview/code.html) · [PNG](./sleep_tracking_preview/screen.png) |
| ST-060 | `stress_tracking_preview` — căng thẳng | placeholder | `V1_PREVIEWS` | `/stress-tracking` | placeholder | `PLACEHOLDER_QA_PENDING` | [HTML](./stress_tracking_preview/code.html) · [PNG](./stress_tracking_preview/screen.png) |
| ST-061 | `t_ng_quan_sale` — tổng quan Sale | component | `SALE` | `/v2/sale`, Overview tab | embedded | `GREEN_QA_PENDING` | [HTML](./t_ng_quan_sale/code.html) · [PNG](./t_ng_quan_sale/screen.png) |
| ST-062 | `text_scale_setup` — cỡ chữ onboarding | page | `V1_ONBOARDING` | gate trước `/start`/`/onboarding` | embedded gate | `GREEN_QA_PENDING` | [HTML](./text_scale_setup/code.html) · [PNG](./text_scale_setup/screen.png) |
| ST-063 | `thanh_to_n_th_nh_vi_n` — thanh toán hội viên | page | `V2_PAYMENT` | `/v2/payments` | active-route | `GREEN_QA_PENDING` | [HTML](./thanh_to_n_th_nh_vi_n/code.html) · [PNG](./thanh_to_n_th_nh_vi_n/screen.png) |
| ST-064 | `theo_d_i_n_ng_cao` — theo dõi nâng cao | page | `V3_ADVANCED` | `/v3/advanced-tracking` | active-route; hydration scope hiện tại | `GREEN_QA_PENDING` | [HTML](./theo_d_i_n_ng_cao/code.html) · [PNG](./theo_d_i_n_ng_cao/screen.png) |
| ST-065 | `theo_d_i_s_c_kh_e` — nhật ký sức khỏe | page | `V1_HEALTH_JOURNAL` | `/health-tracking` | alias sang Lifestyle Schedule hiện tại | `DD_BLOCKED` | [HTML](./theo_d_i_s_c_kh_e/code.html) · [PNG](./theo_d_i_s_c_kh_e/screen.png) |
| ST-066 | `thi_t_l_p_nh_p_sinh_ho_t` — thiết lập nhịp sinh hoạt | page | `V1_ROUTINE` | `/daily-routine-preferences` | active-route | `GREEN_QA_PENDING` | [HTML](./thi_t_l_p_nh_p_sinh_ho_t/code.html) · [PNG](./thi_t_l_p_nh_p_sinh_ho_t/screen.png) |
| ST-067 | `tr_chuy_n_v_i_nabi` — AI Chat | page | `V1_AI_CHAT` | `/ai-chat` | active-route, auth/quota-gated | `GREEN_QA_PENDING` | [HTML](./tr_chuy_n_v_i_nabi/code.html) · [PNG](./tr_chuy_n_v_i_nabi/screen.png) |
| ST-068 | `trang_ch_v3_plus` — V3 home | page | `V3_HOME` | `/v3` | active-route, planned shell | `GREEN_QA_PENDING` | [HTML](./trang_ch_v3_plus/code.html) · [PNG](./trang_ch_v3_plus/screen.png) |
| ST-069 | `v2_auth_gate` — trạng thái đồng bộ auth | state | `V2_AUTH` | `/v2/auth` | active-route gate | `GREEN_QA_PENDING` | [HTML](./v2_auth_gate/code.html) · [PNG](./v2_auth_gate/screen.png) |
| ST-070 | `v2_home` — V2 home | page | `V2_HOME` | `/v2` | active-route; auth-ready redirect hiện dẫn V1 menu | `GREEN_QA_PENDING` | [HTML](./v2_home/code.html) · [PNG](./v2_home/screen.png) |
| ST-071 | `v2_login` — đăng nhập V2 | page | `V2_AUTH` | `/v2/auth/login` | active-route | `GREEN_QA_PENDING` | [HTML](./v2_login/code.html) · [PNG](./v2_login/screen.png) |
| ST-072 | `v2_register` — đăng ký V2 | page | `V2_AUTH` | `/v2/auth/register` | active-route | `GREEN_QA_PENDING` | [HTML](./v2_register/code.html) · [PNG](./v2_register/screen.png) |
| ST-073 | `verify_email` — xác thực email | page | `V2_AUTH` | `/v2/auth/verify-email` | active-route | `GREEN_QA_PENDING` | [HTML](./verify_email/code.html) · [PNG](./verify_email/screen.png) |
| ST-074 | `water_tracking` — uống nước | page | `V1_WELLNESS` | `/water-tracking` | active-route; local daily record + user-selected target | `GREEN_QA_PENDING` | [HTML](./water_tracking/code.html) · [PNG](./water_tracking/screen.png) |
| ST-075 | `weekly_summary` — tóm tắt tuần | page | `V1_WELLNESS` | `/weekly-summary` | active-route; honest empty state until real records exist | `GREEN_QA_PENDING` | [HTML](./weekly_summary/code.html) · [PNG](./weekly_summary/screen.png) |
| ST-076 | `welcome_step` — chào mừng onboarding | component | `V1_ONBOARDING` | `/onboarding`, internal step | embedded | `GREEN_QA_PENDING` | [HTML](./welcome_step/code.html) · [PNG](./welcome_step/screen.png) |

## Asset evidence

- HTML references found: **90** unique HTTPS images.
- Controlled import result: **90 downloaded, 0 failed, 90 unique content hashes**.
- Provenance and validation fields: [`assets/config/stitch/manifest.json`](../../../assets/config/stitch/manifest.json).
- Local reference files: `assets/images/stitch/<surface>/...`.
- All imported records are `license_status: unverified`,
  `runtime_eligible: false`; production fallback policy is documented beside the
  manifest. Source URLs are provenance only and must never be runtime hotlinks.

## Acceptance completion rule

A row may move to an accepted status only when its exact HTML/PNG comparison,
light/dark/adaptive layout, loading/empty/error/locked/offline states,
accessibility and navigation behavior have evidence. `DD_BLOCKED` rows must also
reference an Approved DD before any business route or persistence is enabled.
