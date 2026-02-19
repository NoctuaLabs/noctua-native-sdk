package com.noctuagames.app

import android.os.Bundle
import android.util.Log
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.activity.enableEdgeToEdge
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.AccountCircle
import androidx.compose.material.icons.filled.Fingerprint
import androidx.compose.material.icons.filled.Menu
import androidx.compose.material.icons.filled.Refresh
import androidx.compose.material.icons.filled.Science
import androidx.compose.material.icons.filled.Settings
import androidx.compose.material.icons.filled.Share
import androidx.compose.material.icons.filled.ShoppingCart
import androidx.compose.material.icons.filled.SwapVert
import androidx.compose.material.icons.filled.Warning
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.LargeTopAppBar
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Scaffold
import androidx.compose.material3.SnackbarDuration
import androidx.compose.material3.SnackbarHost
import androidx.compose.material3.SnackbarHostState
import androidx.compose.material3.Text
import androidx.compose.material3.TopAppBarDefaults
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateListOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.input.nestedscroll.nestedScroll
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import com.noctuagames.app.ui.components.AccountSection
import com.noctuagames.app.ui.components.AnalyticsSection
import com.noctuagames.app.ui.components.AttributionSection
import com.noctuagames.app.ui.components.BillingSection
import com.noctuagames.app.ui.components.ExperimentsSection
import com.noctuagames.app.ui.components.FirebaseIdsSection
import com.noctuagames.app.ui.components.LifecycleSection
import com.noctuagames.app.ui.components.RemoteConfigSection
import com.noctuagames.app.ui.components.SectionCard
import com.noctuagames.app.ui.components.SessionInfoCard
import com.noctuagames.app.ui.components.TestingSection
import com.noctuagames.app.ui.theme.NoctuaandroidsdkTheme
import com.noctuagames.sdk.Noctua
import com.noctuagames.sdk.models.Account
import com.noctuagames.sdk.models.BillingErrorCode
import com.noctuagames.sdk.models.ConsumableType
import com.noctuagames.sdk.models.NoctuaProductDetails
import com.noctuagames.sdk.models.NoctuaBillingConfig
import com.noctuagames.sdk.models.NoctuaProductPurchaseStatus
import com.noctuagames.sdk.models.ProductType
import com.noctuagames.sdk.models.NoctuaPurchaseResult
import kotlinx.coroutines.launch
import java.util.UUID

