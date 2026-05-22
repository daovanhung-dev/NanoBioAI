# README.md — BioAI Project Structure

> Tài liệu mô tả chi tiết cấu trúc thư mục của hệ thống BioAI Flutter + Supabase + AI Health System.  
> Kiến trúc được xây dựng theo hướng:
- Feature-first Architecture
- Clean Architecture
- Modular Flutter Architecture
- AI-first & Scalable System

Dựa trên cấu trúc thực tế trong `tree.txt` và tài liệu kiến trúc hệ thống BioAI.

---

# 📁 ROOT STRUCTURE

```txt
D:.
├── app
├── core
├── features
├── services
└── shared
```

---

# 📦 app/

```txt
app/
```

## 🎯 Chức năng

Đây là tầng cấu hình chính của toàn bộ ứng dụng.

Nơi:
- Khởi tạo app
- Cấu hình router
- Inject provider
- Khởi tạo theme
- Khởi tạo global state
- Mount MaterialApp

## 📌 Thường chứa

```txt
app/
├── app.dart
├── app_router.dart
├── app_provider.dart
└── app_config.dart
```

## 📌 Vai trò

`app/` là nơi “kết nối tất cả module lại với nhau”.

Ví dụ:
- Gắn Riverpod
- Gắn GoRouter
- Gắn Theme
- Khởi tạo Splash route
- Khởi tạo Authentication flow

---

# 🧠 core/

```txt
core/
├── constants
├── network
├── router
├── storage
├── theme
└── utils
```

## 🎯 Chức năng

`core/` chứa các thành phần nền tảng của hệ thống.

Đây là:
- phần lõi
- dùng toàn hệ thống
- ít phụ thuộc business logic

---

# 📁 core/constants/

## 🎯 Chức năng

Chứa:
- hằng số hệ thống
- key
- enum
- app text
- route name
- app dimension

## 📌 Ví dụ

```dart
class AppColors
class AppText
class RouteNames
class ApiEndpoints
```

## 📌 Mục đích

Giúp:
- tránh hard-code
- quản lý tập trung
- dễ bảo trì

---

# 🌐 core/network/

## 🎯 Chức năng

Quản lý:
- API client
- network interceptor
- request handler
- internet checking

## 📌 Thường chứa

```txt
network/
├── dio_client.dart
├── network_checker.dart
├── interceptors/
└── api_response.dart
```

## 📌 Vai trò

Tất cả request:
- Supabase
- AI API
- REST API

đều đi qua đây.

---

# 🛣️ core/router/

## 🎯 Chức năng

Quản lý:
- điều hướng app
- route
- navigation guard
- auth redirect

## 📌 Ví dụ

```dart
GoRouter
AppRoutes
AuthGuard
```

## 📌 Vai trò

Điều hướng:
- splash
- login
- dashboard
- profile
- ai_chat

---

# 💾 core/storage/

```txt
storage/
└── localdb
```

## 🎯 Chức năng

Quản lý:
- local database
- offline-first architecture
- SQLite layer

---

# 🗄️ core/storage/localdb/

```txt
localdb/
├── daos
├── migrations
├── models
├── seeds
└── tables
```

## 🎯 Chức năng

Đây là tầng SQLite nội bộ của ứng dụng.

Dùng để:
- cache dữ liệu
- offline mode
- local sync
- performance optimization

---

# 📁 localdb/daos/

## 🎯 DAO = Data Access Object

Chứa:
- CRUD query
- thao tác database

## 📌 Ví dụ

```txt
user_dao.dart
health_log_dao.dart
nutrition_dao.dart
```

## 📌 Vai trò

DAO là nơi:
- insert
- update
- delete
- select

database.

---

# 📁 localdb/migrations/

## 🎯 Chức năng

Quản lý version database.

## 📌 Ví dụ

```txt
migration_v1.dart
migration_v2.dart
```

## 📌 Vai trò

Khi app update:
- thêm bảng
- sửa column
- đổi schema

thì migration sẽ xử lý.

---

# 📁 localdb/models/

## 🎯 Chức năng

Chứa model SQLite.

## 📌 Ví dụ

```dart
UserLocalModel
HealthTrackingModel
NutritionModel
```

## 📌 Vai trò

Map:
- object Dart
↔
- SQLite row

---

# 📁 localdb/seeds/

## 🎯 Chức năng

Dữ liệu mẫu mặc định.

## 📌 Ví dụ

```txt
default_foods.dart
default_goals.dart
```

## 📌 Vai trò

Dùng:
- test
- preload
- demo data

---

# 📁 localdb/tables/

## 🎯 Chức năng

Khai báo:
- tên bảng
- schema
- column

## 📌 Ví dụ

```dart
class UserTable
class NutritionTable
```

---

# 🎨 core/theme/

## 🎯 Chức năng

Quản lý:
- màu sắc
- typography
- dark/light mode
- animation style
- app theme

## 📌 Thường chứa

```txt
theme/
├── app_colors.dart
├── app_theme.dart
├── app_text_style.dart
└── app_spacing.dart
```

---

# 🧰 core/utils/

## 🎯 Chức năng

Helper dùng toàn hệ thống.

## 📌 Ví dụ

```txt
date_utils.dart
validator.dart
bmi_calculator.dart
extensions.dart
```

## 📌 Vai trò

Chứa:
- function nhỏ
- reusable logic

---

# 🚀 features/

```txt
features/
├── ai_chat
├── auth
├── community
├── dashboard
├── nutrition
├── profile
├── settings
├── sleep_tracking
├── splash
└── stress_tracking
```

## 🎯 Chức năng

Đây là tầng business chính của ứng dụng.

Mỗi feature:
- độc lập
- tự quản lý logic riêng
- dễ mở rộng

