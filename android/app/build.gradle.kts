import java.util.Properties
import java.io.FileInputStream

plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
}

val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")

if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

android {
    namespace = "com.nanobioai.app"
    compileSdk = 36
    ndkVersion = flutter.ndkVersion

    signingConfigs {
       create("release") {
           keyAlias = keystoreProperties["keyAlias"] as String
           keyPassword = keystoreProperties["keyPassword"] as String
           storeFile = keystoreProperties["storeFile"]?.let { file(it) }
           storePassword = keystoreProperties["storePassword"] as String
       }
   }		


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
        applicationId = "com.nanobioai.app"
        minSdk = flutter.minSdkVersion
        targetSdk = 36
        versionCode = flutter.versionCode
        versionName = flutter.versionName

    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("release")
        }
    }
}

dependencies {
    // Required for Java 8+ APIs used by flutter_local_notifications
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
    implementation("com.github.espressif:esp-idf-provisioning-android:lib-2.4.4")
    implementation("org.greenrobot:eventbus:3.3.1")
}

flutter {
    source = "../.."
}

// Flutter currently includes the dev-only integration_test plugin in the generated Android
// registrant, but excludes its Android library from the release compile classpath. Remove only
// that registration while compiling release Java; keep the generated file intact for debug and
// integration-test builds.
val generatedPluginRegistrant = file("src/main/java/io/flutter/plugins/GeneratedPluginRegistrant.java")
var originalReleasePluginRegistrant: String? = null
val restoreReleasePluginRegistrant = tasks.register("restoreReleasePluginRegistrant") {
    doLast {
        originalReleasePluginRegistrant?.let { source ->
            if (generatedPluginRegistrant.exists()) {
                generatedPluginRegistrant.writeText(source)
            }
        }
    }
}

tasks.configureEach {
    if (name == "compileReleaseJavaWithJavac") {
        doFirst {
            if (!generatedPluginRegistrant.exists()) {
                throw GradleException("Flutter's generated Android plugin registrant was not found.")
            }
            val source = generatedPluginRegistrant.readText()
            val integrationTestRegistration = """    try {
      flutterEngine.getPlugins().add(new dev.flutter.plugins.integration_test.IntegrationTestPlugin());
    } catch (Exception e) {
      Log.e(TAG, "Error registering plugin integration_test, dev.flutter.plugins.integration_test.IntegrationTestPlugin", e);
    }
"""
            val registrationIndex = source.indexOf(integrationTestRegistration)
            if (registrationIndex >= 0) {
                if (source.indexOf(integrationTestRegistration, registrationIndex + 1) >= 0) {
                    throw GradleException("Found duplicate integration_test registrations in the Android plugin registrant.")
                }
                originalReleasePluginRegistrant = source
                generatedPluginRegistrant.writeText(source.replace(integrationTestRegistration, ""))
            }
        }
        finalizedBy(restoreReleasePluginRegistrant)
    }
}
