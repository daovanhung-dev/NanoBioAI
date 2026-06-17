# TÀI LIỆU MÔ TẢ CHỨC NĂNG HỆ THỐNG BIOAI

## 📋 TỔNG QUAN

**BioAI** là ứng dụng Flutter theo dõi sức khỏe cá nhân sử dụng AI (Google Gemini), cung cấp:
- Lập kế hoạch dinh dưỡng cá nhân hóa
- Theo dõi sức khỏe hàng ngày
- Trợ lý AI tư vấn sức khỏe
- Lưu trữ offline-first với SQLite
- Xác thực qua Supabase

**Package Flutter**: `nano_app`  
**Tên sản phẩm**: BioAI  
**Flutter SDK**: `^3.9.2`

---

## 🔐 1. HỆ THỐNG XÁC THỰC (AUTHENTICATION)

### 📁 Vị trí files
```
features/auth/
├── presentation/
│   ├── pages/login_pages.dart
│   └── controllers/login_controller.dart
├── providers/auth_provider.dart
├── data/datasource/auth_remote_datasource.dart
└── domain/repositories/
    ├── auth_repository.dart
    └── auth_repository_impl.dart
```

### 🔄 Luồng hoạt động

#### **1.1. Đăng nhập (Login)**

**Bước 1**: Người dùng nhập email và mật khẩu trên `LoginPage`
- Validation inline: kiểm tra định dạng email và độ dài mật khẩu
- Form state quản lý bởi local state

**Bước 2**: Nhấn nút "Đăng nhập"
- Gọi `loginControllerProvider.notifier.login(email, password)`
- `LoginController` chuyển state sang `AsyncLoading`

**Bước 3**: Xử lý qua các tầng
```
LoginPage → LoginController → AuthRepository → AuthRepositoryImpl 
  → AuthRemoteDatasource → Supabase.auth.signInWithPassword()
```

**Bước 4**: Xử lý kết quả
- **Thành công**: 
  - `LoginPage` lắng nghe state qua `ref.listen`
  - Tự động chuyển hướng đến `/menu` bằng `context.go('/menu')`
  - Session được lưu trong Supabase client
  
- **Thất bại**: 
  - Hiển thị `SnackBar` với thông báo lỗi
  - State trở về ready để người dùng thử lại

### 🛡️ Route Guards

**authGuard**: Bảo vệ các route yêu cầu đăng nhập

- Kiểm tra `Supabase.instance.client.auth.currentUser`
- Nếu `null` → Redirect về `/login`
- Áp dụng cho: `/ai-chat`, `/nutrition`, `/profile`

**guestGuard**: Ngăn người đã đăng nhập truy cập trang login
- Nếu đã có user → Redirect về `/dashboard`
- Áp dụng cho: `/login`

### ⚠️ Tính năng chưa hoàn thiện
- Đăng ký tài khoản (route `/register` hiện là `Placeholder`)
- Quên mật khẩu
- Đăng nhập bằng social media

### 🔌 Tích hợp
- **Backend**: Supabase Authentication
- **State Management**: Legacy `StateNotifierProvider<LoginController, AsyncValue<void>>`

---

## 🚀 2. KHỞI ĐỘNG ỨNG DỤNG (SPLASH & INITIALIZATION)

### 📁 Vị trí files
```
lib/main.dart
lib/app/app.dart
features/splash/
├── presentation/pages/splash_page.dart
└── providers/splash_provider.dart
```

### 🔄 Quy trình khởi động hoàn chỉnh


#### **Phase 1: App Bootstrap (main.dart)**

```dart
main() async {
  // 1. Khởi tạo Flutter bindings
  WidgetsFlutterBinding.ensureInitialized();
  
  // 2. Load environment variables từ .env
  await dotenv.load(fileName: ".env");
  
  // 3. Khởi tạo Supabase
  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL']!,
    anonKey: dotenv.env['SUPABASE_ANON_KEY']!,
  );
  
  // 4. Khởi tạo hệ thống thông báo
  await NotificationBootstrap.initialize();
  
  // 5. Chạy app với Riverpod
  runApp(
    ProviderScope(
      overrides: [
        // Override callback xử lý sau khi onboarding hoàn tất
        onboardingCompletionCallbackProvider.overrideWithValue(
          (profile) async {
            // Generate meal plan 7 ngày
            // Generate exercise tasks 7 ngày  
            // Build lifestyle schedule
            // Schedule notification reminders
          }
        )
      ],
      child: const BioAIApp(),
    ),
  );
}
```

#### **Phase 2: Router Initialization (app.dart)**


```dart
MaterialApp.router(
  title: 'BioAI',
  theme: AppTheme.lightTheme,  // Theme chính của app
  routerConfig: appRouter,     // GoRouter configuration
)
```

#### **Phase 3: Splash Screen (splash_page.dart)**

**Bước 1**: Hiển thị màn hình chờ
- Logo BioAI với animation floating
- Loading indicator

**Bước 2**: Kiểm tra trạng thái onboarding
```dart
await splashProvider.notifier.initialize();
final completed = await AppPrefs.isOnboardingCompleted();
```

**Bước 3**: Điều hướng dựa trên kết quả
- **Nếu `completed == true`**: 
  - `AppNavigator.goMenu(context)` → Chuyển đến `/menu`
  - Người dùng đã thiết lập hồ sơ sức khỏe
  
- **Nếu `completed == false`**: 
  - `AppNavigator.goOnboarding(context)` → Chuyển đến `/onboarding`
  - Yêu cầu người dùng hoàn thành wizard

**Delay**: `AppDuration.loading` (được định nghĩa trong theme constants)

### ⚠️ Lưu ý quan trọng

- Splash **KHÔNG kiểm tra** Supabase auth session
- Chỉ dựa vào flag `onboarding_completed` trong SharedPreferences
- Người dùng có thể truy cập app mà không cần đăng nhập (offline-first)

### 🎨 Animation
- `TickerProviderStateMixin` cho floating animation
- Duration và curves được định nghĩa trong `AppMotionTokens`

---

## 📝 3. QUY TRÌNH ONBOARDING (7 BƯỚC)

