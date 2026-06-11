# Glossary

## Domain Terms

| Thuật ngữ | Định nghĩa |
|---|---|
| **Onboarding** | Wizard 7 bước thu thập thông tin sức khỏe lần đầu của người dùng |
| **Health Profile** | Bộ thông tin sức khỏe cơ bản: chiều cao, cân nặng, BMI, nghề nghiệp |
| **Health Goal** | Mục tiêu sức khỏe người dùng chọn, ví dụ: giảm cân, ngủ ngon hơn |
| **Health Condition** | Tình trạng sức khỏe hiện tại, ví dụ: mất ngủ, đau dạ dày |
| **Lifestyle Habit** | Thói quen sinh hoạt: ăn sáng, đi ngủ muộn, uống rượu, v.v. |
| **Meal Plan** | Kế hoạch ăn uống 7 ngày (3 bữa/ngày) do AI tạo ra |
| **AI Insight** | Phân tích AI về tình trạng sức khỏe (bảng tồn tại, chưa dùng) |
| **Survey Answer** | Câu trả lời dạng key-value lưu thêm metadata onboarding |
| **BMI** | Body Mass Index = weight(kg) / height(m)² |

## Technical Terms

| Thuật ngữ | Định nghĩa |
|---|---|
| **BioAIApp** | Widget gốc của ứng dụng (`lib/app/app.dart`) |
| **DatabaseService** | Singleton quản lý SQLite connection (`core/storage/localdb/database_service.dart`) |
| **AppPrefs** | Wrapper SharedPreferences, hiện chỉ lưu flag `onboarding_completed` |
| **AppNavigator** | Static helper class cho navigation (`core/router/navigation_service.dart`) |
| **RoutePaths** | Abstract class chứa tất cả route path constants |
| **RouteGuards** | Class chứa `authGuard` và `guestGuard` redirect functions |
| **OnboardingState** | Immutable state object cho toàn bộ wizard onboarding |
| **DashboardEntity** | Aggregate entity tổng hợp toàn bộ health data của một user |
| **MealPlanModel** | Model cho một bữa ăn trong kế hoạch AI (map tới bảng `meal_plans`) |
| **NutritionPrompt** | Builder tạo prompt tiếng Việt gửi cho Gemini AI |
| **AIService** | Service gọi Gemini API và parse response thành `List<MealPlanModel>` |
| **SupabaseService** | Wrapper đơn giản expose `Supabase.instance.client` |
| **AuthService** | Static methods: signUp, signIn, signOut, currentUser |
| **SplashStatus** | Enum: `initial`, `loading`, `onboarded`, `onboardingRequired` |
| **goal_code** | Mã định danh mục tiêu (e.g. `lose_weight`) |
| **condition_code** | Mã định danh tình trạng sức khỏe (e.g. `insomnia`) |
| **canSave** | Computed property trên `OnboardingState` — validation để cho phép lưu |
| **guestGuard** | Route redirect: nếu đã login → không cho vào `/login` |
| **authGuard** | Route redirect: nếu chưa login → redirect về `/login` |

## Abbreviations

| Viết tắt | Ý nghĩa |
|---|---|
| DAO | Data Access Object |
| PK | Primary Key |
| FK | Foreign Key |
| DI | Dependency Injection |
| AI | Artificial Intelligence |
| RLS | Row Level Security (Supabase) |
