/*
 * android/app/build.gradle.kts
 * Works with Flutter + Firebase (Kotlin DSL)
 */

plugins {
    // Android & Kotlin plugins
    id("com.android.application")
    id("org.jetbrains.kotlin.android")

    // Flutter plugin (must come AFTER the Android/Kotlin plugins)
    id("dev.flutter.flutter-gradle-plugin")

    // Google Services (Firebase) plugin
    id("com.google.gms.google-services")
}

android {
    namespace = "app.overloadpro.overloadproapp"

    compileSdk = flutter.compileSdkVersion      // resolved from Flutter
    ndkVersion  = flutter.ndkVersion

    defaultConfig {
        compileSdk = 35
        ndkVersion = "27.0.12077973" // Add or update this line
        applicationId = "app.overloadpro.overloadproapp"
        minSdk        = 27
        targetSdk     = flutter.targetSdkVersion
        versionCode   = flutter.versionCode
        versionName   = flutter.versionName
    }

    // Java 11 / Kotlin 11
    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }
    kotlinOptions { jvmTarget = JavaVersion.VERSION_11.toString() }

    buildTypes {
        // Keep release simple for now
        getByName("release") {
            isMinifyEnabled     = false
            isShrinkResources   = false
            signingConfig       = signingConfigs.getByName("debug")
        }
    }
}

flutter {
    // path back to <project root>/lib
    source = "../.."
}

dependencies {
    // --- Firebase BoM (version catalog) ---
    implementation(platform("com.google.firebase:firebase-bom:33.16.0"))

    // --- Firebase products you need ---
    implementation("com.google.firebase:firebase-analytics") // basic analytics
    implementation("com.google.firebase:firebase-auth")      // remove if not using Auth
    // implementation("com.google.firebase:firebase-firestore") // add more as needed
}

// MUST be at bottom when using Kotlin DSL
apply(plugin = "com.google.gms.google-services")
