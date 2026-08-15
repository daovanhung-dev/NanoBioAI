Commit de xuat: fix(android): nang Android toolchain cho Flutter

# Fixbug - Android build toolchain compatibility

## Van de

`flutter run` dung o Flutter Gradle plugin do bo Android toolchain cua du an thap hon muc Flutter hien tai yeu cau. Sau khi nang Gradle va AGP, Flutter tiep tuc bao Kotlin `2.1.0` thap hon muc toi thieu `2.2.20`.

Thong bao runtime cua Flutter yeu cau Gradle toi thieu `8.14.0`, AGP toi thieu `8.11.1`, va Kotlin toi thieu `2.2.20`.

## Root cause

`android/settings.gradle.kts` khai bao AGP va Kotlin cu:

```kotlin
id("com.android.application") version "8.9.1" apply false
id("org.jetbrains.kotlin.android") version "2.1.0" apply false
```

Trong khi Flutter SDK dang duoc su dung kiem tra dependency va tu choi cac phien ban thap hon muc tuong ung.

## Ban va

1. Nang Gradle Wrapper:
   - `8.12` -> `8.14`
2. Nang AGP:
   - `8.9.1` -> `8.11.1`
3. Nang Kotlin Android plugin:
   - `2.1.0` -> `2.2.20`
4. Giu `android.newDsl=false` va `android.builtInKotlin=false`.
5. Khong chuyen sang AGP 9 / Gradle 9 trong ban va nay.
6. Khong sua Dart, UI, SQLite, Supabase hoac business logic.

## Files

- `android/settings.gradle.kts`
- `android/gradle/wrapper/gradle-wrapper.properties`

## Validation

- Static check Gradle wrapper = `8.14`: PASS
- Static check AGP = `8.11.1`: PASS
- Static check Kotlin = `2.2.20`: PASS
- `flutter analyze --suggestions`: PASS
- `flutter build apk --debug --no-pub`: PASS
- `flutter run`: PASS - app da mo tren thiet bi `220333QPG` va `MainActivity` dang resumed.

## Kiem tra tren may Windows cua du an

```powershell
java -version
flutter doctor -v
flutter clean
flutter pub get
cd android
.\gradlew.bat --version
cd ..
flutter analyze --suggestions
flutter build apk --debug
flutter run
```

Moi truong da xac nhan JDK 17. Cac canh bao ve viec Flutter sap bo ho tro Gradle 8.14, AGP 8.11.1 va Kotlin 2.2.20 khong chan build hien tai; co the xu ly trong dot nang cap toolchain tiep theo.