### 📁 Vị trí files
```
features/onboarding/
├── presentation/
│   ├── pages/onboarding_page.dart
│   ├── controllers/onboarding_controller.dart
│   └── widgets/
│       ├── welcome_step.dart
│       ├── basic_info_step.dart
│       ├── goals_step.dart
│       ├── conditions_step.dart
│       ├── lifestyle_step.dart
│       ├── extras_step.dart
│       └── review_step.dart
├── domain/
│   ├── entities/onboarding_entity.dart
│   └── repositories/
│       ├── onboarding_repository.dart
│       └── onboarding_repository_impl.dart
├── data/
│   ├── datasource/onboarding_local_datasource.dart
│   └── models/onboarding_model.dart
└── providers/onboarding_provider.dart
```

### 🎯 Mục đích
Thu thập thông tin sức khỏe ban đầu để:

- Tạo hồ sơ sức khỏe cá nhân
- Generate meal plan 7 ngày bằng AI
- Generate lịch trình sức khỏe hàng ngày
- Cá nhân hóa nội dung và khuyến nghị

### 📋 Chi tiết 7 bước

#### **Bước 0: Welcome Step** (`welcome_step.dart`)
**Nội dung**:
- Màn hình chào mừng giới thiệu BioAI
- Mô tả lợi ích của việc sử dụng app
- Nút "Bắt đầu" để tiếp tục

**UI Elements**:
- Hero image/illustration
- Welcome message
- Feature highlights
- Primary CTA button

---

#### **Bước 1: Basic Info Step** (`basic_info_step.dart`)
**Thu thập**:
- **Họ tên** (`fullName`) - TextFormField (bắt buộc)
- **Email** (`email`) - TextFormField với validation
- **Số điện thoại** (`phone`) - TextFormField với formatting
- **Giới tính** (`gender`) - Radio buttons: "Nam"/"Nữ"/"Khác" (bắt buộc)
- **Năm sinh** (`birthYear`) - Number input, validate > 1900 (bắt buộc)
- **Nghề nghiệp** (`occupation`) - Dropdown/TextFormField (bắt buộc)

**Validation Rules**:

- Tên không được rỗng
- Email phải đúng format (regex validation)
- Năm sinh phải > 1900 và <= năm hiện tại
- Giới tính phải được chọn
- Nghề nghiệp không được rỗng

**State Updates**:
```dart
state = state.copyWith(
  fullName: value,
  email: value,
  phone: value,
  gender: value,
  birthYear: int.parse(value),
  occupation: value,
);
```

---

#### **Bước 2: Goals Step** (`goals_step.dart`)
**Thu thập**: Mục tiêu sức khỏe (`goals` - List<String>)

**Options** (multi-select chips):
- Giảm cân
- Tăng cơ
- Cải thiện giấc ngủ
- Tăng năng lượng
- Giảm stress
- Cải thiện tiêu hóa
- Tăng cường miễn dịch
- Cân bằng hormone
- Cải thiện da
- Tăng sự tập trung

**UI Pattern**:
- Wrap grid của AppChip components
- Multi-selection với visual feedback
- Có thể chọn nhiều mục tiêu

- Color coding theo AppColorTokens

**State Updates**:
```dart
// Toggle selection
if (state.goals.contains(goal)) {
  state = state.copyWith(
    goals: state.goals.where((g) => g != goal).toList()
  );
} else {
  state = state.copyWith(
    goals: [...state.goals, goal]
  );
}
```

---

#### **Bước 3: Conditions Step** (`conditions_step.dart`)
**Thu thập**: Tình trạng sức khỏe (`conditions` - List<String>)

**Options** (multi-select chips):
- Tiểu đường (Diabetes)
- Huyết áp cao (Hypertension)
- Bệnh tim (Heart Disease)
- Astm a (Asthma)
- Dị ứng (Allergies)
- Viêm khớp (Arthritis)
- Rối loạn tiêu hóa (Digestive Issues)
- Rối loạn giấc ngủ (Sleep Disorders)
- Lo âu/Trầm cảm (Anxiety/Depression)
- Béo phì (Obesity)
- PCOS
- Không có ("Tôi khỏe mạnh")

**Important Logic**:

- Nếu chọn "Không có" → Xóa tất cả conditions khác
- Nếu chọn condition khác → Bỏ "Không có" nếu đang có

**UI Enhancements**:
- Warning icon cho conditions nghiêm trọng
- Info tooltips giải thích từng condition
- Section grouping (Chronic, Mental, Physical)

---

#### **Bước 4: Lifestyle Step** (`lifestyle_step.dart`)
**Thu thập thông tin lối sống**:

**4.1. Thông số cơ thể**:
- **Chiều cao** (`heightCm` - double) - Number input với đơn vị cm
- **Cân nặng** (`weightKg` - double) - Number input với đơn vị kg
- **BMI tự động tính**: `BMI = weightKg / ((heightCm/100) ^ 2)`

**4.2. Chất lượng giấc ngủ** (`sleepQuality` - String):
- "Tốt" (7-9 giờ)
- "Trung bình" (5-7 giờ)
- "Kém" (<5 giờ)
- Radio selection

**4.3. Mức độ vận động** (`activityLevel` - String):
- "Ít vận động" (Sedentary)
- "Nhẹ" (Light exercise 1-3 days/week)
- "Trung bình" (Moderate 3-5 days/week)
- "Cao" (Intense 6-7 days/week)
- Radio selection

**4.4. Lượng nước mỗi ngày** (`waterPerDay` - int):

- Slider từ 0-4000ml
- Step: 250ml
- Visual indicator: Cup icons fill theo giá trị
- Recommended range highlight (2000-3000ml)

**4.5. Thói quen ăn uống** (`habits` - List<String>):
- "Ăn sáng đầy đủ"
- "Ăn muộn"
- "Ăn vặt nhiều"
- "Thích đồ ngọt"
- "Uống cà phê nhiều"
- "Uống rượu/bia"
- "Ăn chay"
- Multi-select chips