---

# 🧠 Feature Architecture

Ví dụ:

```txt
splash/
├── data
├── domain
├── presentation
└── providers
```

Đây là kiến trúc Clean Architecture.

---

# 📁 data/

## 🎯 Chức năng

Tầng làm việc với:
- API
- Supabase
- SQLite
- Repository implementation

## 📌 Thường chứa

```txt
models/
datasources/
repositories/
```

## 📌 Vai trò

Lấy dữ liệu từ:
- backend
- local db
- AI service

---

# 📁 domain/

## 🎯 Chức năng

Business logic thuần.

## 📌 Thường chứa

```txt
entities/
usecases/
repositories/
```

## 📌 Vai trò

Nơi xử lý:
- nghiệp vụ
- rule hệ thống
- use case

Ví dụ:
- tính BMI
- đánh giá health score
- validate sleep quality

---

# 📁 presentation/

## 🎯 Chức năng

Tầng giao diện UI.

## 📌 Chứa

```txt
pages/
widgets/
```

---

# 📁 presentation/pages/

## 🎯 Chức năng

Mỗi page là:
- một màn hình hoàn chỉnh

## 📌 Ví dụ

```txt
login_page.dart
dashboard_page.dart
profile_page.dart
```

---

# 📁 presentation/widgets/

## 🎯 Chức năng

Widget riêng của feature.

## 📌 Ví dụ

```txt
health_card.dart
sleep_chart.dart
nutrition_tile.dart
```

## 📌 Vai trò

Chỉ dùng trong feature đó.

---

# 📁 providers/

## 🎯 Chức năng

State management bằng Riverpod.

## 📌 Ví dụ

```dart
authProvider
dashboardProvider
sleepTrackingProvider
```

## 📌 Vai trò

Kết nối:
UI ↔ Business Logic

---

# 🤖 features/ai_chat/

## 🎯 Chức năng

AI Chat Assistant.

Bao gồm:
- chat AI
- tư vấn dinh dưỡng
- phân tích sức khỏe
- AI recommendation

---

# 🔐 features/auth/

## 🎯 Chức năng

Authentication system.

Bao gồm:
- login
- register
- forgot password
- OTP
- Google/Apple login

---

# 📊 features/dashboard/

## 🎯 Chức năng

Màn hình tổng quan.

Hiển thị:
- BMI
- health score
- chart
- calories
- sleep score
- AI insight

---

# 🥗 features/nutrition/

## 🎯 Chức năng

Theo dõi:
- calories
- meals
- nutrition recommendation
- water tracking

---

# 👤 features/profile/

## 🎯 Chức năng

Quản lý:
- hồ sơ người dùng
- thông tin sức khỏe
- mục tiêu

---

# ⚙️ features/settings/

## 🎯 Chức năng

Cài đặt:
- theme
- language
- notification
- account

---

# 😴 features/sleep_tracking/

## 🎯 Chức năng

Theo dõi:
- giấc ngủ
- sleep quality
- AI sleep analysis

---

# 😵‍💫 features/stress_tracking/

## 🎯 Chức năng

Theo dõi:
- stress
- burnout
- mood
- relaxation

---

# 🌅 features/splash/

## 🎯 Chức năng

Màn hình khởi động app.

Bao gồm:
- logo animation
- initialize app
- check auth
- preload config

---

# 🔌 services/

```txt
services/
├── ai
├── notification
└── supabase
```

## 🎯 Chức năng

Tầng tích hợp dịch vụ bên ngoài.

---

# 🤖 services/ai/

## 🎯 Chức năng

Kết nối:
- OpenAI API
- AI engine
- AI analysis

## 📌 Ví dụ

```txt
openai_service.dart
prompt_builder.dart
ai_parser.dart
```

---

# 🔔 services/notification/

## 🎯 Chức năng

Notification system.

Bao gồm:
- FCM
- local notification
- reminder
- realtime push

---

# ☁️ services/supabase/

## 🎯 Chức năng

Kết nối Supabase.

Bao gồm:
- auth
- realtime
- storage
- database

## 📌 Ví dụ

```txt
supabase_client.dart
auth_service.dart
database_service.dart
```

---

# ♻️ shared/

```txt
shared/
└── widgets
```

## 🎯 Chức năng

Reusable component toàn hệ thống.

---

# 🧩 shared/widgets/

## 🎯 Chức năng

Widget dùng chung nhiều feature.

## 📌 Ví dụ

```txt
primary_button.dart
loading_widget.dart
custom_textfield.dart
app_dialog.dart
```

## 📌 Khác gì với feature widgets?

### Feature Widgets
- chỉ dùng trong feature đó

Ví dụ:
```txt
dashboard_health_chart.dart
```

### Shared Widgets
- dùng nhiều nơi toàn app

Ví dụ:
```txt
primary_button.dart
```

---

# 🏗️ LUỒNG KIẾN TRÚC HỆ THỐNG

```txt
UI
↓
Provider (Riverpod)
↓
UseCase
↓
Repository
↓
Service
↓
Supabase / SQLite
```

---

# 📌 NGUYÊN TẮC CODE TRONG HỆ THỐNG

## Core
- Generic
- Reusable
- Không chứa business logic

## Shared
- Reusable UI component

## Services
- Giao tiếp external service

## Features
- Chứa business logic chính

## Domain
- Logic nghiệp vụ thuần

## Data
- Làm việc dữ liệu

## Presentation
- UI

---

# 📈 ĐỊNH HƯỚNG MỞ RỘNG

Hệ thống hỗ trợ mở rộng:
- AI Health Score
- Wearable Sync
- Food Scanner AI
- Health Prediction AI
- Community Health
- AI Voice Assistant

