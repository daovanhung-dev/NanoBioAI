# Project Overview

## Tên dự án
**BioAI** (package: `nano_app`)

## Mục tiêu
Ứng dụng mobile AI-powered giúp người dùng theo dõi sức khỏe cá nhân, gợi ý kế hoạch dinh dưỡng và phân tích lối sống thông qua AI.

## Đối tượng người dùng
Người dùng cá nhân quan tâm đến sức khỏe, dinh dưỡng, giấc ngủ, và quản lý stress.

## Phạm vi chức năng chính
- **Onboarding**: Thu thập thông tin sức khỏe cá nhân qua 7 bước (step-by-step wizard)
- **Auth**: Đăng nhập qua Supabase (email/password)
- **Dashboard**: Tổng quan sức khỏe (BMI, goals, metrics)
- **Meal Plan**: Kế hoạch dinh dưỡng 7 ngày do AI sinh ra (Gemini 2.5 Flash)
- **AI Chat**: Hỗ trợ tư vấn sức khỏe qua AI (đang phát triển)
- **Tracking**: Theo dõi giấc ngủ, stress (đang phát triển)

## Điểm nổi bật
- Toàn bộ dữ liệu người dùng lưu **offline-first** qua SQLite (`bioai.db`)
- Meal plan được **sinh bởi Gemini AI** dựa trên health profile thực tế
- Supabase chỉ dùng cho **authentication**, không dùng cho lưu health data
- Kiến trúc **Feature-first + Clean Architecture**

## Trạng thái hiện tại
`v0.1.0` — đang phát triển tích cực, các feature tracking/community chưa hoàn thiện.
