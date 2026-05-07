import org.jetbrains.kotlin.gradle.dsl.JvmTarget

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.blissfruitz.app"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = "28.2.13676358"

    lint {
        checkReleaseBuilds = false
        abortOnError = false
    }

    compileOptions {
        isCoreLibraryDesugaringEnabled = true
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }


    defaultConfig {
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        multiDexEnabled = true
        
        ndk {
            // Fix for "failed to strip debug symbols" on newer AGP/NDK versions
            debugSymbolLevel = "none"
            abiFilters += listOf("armeabi-v7a", "arm64-v8a", "x86_64")
        }
    }

    flavorDimensions += "app"
    productFlavors {
        create("customer") {
            dimension = "app"
            applicationId = "com.blissfruitz.customer"
            versionNameSuffix = "-customer"
            resValue("string", "app_name", "BlissFruitz")
        }
        create("rider") {
            dimension = "app"
            applicationId = "com.blissfruitz.rider"
            versionNameSuffix = "-rider"
            resValue("string", "app_name", "BF Rider")
        }
    }

    buildTypes {
        release {
            // TODO: Add your own signing config for the release build.
            // Signing with the debug keys for now, so `flutter run --release` works.
            signingConfig = signingConfigs.getByName("debug")
            
            // Enable R8 / ProGuard for size optimization
            // DISABLED TEMPORARILY TO FIX CRASHES
            isMinifyEnabled = false
            isShrinkResources = false
            
            // Apply ProGuard rules to prevent crashes with native plugins like Razorpay
            proguardFiles(getDefaultProguardFile("proguard-android.txt"), "proguard-rules.pro")
        }
    }

    packaging {
        resources {
            excludes += "/META-INF/{AL2.0,LGPL2.1}"
        }
    }
}

kotlin {
    compilerOptions {
        jvmTarget.set(JvmTarget.JVM_17)
    }
}

flutter {
    source = "../.."
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}
