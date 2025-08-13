import com.vanniktech.maven.publish.AndroidSingleVariantLibrary
import com.vanniktech.maven.publish.SonatypeHost

plugins {
    alias(libs.plugins.android.library)
    alias(libs.plugins.jetbrains.kotlin.android)
    `maven-publish`
    id("com.vanniktech.maven.publish") version "0.29.0"
}

android {
    namespace = "com.noctuagames.sdk"
    compileSdk = 34

    defaultConfig {
        aarMetadata {
            minCompileSdk = 32
        }
        minSdk = 22
        compileSdk = 34
        testInstrumentationRunner = "androidx.test.runner.AndroidJUnitRunner"
        consumerProguardFiles("consumer-rules.pro")
    }
    buildTypes {
        debug {
            isMinifyEnabled = false
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
        }
        release {
            isMinifyEnabled = false
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
        }
    }
    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }
    kotlinOptions {
        jvmTarget = "11"
    }
    buildFeatures {
        compose = false
    }
}

mavenPublishing {
    coordinates(
        groupId = "com.noctuagames.sdk",
        artifactId = "noctua-android-sdk",
        version = File("version.txt").readText().trim(),
    )
    configure(
        AndroidSingleVariantLibrary(
            variant = "release",
            sourcesJar = true,
            publishJavadocJar = true
        )
    )
    signAllPublications()
    publishToMavenCentral(SonatypeHost.CENTRAL_PORTAL)
    pom {
        name.set("Noctua Android SDK")
        description.set("SDK to integrate with Noctua Games")
        inceptionYear.set("2024")
        url.set("https://github.com/NoctuaLabs/noctua-native-sdk/")
        licenses {
            license {
                name.set("The Apache License, Version 2.0")
                url.set("http://www.apache.org/licenses/LICENSE-2.0.txt")
                distribution.set("http://www.apache.org/licenses/LICENSE-2.0.txt")
            }
        }
        developers {
            developer {
                id.set("noctualabs")
                name.set("Noctua Labs")
                url.set("https://github.com/NoctuaLabs/")
            }
        }
        scm {
            url.set("https://github.com/NoctuaLabs/noctua-native-sdk/")
            connection.set("scm:git:git://github.com/noctualabs/noctua-native-sdk.git")
            developerConnection.set("scm:git:ssh://git@github.com/noctualabs/noctua-native-sdk.git")
        }
    }
}

publishing {
    repositories {
        maven {
            name = "GitLab"
            url = uri("https://gitlab.com/api/v4/projects/59492250/packages/maven")
            credentials(HttpHeaderCredentials::class) {
                name = "Job-Token"
                value = System.getenv("CI_JOB_TOKEN")
            }
            authentication {
                create<HttpHeaderAuthentication>("header")
            }
        }
    }
}

dependencies {
    implementation(libs.noctua.internal.native)
    implementation(libs.play.services.appset)
    implementation(libs.play.services.ads.identifier)
    implementation(libs.androidx.core.ktx)
    implementation(libs.installreferrer)
    implementation(libs.adjust.android)
    implementation(libs.gson)
    implementation(libs.okhttp)
    implementation(libs.kotlinx.coroutines.core)
    implementation(libs.kotlinx.coroutines.android)
    implementation(libs.firebase.analytics)
    implementation(libs.firebase.crashlytics)
    implementation(libs.firebase.crashlytics.ndk)
    implementation(libs.firebase.messaging)
    implementation(libs.facebook.core)
    testImplementation(libs.junit)
}