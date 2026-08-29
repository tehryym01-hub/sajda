plugins {
    id("com.android.application")
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.sajda.dataplus"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = "28.2.13676358"

    compileOptions {
        isCoreLibraryDesugaringEnabled = true
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        applicationId = "com.sajda.dataplus"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        ndk {
            abiFilters += listOf("arm64-v8a", "armeabi-v7a")
        }
    }

    signingConfigs {
        val keyProps = mutableMapOf<String, String>()
        val keyFile = rootProject.file("key.properties")
        if (keyFile.exists()) {
            keyFile.readLines().forEach { line ->
                val trimmed = line.trim()
                if (trimmed.isNotEmpty() && !trimmed.startsWith("#")) {
                    val parts = trimmed.split("=", limit = 2)
                    if (parts.size == 2) {
                        keyProps[parts[0].trim()] = parts[1].trim()
                    }
                }
            }
        }
        create("release") {
            val storeFilePath = keyProps["storeFile"]
            if (!storeFilePath.isNullOrBlank()) {
                storeFile = file(storeFilePath)
            }
            storePassword = keyProps["storePassword"]
            keyAlias = keyProps["keyAlias"]
            keyPassword = keyProps["keyPassword"]
        }
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("release")
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
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
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}


