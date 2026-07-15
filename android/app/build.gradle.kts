import java.util.Properties
import java.io.FileInputStream

plugins {
    id("com.android.application")
    id("com.google.gms.google-services")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// key.properties and the upload keystore are intentionally gitignored. Debug
// tasks do not need them, but every release task fails closed below if the real
// signing material is absent or incomplete.
val keystorePropertiesFile = rootProject.file("key.properties")
val keystoreProperties = Properties()
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}
val releaseSigningKeys = listOf("keyAlias", "keyPassword", "storeFile", "storePassword")
val missingReleaseSigningKeys = releaseSigningKeys.filter {
    keystoreProperties.getProperty(it).isNullOrBlank()
}
val releaseStoreFile = keystoreProperties.getProperty("storeFile")
    ?.takeIf { it.isNotBlank() }
    ?.let(rootProject::file)
val releaseSigningError = when {
    !keystorePropertiesFile.exists() ->
        "Missing android/key.properties. A release build requires the real upload keystore."
    missingReleaseSigningKeys.isNotEmpty() ->
        "android/key.properties is missing: ${missingReleaseSigningKeys.joinToString()}."
    releaseStoreFile?.isFile != true ->
        "The upload keystore configured by android/key.properties does not exist: ${releaseStoreFile?.path}."
    else -> null
}
val hasReleaseSigning = releaseSigningError == null

gradle.taskGraph.whenReady {
    val requestedReleaseTask = allTasks.any {
        it.project == project && it.name.contains("Release", ignoreCase = true)
    }
    if (requestedReleaseTask && releaseSigningError != null) {
        throw GradleException(
            "$releaseSigningError Release signing never falls back to the debug key. " +
                "Use a debug build for local testing.",
        )
    }
}

android {
    namespace = "com.linguaproapps.exam_trainer"
    // audioplayers pulls in flutter_plugin_android_lifecycle, which requires
    // compileSdk 36+ — flutter.compileSdkVersion (34) is too old for it.
    compileSdk = 36
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.linguaproapps.exam_trainer"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    flavorDimensions += "environment"
    productFlavors {
        create("production") {
            dimension = "environment"
        }
        create("integration") {
            dimension = "environment"
            applicationIdSuffix = ".integration"
            versionNameSuffix = "-integration"
        }
    }

    signingConfigs {
        if (hasReleaseSigning) {
            create("release") {
                keyAlias = keystoreProperties.getProperty("keyAlias")
                keyPassword = keystoreProperties.getProperty("keyPassword")
                storeFile = releaseStoreFile
                storePassword = keystoreProperties.getProperty("storePassword")
            }
        }
    }

    buildTypes {
        release {
            if (hasReleaseSigning) {
                signingConfig = signingConfigs.getByName("release")
            }
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
        }
    }
}

// The repository has a real Firebase config only for the production flavor.
// The integration journey uses local fakes and must not invent or commit a
// second Firebase app configuration merely to build its isolated test APK.
tasks.configureEach {
    if (name == "processIntegrationDebugGoogleServices") {
        enabled = false
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
