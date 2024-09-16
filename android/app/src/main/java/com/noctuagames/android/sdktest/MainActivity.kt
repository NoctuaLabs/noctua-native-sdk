package com.noctuagames.android.sdktest

import android.os.Bundle
import android.util.Log
import android.widget.Button
import androidx.activity.enableEdgeToEdge
import androidx.appcompat.app.AppCompatActivity
import androidx.core.view.ViewCompat
import androidx.core.view.WindowInsetsCompat
import com.noctuagames.sdk.Noctua
import java.util.UUID

class MainActivity : AppCompatActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        Noctua.init(this)
        enableEdgeToEdge()
        setContentView(R.layout.activity_main)
        ViewCompat.setOnApplyWindowInsetsListener(findViewById(R.id.main)) { v, insets ->
            val systemBars = insets.getInsets(WindowInsetsCompat.Type.systemBars())
            v.setPadding(systemBars.left, systemBars.top, systemBars.right, systemBars.bottom)
            insets
        }

        findViewById<Button>(R.id.btnTrackAdRevenue).setOnClickListener {
            Noctua.trackAdRevenue("admob_sdk", 0.19, "USD")
                Log.d("MainActivity", "Ad revenue tracked")
        }
        findViewById<Button>(R.id.btnTrackPurchase).setOnClickListener {
            val uuid = UUID.randomUUID().toString()
            Noctua.trackPurchase("example.orderId.$uuid", 0.19, "USD")
            Log.d("MainActivity", "Purchase tracked")
        }
        findViewById<Button>(R.id.btnTrackCustomEvent).setOnClickListener {
            Noctua.trackCustomEvent("TestSendEvent", mutableMapOf("k1" to "v1", "k2" to "v2"))
            Log.d("MainActivity", "Custom event tracked")
        }

        findViewById<Button>(R.id.btnGetAdjustMetadata).setOnClickListener {
            Log.d("MainActivity", "loadAdjustMetadata")
        }
    }

    override fun onResume() {
        super.onResume()
        Noctua.onResume()
    }

    override fun onPause() {
        super.onPause()
        Noctua.onPause()
    }
}