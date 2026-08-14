import java.io.File

plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
}

fun cleanRuntimeValue(value: String?): String? {
    var cleaned = value?.trim()?.removePrefix("\uFEFF") ?: return null
    if (cleaned.length >= 2) {
        val first = cleaned.first()
        val last = cleaned.last()
        if ((first == '"' && last == '"') || (first == '\'' && last == '\'')) {
            cleaned = cleaned.substring(1, cleaned.length - 1).trim()
        }
    }
    return cleaned.takeIf { it.isNotEmpty() }
}

fun readDotEnv(file: File): Map<String, String> {
    if (!file.isFile) return emptyMap()

    val values = mutableMapOf<String, String>()
    file.forEachLine { rawLine ->
        var line = rawLine.removePrefix("\uFEFF").trim()
        if (line.isEmpty() || line.startsWith("#")) return@forEachLine

        if (line.startsWith("export ", ignoreCase = true)) {
            line = line.substring("export ".length).trimStart()
        }

        val separatorIndex = line.indexOf('=')
        if (separatorIndex <= 0) return@forEachLine

        val key = line.substring(0, separatorIndex).removePrefix("\uFEFF").trim()
        val value = cleanRuntimeValue(line.substring(separatorIndex + 1))
        if (key.isNotEmpty() && value != null) {
            values[key] = value
        }
    }
    return values
}

fun buildConfigString(value: String): String =
    "\"${value.replace("\\", "\\\\").replace("\"", "\\\"")}\""

val localEnvironment = readDotEnv(rootProject.file("../.env"))

// AppEnv prefers --dart-define at runtime. This native value is the safe
// Android fallback for plain flutter run/build invocations where Dart defines
// were not supplied. Resolution supports CI/Gradle properties and the local
// untracked .env file without bundling that file as a Flutter asset.
val nativeGeminiApiKey =
    cleanRuntimeValue(providers.gradleProperty("GEMINI_API_KEY").orNull)
        ?: cleanRuntimeValue(providers.environmentVariable("GEMINI_API_KEY").orNull)
        ?: cleanRuntimeValue(localEnvironment["GEMINI_API_KEY"])
        ?: ""

android {
    namespace = "com.example.nano_app"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11

        // Required by flutter_local_notifications
        isCoreLibraryDesugaringEnabled = true
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        applicationId = "com.example.nano_app"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName

        // Keep the private Gemini configuration available to every Android
        // build type (debug/profile/release). AppEnv still gives Dart defines
        // precedence, so canonical run scripts continue to work unchanged.
        buildConfigField(
            "String",
            "GEMINI_API_KEY",
            buildConfigString(nativeGeminiApiKey),
        )
    }

    buildFeatures {
        buildConfig = true
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

dependencies {
    // Required for Java 8+ APIs used by flutter_local_notifications
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}

flutter {
    source = "../.."
}
