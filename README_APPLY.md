# Apply patch

Giai nen ZIP vao root du an `nano_app` / `NanoBioAI` va cho phep ghi de file trung ten.

Sau do chay:

```powershell
flutter clean
flutter pub get
flutter analyze --suggestions
flutter build apk --debug
flutter run
```

Bo thay doi Android gom:

```text
android/gradle/wrapper/gradle-wrapper.properties
android/settings.gradle.kts
```

`settings.gradle.kts` nang AGP len `8.11.1` va Kotlin len `2.2.20`; Gradle Wrapper nang len `8.14` de dap ung Flutter toolchain.
