import java.util.Properties

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")

    // Add the dependency for the Google services Gradle plugin
    id("com.google.gms.google-services") version "4.4.3" apply false
}

dependencies {
  // Import the Firebase BoM
  implementation(platform("com.google.firebase:firebase-bom:34.0.0"))

  // TODO: Add the dependencies for Firebase products you want to use
  // When using the BoM, don't specify versions in Firebase dependencies
  implementation("com.google.firebase:firebase-analytics")

  implementation("com.google.firebase:firebase-messaging")

  // Add the dependencies for any other desired Firebase products
  // https://firebase.google.com/docs/android/setup#available-libraries
}

val keystoreProperties = Properties()
val keystoreFile = rootProject.file("key.properties") //android

if (keystoreFile.exists()) {
    keystoreFile.inputStream().use {
        keystoreProperties.load(it)
    }
}

android {
    namespace = "com.example.oficinaescolar_colaboradores"
    compileSdk = 36
    ndkVersion = "27.0.12077973"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.edgargutierrez.oficinaescolar_colaboradores"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = 36
        versionCode = flutter.versionCode
        versionName = flutter.versionName

        // This block is different from the one you use to link Gradle
        // to your CMake or ndk-build script.
        externalNativeBuild {
            // For ndk-build, instead use the ndkBuild block.
            cmake {
                // Passes optional arguments to CMake.
                arguments += listOf("-DANDROID_SUPPORT_FLEXIBLE_PAGE_SIZES=ON", "-Wl,-z,max-page-size=16384")
            }
        }
    }

    signingConfigs {
        // Define your release signing configuration
        create("release") {
            // Correct way to specify the keystore file:
            // Use file() to resolve the path relative to the project root
            storeFile = file("oficinaescolar_colaboradores.jks") //android/app

            //if ( keystoreProperties.isNotEmpty()) {
                val keyAliassss = keystoreProperties.getProperty("keyAlias") ?: ""
                val keyPassworddd = keystoreProperties.getProperty("keyPassword") ?: ""
                //throw GradleException("Build terminado 1:${keyAliassss} ${keyPassworddd}")
            //}

            storePassword = keyPassworddd //System.getenv("keyPassword") //?: "" // Use environment variable for security
            keyAlias = keyAliassss//System.getenv("keyAlias")// ?: "" // Use environment variable for security
            keyPassword = keyPassworddd //System.getenv("keyPassword")// ?: "" // Use environment variable for security

            //throw GradleException("No se encontro las variables Configuracion en el archivo")

            // IMPORTANT: For production, NEVER hardcode passwords like "your_store_password".
            // Use environment variables, Gradle properties, or a more secure method.
            // The System.getenv() approach shown above is a better practice.
            // You would set these environment variables in your CI/CD pipeline or local environment.
            // Example for local development (NOT for production):
            // storePassword = "my_super_secret_store_password"
            // keyAlias = "my_app_alias"
            // keyPassword = "my_super_secret_key_password"
        }
    }

    buildTypes {
        release {
            // These are properties of the ApplicationBuildType
            isMinifyEnabled = true // Enable code shrinking and obfuscation for release builds
            // Enables resource shrinking.
            isShrinkResources = true
            //proguardFiles(getDefaultProguardFile("proguard-android-optimize.txt"), "proguard-rules.pro")
            signingConfig = signingConfigs.getByName("release") // Assuming you have a "release" signingConfig
            // ... other configurations specific to your release build
        }

        // You will typically also have a 'debug' build type
        debug {
            // ... debug specific configurations
        }
    }
}

flutter {
    source = "../.."
}

// Necesario para habilitar Google Services (Firebase)
apply(plugin = "com.google.gms.google-services")