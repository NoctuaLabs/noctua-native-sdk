package com.noctuagames.unrealsdktest

import com.noctuagames.sdk.NoctuaProxyTracker
import android.os.Bundle
import android.util.Log
import android.widget.Button
import androidx.activity.enableEdgeToEdge
import androidx.appcompat.app.AppCompatActivity
import androidx.core.view.ViewCompat
import androidx.core.view.WindowInsetsCompat

class MainActivity : AppCompatActivity() {
    private val tracker: NoctuaProxyTracker = NoctuaProxyTracker()

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        tracker.init(this)
        tracker.setAppVersion("1.2.3")
        enableEdgeToEdge()
        setContentView(R.layout.activity_main)
        ViewCompat.setOnApplyWindowInsetsListener(findViewById(R.id.main)) { v, insets ->
            val systemBars = insets.getInsets(WindowInsetsCompat.Type.systemBars())
            v.setPadding(systemBars.left, systemBars.top, systemBars.right, systemBars.bottom)
            insets
        }

        findViewById<Button>(R.id.btnTrackAdRevenue).setOnClickListener {
            tracker.trackAdRevenue("admob_sdk", 0.19, "USD")
                Log.d("NoctuaProxyTracker", "Ad revenue tracked")
        }
        findViewById<Button>(R.id.btnTrackPurchase).setOnClickListener {
            tracker.trackPurchase("example.orderId.1", 0.19, "USD")
            Log.d("NoctuaProxyTracker", "Purchase tracked")
        }
        findViewById<Button>(R.id.btnTrackCustomEvent).setOnClickListener {
            tracker.trackCustomEvent("sdkinit", mapOf("k1" to "v1", "k2" to "v2"))
            Log.d("NoctuaProxyTracker", "Custom event tracked")
        }

        findViewById<Button>(R.id.btnGetAdjustMetadata).setOnClickListener {
            tracker.loadAdjustMetadata()
            Log.d("NoctuaProxyTracker", "loadAdjustMetadata")
        }
    }

    override fun onResume() {
        super.onResume()
        tracker.onResume()
    }

    override fun onPause() {
        super.onPause()
        tracker.onPause()
    }
}