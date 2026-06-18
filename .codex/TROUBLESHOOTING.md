# TROUBLESHOOTING — Common Issues & Solutions

Hướng dẫn giải quyết các vấn đề thường gặp trong dự án BioAI.

---

## 🔍 Quick Diagnosis

### Issue Categories

| Symptom | Category | Jump To |
|---------|----------|---------|
| App crashes on startup | [Initialization](#initialization-issues) |
| Data not showing | [Database](#database-issues) |
| AI generation fails | [AI Service](#ai-service-issues) |
| Notification không đổ chuông | [Notifications](#notification-issues) |
| Build fails | [Build](#build-issues) |
| Tests fail | [Testing](#testing-issues) |
| Architecture violation warning | [Architecture](#architecture-issues) |

---

## 🚀 Initialization Issues

### Issue: App crashes on startup with "Supabase not initialized"

**Symptoms**:
```
Error: Supabase.instance.client accessed before initialization
```

**Root Cause**: `main()` chưa await `Supabase.initialize()`

**Solution**:
```dart
// ✅ CORRECT
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL']!,
    anonKey: dotenv.env['SUPABASE_ANON_KEY']!,
  );
  runApp(const BioAIApp());
}
```

**Checklist**:
- [ ] `.env` file exists và có đủ keys
- [ ] `await` Supabase.initialize()
- [ ] Keys không rỗng

---

### Issue: "GEMINI_API_KEY not found"

**Symptoms**:
```
Exception: Không tìm thấy GEMINI_API_KEY
```

**Root Cause**: Thiếu GEMINI_API_KEY trong `.env`

**Solution**:
1. Kiểm tra `.env` file:
```env
GEMINI_API_KEY=your-api-key-here
```

2. Verify dotenv loaded:
```dart
await dotenv.load(fileName: ".env");
print(dotenv.env['GEMINI_API_KEY']); // Should not be null
```

3. Restart app (hot reload không reload .env)

---

### Issue: "Timezone not initialized"

**Symptoms**:
```
Error: Timezone database not found
Notification scheduled with wrong time
```

**Root Cause**: `NotificationBootstrap.initialize()` chưa được gọi

**Solution**:
```dart
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // ...
  await NotificationBootstrap.initialize(); // ← Must call this
  runApp(const BioAIApp());
}
```

---

## 💾 Database Issues

### Issue: "Database version mismatch"

**Symptoms**:
```
App crashes after pulling new code
Database schema errors
```

**Root Cause**: Database schema changed nhưng app version cũ

**Solution**:
1. Uninstall app hoàn toàn
2. Verify `database_version.dart` increased
3. Check migration created (`migrations/migration_vX.dart`)
4. Reinstall app

**For Development**:
```dart
// Delete database (DEV ONLY!)
await DatabaseService.deleteDatabaseFile();
```

---

### Issue: "No data showing in Dashboard"

**Symptoms**:
- Dashboard empty
- BMI shows 0
- Goals/conditions empty

**Root Cause Options**:
1. Onboarding chưa complete
2. Database query sai
3. Using mock data bị remove

**Solution**:

**Step 1**: Check onboarding completed
```dart
final completed = await AppPrefs.isOnboardingCompleted();
print('Onboarding completed: $completed');
```

**Step 2**: Check database has data
```dart
final db = await DatabaseService.database;
final users = await db.query('users');
print('Users count: ${users.length}');
```

**Step 3**: Check repository query
```dart
// In dashboard_repository_impl.dart
Future<DashboardEntity> fetchDashboard() async {
  final model = await datasource.fetchDashboardData();
  print('Fetched model: $model'); // Add debug log
  return model.toEntity();
}
```

**Step 4**: Verify NOT using mock
```bash
rg "mock|fake|sample" lib/features/dashboard
```

---

### Issue: "Duplicate entries in database"

**Symptoms**:
- Multiple meal plans for same day
- Duplicate tracking logs

**Root Cause**: Insert without checking existing

**Solution**:
```dart
// ✅ CORRECT - Use REPLACE
await db.insert(
  'table_name',
  data,
  conflictAlgorithm: ConflictAlgorithm.replace,
);

// Or check first
final existing = await db.query(
  'table_name',
  where: 'date = ? AND user_id = ?',
  whereArgs: [date, userId],
);
if (existing.isEmpty) {
  await db.insert('table_name', data);
}
```

---

## 🤖 AI Service Issues

### Issue: "AI generation timeout"

**Symptoms**:
```
TimeoutException: Future timeout after 10 minutes
```

**Root Cause**: Gemini API slow hoặc stuck

**Solution**:

**Option 1**: Retry với fallback
```dart
try {
  return await aiService.generateMealPlan(/* ... */);
} catch (e) {
  print('AI failed, using fallback: $e');
  // Fallback already implemented in AIService
}
```

**Option 2**: Check API key
```bash
curl "https://generativelanguage.googleapis.com/v1beta/models?key=YOUR_KEY"
```

**Option 3**: Check network
```dart
final connectivity = await Connectivity().checkConnectivity();
print('Network: $connectivity');
```

---

### Issue: "AI returns text without diacritics"

**Symptoms**:
```
Meal name: "Com ga" (should be "Cơm gà")
```

**Root Cause**: AI không tạo dấu hoặc normalizer không validate

**Solution**:

**Step 1**: Check normalizer validation
```dart
// In meal_plan_ai_normalizer.dart
void _validateVietnameseText(String text) {
  if (!_hasVietnameseDiacritics(text)) {
    throw FormatException('Text missing diacritics: $text');
  }
}
```

**Step 2**: Enhance prompt
```dart
final prompt = '''
CRITICAL: Tất cả text tiếng Việt PHẢI có dấu đầy đủ.
Ví dụ: "Cơm gà" (ĐÚNG), "Com ga" (SAI)
''';
```

**Step 3**: Fallback to catalog
```dart
// Catalog has correct Vietnamese text
final catalogItem = catalog.findByCode(mealCode);
return catalogItem.name; // Has diacritics
```

---

### Issue: "Expected 21 meals, got X"

**Symptoms**:
```
Exception: Expected 21 meals, got 18
Onboarding callback fails
```

**Root Cause**: AI không generate đủ hoặc validation sai

**Solution**:

**Option 1**: Check chunking logic
```dart
// Should generate: 2 + 2 + 3 = 7 days × 3 meals = 21
final chunks = _chunkPlan(7); // Returns [2,2,3]
```

**Option 2**: Fallback to catalog
```dart
// If AI fails, normalizer creates fallback meals
return normalizer.fallbackCodeItems(
  catalog: catalog,
  startDay: 1,
  days: 7, // Must generate full 7 days
);
```

**Option 3**: Don't use `requireComplete` for manual refresh
```dart
// For manual refresh button
await controller.genMealByWeeksToDB(
  requireComplete: false, // Allow partial generation
);
```

---

## 🔔 Notification Issues

### Issue: "Notifications không đổ chuông"

**Symptoms**:
- Notification scheduled nhưng không xuất hiện
- No sound/vibration

**Root Cause Options**:
1. Timezone không init
2. Permission not granted
3. Notification channel not setup

**Solution**:

**Step 1**: Check timezone init
```dart
// In main.dart
await NotificationBootstrap.initialize(); // Must call first
```

**Step 2**: Check permissions (Android 13+)
```dart
final granted = await Permission.notification.isGranted;
if (!granted) {
  await Permission.notification.request();
}
```

**Step 3**: Check notification scheduled
```dart
final pending = await flutterLocalNotificationsPlugin
    .pendingNotificationRequests();
print('Pending notifications: ${pending.length}');
```

**Step 4**: Test immediate notification
```dart
// Test notification shows immediately
await flutterLocalNotificationsPlugin.show(
  0,
  'Test',
  'If this shows, plugin works',
  notificationDetails,
);
```

---

### Issue: "Notification action không update DB"

**Symptoms**:
- Click "Đã làm" nhưng status vẫn pending
- Dashboard không refresh

**Root Cause**: Action handler không được register hoặc có bug

**Solution**:

**Step 1**: Verify action handler registered
```dart
// In notification_bootstrap.dart
await flutterLocalNotificationsPlugin.initialize(
  initializationSettings,
  onDidReceiveNotificationResponse: _handleNotificationResponse,
);
```

**Step 2**: Check action handler implementation
```dart
void _handleNotificationResponse(NotificationResponse response) async {
  final action = response.actionId; // 'complete' or 'skip'
  final payload = NotificationPayload.fromJson(response.payload!);
  
  // Update DB
  await scheduleItemsDao.updateStatus(
    payload.scheduleItemId!,
    action == 'complete' ? 'completed' : 'skipped',
  );
  
  print('Updated item ${payload.scheduleItemId} to $action');
}
```

**Step 3**: Check payload có scheduleItemId
```dart
final payload = NotificationPayload(
  type: 'schedule_reminder',
  scheduleItemId: item.id, // ← Must have this!
);
```

---

### Issue: "Notification ID conflicts"

**Symptoms**:
- Some notifications don't show
- Notifications replace each other

**Root Cause**: Duplicate notification IDs

**Solution**:
```dart
// ✅ CORRECT - Unique stable ID
int generateNotificationId(String scheduleItemId) {
  return scheduleItemId.hashCode.abs() % 2147483647;
}

// ❌ WRONG - Random ID
int generateNotificationId() {
  return Random().nextInt(999999); // Can duplicate!
}
```

---

## 🏗️ Build Issues

### Issue: "Build failed: AndroidManifest.xml error"

**Symptoms**:
```
error: attribute 'android:exported' not specified
```

**Root Cause**: Android 12+ requires explicit exported

**Solution**:
```xml
<!-- android/app/src/main/AndroidManifest.xml -->
<activity
    android:name=".MainActivity"
    android:exported="true"  <!-- Add this -->
    android:launchMode="singleTop">
```

---

### Issue: "Gradle build failed"

**Symptoms**:
```
Could not resolve all dependencies
```

**Solution**:
```bash
# Clean gradle cache
cd android
./gradlew clean
./gradlew build --refresh-dependencies

# If still fails, delete .gradle folder
rm -rf ~/.gradle/caches/
```

---

### Issue: "iOS build failed: CocoaPods"

**Symptoms**:
```
[!] CocoaPods could not find compatible versions
```

**Solution**:
```bash
cd ios
rm Podfile.lock
rm -rf Pods/
pod repo update
pod install
cd ..
flutter build ios
```

---

## 🧪 Testing Issues

### Issue: "Test calls real Gemini API"

**Symptoms**:
```
Test takes 30+ seconds
Real HTTP requests in test output
```

**Root Cause**: AIService not mocked

**Solution**:
```dart
// In test file
final mockAIService = MockAIService();
when(mockAIService.generateMealPlan(any))
    .thenAnswer((_) async => mockMealPlans);

// Inject mock
final container = ProviderContainer(
  overrides: [
    aiServiceProvider.overrideWithValue(mockAIService),
  ],
);
```

---

### Issue: "Test fails: 'Database is locked'"

**Symptoms**:
```
DatabaseException: database is locked
```

**Root Cause**: SQLite in-memory DB not properly isolated

**Solution**:
```dart
// Use sqflite_common_ffi for tests
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

setUpAll(() {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;
});

setUp(() async {
  // Each test gets fresh DB
  db = await databaseFactory.openDatabase(
    inMemoryDatabasePath,
    options: OpenDatabaseOptions(
      version: DatabaseVersion.currentVersion,
      onCreate: (db, version) async {
        await DatabaseService._createTables(db);
      },
    ),
  );
});

tearDown(() async {
  await db.close();
});
```

---

## 🏛️ Architecture Issues

### Issue: "Architecture violation detected"

**Symptoms**:
```
Presentation layer importing from Data layer
Cross-feature dependency found
```

**Root Cause**: Incorrect import

**Solution**:

**Example 1**: Presentation → Data (WRONG)
```dart
// ❌ BAD
import 'package:nano_app/features/dashboard/data/datasources/dashboard_local_datasource.dart';

// ✅ GOOD
import 'package:nano_app/features/dashboard/domain/repositories/dashboard_repository.dart';
```

**Example 2**: Feature → Feature (WRONG)
```dart
// ❌ BAD
import 'package:nano_app/features/dashboard/presentation/controllers/dashboard_controller.dart';

// ✅ GOOD - Use callback in main.dart
onboardingCompletionCallbackProvider.overrideWith((ref) {
  return () async {
    await ref.read(dashboardControllerProvider.notifier).generateMealPlan();
  };
});
```

**Check violations**:
```bash
# Find cross-feature imports
rg "import.*features/dashboard" lib/features/onboarding

# Find layer violations
rg "import.*data/datasources" lib/features/*/presentation/
```

---

## 🎨 UI Issues

### Issue: "Overflow error on small screens"

**Symptoms**:
```
RenderFlex overflowed by X pixels
```

**Solution**:
```dart
// ✅ Use Expanded/Flexible
Row(
  children: [
    Expanded(child: Text('Long text...')),
    Icon(Icons.arrow_forward),
  ],
)

// ✅ Use ListView for scrollable content
ListView(
  children: [...],
)

// ✅ Set maxLines for text
Text(
  'Long text...',
  maxLines: 2,
  overflow: TextOverflow.ellipsis,
)
```

---

### Issue: "Vietnamese text không có dấu"

**Symptoms**:
- "Suc khoe" instead of "Sức khỏe"
- "Dinh duong" instead of "Dinh dưỡng"

**Root Cause**: Copy-paste từ source không có dấu

**Solution**:
```dart
// ✅ CORRECT Vietnamese text
final title = 'Sức khỏe';
final subtitle = 'Dinh dưỡng cân bằng';

// ❌ WRONG
final title = 'Suc khoe'; // Missing diacritics!
```

**Validate**:
```bash
# Find text without diacritics
rg "Suc khoe|Dinh duong|Can nang" lib/
```

---

## 📱 Runtime Issues

### Issue: "Memory leak / App slow after time"

**Symptoms**:
- App becomes slower over time
- Memory usage increases

**Root Cause Options**:
1. Provider not disposed
2. Stream subscription not cancelled
3. Large list không virtualized

**Solution**:

**Check 1**: Use AutoDisposeNotifier
```dart
// ✅ GOOD - Auto-disposes
class MyController extends AutoDisposeNotifier<MyState> {
  @override
  MyState build() => MyState();
}
```

**Check 2**: Cancel subscriptions
```dart
StreamSubscription? _subscription;

@override
void dispose() {
  _subscription?.cancel();
  super.dispose();
}
```

**Check 3**: Use ListView.builder
```dart
// ✅ GOOD - Virtualized
ListView.builder(
  itemCount: items.length,
  itemBuilder: (context, index) => ItemWidget(items[index]),
)

// ❌ BAD - All widgets created at once
ListView(
  children: items.map((item) => ItemWidget(item)).toList(),
)
```

---

## 🔧 Development Issues

### Issue: "Hot reload không work"

**Symptoms**:
- Changes not reflected
- Need full restart every time

**Root Cause Options**:
1. Stateful widget state not updated
2. Provider không rebuild
3. Code error prevent hot reload

**Solution**:

**Option 1**: Use hot restart (R) instead of hot reload (r)

**Option 2**: Check console for hot reload errors
```
Hot reload was rejected: ...
```

**Option 3**: Rebuild provider
```dart
ref.invalidate(myProvider); // Force rebuild
```

---

### Issue: "Analyzer shows errors but app runs"

**Symptoms**:
```
flutter analyze shows errors
flutter run works fine
```

**Root Cause**: Generated code not up-to-date

**Solution**:
```bash
flutter pub get
flutter pub run build_runner build --delete-conflicting-outputs
flutter analyze
```

---

## 📚 Common Error Messages

| Error Message | Cause | Solution |
|---------------|-------|----------|
| `LateInitializationError: Field '...' has not been initialized` | Accessing field before init | Initialize in constructor or use `late final` |
| `StateError: Bad state: No element` | Query returns empty | Check `isEmpty` before accessing `.first` |
| `RangeError: Index out of range` | Accessing invalid index | Check `length` before accessing `[index]` |
| `FormatException: Unexpected character` | JSON parsing error | Validate JSON string before parse |
| `TimeoutException: Future timeout` | Operation too slow | Increase timeout or check network |
| `DatabaseException: no such table` | Table not created | Check onCreate or migration |

---

## 🆘 Still Stuck?

If issue persists after trying solutions:

1. **Check existing issues**: `docs/issues/bug_architecture.md`
2. **Run full check**: `.codex/tool/codex_check.sh --fix-format`
3. **Clean project**:
   ```bash
   flutter clean
   flutter pub get
   flutter run
   ```
4. **Delete and reinstall**:
   ```bash
   # Delete app from device
   # Uninstall completely
   flutter run
   ```
5. **Check logs**:
   ```bash
   flutter run --verbose
   adb logcat # Android
   ```

---

**Last Updated**: 2026-06-18  
**Maintained By**: Development Team
