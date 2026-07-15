package com.linguaproapps.exam_trainer

import android.os.Bundle
import android.view.View
import android.view.ViewGroup
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.renderer.FlutterUiDisplayListener

class MainActivity : FlutterActivity() {
    private var startupOverlay: View? = null

    private val flutterUiListener = object : FlutterUiDisplayListener {
        override fun onFlutterUiDisplayed() {
            startupOverlay?.let { overlay ->
                (overlay.parent as? ViewGroup)?.removeView(overlay)
            }
            startupOverlay = null
            flutterEngine?.renderer?.removeIsDisplayingFlutterUiListener(this)
        }

        override fun onFlutterUiNoLongerDisplayed() = Unit
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        val renderer = flutterEngine?.renderer ?: return
        if (renderer.isDisplayingFlutterUi) return

        val decor = window.decorView as ViewGroup
        startupOverlay = layoutInflater.inflate(R.layout.startup_overlay, decor, false)
        decor.addView(
            startupOverlay,
            ViewGroup.LayoutParams(
                ViewGroup.LayoutParams.MATCH_PARENT,
                ViewGroup.LayoutParams.MATCH_PARENT,
            ),
        )
        renderer.addIsDisplayingFlutterUiListener(flutterUiListener)
    }

    override fun onDestroy() {
        flutterEngine?.renderer?.removeIsDisplayingFlutterUiListener(flutterUiListener)
        startupOverlay = null
        super.onDestroy()
    }
}
