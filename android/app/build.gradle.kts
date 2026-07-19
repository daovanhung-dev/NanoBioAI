import java.util.Properties

plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
}

val localEnvironment = Properties().apply {
    val envFile = rootProject.file("../.env")
    if (envFile.isFile) {
        envFile.inputStream().use(::load)
    }
}

fun buildConfigString(value: String): String =
    "\"${value.replace("\\", "\\\\").replace("\"", "\\\"")}\""

val debugGeminiApiKey =
    localEnvironment.getProperty("GEMINI_API_KEY")?.trim().orEmpty()

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

        // Production continues to receive this through --dart-define. The
        // Android debug build gets a local-only fallback below so an IDE gutter
        // run cannot silently omit Gemini configuration.
        buildConfigField("String", "GEMINI_API_KEY", buildConfigString(""))
    }

    buildFeatures {
        buildConfig = true
    }

    buildTypes {
        getByName("debug") {
            buildConfigField(
                "String",
                "GEMINI_API_KEY",
                buildConfigString(debugGeminiApiKey),
            )
        }
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
