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

        setContent {
            MainScreen()
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
fun MainScreen() {
    var data by remember { mutableStateOf(listOf<Account>()) }

    Column(
        modifier = Modifier
            .fillMaxSize()
            .padding(16.dp),
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

        Spacer(modifier = Modifier.height(16.dp))

        Button(
            modifier = Modifier.fillMaxWidth(),
            onClick = {
                val uuid = UUID.randomUUID().toString()
                Noctua.trackPurchase("example.orderId.$uuid", 0.19, "USD")
                Log.d("MainActivity", "Purchase tracked")
            }) {
            Text("Track Purchase")
        }

        Spacer(modifier = Modifier.height(16.dp))

        Button(
            modifier = Modifier.fillMaxWidth(),
            onClick = {
                Noctua.trackCustomEvent("TestSendEvent", mutableMapOf("k1" to "v1", "k2" to "v2"))
                Log.d("MainActivity", "Custom event tracked")
            }) {
            Text("Track Custom Event")
        }

        Spacer(modifier = Modifier.height(16.dp))

        Button(
            modifier = Modifier.fillMaxWidth(),
            onClick = {
                Log.d("MainActivity", "loadAdjustMetadata")
            }) {
            Text("Get Adjust Metadata")
        }

        Spacer(modifier = Modifier.height(16.dp))

        Button(
            modifier = Modifier.fillMaxWidth(),
            onClick = {
                val randomAccount = Account(
                    userId = (1..3L).random(),
                    gameId = (1..3L).random(),
                    playerId = (1..1000L).random(),
                    accessToken = UUID.randomUUID().toString().substring(0, 8)
                )
                Noctua.putAccount(randomAccount)
                Log.d("MainActivity", "Random account saved: $randomAccount")
                data = Noctua.getAccounts()
            }) {
            Text("Save Random Account")
        }

        Spacer(modifier = Modifier.height(16.dp))

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
            }
        }
    }
}