**Real-time Features**:
- BMI calculator live update
- BMI category badge (Underweight/Normal/Overweight/Obese)
- Color-coded health indicators
- Validation messages

---

#### **Bước 5: Extras Step** (`extras_step.dart`)
**Thu thập thông tin bổ sung (optional)**:

**5.1. Dị ứng thực phẩm**:
- `allergyName` (String) - Tên thực phẩm dị ứng
- `allergyNote` (String) - Mô tả triệu chứng
- TextFormField với expansion panel

**5.2. Điều trị y tế**:
- `treatmentName` (String) - Tên bệnh đang điều trị
- `medicationName` (String) - Tên thuốc đang dùng
- `treatmentNote` (String) - Ghi chú thêm
- Expandable section với multiple entry support


**5.3. Mối quan tâm khác**:
- `concernText` (String) - Free-form text area
- Placeholder: "Ví dụ: Tôi muốn cải thiện khả năng tập trung, giảm đau đầu..."
- MaxLines: 5

**UI Note**: 
- Tất cả fields ở bước này đều optional
- Có thể skip toàn bộ bước
- ⚠️ **BUG**: `concernText` không được lưu vào database (cần fix)

---

#### **Bước 6: Review Step** (`review_step.dart`)
**Hiển thị tóm tắt toàn bộ thông tin đã nhập**:

**Layout Sections**:
1. **Thông tin cá nhân**
   - Họ tên, giới tính, năm sinh, nghề nghiệp
   - Email, số điện thoại

2. **Thông số sức khỏe**
   - Chiều cao, cân nặng, BMI (với badge màu)
   - Mục tiêu (chip list)
   - Tình trạng sức khỏe (chip list với icons)

3. **Lối sống**
   - Chất lượng giấc ngủ (icon + text)
   - Mức độ vận động (icon + text)
   - Lượng nước/ngày (progress bar + text)
   - Thói quen ăn uống (chip list)

4. **Thông tin bổ sung** (if any)
   - Dị ứng thực phẩm
   - Điều trị y tế
   - Mối quan tâm

**Action Area**:

- **Checkbox điều khoản** (`agreed` - bool, BẮT BUỘC):
  ```
  ☐ Tôi đồng ý cho BioAI sử dụng thông tin của tôi để cá nhân hóa 
    nội dung và tạo kế hoạch sức khỏe. Dữ liệu được lưu trữ cục bộ 
    trên thiết bị của tôi.
  ```
  
- **Edit buttons**: Mỗi section có nút "Sửa" quay lại bước tương ứng
- **Submit button**: "Hoàn thành" (disabled nếu chưa agree)

---

### 💾 Quy trình lưu dữ liệu

#### **Validation Pre-save**

Method: `OnboardingState.canSave`

```dart
bool get canSave {
  return fullName.isNotEmpty &&
         gender.isNotEmpty &&
         birthYear > 1900 &&
         occupation.isNotEmpty &&
         agreed == true;
}
```

#### **Save Flow** (Controller method: `saveOnboarding()`)

**Phase 1: Validation & State Update**
```dart
if (!state.agreed) {
  state = state.copyWith(
    savedLog: 'Bạn cần đồng ý với điều khoản'
  );
  return;
}

if (!state.canSave) {
  state = state.copyWith(
    savedLog: 'Vui lòng điền đầy đủ thông tin bắt buộc'
  );
  return;
}

state = state.copyWith(isSaving: true);
```


**Phase 2: Entity Conversion**
```dart
final entity = OnboardingEntity(
  email: state.email,
  phone: state.phone,
  fullName: state.fullName,
  gender: state.gender,
  birthYear: state.birthYear,
  occupation: state.occupation,
  goals: state.goals,
  conditions: state.conditions,
  habits: state.habits,
  heightCm: state.heightCm,
  weightKg: state.weightKg,
  sleepQuality: state.sleepQuality,
  activityLevel: state.activityLevel,
  waterPerDay: state.waterPerDay,
  allergyName: state.allergyName,
  allergyNote: state.allergyNote,
  treatmentName: state.treatmentName,
  medicationName: state.medicationName,
  treatmentNote: state.treatmentNote,
  // Note: concernText missing from entity (BUG)
);
```

**Phase 3: Repository Save** (Multi-table transaction)

File: `onboarding_local_datasource.dart`

```sql
BEGIN TRANSACTION;

-- 1. Insert/Update users table
INSERT OR REPLACE INTO users (
  id, email, phone, full_name, gender, birth_year, occupation, created_at, updated_at
) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?);

-- 2. Insert/Update health_profiles table
INSERT OR REPLACE INTO health_profiles (
  id, user_id, height_cm, weight_kg, created_at, updated_at
) VALUES (?, ?, ?, ?, ?, ?);

-- 3. Delete old goals and insert new
DELETE FROM health_goals WHERE user_id = ?;
INSERT INTO health_goals (id, user_id, goal_name) 
VALUES (?, ?, ?); -- Repeat for each goal


-- 4. Delete old conditions and insert new
DELETE FROM health_conditions WHERE user_id = ?;
INSERT INTO health_conditions (id, user_id, condition_name) 
VALUES (?, ?, ?); -- Repeat for each condition

-- 5. Delete old habits and insert new
DELETE FROM lifestyle_habits WHERE user_id = ?;
INSERT INTO lifestyle_habits (
  id, user_id, sleep_quality, activity_level, water_per_day, habit_name
) VALUES (?, ?, ?, ?, ?, ?); -- Repeat for each habit

-- 6. Insert food allergies if provided
DELETE FROM food_allergies WHERE user_id = ?;
INSERT INTO food_allergies (id, user_id, allergy_name, allergy_note) 
VALUES (?, ?, ?, ?);

-- 7. Insert medical treatments if provided
DELETE FROM medical_treatments WHERE user_id = ?;
INSERT INTO medical_treatments (
  id, user_id, treatment_name, medication_name, treatment_note
) VALUES (?, ?, ?, ?, ?);

-- 8. Insert survey answers for analytics
INSERT INTO survey_answers (id, user_id, question, answer) 
VALUES (?, ?, ?, ?); -- For each survey field

COMMIT;
```

