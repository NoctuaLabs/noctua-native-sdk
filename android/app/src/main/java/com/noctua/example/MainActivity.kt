package com.noctua.example

import com.noctuagg.sdk.NoctuaProxyTracker
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
        enableEdgeToEdge()
        setContentView(R.layout.activity_main)
        ViewCompat.setOnApplyWindowInsetsListener(findViewById(R.id.main)) { v, insets ->
            val systemBars = insets.getInsets(WindowInsetsCompat.Type.systemBars())
            v.setPadding(systemBars.left, systemBars.top, systemBars.right, systemBars.bottom)
            insets
        }

        findViewById<Button>(R.id.btnTrackAdRevenue).setOnClickListener {
            tracker.trackAdRevenue("admob_sdk", 0.19, "USD")
                Log.d("NoctuaProxyTracker", "Ad revenue tracked: $it")
        }
        findViewById<Button>(R.id.btnTrackPurchase).setOnClickListener {
            tracker.trackPurchase("example.orderId.1", 0.19, "USD")
            Log.d("NoctuaProxyTracker", "Purchase tracked")
        }
    }
}