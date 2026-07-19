buildscript {
    repositories {
        google()
        mavenCentral()
        maven {
            url = uri("http://dl.google.com/dl/android/maven2")
            isAllowInsecureProtocol = true
        }
    }
    dependencies {
        classpath("com.android.tools.build:gradle:7.4.2")
        classpath("org.jetbrains.kotlin:kotlin-gradle-plugin:1.9.0")
    }
}

allprojects {
    repositories {
        google()
        mavenCentral()
        maven {
            url = uri("http://dl.google.com/dl/android/maven2")
            isAllowInsecureProtocol = true
        }
    }
}

tasks.register("clean", Delete::class) {
    delete(rootProject.buildDir)
}