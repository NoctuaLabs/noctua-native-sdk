package com.noctuagames.app

import android.content.Context
import android.os.Bundle
import android.util.Log
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.material3.Button
import androidx.compose.material3.Label
import androidx.compose.material3.Text
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp
import com.noctuagames.sdk.Account
import com.noctuagames.sdk.Noctua
import java.time.DayOfWeek
import java.time.Instant
import java.util.Date
import java.util.UUID

class MainActivity : ComponentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        Noctua.init(this, listOf("com.noctuagames.android.unitysdktest", "com.noctuagames.android.secondexamplegame"))
        val offset = when (this.packageName) {
            "com.noctuagames.android.unitysdktest" -> 1000
            "com.noctuagames.android.secondexamplegame" -> 2000
            else -> 0
        }
        setContent {
            MainScreen(offset, this.packageName)
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

@Composable
fun MainScreen(offset: Int, packageName: String) {
    var data by remember { mutableStateOf(Noctua.getAccounts()) }

    Column(
        modifier = Modifier
            .fillMaxSize()
            .padding(8.dp),
        horizontalAlignment = Alignment.CenterHorizontally
    ) {

        Text(text = "Package Name: $packageName")

        Button(
            modifier = Modifier.fillMaxWidth(),
            onClick = {
                Noctua.trackAdRevenue("admob_sdk", 0.19, "USD")
                Log.d("MainActivity", "Ad revenue tracked")
            }) {
            Text("Track Ad Revenue")
        }

        Button(
            modifier = Modifier.fillMaxWidth(),
            onClick = {
                val uuid = UUID.randomUUID().toString()
                Noctua.trackPurchase("example.orderId.$uuid", 0.19, "USD")
                Log.d("MainActivity", "Purchase tracked")
            }) {
            Text("Track Purchase")
        }

        Button(
            modifier = Modifier.fillMaxWidth(),
            onClick = {
                Noctua.trackCustomEvent(
                    "TestSendEvent",
                    mutableMapOf(
                        "k1" to 0.123f,
                        "k2" to 0.123,
                        "k3" to 123,
                        "k4" to 123L,
                        "k5" to true,
                        "k6" to "string",
                        "k7" to Date.from(Instant.now()),
                        "k8" to DayOfWeek.SATURDAY,
                        "suffix" to 123,
                    )
                )
                Log.d("MainActivity", "Custom event tracked")
            }) {
            Text("Track Custom Event")
        }

        Button(
            modifier = Modifier.fillMaxWidth(),
            onClick = {
                Log.d("MainActivity", "loadAdjustMetadata")
            }) {
            Text("Get Adjust Metadata")
        }

        Button(
            modifier = Modifier.fillMaxWidth(),
            onClick = {
                data = Noctua.getAccounts()
            }) {
            Text("Load accounts")
        }

        Button(
            modifier = Modifier.fillMaxWidth(),
            onClick = {
                val randomAccount = Account(
                    userId = (1L..3).random(),
                    gameId = (1L..3).random() + offset,
                    rawData = UUID.randomUUID().toString()
                )
                Noctua.putAccount(randomAccount)
                Log.d("MainActivity", "Random account saved: $randomAccount")
                data = Noctua.getAccounts()
            }) {
            Text("Save Random Account")
        }

        Button(
            modifier = Modifier.fillMaxWidth(),
            onClick = {
                val accounts = Noctua.getAccounts()
                if (accounts.isNotEmpty()) {
                    val accountToDelete = accounts
                        .filter { it.gameId in offset..(offset + 999) }
                        .randomOrNull()
                    accountToDelete?.let { Noctua.deleteAccount(it) }

                    Log.d("MainActivity", "Deleted account: $accountToDelete")
                    data = Noctua.getAccounts()
                } else {
                    Log.d("MainActivity", "No accounts to delete")
                }
            }) {
            Text("Delete Random Account")
        }

        Button(
            modifier = Modifier.fillMaxWidth(),
            onClick = {
                throw RuntimeException("Test Crash")
            }) {
            Text("Crash Me")
        }

        Spacer(modifier = Modifier.height(16.dp))

        LazyColumn {
            items(data) { account ->
                Text(text = account.toString())
                Spacer(modifier = Modifier.height(4.dp))
            }
        }
    }
}