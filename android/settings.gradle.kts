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
        maven(url="https://gitlab.com/api/v4/projects/59492250/packages/maven")
        gradlePluginPortal()
    }
}
dependencyResolutionManagement {
    repositoriesMode.set(RepositoriesMode.FAIL_ON_PROJECT_REPOS)
    repositories {
        google()
        maven(url="https://gitlab.com/api/v4/projects/59492250/packages/maven")
        mavenCentral()
    }
}

rootProject.name = "noctua-android-sdk"
include(":sdk")
include(":app")
