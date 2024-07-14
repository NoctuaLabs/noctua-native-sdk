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
        maven(url="https://gitlab.com/api/v4/projects/59492250/packages/maven")
    }
}
dependencyResolutionManagement {
    repositoriesMode.set(RepositoriesMode.FAIL_ON_PROJECT_REPOS)
    repositories {
        google()
        mavenCentral()
        maven(url="https://gitlab.com/api/v4/projects/59492250/packages/maven")
    }
}

rootProject.name = "noctua-android-sdk"
include(":sdk")
include(":app")