**Phase 4: Completion Callback** ⚠️ **CRITICAL STEP**

```dart
await ref.read(onboardingCompletionCallbackProvider)(entity);
```

Callback được override trong `main.dart`:

```dart
onboardingCompletionCallbackProvider.overrideWithValue(
  (OnboardingEntity profile) async {
    try {
      // Step 1: Generate 21 meal records via AI
      final dashboardController = container.read(
        dashboardControllerProvider.notifier
      );
      await dashboardController.genMealByWeeksToDB(
        requireComplete: true  // Must have exactly 21 meals
      );

      
      // Step 2: Generate exercise tasks via AI
      final aiService = container.read(aiServiceProvider);
      final today = DateTime.now();
      final tomorrow = today.add(const Duration(days: 1));
      final exerciseTasks = await aiService.generateExerciseTasks(
        profile: profile,
        startDate: tomorrow,
        days: 7,
      );
      
      // Step 3: Fetch meal plans to include in schedule
      final mealPlanRepo = container.read(mealPlanRepositoryProvider);
      final mealPlans = await mealPlanRepo.getMealByWeeks();
      
      // Step 4: Build complete lifestyle schedule
      final scheduleService = LifestyleScheduleBuilderService();
      final scheduleItems = await scheduleService.buildSchedule(
        profile: profile,
        mealPlans: mealPlans,
        exerciseTasks: exerciseTasks,
        startDate: tomorrow,
        days: 7,
      );
      
      // Step 5: Save schedule to database
      final scheduleRepo = container.read(
        lifestyleScheduleRepositoryProvider
      );
      await scheduleRepo.seedScheduleItems(scheduleItems);
      
      // Step 6: Schedule local reminder notifications
      final reminderService = container.read(
        reminderScheduleServiceProvider
      );
      await reminderService.scheduleFromLifestyleSchedule();
      
    } catch (e) {
      throw Exception('Onboarding generation failed: $e');
    }
  }
)
```


**Phase 5: Mark Completion**

```dart
// Only set flag if callback succeeds
await AppPrefs.setOnboardingCompleted(true);

state = state.copyWith(
  isSaving: false,
  savedLog: 'Đã lưu thành công!'
);
```

**Phase 6: Navigation**

Page listens to `savedLog` changes:
```dart
ref.listen(onboardingProvider.select((s) => s.savedLog), (prev, next) {
  if (next == 'Đã lưu thành công!') {
    context.go('/menu');
  }
});
```

### ⚠️ Error Handling

**If any step fails**:
- Transaction rollback (database integrity maintained)
- `onboarding_completed` flag NOT set
- User stays on review step
- Error message displayed in `savedLog`
- User can retry

**Common failure points**:
- AI generation timeout (10 minutes limit)
- Invalid AI response format
- Database write error
- Insufficient meal records (<21)

### 🔌 Dependencies

- **State**: `NotifierProvider<OnboardingController, OnboardingState>`
- **Storage**: SQLite (8 tables involved)
- **AI**: Gemini API (meal + exercise generation)
- **Notifications**: Local notification scheduling
- **Preferences**: SharedPreferences (completion flag)

---


## 📊 4. DASHBOARD (MÀN HÌNH CHÍNH)

### 📁 Vị trí files
```
features/dashboard/
├── presentation/
│   ├── pages/
│   │   ├── dashboard_page.dart
│   │   └── menu_page.dart (Main Navigation Shell)
│   └── controllers/dashboard_controller.dart
├── providers/dashboard_provider.dart
├── data/
│   ├── datasources/dashboard_local_datasource.dart
│   └── models/dashboard_mock_stats.dart
├── domain/
│   ├── entities/dashboard_entity.dart
│   └── repositories/
│       ├── dashboard_repository.dart
│       └── dashboard_repository_impl.dart
```

### 🎯 Mục đích
- Tổng quan sức khỏe hàng ngày
- Hiển thị BMI và thông số cơ bản
- Timeline hoạt động trong ngày
- Tiến độ mục tiêu
- AI insights và khuyến nghị

### 📱 UI Components (từ trên xuống dưới)

#### **1. Hero Header** (`HeroHeader` widget)
**Nội dung**:
- Avatar placeholder (tròn, 60x60)
- Greeting theo thời gian:
  - 5h-12h: "Chào buổi sáng"
  - 12h-18h: "Chào buổi chiều"
  - 18h-5h: "Chào buổi tối"
- Tên người dùng (từ database)
- Quick action buttons:
  - Notification bell icon
  - Settings icon

**Data**: `dashboardEntity.fullName`

---

#### **2. Health Score Card** (`HealthScoreCard` widget)
**Hiển thị**:

- **BMI Value**: `dashboardEntity.bmi.toStringAsFixed(1)`
- **BMI Category** với màu sắc:
  - < 18.5: "Thiếu cân" (blue)
  - 18.5-24.9: "Bình thường" (green)
  - 25-29.9: "Thừa cân" (orange)
  - ≥ 30: "Béo phì" (red)
- Progress ring visualization
- Tap để xem chi tiết

**Calculation**: BMI được tính lại từ height và weight trong database

---

#### **3. Quick Stats Grid** (`QuickStatsGrid` widget)
**4 stat cards (2x2 grid)**:

1. **Chiều cao**
   - Icon: ruler
   - Value: `${heightCm} cm`
   - Label: "Chiều cao"

2. **Cân nặng**
   - Icon: scale
   - Value: `${weightKg} kg`
   - Label: "Cân nặng"

3. **Mục tiêu**
   - Icon: target
   - Value: `${goals.length}`
   - Label: "Mục tiêu đang theo dõi"

4. **Tình trạng**
   - Icon: medical
   - Value: `${conditions.length}`
   - Label: "Tình trạng sức khỏe"

**Data Source**: Real data từ `dashboardEntity`

---

#### **4. AI Insight Section** (`AiInsightSection` widget)
**Status**: ⚠️ Mock data (chưa tích hợp AI thật)

