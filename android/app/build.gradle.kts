// Only the release pipeline may opt into preview debug signing.
// Production builds require a real upload keystore and separate credentials.
val veldigoKeyFile = System.getenv("VELDIGO_ANDROID_KEYSTORE_PATH")
val veldigoStorePassword = System.getenv("VELDIGO_ANDROID_STORE_PASSWORD")
val veldigoKeyAlias = System.getenv("VELDIGO_ANDROID_KEY_ALIAS")
val veldigoKeyPassword = System.getenv("VELDIGO_ANDROID_KEY_PASSWORD")
val veldigoHasUploadKey = listOf(
    veldigoKeyFile, veldigoStorePassword, veldigoKeyAlias, veldigoKeyPassword
).all { !it.isNullOrBlank() }

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.brendigo.veldigo"
    // Google Play 2026 requires Android 16 (API 36) for new releases.\n    compileSdk = maxOf(flutter.compileSdkVersion, 36)
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.brendigo.veldigo"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = 24
        targetSdk = 36
        // Uses the version code from pubspec.yaml. When using split APKs, 1000 * ABI_VERSION
        // is added automatically by Flutter. (https://developer.android.com/studio/build/configure-apk-splits#configure-APK-versions)
        // You can force using the value of versionCode by specifying the `-P force-version-code-ignoring-abi=true`
        // flag during build.
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        if (veldigoHasUploadKey) {
            create("veldigoUpload") {
                storeFile = file(veldigoKeyFile!!)
                storePassword = veldigoStorePassword
                keyAlias = veldigoKeyAlias
                keyPassword = veldigoKeyPassword
            }
        }
    }

    buildTypes {
        release {
            // Preview artifacts may use the debug key ONLY when explicitly
            // authorized in CI. Never silently debug-sign a production AAB.
            signingConfig = when {
                veldigoHasUploadKey -> signingConfigs.getByName("veldigoUpload")
                System.getenv("VELDIGO_ALLOW_DEBUG_SIGNED_PREVIEW") == "true" ->
                    signingConfigs.getByName("debug")
                else -> null // Unsigned; never implicitly use the debug key.
            }
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
