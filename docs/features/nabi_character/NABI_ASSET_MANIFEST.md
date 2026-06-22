# NABI_ASSET_MANIFEST

Mỗi file bên dưới là **PNG RGBA 512×512, nền trong suốt**. Không đặt text/UI trong ảnh; text hiển thị ở Flutter để hỗ trợ localization và accessibility.

| # | File | Ý nghĩa | Dùng khi | Trigger | Motion recipe |
|---:|---|---|---|---|---|
| 01 | `core/nabi_idle_neutral.png` | Đứng chờ nhẹ | Nabi ở trạng thái chờ, giữ nụ cười thân thiện và không gây áp lực. | Mở màn hình hoặc khi chưa có nội dung | `idle_breathe` |
| 02 | `core/nabi_idle_happy.png` | Đứng vui vẻ | Nabi thể hiện năng lượng tích cực khi có tiến triển tốt. | Người dùng mở dashboard có dữ liệu tốt | `idle_bounce` |
| 03 | `core/nabi_wave.png` | Chào bạn | Nabi vẫy tay chào người dùng. | Mở ứng dụng, mở chat, bắt đầu onboarding | `wave` |
| 04 | `core/nabi_point_guide.png` | Chỉ dẫn | Nabi chỉ tay để hướng dẫn thao tác hoặc điều hướng. | Có bước tiếp theo hoặc CTA rõ ràng | `point` |
| 05 | `core/nabi_listen.png` | Lắng nghe | Nabi nghiêng đầu và lắng nghe câu hỏi hoặc cảm xúc của người dùng. | Người dùng đang nhập hoặc vừa gửi chat | `listen` |
| 06 | `core/nabi_think.png` | Suy nghĩ | Nabi chạm cằm để thể hiện đang cân nhắc. | Cần gợi ý thêm dữ liệu hoặc đang suy luận | `think` |
| 07 | `core/nabi_analyze.png` | Phân tích | Nabi đang phân tích dữ liệu sức khỏe bằng một thẻ biểu đồ nhỏ. | AI đang tổng hợp chỉ số hoặc lịch sử | `analyze` |
| 08 | `core/nabi_speak.png` | Giải thích | Nabi mở lòng bàn tay để giải thích một nội dung ngắn. | Hiển thị lời giải thích, hướng dẫn ngắn | `speak` |
| 09 | `onboarding/nabi_onboarding_intro.png` | Chào mừng onboarding | Chào đón người dùng mới trước khi thu thập thông tin. | Bước mở đầu onboarding | `wave` |
| 10 | `onboarding/nabi_onboarding_basic_info.png` | Thông tin cơ bản | Mời người dùng hoàn thiện thông tin cơ bản bằng checklist. | Bước thông tin cơ bản | `present` |
| 11 | `onboarding/nabi_onboarding_body_profile.png` | Hồ sơ cơ thể | Gợi ý điền chỉ số cơ thể bằng biểu tượng cân/đo lường. | Bước chiều cao, cân nặng, tuổi | `point` |
| 12 | `onboarding/nabi_onboarding_lifestyle.png` | Thói quen sống | Nabi quan sát nhẹ nhàng để hỏi về nhịp sinh hoạt. | Bước sinh hoạt, giấc ngủ, vận động | `listen` |
| 13 | `onboarding/nabi_onboarding_goal.png` | Mục tiêu sức khỏe | Nabi chỉ vào cờ mục tiêu để cùng người dùng xác định hướng đi. | Bước chọn mục tiêu | `point` |
| 14 | `onboarding/nabi_onboarding_health_check.png` | Kiểm tra sức khỏe | Nabi cầm biểu tượng tim/lá để hỏi điều kiện sức khỏe cẩn trọng. | Bước tình trạng sức khỏe | `listen` |
| 15 | `onboarding/nabi_onboarding_review.png` | Xem lại thông tin | Nabi cùng người dùng rà soát câu trả lời trước khi lưu. | Bước review onboarding | `present` |
| 16 | `onboarding/nabi_ai_generating_plan.png` | Đang tạo lịch | Nabi đang tổng hợp dữ liệu để tạo lịch cá nhân. | Đang gọi AI/tạo lịch trình | `analyze` |
| 17 | `onboarding/nabi_plan_ready.png` | Lịch đã sẵn sàng | Nabi mừng vì kế hoạch cá nhân đã hoàn tất. | AI tạo lịch thành công | `celebrate` |
| 18 | `chat/nabi_chat_greet.png` | Chào trong chat | Nabi mở cuộc trò chuyện bằng cử chỉ chào. | Mở màn hình AI chat | `wave` |
| 19 | `chat/nabi_chat_listen.png` | Lắng nghe chat | Nabi lắng nghe điều người dùng vừa chia sẻ. | Đang soạn hoặc gửi tin nhắn | `listen` |
| 20 | `chat/nabi_chat_typing.png` | Đang trả lời | Nabi thao tác trên thiết bị để chuẩn bị phản hồi. | AI đang phản hồi | `typing` |
| 21 | `chat/nabi_chat_reasoning.png` | Đang suy luận | Nabi suy nghĩ trước khi đưa khuyến nghị. | Cần phân tích câu hỏi | `think` |
| 22 | `chat/nabi_chat_clarify.png` | Xin thêm thông tin | Nabi hỏi thêm dữ liệu để gợi ý chính xác hơn. | Thiếu dữ liệu cần thiết | `listen` |
| 23 | `chat/nabi_chat_meal_tip.png` | Gợi ý dinh dưỡng | Nabi gợi ý một bữa ăn cân bằng. | Câu hỏi về ăn uống | `present` |
| 24 | `chat/nabi_chat_exercise_tip.png` | Gợi ý vận động | Nabi cổ vũ một bài vận động nhẹ. | Câu hỏi về vận động | `exercise` |
| 25 | `chat/nabi_chat_rest_tip.png` | Gợi ý nghỉ ngơi | Nabi đề xuất nhịp nghỉ ngơi nhẹ nhàng. | Câu hỏi về giấc ngủ/nghỉ ngơi | `rest` |
| 26 | `chat/nabi_chat_water_tip.png` | Gợi ý uống nước | Nabi nhắc bổ sung nước hợp lý. | Câu hỏi về nước hoặc nhắc uống nước | `present` |
| 27 | `chat/nabi_chat_answer_ready.png` | Đã có câu trả lời | Nabi đưa ra phản hồi hoàn chỉnh dưới dạng thẻ gợi ý. | Hoàn tất trả lời AI chat | `speak` |
| 28 | `daily/nabi_breakfast.png` | Bữa sáng | Nhắc một bữa sáng lành mạnh. | Khung giờ sáng | `present` |
| 29 | `daily/nabi_lunch.png` | Bữa trưa | Gợi ý bữa trưa cân bằng. | Khung giờ trưa | `present` |
| 30 | `daily/nabi_dinner.png` | Bữa tối | Gợi ý bữa tối nhẹ nhàng. | Khung giờ tối | `present` |
| 31 | `daily/nabi_healthy_snack.png` | Ăn nhẹ lành mạnh | Khuyến khích một bữa phụ lành mạnh. | Giữa các bữa chính | `present` |
| 32 | `daily/nabi_drink_water.png` | Uống nước | Nabi cầm nước và khuyến khích uống đủ. | Theo lịch uống nước | `present` |
| 33 | `daily/nabi_exercise.png` | Tập thể dục | Nabi vận động và tạo năng lượng tích cực. | Theo lịch tập | `exercise` |
| 34 | `daily/nabi_walk.png` | Đi bộ | Nabi đi bộ nhẹ để nhắc duy trì vận động. | Nhắc đi bộ/đạt bước | `walk` |
| 35 | `daily/nabi_stretch.png` | Giãn cơ | Nabi vươn người, gợi ý nghỉ giải lao ngắn. | Sau thời gian ngồi lâu | `stretch` |
| 36 | `daily/nabi_sleep.png` | Ngủ ngon | Nabi ngủ yên bình để chúc một giấc ngủ tốt. | Nhắc giờ ngủ | `rest` |
| 37 | `daily/nabi_morning_checkin.png` | Chào buổi sáng | Nabi chào ngày mới với mặt trời nhỏ. | Mở app vào buổi sáng | `wave` |
| 38 | `daily/nabi_mood_checkin.png` | Kiểm tra cảm xúc | Nabi hỏi thăm cảm xúc với biểu tượng trái tim. | Mở mood check-in | `listen` |
| 39 | `daily/nabi_body_measure.png` | Theo dõi chỉ số | Nabi đồng hành khi cập nhật cân nặng/chỉ số cơ thể. | Mở tính chỉ số sức khỏe | `point` |
| 40 | `daily/nabi_view_schedule.png` | Xem lịch hôm nay | Nabi cầm lịch ngày để dẫn người dùng xem nhiệm vụ. | Mở lịch cá nhân | `present` |
| 41 | `daily/nabi_notification_reminder.png` | Nhắc việc | Nabi kèm chuông nhắc một nhiệm vụ đúng thời điểm. | Khi đến giờ nhiệm vụ | `point` |
| 42 | `progress/nabi_task_complete.png` | Hoàn thành nhiệm vụ | Nabi xác nhận nhiệm vụ được hoàn thành. | User complete task | `celebrate` |
| 43 | `progress/nabi_task_skip_gentle.png` | Bỏ qua nhẹ nhàng | Nabi ghi nhận việc bỏ qua mà không phán xét. | User skip task | `calm` |
| 44 | `progress/nabi_task_pending.png` | Nhiệm vụ đang chờ | Nabi nhắc một nhiệm vụ còn đang chờ. | Có nhiệm vụ pending | `point` |
| 45 | `progress/nabi_day_complete.png` | Hoàn thành ngày | Nabi ăn mừng khi người dùng hoàn thành lịch ngày. | Tất cả nhiệm vụ ngày complete | `celebrate` |
| 46 | `progress/nabi_streak_start.png` | Bắt đầu chuỗi | Nabi cổ vũ một chuỗi thói quen mới. | Ngày đầu streak | `encourage` |
| 47 | `progress/nabi_streak_7days.png` | Chuỗi 7 ngày | Nabi mừng khi duy trì thói quen 7 ngày. | Streak 7 ngày | `celebrate` |
| 48 | `progress/nabi_milestone_badge.png` | Đạt cột mốc | Nabi trao huy hiệu cho cột mốc đáng nhớ. | Mốc sức khỏe/hoàn thành | `present` |
| 49 | `progress/nabi_personal_best.png` | Kỷ lục cá nhân | Nabi chúc mừng thành tích tốt nhất của người dùng. | Vượt personal best | `celebrate` |
| 50 | `progress/nabi_low_progress_encourage.png` | Động viên khi chậm | Nabi động viên khi tiến độ chưa như mong muốn. | Tiến độ giảm hoặc bỏ dở | `encourage` |
| 51 | `progress/nabi_missed_task_remind.png` | Nhắc việc lỡ | Nabi nhắc một nhiệm vụ đã lỡ bằng sắc thái nhẹ nhàng. | Missed task | `calm` |
| 52 | `progress/nabi_thank_you.png` | Cảm ơn | Nabi cúi nhẹ để cảm ơn nỗ lực của người dùng. | Hoàn thành phản hồi/đóng góp | `thank` |
| 53 | `progress/nabi_proud_of_you.png` | Tự hào về bạn | Nabi giơ nắm tay khích lệ vì nỗ lực của người dùng. | Đạt tiến độ tốt | `encourage` |
| 54 | `engagement/nabi_new_user.png` | Người dùng mới | Nabi chào người dùng mới và sẵn sàng đồng hành từng bước. | Vừa cài app hoặc chưa có thói quen | `wave` |
| 55 | `engagement/nabi_occasional_user.png` | Dùng thỉnh thoảng | Nabi gợi mở nhẹ nhàng để người dùng trở lại nhịp khỏe. | 1–2 lần/tuần | `think` |
| 56 | `engagement/nabi_regular_user.png` | Dùng đều đặn | Nabi công nhận việc sử dụng đều đặn. | 3–5 lần/tuần | `celebrate` |
| 57 | `engagement/nabi_daily_user.png` | Gắn bó mỗi ngày | Nabi chủ động giới thiệu kế hoạch nhỏ mỗi ngày. | Mở app mỗi ngày | `present` |
| 58 | `engagement/nabi_away_1day.png` | Vắng 1 ngày | Nabi để lại lời nhắc mềm mại sau một ngày vắng. | Không mở app 1 ngày | `wave` |
| 59 | `engagement/nabi_away_3days.png` | Vắng 3 ngày | Nabi suy nghĩ và gửi lời gợi mở sau ba ngày. | Không mở app 3 ngày | `think` |
| 60 | `engagement/nabi_away_7days.png` | Vắng 7 ngày | Nabi bày tỏ sự nhớ người dùng theo cách không áp lực. | Không mở app 7 ngày | `calm` |
| 61 | `engagement/nabi_away_14days.png` | Vắng từ 14 ngày | Nabi ở đó khi người dùng sẵn sàng quay lại. | Không mở app từ 14 ngày | `rest` |
| 62 | `engagement/nabi_welcome_back.png` | Chào mừng quay lại | Nabi dang tay mừng người dùng trở lại. | Mở lại app sau thời gian vắng | `wave` |
| 63 | `engagement/nabi_fresh_restart.png` | Bắt đầu lại | Nabi trao checklist mới để người dùng bắt đầu lại rất nhẹ nhàng. | Người dùng chọn bắt đầu lại | `present` |
| 64 | `system/nabi_loading.png` | Đang tải | Nabi chờ nhẹ với vòng tải nhỏ. | Màn hình load dữ liệu | `analyze` |
| 65 | `system/nabi_empty_dashboard.png` | Chưa có dữ liệu | Nabi đưa gợi ý nhẹ khi dashboard chưa có dữ liệu. | Dashboard empty state | `point` |
| 66 | `system/nabi_no_schedule.png` | Chưa có lịch | Nabi mời tạo lịch trình cá nhân. | Chưa có personal schedule | `present` |
| 67 | `system/nabi_offline.png` | Ngoại tuyến | Nabi thông báo không có mạng bằng sắc thái bình tĩnh. | Không có Internet | `calm` |
| 68 | `system/nabi_syncing.png` | Đang đồng bộ | Nabi đồng bộ dữ liệu bằng biểu tượng cloud/sync. | Bắt đầu đồng bộ dữ liệu | `analyze` |
| 69 | `system/nabi_sync_success.png` | Đồng bộ thành công | Nabi xác nhận dữ liệu đã đồng bộ. | Đồng bộ thành công | `celebrate` |
| 70 | `system/nabi_sync_retry.png` | Cần thử lại đồng bộ | Nabi gợi ý thử đồng bộ lại, không làm người dùng lo lắng. | Đồng bộ thất bại có thể retry | `calm` |
| 71 | `system/nabi_notification_permission.png` | Quyền thông báo | Nabi giải thích nhẹ về quyền nhận nhắc nhở. | Cần xin quyền notification | `point` |
| 72 | `system/nabi_login.png` | Mời đăng nhập | Nabi mời đăng nhập để bảo toàn dữ liệu và mở rộng trải nghiệm. | Cần xác thực để mở tính năng | `wave` |
| 73 | `system/nabi_account_connected.png` | Đã liên kết tài khoản | Nabi vui vì tài khoản đã được liên kết. | Login/link account success | `celebrate` |
| 74 | `system/nabi_access_locked.png` | Tính năng chưa mở | Nabi thông báo tính năng đang khóa theo gói bằng sắc thái lịch sự. | Feature access denied/locked | `calm` |
| 75 | `future/nabi_family_plan.png` | Gói gia đình | Nabi giới thiệu trải nghiệm chăm sóc cùng gia đình. | Giới thiệu FamilyPlus | `present` |
| 76 | `future/nabi_family_invite.png` | Mời người thân | Nabi gửi lời mời người thân tham gia. | Mời thành viên family | `point` |
| 77 | `future/nabi_family_shared_progress.png` | Tiến độ gia đình | Nabi ăn mừng tiến độ chung của gia đình. | Family shared progress | `celebrate` |
| 78 | `future/nabi_family_member_joined.png` | Thành viên tham gia | Nabi chào mừng thành viên mới trong nhóm gia đình. | Family member joined | `wave` |
| 79 | `future/nabi_premium_unlocked.png` | Mở khóa nâng cao | Nabi chúc mừng tính năng nâng cao được mở. | Premium unlocked | `celebrate` |
| 80 | `future/nabi_referral_invite.png` | Mời bạn bè | Nabi mời chia sẻ mã giới thiệu với bạn bè. | Mở referral invite | `point` |
| 81 | `future/nabi_referral_success.png` | Mời bạn thành công | Nabi chúc mừng khi lời mời thành công. | Referral conversion success | `celebrate` |
| 82 | `future/nabi_sales_leaderboard.png` | Bảng xếp hạng sale | Nabi chỉ vào biểu đồ để giới thiệu bảng xếp hạng. | Mở sale leaderboard | `point` |
| 83 | `future/nabi_sales_reward.png` | Thưởng sale | Nabi trao cúp/huy hiệu cho thành tích sale. | Sale achieved monthly reward | `present` |
| 84 | `future/nabi_commission_success.png` | Hoa hồng thành công | Nabi vui mừng khi hoa hồng được ghi nhận. | Commission success | `celebrate` |
