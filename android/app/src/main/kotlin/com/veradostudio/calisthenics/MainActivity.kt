package com.veradostudio.calisthenics

import android.graphics.Color
import android.os.Build
import android.os.Bundle
import androidx.core.view.WindowCompat
import io.flutter.embedding.android.FlutterActivity

// Some OEM skins (e.g. Vivo FuntouchOS) keep painting an opaque system
// navigation bar regardless of the theme's transparent navigationBarColor,
// so the bar colors and contrast-enforcement are also cleared here directly
// on the Window, not just declared in the theme.
class MainActivity : FlutterActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        WindowCompat.setDecorFitsSystemWindows(window, false)
        window.statusBarColor = Color.TRANSPARENT
        window.navigationBarColor = Color.TRANSPARENT
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            window.isNavigationBarContrastEnforced = false
            window.isStatusBarContrastEnforced = false
        }
    }
}
