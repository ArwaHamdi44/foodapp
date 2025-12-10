pluginManagement {
    val flutterSdkPath =
        run {
            val properties = java.util.Properties()
            file("local.properties").inputStream().use { properties.load(it) }
            val flutterSdkPath = properties.getProperty("flutter.sdk")
            require(flutterSdkPath != null) { "flutter.sdk not set in local.properties" }
            flutterSdkPath
        }

    // Read Mapbox token early and make it available
    // The plugin looks for SDK_REGISTRY_TOKEN (not MAPBOX_DOWNLOADS_TOKEN)
    val localProperties = java.util.Properties()
    val localPropertiesFile = file("local.properties")
    if (localPropertiesFile.exists()) {
        localPropertiesFile.inputStream().use { localProperties.load(it) }
        val mapboxToken = localProperties.getProperty("SDK_REGISTRY_TOKEN")
            ?: localProperties.getProperty("MAPBOX_DOWNLOADS_TOKEN")
        if (mapboxToken != null) {
            System.setProperty("SDK_REGISTRY_TOKEN", mapboxToken)
        }
    }
    
    // Also try reading from gradle.properties
    val gradleProperties = java.util.Properties()
    val gradlePropertiesFile = file("gradle.properties")
    if (gradlePropertiesFile.exists()) {
        gradlePropertiesFile.inputStream().use { gradleProperties.load(it) }
        val mapboxToken = gradleProperties.getProperty("SDK_REGISTRY_TOKEN")
            ?: gradleProperties.getProperty("MAPBOX_DOWNLOADS_TOKEN")
        if (mapboxToken != null && System.getProperty("SDK_REGISTRY_TOKEN") == null) {
            System.setProperty("SDK_REGISTRY_TOKEN", mapboxToken)
        }
    }

    includeBuild("$flutterSdkPath/packages/flutter_tools/gradle")

    repositories {
        google()
        mavenCentral()
        gradlePluginPortal()
    }
}

plugins {
    id("dev.flutter.flutter-plugin-loader") version "1.0.0"
    id("com.android.application") version "8.9.1" apply false
    id("org.jetbrains.kotlin.android") version "2.1.0" apply false
}

include(":app")
