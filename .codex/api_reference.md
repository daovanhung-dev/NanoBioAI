# API And Services Reference

## Environment variables

Do not copy `.env` contents into docs or commits. Use `.env.example` as public template.

Required by current boot/runtime:

```env
SUPABASE_URL=
SUPABASE_ANON_KEY=
GEMINI_API_KEY=
```

Optional/used by code but missing from `.env.example`:

```env
GEMINI_MODEL=
GEMINI_BASE_URL=
OPENAI_BASE_URL=
```

Notes:

- `GEMINI_MODEL` defaults differ:
  - `AIService`: fallback `gemini-1.5-flash`.
  - `AIChatService`: fallback `gemini-2.5-flash`.
- `GEMINI_BASE_URL` is only used in `services/ai/providers/ai_provider.dart`, a Dio provider not used by the primary Gemini service flow.
- `OPENAI_BASE_URL` is read by `core/network/dio_provider.dart`, but no current primary feature uses OpenAI API.

## Supabase

Initialization:

- `main.dart` calls `Supabase.initialize(url, anonKey)`.
- `services/supabase/supabase_service.dart` exposes `Supabase.instance.client`.

Auth service:

`services/supabase/auth_service.dart`

- `signUp(email, password)` -> `SupabaseService.client.auth.signUp`.
- `signIn(email, password)` -> `signInWithPassword`.
- `signOut()`.
- `currentUser`.

Auth feature datasource:

`features/auth/data/datasource/auth_remote_datasource.dart`

- `login(email, password)` -> `supabase.auth.signInWithPassword`.

Settings remote datasource:

`features/settings/data/datasources/settings_remote_datasource.dart`

- `updatePassword(newPassword)` -> `supabase.auth.updateUser(UserAttributes(password: newPassword))`.
- `signOut()` -> `supabase.auth.signOut()`.

Current cloud scope:

- README says Supabase is for auth only/minimal cloud dependency.
- Health profile, meal plan, and settings storage are local-first.

## Gemini meal plan service

File: `services/ai/ai_service.dart`

Provider:

```dart
final aiServiceProvider = Provider<AIService>((ref) { ... });
```

Constructor:

- Creates Dio with base URL `https://generativelanguage.googleapis.com/v1beta`, but actual generation uses `google_generative_ai.GenerativeModel`, not Dio.
- Reads `GEMINI_API_KEY`.
- Reads optional `GEMINI_MODEL`.
- Throws if API key missing.

Public method:

```dart
Future<List<MealPlanModel>> generateMealPlan({
  required HealthDataInterface healthData,
})
```

Behavior:

1. Retry up to 3 attempts.
2. Build prompt using `NutritionPrompt.generateMealPlan(healthData: healthData)`.
3. Ask Gemini to return only valid JSON array.
4. Timeout 10 minutes.
5. Clean response:
   - remove ```json
   - remove ```
   - trim
   - remove trailing commas before `]` and `}`
   - extract first `[` to last `]`
6. `jsonDecode`.
7. Map each item to `MealPlanModel.fromJson`.
8. On final failure return `[]`, not throw.

Important contract:

- Prompt says create 7-day meal plan, starting tomorrow.
- Schema expects meal records, 3 meals/day: breakfast/lunch/dinner.
- Schema includes `cooking_instructions` for 2-4 short preparation/cooking steps per meal.
- JSON keys use snake_case.
- Numeric values must be numbers, not strings.
- `DashboardController.genMealByWeeksToDB(requireComplete: true)` throws unless Gemini returns exactly 21 meal records.

## Gemini daily health task service

File: `services/ai/ai_service.dart`

Public method:

```dart
Future<List<DailyHealthTaskModel>> generateDailyHealthTasks({
  required DailyHealthProfileEntity profile,
  required DateTime startDate,
  int days = 7,
})
```

Behavior:

