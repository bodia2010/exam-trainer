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
            flutterEngine?.renderer?.removeIsDisplayingFlutterUiListener(this)
            val overlay = startupOverlay ?: return
            // The renderer callback can precede SurfaceView composition by a
            // frame on some devices. Fading the native layer only after that
            // callback keeps the already-painted Flutter loader underneath and
            // prevents a white flash between the two rendering surfaces.
            overlay.animate()
                .alpha(0f)
                .setDuration(180L)
                .withEndAction {
                    (overlay.parent as? ViewGroup)?.removeView(overlay)
                    if (startupOverlay === overlay) startupOverlay = null
                }
                .start()
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
        startupOverlay?.animate()?.cancel()
        startupOverlay = null
        super.onDestroy()
    }
}