**Hiển thị**:
- Card với gradient background
- AI avatar icon
- Insight message:
  ```
  "Dựa trên dữ liệu của bạn, tôi nhận thấy bạn đang có xu hướng 
   cải thiện chất lượng giấc ngủ. Hãy tiếp tục duy trì!"
  ```
- "Xem chi tiết" button

**Future Implementation**:

- Analyze health trends từ `health_tracking_logs`
- Generate insights qua Gemini AI
- Store in `ai_insights` table
- Daily refresh

---

#### **5. Daily Timeline** (`DailyTimeline` widget)
**Status**: ⚠️ Mock data

**Hiển thị**:
- Timeline view với time markers
- Activity cards:
  - 07:00 - Ăn sáng: "Cháo yến mạch + trái cây"
  - 09:00 - Uống nước: "250ml"
  - 12:00 - Ăn trưa: "Cơm gạo lứt + rau củ"
  - 15:00 - Vận động: "Đi bộ 30 phút"
  - 18:00 - Ăn tối: "Salad + cá hồi nướng"
  - 22:00 - Ngủ

**Icons & Colors**:
- Meal: fork_knife (cyan)
- Water: water_drop (blue)
- Exercise: fitness (green)
- Sleep: bed (purple)

**Future Implementation**:
- Link to `lifestyle_schedule_items` table
- Real-time completion status
- Tap to mark as done

---

#### **6. Goal Progress Section** (`GoalProgressSection` widget)
**Status**: ⚠️ Mock data

**Hiển thị từng goal với**:
- Goal name
- Progress bar (0-100%)
- Current/Target values
- Color coding

**Example mock goals**:
- "Giảm cân": 65kg/60kg (83%)
- "Cải thiện giấc ngủ": 6.5h/8h (81%)
- "Tăng cường vận động": 4/5 ngày (80%)

**Future Implementation**:

- Calculate từ `health_goals` và `health_tracking_logs`
- Weekly/Monthly progress trends
- Goal completion notifications

---

#### **7. Smart Lifestyle Section** (`SmartLifestyleSection` widget)
**Status**: ⚠️ Mock data

**Quick tips cards**:
- "Đã đến giờ uống nước" (with water icon)
- "Nghỉ giải lao sau 2 tiếng làm việc" (with break icon)
- "Chuẩn bị bữa tối lành mạnh" (with meal icon)

**Future Implementation**:
- Time-based smart suggestions
- Context-aware tips (weather, schedule, health data)
- Actionable reminders

---

#### **8. Goal Chips Grid** (`GoalChipsGrid` widget)
**Status**: ✅ Real data

**Hiển thị**:
- Wrap grid của goal chips
- Each chip shows:
  - Goal icon (auto-mapped từ goal name)
  - Goal name
  - Filled variant với primary color

**Data**: `dashboardEntity.goals` (List<String>)

**Icon Mapping**:
```dart
"Giảm cân" → Icons.trending_down
"Tăng cơ" → Icons.fitness_center
"Cải thiện giấc ngủ" → Icons.bed
"Tăng năng lượng" → Icons.bolt
"Giảm stress" → Icons.spa
// ... etc
```

---

### 🔄 Data Flow

#### **Provider Setup**


```dart
// FutureProvider fetches dashboard data once
final dashboardProvider = FutureProvider<DashboardEntity>((ref) async {
  final repository = ref.read(dashboardRepositoryProvider);
  return await repository.fetchDashboard();
});

// Page watches provider
final dashboardAsync = ref.watch(dashboardProvider);

dashboardAsync.when(
  data: (dashboard) => /* Render UI */,
  loading: () => LoadingState(),
  error: (err, stack) => ErrorState(error: err),
);
```

#### **Repository Query** (dashboard_repository_impl.dart)

```sql
-- Join multiple tables to build DashboardEntity
SELECT 
  u.full_name,
  u.gender,
  u.birth_year,
  hp.height_cm,
  hp.weight_kg,
  GROUP_CONCAT(DISTINCT hg.goal_name) as goals,
  GROUP_CONCAT(DISTINCT hc.condition_name) as conditions,
  lh.sleep_quality,
  lh.activity_level,
  lh.water_per_day,
  GROUP_CONCAT(DISTINCT lh.habit_name) as habits
FROM users u
LEFT JOIN health_profiles hp ON hp.user_id = u.id
LEFT JOIN health_goals hg ON hg.user_id = u.id
LEFT JOIN health_conditions hc ON hc.user_id = u.id
LEFT JOIN lifestyle_habits lh ON lh.user_id = u.id
WHERE u.id = ?
GROUP BY u.id;
```

#### **Entity Calculation**

```dart
class DashboardEntity implements HealthDataInterface {
  // ... fields
  
  double get bmi {
    if (heightCm == null || weightKg == null) return 0;
    final heightM = heightCm! / 100;
    return weightKg! / (heightM * heightM);
  }
  
  String get bmiCategory {
    if (bmi < 18.5) return 'Thiếu cân';
    if (bmi < 25) return 'Bình thường';
    if (bmi < 30) return 'Thừa cân';
    return 'Béo phì';
  }
}
```

---

### 🍽️ Meal Generation Orchestration


**Controller Method**: `DashboardController.genMealByWeeksToDB()`

```dart
Future<void> genMealByWeeksToDB({bool requireComplete = false}) async {
  state = const AsyncLoading();
  
  try {
    // 1. Fetch dashboard data
    final repository = ref.read(dashboardRepositoryProvider);
    final dashboardData = await repository.fetchDashboard();
    
    // 2. Generate meals via AI
    final aiService = ref.read(aiServiceProvider);
    final mealPlan = await aiService.generateMealPlan(
      healthData: dashboardData  // Polymorphic: DashboardEntity implements HealthDataInterface
    );
    
    // 3. Validate meal count if required
    if (requireComplete && mealPlan.length != 21) {
      throw Exception('Expected 21 meals, got ${mealPlan.length}');
    }
    
    // 4. Save to database
    await repository.saveMealPlan(mealPlan);
    
    state = const AsyncData(null);
  } catch (e, stack) {
    state = AsyncError(e, stack);
    rethrow;
  }
}
```

