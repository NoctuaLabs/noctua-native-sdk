package com.noctuagames.app

import android.os.Bundle
import android.util.Log
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.material3.Button
import androidx.compose.material3.Text
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp
import com.noctuagames.sdk.Account
import com.noctuagames.sdk.Noctua
import java.util.UUID

class MainActivity : ComponentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        Noctua.init(this)
        val offset = if (this.packageName.endsWith("1")) 1000 else 2000

        setContent {
            MainScreen(offset)
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
fun MainScreen(offset: Int) {
    var data by remember { mutableStateOf(Noctua.getAccounts()) }

    Column(
        modifier = Modifier
            .fillMaxSize()
            .padding(8.dp),
        horizontalAlignment = Alignment.CenterHorizontally
    ) {
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
                Noctua.trackCustomEvent("TestSendEvent", mutableMapOf("k1" to "v1", "k2" to "v2"))
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
                    val accountToDelete = accounts.random()
                    Noctua.deleteAccount(accountToDelete)
                    Log.d("MainActivity", "Deleted account: $accountToDelete")
                    data = Noctua.getAccounts()
                } else {
                    Log.d("MainActivity", "No accounts to delete")
                }
            }) {
            Text("Delete Random Account")
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