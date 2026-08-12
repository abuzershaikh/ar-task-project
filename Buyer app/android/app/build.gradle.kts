plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services")
}

android {
    namespace = "com.buy.taskpost.marketing_pro"
    compileSdk = 37
    ndkVersion = flutter.ndkVersion

    compileOptions {
        isCoreLibraryDesugaringEnabled = true
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        applicationId = "com.buy.taskpost.marketing_pro"
        minSdk = flutter.minSdkVersion
        targetSdk = 37
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        create("customRelease") {
            storeFile = file("buyer-key.jks")
            storePassword = "buyerpassword123"
            keyAlias = "buyerkey"
            keyPassword = "buyerpassword123"
        }
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("customRelease")
        }
        debug {
            signingConfig = signingConfigs.getByName("customRelease")
        }
    }
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.0.4")
}

flutter {
    source = "../.."
}

tasks.withType<com.android.build.gradle.internal.tasks.CheckAarMetadataTask> {
    enabled = false
}