**Usage Contexts**:
1. **Onboarding callback**: `requireComplete: true` (must have 21 meals)
2. **Manual refresh**: `requireComplete: false` (best effort)

---

### 🔌 Main Navigation Shell

**File**: `menu_page.dart` → `MainNavigationPage`

**Structure**:
```dart
Scaffold(
  body: PageView(
    controller: _pageController,
    children: [
      DashboardPage(),           // Tab 0
      MealPlanPage(),            // Tab 1
      HealthInsightsView(),      // Tab 2
      SettingsView(),            // Tab 3
    ],
  ),
  bottomNavigationBar: NavigationBar(
    selectedIndex: _currentIndex,
    destinations: [
      NavigationDestination(icon: Icons.home, label: "Hôm nay"),
      NavigationDestination(icon: Icons.restaurant, label: "Ăn gì"),
      NavigationDestination(icon: Icons.favorite, label: "Góc của bạn"),
      NavigationDestination(icon: Icons.settings, label: "Tùy chỉnh"),
    ],
  ),
  floatingActionButton: AIChatFAB(),  // AI chat shortcut
)
```

**Behavior**:
- Smooth page transitions với `PageView`

- State preserved khi switch tabs
- Bottom navigation sync với PageView
- FAB visible trên tất cả tabs

---

## 🍽️ 5. KẾ HOẠCH ĂN UỐNG AI (MEAL PLAN)

### 📁 Vị trí files
```
features/meal_plan/
├── presentation/
│   ├── pages/meal_plan_page.dart
│   └── controllers/meal_plan_controller.dart
├── data/
│   ├── datasources/meal_plan_local_datasource.dart
│   ├── daos/meal_plan_dao.dart
│   └── models/meal_plan_model.dart
├── domain/
│   ├── entities/meal_plan_entity.dart
│   └── repositories/
│       ├── meal_plan_repository.dart
│       └── meal_plan_repository_impl.dart
└── providers/meal_plan_provider.dart
```

### 🎯 Mục đích
Hiển thị kế hoạch ăn uống 7 ngày được AI tạo ra dựa trên:
- BMI và thông số cơ thể
- Mục tiêu sức khỏe
- Tình trạng sức khỏe (diabetes, hypertension, etc.)
- Dị ứng thực phẩm
- Thói quen ăn uống
- Mức độ vận động
- Chất lượng giấc ngủ

### 📱 UI Components

#### **Header Section**
- Title: "Kế hoạch ăn uống"
- Subtitle: "7 ngày bắt đầu từ ngày mai"
- Refresh button (circular icon)
- Pull-to-refresh gesture

#### **Date Selector**
**Component**: Horizontal scrollable date chips

```dart
ListView.builder(
  scrollDirection: Axis.horizontal,
  itemCount: availableDates.length,
  itemBuilder: (context, index) {
    final date = availableDates[index];
    final isSelected = date == selectedDate;
    
    return DateChip(
      date: date,
      isSelected: isSelected,
      onTap: () => setSelectedDate(date),
    );
  },
)
```

**Date Chip Content**:

- Day of week: "T2", "T3", "T4", "T5", "T6", "T7", "CN"
- Day of month: "15"
- Month abbreviation: "Th6"
- Visual state:
  - Selected: Primary color fill, white text
  - Unselected: Neutral background, dark text

#### **Meal Cards List**

**3 meals per day**: Breakfast, Lunch, Dinner

**Card Structure**:
```
┌─────────────────────────────────────────┐
│ 🍽️ BREAKFAST                 [Badge]   │
│ ─────────────────────────────────────── │
│ Cháo yến mạch với trái cây và hạt       │
│                                         │
│ Cháo yến mạch nấu với sữa tươi không   │
│ đường, thêm chuối, dâu tây, hạnh nhân...│
│                                         │
│ 📖 Cách chế biến                        │
│ 1. Nấu yến mạch với sữa trong 5 phút   │
│ 2. Thêm trái cây và hạt lên trên       │
│                                         │
│ 💊 Dinh dưỡng                           │
│ 🔥 350 kcal  💧 200ml  🥩 12g protein  │
│ 🍚 45g carbs 🥑 10g fat 🌾 8g fiber    │
└─────────────────────────────────────────┘
```

**Fields Displayed**:
1. **Meal Type Badge**
   - "BREAKFAST" / "LUNCH" / "DINNER"
   - Icon + color coded:
     - Breakfast: 🌅 Amber
     - Lunch: ☀️ Orange
     - Dinner: 🌙 Indigo

2. **Meal Name** (headline style)
   - Font: AppTextStyles.headingMedium
   - MaxLines: 2, overflow ellipsis

3. **Description** (body style)
   - Font: AppTextStyles.bodyMedium
   - Color: Neutral 600
   - MaxLines: 3, overflow ellipsis
   - Expandable on tap

4. **Cooking Instructions Section** (collapsible)

   - Title: "📖 Cách chế biến"
   - Content: Step-by-step instructions
   - Initially collapsed, expand on tap
   - Only shown if `cooking_instructions` not null

5. **Nutrition Facts Grid** (2x3)
   ```
   🔥 350 kcal        💧 200ml
   🥩 12g protein     🍚 45g carbs
   🥑 10g fat         🌾 8g fiber
   ```

6. **Status Badge** (optional)
   - "Đã hoàn thành" (green) if marked done
   - "Bỏ qua" (gray) if skipped
   - Default: No badge

**Card Interaction**:
- Tap card → Expand/collapse description
- Tap cooking section → Expand/collapse instructions
- Long press → Show options (Mark done, Skip, Share)

#### **Empty State**

Hiển thị khi không có meal plan:

```
┌─────────────────────────────────────────┐
│              🍽️                         │
│                                         │
│    Chưa có kế hoạch ăn uống            │
│                                         │
│    Nhấn nút làm mới để tạo kế hoạch    │
│    ăn uống cá nhân hóa cho bạn         │
│                                         │
│         [🔄 Tạo kế hoạch]              │
└─────────────────────────────────────────┘
```

---

### 🤖 AI Generation Process

