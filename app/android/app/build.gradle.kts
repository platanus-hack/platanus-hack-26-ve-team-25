import java.util.Properties

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// La llave de subida a Google Play vive en android/key.properties, que no va al repo.
// Sin ese archivo, el release se firma con la llave de debug: sirve para instalar a mano,
// pero Play lo rechaza.
val llave = Properties().apply {
    val archivo = rootProject.file("key.properties")
    if (archivo.exists()) archivo.inputStream().use { load(it) }
}

android {
    namespace = "ve.equipo25.casa"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "ve.equipo25.casa"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        // Uses the version code from pubspec.yaml. When using split APKs, 1000 * ABI_VERSION
        // is added automatically by Flutter. (https://developer.android.com/studio/build/configure-apk-splits#configure-APK-versions)
        // You can force using the value of versionCode by specifying the `-P force-version-code-ignoring-abi=true`
        // flag during build.
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    // Solo teléfonos ARM, que son todos los Android reales: sin las copias x86 de Vosk, JNA y
    // TFLite (solo sirven en emuladores) el APK pesa menos y por depuración inalámbrica se instala
    // sin cortarse. abiFilters no sirve aquí: el plugin de Flutter lo pisa.
    packaging {
        jniLibs {
            excludes += listOf("lib/x86/**", "lib/x86_64/**")
        }
    }

    signingConfigs {
        if (llave.isNotEmpty()) {
            create("subida") {
                keyAlias = llave.getProperty("keyAlias")
                keyPassword = llave.getProperty("keyPassword")
                storeFile = rootProject.file(llave.getProperty("storeFile"))
                storePassword = llave.getProperty("storePassword")
            }
        }
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.findByName("subida") ?: signingConfigs.getByName("debug")
            // Vosk usa JNA, que no aguanta que R8 le cambie los nombres (proguard-rules.pro).
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro",
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
    // Vosk: reconoce sin internet las frases de ayuda sobre el mismo audio del oído (Apache 2.0).
    implementation("com.alphacephei:vosk-android:0.3.47")
    implementation("net.java.dev.jna:jna:5.13.0@aar")
}
