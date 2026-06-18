# TEST_WORKFLOW

## Lệnh bắt buộc

Quick check:

```bash
flutter pub get
dart format --set-exit-if-changed .
flutter analyze
flutter test
```

Full check khi đổi Android/native/notification/build config:

```bash
flutter doctor -v
flutter pub get
dart format --set-exit-if-changed .
flutter analyze
flutter test
flutter build apk --debug
```

## Ưu tiên loại test

1. Unit test: parser, validator, calculator, mapper, payload, id generator.
2. Provider/controller test: onboarding/dashboard/schedule flow.
3. DAO/datasource test: SQLite in-memory hoặc fake DB có kiểm soát.
4. Widget test: widget độc lập, không bootstrap app thật nếu không cần.
5. Integration test: chỉ khi có emulator/máy thật.

## Cấm trong unit/widget test

- Không gọi API thật: Gemini/OpenAI/Supabase/network.
- Không phụ thuộc giờ thật nếu có thể inject clock.
- Không phụ thuộc notification plugin thật.
- Không dùng dữ liệu random không kiểm soát.

## Regression test

Nếu sửa bug từng xảy ra, thêm test tái hiện bug trước rồi sửa để test pass.