#### **Trigger Points**
1. **Sau onboarding**: Tự động generate (required 21 meals)
2. **Manual refresh**: User nhấn refresh button
3. **Empty state button**: User nhấn "Tạo kế hoạch"

#### **AI Prompt Structure**

**Input to Gemini** (via `AIService.generateMealPlan()`):

```json
{
  "user_profile": {
    "bmi": 22.5,
    "height_cm": 170,
    "weight_kg": 65,
    "age": 28,
    "gender": "Nữ",
    "goals": ["Giảm cân", "Cải thiện giấc ngủ"],
    "conditions": ["Không có"],
    "habits": ["Ăn sáng đầy đủ", "Thích đồ ngọt"],
    "allergies": "Không dung nạp lactose",
    "sleep_quality": "Trung bình",
    "activity_level": "Nhẹ",
    "water_per_day": 2000
  },
  "requirements": {
    "days": 7,
    "start_date": "2026-06-18",
    "meals_per_day": 3,
    "total_meals": 21,
    "cuisine": "Vietnamese",
    "dietary_restrictions": ["Lactose-free"],
    "calorie_target": "Deficit for weight loss"
  }
}
```

**System Prompt** (NutritionPrompt.generateMealPlan):


```
Bạn là chuyên gia dinh dưỡng AI của BioAI. Nhiệm vụ của bạn là tạo 
kế hoạch ăn uống 7 ngày cá nhân hóa cho người dùng.

Yêu cầu:
1. Mỗi ngày có 3 bữa: breakfast, lunch, dinner
2. Tính toán chính xác calories và dinh dưỡng
3. Phù hợp với mục tiêu và tình trạng sức khỏe
4. Tránh thực phẩm gây dị ứng
5. Ưu tiên món ăn Việt Nam, dễ chế biến
6. Cân bằng dinh dưỡng: protein, carbs, fat, fiber
7. Đủ 2000-3000ml nước/ngày

Trả về JSON array với format:
[
  {
    "meal_date": "YYYY-MM-DD",
    "meal_type": "breakfast|lunch|dinner",
    "meal_name": "Tên món",
    "description": "Mô tả chi tiết",
    "cooking_instructions": "Hướng dẫn từng bước",
    "calories": 350,
    "protein_grams": 12,
    "carbs_grams": 45,
    "fat_grams": 10,
    "fiber_grams": 8,
    "water_ml": 200,
    "is_vegetarian": false,
    "is_vegan": false,
    "allergen_warnings": "Chứa hạt",
    "health_benefits": "Tốt cho tim mạch",
    "meal_timing": "07:00"
  }
]
```

**AI Model**: `gemini-1.5-flash`  
**Temperature**: 0.7 (creative but consistent)  
**Max Tokens**: 8000  
**Timeout**: 10 minutes  
**Retry**: 3 attempts với exponential backoff

#### **Response Processing**

**Step 1: Extract JSON**
```dart
String cleanedResponse = response
  .replaceAll('```json', '')
  .replaceAll('```', '')
  .trim();

// Remove trailing commas (common AI mistake)
cleanedResponse = cleanedResponse.replaceAll(RegExp(r',(\s*[}\]])'), r'$1');

// Extract array if wrapped in object
if (cleanedResponse.contains('"meals"')) {
  final parsed = jsonDecode(cleanedResponse);
  cleanedResponse = jsonEncode(parsed['meals']);
}
```

**Step 2: Parse & Validate**

```dart
final List<dynamic> jsonList = jsonDecode(cleanedResponse);

if (requireComplete && jsonList.length != 21) {
  throw FormatException('Expected 21 meals, got ${jsonList.length}');
}

final meals = jsonList.map((json) {
  return MealPlanModel.fromJson(json);
}).toList();
```

**Step 3: Database Insert**
```sql
BEGIN TRANSACTION;

-- Clear existing meals for user
DELETE FROM meal_plans WHERE user_id = ?;

-- Insert new meals
INSERT INTO meal_plans (
  id, user_id, meal_date, meal_type, meal_name, description,
  cooking_instructions, calories, protein_grams, carbs_grams,
  fat_grams, fiber_grams, water_ml, is_vegetarian, is_vegan,
  allergen_warnings, health_benefits, meal_timing,
  created_at, updated_at
) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);

COMMIT;
```

---

### 📅 Date Parsing Logic

**Supported Formats**:
1. ISO 8601: `"2026-06-18T07:00:00.000Z"`
2. YYYY-MM-DD: `"2026-06-18"`
3. DD/MM/YYYY: `"18/06/2026"`

**Parser Code**:
```dart
DateTime? parseMealDate(String? dateStr) {
  if (dateStr == null || dateStr.isEmpty) return null;
  
  // Try ISO 8601 first
  DateTime? date = DateTime.tryParse(dateStr);
  if (date != null) return date;
  
  // Try YYYY-MM-DD
  final dashParts = dateStr.split('-');
  if (dashParts.length == 3) {
    final year = int.tryParse(dashParts[0]);
    final month = int.tryParse(dashParts[1]);
    final day = int.tryParse(dashParts[2]);
    if (year != null && month != null && day != null) {
      return DateTime(year, month, day);
    }
  }
  
  // Try DD/MM/YYYY
  final slashParts = dateStr.split('/');
  if (slashParts.length == 3) {
    final day = int.tryParse(slashParts[0]);
    final month = int.tryParse(slashParts[1]);
    final year = int.tryParse(slashParts[2]);
    if (day != null && month != null && year != null) {
      return DateTime(year, month, day);
    }
  }
  
  return null;
}
```

---

### 🔄 Controller State Management


**Provider**: `AsyncNotifierProvider<MealPlanController, List<MealPlanEntity>>`

```dart
class MealPlanController extends AsyncNotifier<List<MealPlanEntity>> {
  @override
  Future<List<MealPlanEntity>> build() async {
    // Initial load
    final repository = ref.read(mealPlanRepositoryProvider);
    return await repository.getMealByWeeks();
  }
  
