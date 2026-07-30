pluginManagement {
    val flutterSdkPath =
        run {
            val properties = java.util.Properties()
            file("local.properties").inputStream().use { properties.load(it) }
            val flutterSdkPath = properties.getProperty("flutter.sdk")
            require(flutterSdkPath != null) { "flutter.sdk not set in local.properties" }
            flutterSdkPath
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
    id("com.android.application") version "9.0.1" apply false
    id("org.jetbrains.kotlin.android") version "2.3.20" apply false
}

include(":app")

gradle.beforeProject {
    if (this != rootProject) {
        plugins.withId("com.android.library") {
            extensions.findByType(com.android.build.gradle.LibraryExtension::class.java)?.apply {
                if (namespace == null) {
                    val manifestFile = file("src/main/AndroidManifest.xml")
                    val pkgMatch = if (manifestFile.exists()) Regex("""package="([^"]+)"""").find(manifestFile.readText()) else null
                    namespace = pkgMatch?.groupValues?.get(1) ?: "com.flutter.plugins.${this@beforeProject.name.replace("-", "_")}"
                }
            }
        }
        afterEvaluate {
            extensions.findByType(com.android.build.gradle.LibraryExtension::class.java)?.apply {
                compileSdk = 36
            }
        }
    }
}
