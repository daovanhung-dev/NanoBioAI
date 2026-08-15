# NanoBioAI Gradle Fix Patch

Target repository: `daovanhung-dev/NanoBioAI`
Target branch inspected: `main`
Date: `2026-08-15`

## Root cause

Flutter runtime reports the project Android toolchain is below its supported minimums: Gradle `8.12.0`, AGP `8.9.1`, and Kotlin `2.1.0`.

## Functional change

```text
android/gradle/wrapper/gradle-wrapper.properties
  gradle-8.12-all.zip -> gradle-8.14-all.zip
android/settings.gradle.kts
  AGP 8.9.1 -> 8.11.1
  Kotlin 2.1.0 -> 2.2.20
```

`android.newDsl=false` and `android.builtInKotlin=false` remain unchanged.

## Files in this patch

- `android/gradle/wrapper/gradle-wrapper.properties`
- `android/settings.gradle.kts`
- `docs/fixbug/android-build-toolchain-compatibility/001-fixbug-android-build-toolchain-compatibility.md`
- `docs/worklog/2026-08-15/003-worklog-android-build-toolchain-compatibility-kotlin.md`
- `PATCH_MANIFEST.md`
- `README_APPLY.md`

## Validation status

- Patch content check: PASS
- ZIP integrity: PASS
- `flutter analyze --suggestions`: PASS
- `flutter build apk --debug --no-pub`: PASS
- `flutter run`: PASS on device `220333QPG`