class MainActivity : ComponentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        enableEdgeToEdge()

        Noctua.init(
            context = this,
            publishedApps = listOf("com.noctuagames.android.unitysdktest", "com.noctuagames.android.secondexamplegame"),
            billingConfig = NoctuaBillingConfig(
                enablePendingPurchases = true,
                enableAutoServiceReconnection = true,
                verifyPurchasesOnServer = false
            )
        )

        Noctua.setSessionTag("homepage")
        Noctua.setSessionExtraParams(mutableMapOf("noctua" to "test"))
        Noctua.setExperiment("control_group")

        val offset = when (this.packageName) {
            "com.noctuagames.android.unitysdktest" -> 1000
            "com.noctuagames.android.secondexamplegame" -> 2000
            else -> 0
        }

        setContent {
            NoctuaandroidsdkTheme {
                MainScreen(
                    offset = offset,
                    packageName = this.packageName,
                    activity = this
                )
            }
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

    override fun onDestroy() {
        super.onDestroy()
        Noctua.onDestroy()
    }
}

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun MainScreen(offset: Int, packageName: String, activity: MainActivity) {
    val snackbarHostState = remember { SnackbarHostState() }
    val scope = rememberCoroutineScope()
    val scrollBehavior = TopAppBarDefaults.exitUntilCollapsedScrollBehavior()

    // State for accounts and events
    val accounts = remember { mutableStateListOf<Account>() }
    var events by remember { mutableStateOf<List<String>>(emptyList()) }

    // State for per-row event storage
    var batchResult by remember { mutableStateOf("") }
    var eventCount by remember { mutableStateOf(0) }

    // State for Firebase IDs
    var installationId by remember { mutableStateOf<String?>(null) }
    var analyticsSessionId by remember { mutableStateOf<String?>(null) }

    // State for Remote Config
    var remoteConfigResult by remember { mutableStateOf<Pair<String, String>?>(null) }

    // State for Experiments
    var currentExperiment by remember { mutableStateOf<String?>(Noctua.getExperiment()) }
    var generalExperimentResult by remember { mutableStateOf<Pair<String, String>?>(null) }

    // State for Session
    var currentSessionTag by remember { mutableStateOf(Noctua.getSessionTag()) }

    // State for Billing
    val billingProducts = remember { mutableStateListOf<NoctuaProductDetails>() }
    val billingPurchases = remember { mutableStateListOf<NoctuaPurchaseResult>() }
    var billingError by remember { mutableStateOf<Pair<BillingErrorCode, String>?>(null) }
    var productPurchaseStatus by remember { mutableStateOf<NoctuaProductPurchaseStatus?>(null) }

    // Default product SKUs
    val defaultProducts = remember {
        listOf(
            "noctua.sub.1" to ConsumableType.SUBSCRIPTION,
            "noctua.sub.2" to ConsumableType.SUBSCRIPTION,
            "noctua.sub.3" to ConsumableType.SUBSCRIPTION,
            "noctua.test.android.pack1" to ConsumableType.CONSUMABLE,
            "noctua.ashechoes.pack6" to ConsumableType.CONSUMABLE,
            "noctua.test.android.pack2" to ConsumableType.NON_CONSUMABLE
        )
    }

    // Helper function for showing snackbars
    fun showSnackbar(message: String) {
        scope.launch {
            snackbarHostState.showSnackbar(
                message = message,
                duration = SnackbarDuration.Short
            )
        }
    }

    // Initialize Billing on first launch
    LaunchedEffect(Unit) {
        accounts.addAll(Noctua.getAccounts())
        
        // Initialize billing with callbacks
        Noctua.initializeBilling(
            onPurchaseCompleted = { result ->
                billingPurchases.add(result)
                showSnackbar("Purchase completed: ${result.productId}")
                Log.d("MainActivity", "Purchase completed: $result")
            },
            onPurchaseUpdated = { result ->
                // Update existing purchase if found
                val index = billingPurchases.indexOfFirst { it.purchaseToken == result.purchaseToken }
                if (index >= 0) {
                    billingPurchases[index] = result
                } else {
                    billingPurchases.add(result)
                }
                showSnackbar("Purchase updated: ${result.productId} - ${result.purchaseState}")
                Log.d("MainActivity", "Purchase updated: $result")
            },
            onProductDetailsLoaded = { products ->
                billingProducts.clear()
                billingProducts.addAll(products)
                showSnackbar("Loaded ${products.size} products")
                Log.d("MainActivity", "Products loaded: ${products.size}")
            },
            onQueryPurchasesCompleted = { purchases ->
                billingPurchases.clear()
                billingPurchases.addAll(purchases)
                showSnackbar("Found ${purchases.size} purchases")
                Log.d("MainActivity", "Purchases loaded: ${purchases.size}")
            },
            onRestorePurchasesCompleted = { purchases ->
                billingPurchases.clear()
                billingPurchases.addAll(purchases)
                showSnackbar("Restored ${purchases.size} purchases")
                Log.d("MainActivity", "Purchases restored: ${purchases.size}")
            },
            onProductPurchaseStatusResult = { status ->
                productPurchaseStatus = status
                val statusText = if (status.isPurchased) "Purchased" else "Not Purchased"
                showSnackbar("${status.productId}: $statusText")
                Log.d("MainActivity", "Product purchase status: $status")
            },
            onServerVerificationRequired = { result, consumableType ->
                Log.d("MainActivity", "Server verification required for ${result.productId} (type: $consumableType)")
                showSnackbar("Server verification required: ${result.productId}")
                // In a real app, send the purchase token to your server for verification.
                // After verification, call completePurchaseProcessing:
                Noctua.completePurchaseProcessing(
                    purchaseToken = result.purchaseToken,
                    consumableType = consumableType,
                    verified = true // Replace with actual server verification result
                ) { success ->
                    showSnackbar(
                        if (success) "Purchase verified & processed: ${result.productId}"
                        else "Failed to process after verification: ${result.productId}"
                    )
                    Log.d("MainActivity", "completePurchaseProcessing result: $success for ${result.productId}")
                }
            },
            onBillingError = { error, message ->
                billingError = error to message
                showSnackbar("Billing error: ${error.name}")
                Log.e("MainActivity", "Billing error: $error - $message")
            }
        )

        // Register default products with the SDK
        defaultProducts.forEach { (productId, consumableType) ->
            Noctua.registerProduct(productId, consumableType)
        }
    }

    fun refreshAccounts() {
        accounts.clear()
        accounts.addAll(Noctua.getAccounts())
    }

    Scaffold(
        modifier = Modifier.nestedScroll(scrollBehavior.nestedScrollConnection),
        topBar = {
            LargeTopAppBar(
                title = {
                    Column {
                        Text(
                            "Noctua SDK",
                            style = MaterialTheme.typography.headlineLarge
                        )
                        Text(
                            packageName,
                            style = MaterialTheme.typography.bodySmall,
                            color = MaterialTheme.colorScheme.onSurfaceVariant,
                            maxLines = 1,
                            overflow = TextOverflow.Ellipsis
                        )
                    }
                },
                actions = {
                    IconButton(onClick = { refreshAccounts() }) {
                        Icon(Icons.Default.Refresh, "Refresh")
                    }
                },
                scrollBehavior = scrollBehavior,
                colors = TopAppBarDefaults.largeTopAppBarColors(
                    containerColor = MaterialTheme.colorScheme.surface,
                    scrolledContainerColor = MaterialTheme.colorScheme.surface
                )
            )
        },
        snackbarHost = { SnackbarHost(snackbarHostState) }
    ) { padding ->
        LazyColumn(
            modifier = Modifier
                .fillMaxSize()
                .padding(padding),
            verticalArrangement = Arrangement.spacedBy(12.dp),
            contentPadding = PaddingValues(16.dp)
        ) {
            // Lifecycle Section
            item {
                SectionCard(
                    title = "Lifecycle",
                    icon = Icons.Default.SwapVert,
                    color = MaterialTheme.colorScheme.primary,
                    expandedByDefault = false
                ) {
                    LifecycleSection(
                        onOnline = {
                            Noctua.onOnline()
                            showSnackbar("SDK set to ONLINE mode")
                            Log.d("MainActivity", "Noctua.onOnline() called")
                        },
                        onOffline = {
                            Noctua.onOffline()
                            showSnackbar("SDK set to OFFLINE mode")
                            Log.d("MainActivity", "Noctua.onOffline() called")
                        }
                    )
                }
            }

            // Billing / IAP Section
            item {
                SectionCard(
                    title = "In-App Purchases",
                    icon = Icons.Default.ShoppingCart,
                    color = MaterialTheme.colorScheme.primary,
                    expandedByDefault = true
                ) {
                    BillingSection(
                        products = billingProducts,
                        purchases = billingPurchases,
                        billingError = billingError,
                        productPurchaseStatus = productPurchaseStatus,
                        defaultProducts = defaultProducts,
                        onQueryProducts = { ids, type ->
                            Noctua.queryProductDetails(ids, type)
                        },
                        onPurchase = { product ->
                            // Get the current activity for billing flow
                            Noctua.launchBillingFlow(activity, product)
                        },
                        onQueryPurchases = { type ->
                            Noctua.queryPurchases(type)
                        },
                        onAcknowledge = { token ->
                            Noctua.acknowledgePurchase(token) { success ->
                                showSnackbar(if (success) "Purchase acknowledged" else "Failed to acknowledge")
                            }
                        },
                        onConsume = { token ->
                            Noctua.consumePurchase(token) { success ->
                                showSnackbar(if (success) "Purchase consumed" else "Failed to consume")
                            }
                        },
                        onRegisterProduct = { productId, type ->
                            Noctua.registerProduct(productId, type)
                            showSnackbar("Registered $productId as ${type.name}")
                        },
                        onRestorePurchases = {
                            Noctua.restorePurchases()
                            showSnackbar("Restoring purchases...")
                            Log.d("MainActivity", "Restore purchases initiated")
                        },
                        onGetProductPurchaseStatus = { productId ->
                            Noctua.getProductPurchaseStatus(productId)
                            Log.d("MainActivity", "Checking purchase status for: $productId")
                        }
                    )
                }
            }

            // Analytics Section
            item {
                SectionCard(
                    title = "Analytics",
                    icon = Icons.Default.Menu,
                    color = MaterialTheme.colorScheme.primary
                ) {
                    AnalyticsSection(
                        onTrackAdRevenue = {
                            Noctua.trackAdRevenue("admob_sdk", 0.19, "USD")
                            showSnackbar("Ad revenue tracked")
                            Log.d("MainActivity", "Ad revenue tracked")
                        },
                        onTrackPurchase = {
                            val uuid = UUID.randomUUID().toString()
                            Noctua.trackPurchase("example.orderId.$uuid", 0.19, "USD")
                            showSnackbar("Purchase tracked")
                            Log.d("MainActivity", "Purchase tracked")
                        },
                        onTrackCustomEvent = {
                            Noctua.trackCustomEvent(
                                "login",
                                mutableMapOf(
                                    "k1" to 0.123f,
                                    "k2" to 0.123,
                                    "k3" to 123,
                                    "k4" to 123L,
                                    "k5" to true,
                                    "k6" to "string",
                                    "suffix" to 123,
                                )
                            )
                            showSnackbar("Custom event tracked")
                            Log.d("MainActivity", "Custom event tracked")
                        }
                    )
                }
            }

            // Attribution & Remote Config Section
            item {
                SectionCard(
                    title = "Attribution",
                    icon = Icons.Default.Share,
                    color = MaterialTheme.colorScheme.secondary,
                    expandedByDefault = false
                ) {
                    AttributionSection(
                        onGetAdjustAttribution = {
                            Noctua.getAdjustAttribution { attribution ->
                                val msg = "Adjust: $attribution"
                                showSnackbar(msg.take(100))
                                Log.d("MainActivity", "Adjust attribution: $attribution")
                            }
                        },
                        onGetRemoteConfig = {
                            Noctua.getFirebaseRemoteConfigString("welcome_message") { result ->
                                showSnackbar("Remote Config: $result")
                                Log.d("MainActivity", "Firebase Remote Config: $result")
                            }
                        }
                    )
                }
            }

            // Firebase IDs Section
            item {
                SectionCard(
                    title = "Firebase IDs",
                    icon = Icons.Default.Fingerprint,
                    color = MaterialTheme.colorScheme.secondary,
                    expandedByDefault = false
                ) {
                    FirebaseIdsSection(
                        installationId = installationId,
                        sessionId = analyticsSessionId,
                        onGetInstallationId = {
                            Noctua.getFirebaseInstallationID { id ->
                                installationId = id
                                showSnackbar("Installation ID: ${id.take(30)}...")
                                Log.d("MainActivity", "Firebase Installation ID: $id")
                            }
                        },
                        onGetSessionId = {
                            Noctua.getFirebaseAnalyticsSessionID { id ->
                                analyticsSessionId = id
                                showSnackbar("Analytics Session ID: ${id.take(30)}...")
                                Log.d("MainActivity", "Firebase Analytics Session ID: $id")
                            }
                        }
                    )
                }
            }

            // Remote Config Section
            item {
                SectionCard(
                    title = "Remote Config",
                    icon = Icons.Default.Settings,
                    color = MaterialTheme.colorScheme.secondary,
                    expandedByDefault = false
                ) {
                    RemoteConfigSection(
                        onGetString = { key ->
                            Noctua.getFirebaseRemoteConfigString(key) { value ->
                                remoteConfigResult = key to value
                                showSnackbar("$key: $value")
                                Log.d("MainActivity", "Remote Config String [$key]: $value")
                            }
                        },
                        onGetBoolean = { key ->
                            Noctua.getFirebaseRemoteConfigBoolean(key) { value ->
                                remoteConfigResult = key to value.toString()
                                showSnackbar("$key: $value")
                                Log.d("MainActivity", "Remote Config Boolean [$key]: $value")
                            }
                        },
                        onGetDouble = { key ->
                            Noctua.getFirebaseRemoteConfigDouble(key) { value ->
                                remoteConfigResult = key to value.toString()
                                showSnackbar("$key: $value")
                                Log.d("MainActivity", "Remote Config Double [$key]: $value")
                            }
                        },
                        onGetLong = { key ->
                            Noctua.getFirebaseRemoteConfigLong(key) { value ->
                                remoteConfigResult = key to value.toString()
                                showSnackbar("$key: $value")
                                Log.d("MainActivity", "Remote Config Long [$key]: $value")
                            }
                        },
                        lastResult = remoteConfigResult
                    )
                }
            }

            // Experiments Section
            item {
                SectionCard(
                    title = "Experiments",
                    icon = Icons.Default.Science,
                    color = MaterialTheme.colorScheme.tertiary,
                    expandedByDefault = false
                ) {
                    ExperimentsSection(
                        currentExperiment = currentExperiment,
                        onSetExperiment = { value ->
                            Noctua.setExperiment(value)
                            currentExperiment = value
                            showSnackbar("Experiment set: $value")
                            Log.d("MainActivity", "Experiment set: $value")
                        },
                        onGetExperiment = {
                            val exp = Noctua.getExperiment()
                            currentExperiment = exp
                            showSnackbar("Current experiment: $exp")
                            Log.d("MainActivity", "Current experiment: $exp")
                        },
                        onSetGeneralExperiment = { key, value ->
                            Noctua.setGeneralExperiment(value)
                            showSnackbar("General experiment set: $key = $value")
                            Log.d("MainActivity", "General experiment set: $key = $value")
                        },
                        onGetGeneralExperiment = { key ->
                            val value = Noctua.getGeneralExperiment(key)
                            generalExperimentResult = key to value
                            showSnackbar("$key = $value")
                            Log.d("MainActivity", "General experiment [$key]: $value")
                        }
                    )
                }
            }

            // Account Management Section
            item {
                SectionCard(
                    title = "Account Management",
                    icon = Icons.Default.AccountCircle,
                    color = MaterialTheme.colorScheme.tertiary,
                    expandedByDefault = true
                ) {
                    AccountSection(
                        offset = offset,
                        accounts = accounts,
                        onAddRandomAccount = {
                            val randomAccount = Account(
                                userId = (1L..3).random(),
                                gameId = (1L..3).random() + offset,
                                rawData = UUID.randomUUID().toString()
                            )
                            Noctua.putAccount(randomAccount)
                            refreshAccounts()
                            showSnackbar("Account added: ${randomAccount.userId}")
                            Log.d("MainActivity", "Random account saved: $randomAccount")
                        },
                        onDeleteRandomAccount = {
                            if (accounts.isNotEmpty()) {
                                val accountToDelete = accounts
                                    .filter { it.gameId in offset..(offset + 999) }
                                    .randomOrNull()
                                accountToDelete?.let {
                                    Noctua.deleteAccount(it)
                                    refreshAccounts()
                                    showSnackbar("Deleted account: ${it.userId}")
                                    Log.d("MainActivity", "Deleted account: $it")
                                } ?: showSnackbar("No accounts in range to delete")
                            } else {
                                showSnackbar("No accounts to delete")
                            }
                        },
                        onRefresh = { refreshAccounts() }
                    )
                }
            }

            // Testing & Events Section
            item {
                SectionCard(
                    title = "Testing & Events",
                    icon = Icons.Default.Warning,
                    color = MaterialTheme.colorScheme.error,
                    expandedByDefault = false
                ) {
                    TestingSection(
                        onSaveEvents = {
                            val testEvents = "session_test"
                            Noctua.saveEvents(testEvents)
                            showSnackbar("Events saved")
                        },
                        onGetEvents = {
                            Noctua.getEvents { result ->
                                events = result
                                showSnackbar("Retrieved ${result.size} events")
                                Log.d("MainActivity", "Data events local: $result")
                            }
                        },
                        onDeleteEvents = {
                            Noctua.deleteEvents()
                            events = emptyList()
                            showSnackbar("Events deleted")
                        },
                        onTriggerCrash = {
                            throw RuntimeException("Test Crash")
                        },
                        events = events,
                        // Per-row storage callbacks
                        onInsertEvent = {
                            val sampleJson = """{"event_name":"test_event","timestamp":${System.currentTimeMillis()}}"""
                            Noctua.insertEvent(sampleJson)
                            showSnackbar("Event inserted")
                            Log.d("MainActivity", "Inserted event: $sampleJson")
                        },
                        onGetEventsBatch = {
                            Noctua.getEventsBatch(10, 0) { result ->
                                batchResult = result
                                showSnackbar("Batch retrieved")
                                Log.d("MainActivity", "Batch result: $result")
                            }
                        },
                        onGetEventCount = {
                            Noctua.getEventCount { count ->
                                eventCount = count
                                showSnackbar("Event count: $count")
                                Log.d("MainActivity", "Event count: $count")
                            }
                        },
                        onDeleteEventsByIds = {
                            if (batchResult.isNotEmpty() && batchResult != "[]") {
                                // Extract IDs from batch result JSON
                                val idRegex = """"id":(\d+)""".toRegex()
                                val ids = idRegex.findAll(batchResult).map { it.groupValues[1] }.toList()
                                if (ids.isNotEmpty()) {
                                    val idsJson = "[${ids.joinToString(",")}]"
                                    Noctua.deleteEventsByIds(idsJson) { deletedCount ->
                                        batchResult = ""
                                        showSnackbar("Deleted $deletedCount events")
                                        Log.d("MainActivity", "Deleted $deletedCount events by IDs: $idsJson")
                                    }
                                } else {
                                    showSnackbar("No IDs found in batch")
                                }
                            } else {
                                showSnackbar("Get a batch first")
                            }
                        },
                        batchResult = batchResult,
                        eventCount = eventCount
                    )
                }
            }

            // Session Info with editable tag
            item {
                SessionInfoCard(
                    onSessionTagChanged = { newTag ->
                        currentSessionTag = newTag
                        showSnackbar("Session tag updated: $newTag")
                        Log.d("MainActivity", "Session tag updated: $newTag")
                    }
                )
            }
        }
    }
}
