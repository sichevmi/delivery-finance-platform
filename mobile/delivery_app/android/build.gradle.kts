buildscript {
    repositories {
        maven {
            url = uri("http://dl.google.com/dl/android/maven2")
            isAllowInsecureProtocol = true
        }
        mavenCentral()
    }
    dependencies {
        classpath("com.android.tools.build:gradle:7.4.2")
        classpath("org.jetbrains.kotlin:kotlin-gradle-plugin:1.9.0")
    }
}

allprojects {
    repositories {
        maven {
            url = uri("http://dl.google.com/dl/android/maven2")
            isAllowInsecureProtocol = true
        }
        mavenCentral()
    }
}

tasks.register("clean", Delete::class) {
    delete(rootProject.buildDir)
}