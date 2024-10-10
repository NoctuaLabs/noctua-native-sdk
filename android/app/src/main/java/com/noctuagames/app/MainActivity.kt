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

        val games = listOf(
            1L to "GameOne",
            2L to "GameTwo",
        )

        val bundles = listOf(
            1L to "com.noctua.android.gameone",
            2L to "com.noctua.android.gametwo",
        )

        val users = listOf(
            "PlayerOne" to "playerone@example.com",
            "GamerGal" to "gamergal@example.com",
            "NoctuaFan" to "noctuafan@example.com",
        )

        val credentials = listOf(
            "google",
            "facebook",
            "discord",
            "noctua",
        )

        val platforms = listOf(
            1L to "Windows",
            2L to "Android",
            3L to "iOS"
        )

        val players = listOf(
            1L to "CharOne",
            2L to "CharTwo",
            3L to "CharThree",
            4L to "CharFour",
            5L to "CharFive",
            6L to "CharSix",
        )

        Button(
            modifier = Modifier.fillMaxWidth(),
            onClick = {
                val game = games.random()
                val userId = (1L..users.size).random()
                val platform = platforms.random()
                val player = players.random()

                val randomAccount = Account(
                    userId = userId,
                    gameId = game.first,
                    playerId = player.first,
                    userIsGuest = (0..1).random() == 1,
                    userNickname = users[userId.toInt() - 1].first,
                    userEmail = users[userId.toInt() - 1].second,
                    credentialId = (1..1000L).random(),
                    credentialProvider = credentials.random(),
                    credentialDisplayText = UUID.randomUUID().toString().substring(0, 8),
                    gameName = game.second,
                    gamePlatformId = platform.first,
                    gamePlatformName = platform.second,
                    gamePlatformBundleId = bundles[game.first.toInt() - 1].second,
                    playerAccessToken = UUID.randomUUID().toString().substring(0, 8),
                    playerUsername = UUID.randomUUID().toString().substring(0, 8)
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