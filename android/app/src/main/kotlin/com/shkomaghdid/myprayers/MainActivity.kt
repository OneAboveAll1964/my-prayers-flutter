package com.shkomaghdid.myprayers

import android.os.Bundle
import androidx.core.splashscreen.SplashScreen.Companion.installSplashScreen
import io.flutter.embedding.android.FlutterActivity

class MainActivity : FlutterActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        // Install the Android 12+ splash screen before super.onCreate() so the
        // system can transition smoothly from LaunchTheme.Splash into Flutter.
        installSplashScreen()
        super.onCreate(savedInstanceState)
    }
}
