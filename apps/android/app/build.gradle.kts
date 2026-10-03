plugins {
    id("com.android.application")
    id("org.jetbrains.kotlin.android")
    id("org.jetbrains.kotlin.plugin.compose")
}
android {
    namespace = "com.qiyanzhixing.quicksleep"
    compileSdk = 35
    defaultConfig {
        applicationId = "com.qiyanzhixing.quicksleep"
        minSdk = 26
        targetSdk = 35
        versionCode = 1
        versionName = "1.0.0"
    }
    buildFeatures { compose = true }
    compileOptions { sourceCompatibility = JavaVersion.VERSION_17; targetCompatibility = JavaVersion.VERSION_17 }
    kotlinOptions { jvmTarget = "17" }
    androidResources { noCompress += "wav" }
    bundle { language { enableSplit = false } }
    lint { abortOnError = true }
}
tasks.withType<Test>().configureEach {
    systemProperty("sessionVectors", rootProject.file("../../shared/session-vectors.json").absolutePath)
}
val prepareAssets by tasks.registering(Exec::class) {
    workingDir = rootProject.file("../..")
    commandLine(providers.gradleProperty("pythonExecutable").getOrElse("python"), "scripts/prepare_assets.py")
}
tasks.named("preBuild") { dependsOn(prepareAssets) }
dependencies {
    implementation(platform("androidx.compose:compose-bom:2025.04.01"))
    implementation("androidx.activity:activity-compose:1.10.1")
    implementation("androidx.compose.material3:material3")
    implementation("androidx.compose.ui:ui")
    implementation("androidx.compose.foundation:foundation")
    implementation("androidx.lifecycle:lifecycle-runtime-compose:2.9.0")
    implementation("androidx.media3:media3-exoplayer:1.6.1")
    implementation("androidx.media3:media3-session:1.6.1")
    implementation("org.jetbrains.kotlinx:kotlinx-coroutines-android:1.10.2")
    testImplementation("junit:junit:4.13.2")
    testImplementation("org.json:json:20250107")
}
