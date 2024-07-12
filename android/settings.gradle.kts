pluginManagement {
    repositories {
        google {
            content {
                includeGroupByRegex("com\\.android.*")
                includeGroupByRegex("com\\.google.*")
                includeGroupByRegex("androidx.*")
            }
        }
        mavenCentral()
        gradlePluginPortal()
    }
}
dependencyResolutionManagement {
    repositoriesMode.set(RepositoriesMode.FAIL_ON_PROJECT_REPOS)
    repositories {
        google()
        mavenCentral()
        maven {
            url = uri("https://maven.pkg.github.com/noctualabs/noctua-native-sdk")
            credentials {
                username = "jekjektuanakal"
                password = "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"
            }
        }
    }
}

rootProject.name = "noctua-android-sdk"
include(":sdk")
include(":app")
