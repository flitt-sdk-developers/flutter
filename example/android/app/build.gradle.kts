plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.flitt.flitt_mobile_example"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.flitt.flitt_mobile_example"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        // Follows the Flutter floor (flutter.minSdkVersion = 24 on Flutter
        // 3.44). The flitt_mobile plugin itself supports minSdkVersion 21;
        // the effective app floor is whatever the chosen Flutter requires.
        // play-services-wallet:19.4.0 (the native Google Pay button) supports
        // minSdk 21, so Google Pay is not what raises this floor.
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
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

flutter {
    source = "../.."
}

dependencies {
    // The flitt_mobile plugin declares play-services-wallet as compileOnly, so
    // the host app must provide it at runtime for the native Google Pay button.
    // Version matches the plugin's compileOnly dependency.
    implementation("com.google.android.gms:play-services-wallet:19.4.0")
}