  Future<void> refresh() async {
    state = const AsyncLoading();
    
    try {
      // Trigger AI generation
      final dashboardController = ref.read(dashboardControllerProvider.notifier);
      await dashboardController.genMealByWeeksToDB();
      
      // Reload from database
      final repository = ref.read(mealPlanRepositoryProvider);
      final meals = await repository.getMealByWeeks();
      
      state = AsyncData(meals);
    } catch (e, stack) {
      state = AsyncError(e, stack);
    }
  }
}
```

**Page Usage**:
```dart
final mealsAsync = ref.watch(mealPlanControllerProvider);

mealsAsync.when(
  data: (meals) {
    if (meals.isEmpty) {
      return EmptyState(
        message: "Chưa có kế hoạch ăn uống",
        action: () => ref.read(mealPlanControllerProvider.notifier).refresh(),
      );
    }
    
    return MealListView(
      meals: meals,
      selectedDate: selectedDate,
    );
  },
  loading: () => LoadingState(message: "Đang tạo kế hoạch..."),
  error: (error, _) => ErrorState(
    error: error,
    onRetry: () => ref.invalidate(mealPlanControllerProvider),
  ),
);
```

---

### 📊 Data Model

**Entity** (`meal_plan_entity.dart`):
```dart
class MealPlanEntity {
  final String id;
  final String userId;
  final DateTime mealDate;
  final String mealType;  // breakfast, lunch, dinner
  final String mealName;
  final String description;
  final String? cookingInstructions;
  final int calories;
  final double proteinGrams;
  final double carbsGrams;
  final double fatGrams;
  final double fiberGrams;
  final int waterMl;
  final bool isVegetarian;
  final bool isVegan;
  final String? allergenWarnings;
  final String? healthBenefits;
  final String? mealTiming;  // "07:00", "12:00", "18:00"
  final DateTime createdAt;
  final DateTime updatedAt;
}
```

**Database Table** (`meal_plans`):

```sql
CREATE TABLE meal_plans (
  id TEXT PRIMARY KEY,
  user_id TEXT NOT NULL,
  meal_date TEXT NOT NULL,
  meal_type TEXT NOT NULL,
  meal_name TEXT NOT NULL,
  description TEXT,
  cooking_instructions TEXT,  -- Added in v3 migration
  calories INTEGER NOT NULL,
  protein_grams REAL NOT NULL,
  carbs_grams REAL NOT NULL,
  fat_grams REAL NOT NULL,
  fiber_grams REAL NOT NULL,
  water_ml INTEGER NOT NULL,
  is_vegetarian INTEGER DEFAULT 0,
  is_vegan INTEGER DEFAULT 0,
  allergen_warnings TEXT,
  health_benefits TEXT,
  meal_timing TEXT,
  created_at TEXT NOT NULL,
  updated_at TEXT NOT NULL
);

CREATE INDEX idx_meal_plans_user_date 
  ON meal_plans(user_id, meal_date);
  
CREATE INDEX idx_meal_plans_type 
  ON meal_plans(meal_type);
```

---

### ⚠️ Known Issues & Tech Debt

1. **7 ngày vs 30 ngày**
   - Code hiện tại: Generate 7 ngày
   - Product docs: Yêu cầu 30 ngày với cycle refresh
   - Cần quyết định scope trước khi refactor

2. **Tight coupling**
   - `AIService` trả về `MealPlanModel` (feature data model)
   - Nên trả về domain entity hoặc DTO

3. **No meal tracking**
   - Chưa có chức năng đánh dấu "Đã ăn"
   - Không lưu meal completion history

4. **Static timing**
   - Meal timing hardcoded trong AI prompt
   - Nên cho user tùy chỉnh giờ ăn

---

## 📅 6. LỊCH TRÌNH LỐI SỐNG (LIFESTYLE SCHEDULE)

### 📁 Vị trí files
```
features/lifestyle_schedule/
├── presentation/
│   ├── pages/lifestyle_schedule_page.dart
│   └── controllers/lifestyle_schedule_controller.dart
├── data/
│   ├── datasources/lifestyle_schedule_local_datasource.dart
│   ├── daos/lifestyle_schedule_items_dao.dart
│   └── models/lifestyle_schedule_item_model.dart
├── domain/
│   ├── entities/lifestyle_schedule_item_entity.dart
│   ├── services/lifestyle_schedule_builder_service.dart
│   └── repositories/
│       ├── lifestyle_schedule_repository.dart
│       └── lifestyle_schedule_repository_impl.dart
└── providers/lifestyle_schedule_provider.dart
```

### 🎯 Mục đích
Timeline view tổng hợp TẤT CẢ hoạt động sức khỏe trong ngày:
- Bữa ăn (từ meal plan)
- Bài tập thể dục (AI generated)
- Uống nước (rule-based)
- Hoạt động tinh thần (meditation, brain training)
- Giấc ngủ (sleep schedule)

### 📱 UI Components

#### **Header**
- Title: "Lịch trình hôm nay"
- Date selector (week view)
- Progress indicator: "5/12 hoạt động hoàn thành"

#### **Timeline View**

**Visual Design**:
```
07:00 ━●━ 🍽️ ĂN SÁNG                    ✓
      │   Cháo yến mạch với trái cây
      │   350 kcal · 15 phút
      │
09:00 ━●━ 💧 UỐNG NƯỚC                   ✓
      │   250ml nước lọc
      │
10:00 ━○━ 🧠 TRÍ NÃO
      │   Đọc sách 20 phút
      │
12:00 ━●━ 🍽️ ĂN TRƯA                    ✓
      │   Cơm gạo lứt + rau củ
      │   450 kcal · 30 phút
```

**Timeline Elements**:
- **Time marker**: Bold, left-aligned
- **Connector line**: Vertical line linking activities
- **Status dot**: 
  - Filled (●) = Completed (green)
  - Empty (○) = Pending (gray)
  - Current (⊙) = In progress (blue)
- **Category icon**: Color-coded
- **Activity title**: Medium weight
- **Details**: Light text, 2 lines max
- **Checkbox**: Right side, only for future/current tasks

---

### 🏷️ Task Categories

#### **1. MEAL (🍽️) - Cyan**
**Source**: `meal_plans` table

**Properties**:
