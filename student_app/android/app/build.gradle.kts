plugins {
    id("com.android.application")
    // MainActivity is Kotlin, and the kotlin { } block below configures the
    // compiler, so this module has to apply the Kotlin Android plugin. Without
    // it the Android build fails on an unresolved `kotlin` extension.
    id("org.jetbrains.kotlin.android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.examverse.student_app"
    compileSdk = 36
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.examverse.student_app"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = 36
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

// The integration_test dev dependency pulls espresso 3.2.0, whose core and
// idling-resource artifacts both declare the namespace androidx.test.espresso.
// AGP 9 requires every library to have a unique namespace, so the debug build
// fails at manifest merge. Later espresso releases separate the two, so the
// whole group is pinned forward.
configurations.all {
    resolutionStrategy.eachDependency {
        if (requested.group == "androidx.test.espresso") {
            useVersion("3.6.1")
        }
    }
}

flutter {
    source = "../.."
}