1. Retry up to 3 attempts.
2. Ask Gemini to return only valid JSON array.
3. Default contract is 7 days, starting from the provided `startDate`.
4. Each day must contain exactly one task per category: `water`, `body`, `mind`, `brain`.
5. `DailyHealthAiTaskNormalizer` validates exactly 28 tasks for default 7 days and normalizes stable ids:
   - `id = daily_${userId}_${date}_ai_${category}`
   - `task_code = ai_${category}`
   - `source = ai`
   - `current_value = 0`
   - `is_completed = false`
6. On final failure returns `[]`; onboarding completion then fails because datasource requires 28 tasks.

## Nutrition prompt

File: `services/ai/prompts/nutrition_prompt.dart`

Input abstraction:

`HealthDataInterface` from `core/interfaces/health_data_interface.dart`:

- fullName, gender, birthYear
- heightCm, weightKg, bmi
- goals, conditions, habits
- sleepQuality, activityLevel, waterPerDay
- allergy/treatment fields
- concernText

`DashboardEntity implements HealthDataInterface`.

Prompt currently includes:

- name
- bmi
- goals
- conditions
- habits
- sleep
- activity
- water
- concern
- `cooking_instructions` in schema.

## Gemini AI chat service

File: `services/ai/ai_chat_service.dart`

Provider:

```dart
final aiChatServiceProvider = Provider<AIChatService>((ref) => AIChatService());
```

Constructor:

- Reads `GEMINI_API_KEY`.
- Reads optional `GEMINI_MODEL`.
- Default model: `gemini-2.5-flash`.
- Sets system instruction in Vietnamese.
- Starts chat session.

Public methods:

- `Future<String> sendMessage(String message)`
- `void resetChat()`
- `Future<Stream<String>> sendMessageStream(String message)`

System behavior:

- Assistant name/role: BioAI Assistant.
- Friendly Vietnamese voice: calls user `bạn`, self `mình`.
- Short answers, 2-4 sentences.
- Health/nutrition/lifestyle focus.
- No medical diagnosis.
- Does not replace doctor.
- Encourage doctor for serious issues.

Error behavior:

- Empty response -> polite fallback.
- Exception -> technical issue fallback string.
- Stream exception -> fallback stream.

## AI chat repository/controller API

`AIChatRepository`:

- `sendMessage(String)` returns assistant message.
- `getChatHistory()` returns in-memory list.
- `clearHistory()`.

`AIChatController`:

- State: `messages`, `isLoading`, `error`.
- `sendMessage(String)`.
- `clearChat()`.
- `dismissError()`.

No persistence. History resets when provider/repository lifecycle resets or app restarts.

## Device services

### Biometric

File: `services/biometric/biometric_service.dart`

- Uses `local_auth`.
- `isAvailable()`: checks `canCheckBiometrics` and `isDeviceSupported`.
- `authenticate(reason)`: checks availability then calls `_auth.authenticate` with `stickyAuth: true`, `biometricOnly: true`.
- `getAvailableBiometrics()`.
- Throws `BiometricException(message, code)`.

Platform config expected:

- Android permissions: `USE_BIOMETRIC`, `USE_FINGERPRINT`.
- iOS `NSFaceIDUsageDescription`.

### Image picker

File: `services/image_picker/image_picker_service.dart`

- Uses `image_picker`, `permission_handler`, `path_provider`.
- Allowed formats: `png`, `jpg`, `jpeg`.
- Max file size: 5MB.
- `pickFromCamera()` returns null if permission denied/permanently denied.
- `pickFromGallery()` returns null if permission denied/permanently denied.
- `saveImageLocally()` copies into app documents `avatars/`.

## Network/Dio providers

`core/network/dio_provider.dart`:

- Base URL from `OPENAI_BASE_URL`.
- No obvious primary feature currently depends on it.

`services/ai/providers/ai_provider.dart`:

- Base URL from `GEMINI_BASE_URL`.
- No obvious primary feature currently depends on it.

Before using these, verify `.env.example` and actual `.env` include required values.
