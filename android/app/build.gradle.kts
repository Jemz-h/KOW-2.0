plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.testdrive"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.example.testdrive"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            // TODO: Add your own signing config for the release build.
            // Signing with the debug keys for now, so `flutter run --release` works.
            signingConfig = signingConfigs.getByName("debug")
        }
    }

    // ─── PACKAGE CLEANUP & MANIFEST MERGE ──────────────────────────────
    packagingOptions {
        // Exclude duplicate manifest and resource files
        exclude("META-INF/LICENSE")
        exclude("META-INF/LICENSE.txt")
        exclude("META-INF/NOTICE")
        exclude("META-INF/NOTICE.txt")
        exclude("META-INF/MANIFEST.MF")
        exclude("META-INF/android.arch_core_runtime.version")
        exclude("META-INF/androidx.**.version")
        exclude("META-INF/proguard/androidx-**.pro")
    }

    // ─── BUILD OUTPUT CLEANUP ─────────────────────────────────────────
    tasks.register("cleanBuildCache") {
        doLast {
            delete("build", ".gradle")
            println("✓ Build cache and temporary files cleaned")
        }
    }

    tasks.register("fullClean") {
        dependsOn("clean", "cleanBuildCache")
        doLast {
            delete("build", ".gradle", ".idea")
            println("✓ Full clean completed - ready for fresh build")
        }
    }
}

flutter {
    source = "../.."
}
