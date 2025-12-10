plugins {
  
  id("com.google.gms.google-services") version "4.4.4" apply false

}

// Read Mapbox token from gradle.properties or local.properties
// The plugin looks for SDK_REGISTRY_TOKEN (not MAPBOX_DOWNLOADS_TOKEN)
val mapboxToken: String? = project.findProperty("SDK_REGISTRY_TOKEN") as String?
    ?: project.findProperty("MAPBOX_DOWNLOADS_TOKEN") as String?
    ?: run {
        val localProperties = java.util.Properties()
        val localPropertiesFile = rootProject.file("local.properties")
        if (localPropertiesFile.exists()) {
            localPropertiesFile.inputStream().use { localProperties.load(it) }
            localProperties.getProperty("SDK_REGISTRY_TOKEN")
                ?: localProperties.getProperty("MAPBOX_DOWNLOADS_TOKEN")
        } else {
            null
        }
    }

// Make token available to all subprojects
if (mapboxToken != null) {
    allprojects {
        ext.set("SDK_REGISTRY_TOKEN", mapboxToken)
    }
}

allprojects {
    repositories {
        google()
        mavenCentral()
        
        // Mapbox repository with authentication
        maven {
            url = uri("https://api.mapbox.com/downloads/v2/releases/maven")
            authentication {
                create<BasicAuthentication>("basic")
            }
            credentials {
                username = "mapbox"
                password = project.findProperty("SDK_REGISTRY_TOKEN") as String?
                    ?: project.findProperty("MAPBOX_DOWNLOADS_TOKEN") as String?
                    ?: System.getProperty("SDK_REGISTRY_TOKEN")
                    ?: System.getProperty("MAPBOX_DOWNLOADS_TOKEN")
                    ?: run {
                        val localProperties = java.util.Properties()
                        val localPropertiesFile = rootProject.file("local.properties")
                        if (localPropertiesFile.exists()) {
                            localPropertiesFile.inputStream().use { localProperties.load(it) }
                            localProperties.getProperty("SDK_REGISTRY_TOKEN")
                                ?: localProperties.getProperty("MAPBOX_DOWNLOADS_TOKEN")
                        } else {
                            ""
                        }
                    } ?: ""
            }
        }
    }
}

val newBuildDir: Directory =
    rootProject.layout.buildDirectory
        .dir("../../build")
        .get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}
subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
