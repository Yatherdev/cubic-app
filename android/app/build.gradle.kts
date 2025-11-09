plugins {
    // مكون Android الأساسي
    id("com.android.application")

    // مكون Kotlin الصحيح باسم الجديد
    id("org.jetbrains.kotlin.android")

    // لازم ييجي بعد Android و Kotlin
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.calc_wood"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = "27.0.12077973"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        // Application ID (اسم الحزمة)
        applicationId = "com.example.calc_wood"

        // إعدادات الـ SDKs
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion

        // معلومات الإصدار
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            // حالياً بنستخدم debug signing علشان الاختبار
            signingConfig = signingConfigs.getByName("debug")
            // لو هتجهز لتوقيع التطبيق لاحقاً، غيرها هنا
        }
    }
}

flutter {
    source = "../.."
}
