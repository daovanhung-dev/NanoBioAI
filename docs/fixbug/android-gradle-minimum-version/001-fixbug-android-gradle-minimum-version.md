Commit de xuat: fix(android): nang Gradle wrapper len 8.14

# Fixbug - Android Gradle minimum version

## Hien tuong

Khi chay `flutter run`, Flutter dung o buoc apply `dev.flutter.flutter-gradle-plugin` va bao Gradle cua du an dang la 8.12.0, thap hon muc toi thieu 8.14.0 ma Flutter hien tai yeu cau.

## Nguyen nhan goc

`android/gradle/wrapper/gradle-wrapper.properties` tren branch `main` dang tro toi:

```properties
distributionUrl=https\://services.gradle.org/distributions/gradle-8.12-all.zip
```

Trong khi log runtime cua task yeu cau Gradle `>= 8.14.0`.

Cac thanh phan Android lien quan da duoc doi chieu:

- Android Gradle Plugin: `8.9.1` trong `android/settings.gradle.kts`.
- Kotlin Android plugin: `2.1.0` trong `android/settings.gradle.kts`.
- `android.newDsl=false` da co trong `android/gradle.properties`.
- `android.builtInKotlin=false` da co trong `android/gradle.properties`.

Do do khong can nang AGP/Kotlin trong ban va nay.

## Ban va

Doi Gradle Wrapper:

```diff
-distributionUrl=https\://services.gradle.org/distributions/gradle-8.12-all.zip
+distributionUrl=https\://services.gradle.org/distributions/gradle-8.14-all.zip
```

## Pham vi anh huong

- Chi thay doi Android build toolchain.
- Khong thay doi Dart/Flutter business logic.
- Khong thay doi SQLite, Supabase, authentication, AI, Nabi hoac UI.

## Validation

Da kiem tra tinh nhat quan cua patch va cau truc ZIP.

Khong the chay `flutter analyze --suggestions` hoac `flutter build apk --debug` trong moi truong tao patch vi Flutter/Dart SDK khong duoc cai dat. Can chay hai lenh nay tren may dev sau khi ap dung patch.

## Lenh xac minh tren may dev

```powershell
flutter clean
flutter pub get
flutter analyze --suggestions
flutter build apk --debug
flutter run
```
