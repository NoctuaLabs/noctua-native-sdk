package com.noctuagames.app.ui.components

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.ExperimentalLayoutApi
import androidx.compose.foundation.layout.FlowRow
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Add
import androidx.compose.material.icons.filled.Check
import androidx.compose.material.icons.filled.Delete
import androidx.compose.material.icons.filled.Info
import androidx.compose.material.icons.filled.Refresh
import androidx.compose.material.icons.filled.Search
import androidx.compose.material.icons.filled.ShoppingCart
import androidx.compose.material3.Card
import androidx.compose.material3.CardDefaults
import androidx.compose.material3.FilterChip
import androidx.compose.material3.FilterChipDefaults
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateListOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import com.noctuagames.sdk.models.BillingErrorCode
import com.noctuagames.sdk.models.ConsumableType
import com.noctuagames.sdk.models.NoctuaProductDetails
import com.noctuagames.sdk.models.ProductType
import com.noctuagames.sdk.models.NoctuaProductPurchaseStatus
import com.noctuagames.sdk.models.NoctuaPurchaseResult
import com.noctuagames.sdk.models.PurchaseState

@OptIn(ExperimentalLayoutApi::class)
@Composable
fun BillingSection(
    products: List<NoctuaProductDetails>,
    purchases: List<NoctuaPurchaseResult>,
    billingError: Pair<BillingErrorCode, String>?,
    productPurchaseStatus: NoctuaProductPurchaseStatus?,
    onQueryProducts: (List<String>, ProductType) -> Unit,
    onPurchase: (NoctuaProductDetails) -> Unit,
    onQueryPurchases: (ProductType) -> Unit,
    onAcknowledge: (String) -> Unit,
    onConsume: (String) -> Unit,
    onRegisterProduct: (String, ConsumableType) -> Unit,
    onRestorePurchases: () -> Unit,
    onGetProductPurchaseStatus: (String) -> Unit,
    defaultProducts: List<Pair<String, ConsumableType>> = emptyList()
) {
    var productIdInput by remember { mutableStateOf("") }
    var statusProductIdInput by remember { mutableStateOf("") }
    val registeredProducts = remember { mutableStateListOf<Pair<String, ConsumableType>>().apply { addAll(defaultProducts) } }

    Column(
        modifier = Modifier.fillMaxWidth(),
        verticalArrangement = Arrangement.spacedBy(12.dp)
    ) {
        // Product Registration Section
        Text(
            text = "Register Products",
            style = MaterialTheme.typography.labelMedium,
            color = MaterialTheme.colorScheme.onSurfaceVariant
        )

        OutlinedTextField(
            value = productIdInput,
            onValueChange = { productIdInput = it },
            modifier = Modifier.fillMaxWidth(),
            label = { Text("Product ID") },
            placeholder = { Text("e.g., premium_upgrade, gems_100") },
            singleLine = true
        )

        FlowRow(
            modifier = Modifier.fillMaxWidth(),
            horizontalArrangement = Arrangement.spacedBy(8.dp),
            verticalArrangement = Arrangement.spacedBy(8.dp)
        ) {
            ConsumableType.entries.forEach { type ->
                FilterChip(
                    selected = false,
                    onClick = {
                        if (productIdInput.isNotEmpty()) {
                            onRegisterProduct(productIdInput, type)
                            registeredProducts.add(productIdInput to type)
                            productIdInput = ""
                        }
                    },
                    label = { Text(type.name.replace("_", " ")) },
                    colors = FilterChipDefaults.filterChipColors(
                        containerColor = when (type) {
                            ConsumableType.CONSUMABLE -> MaterialTheme.colorScheme.primaryContainer
                            ConsumableType.NON_CONSUMABLE -> MaterialTheme.colorScheme.secondaryContainer
                            ConsumableType.SUBSCRIPTION -> MaterialTheme.colorScheme.tertiaryContainer
                        }
                    )
                )
            }
        }

        // Show registered products
        if (registeredProducts.isNotEmpty()) {
            Text(
                text = "Registered Products (${registeredProducts.size})",
                style = MaterialTheme.typography.labelSmall,
                color = MaterialTheme.colorScheme.onSurfaceVariant
            )
            FlowRow(
                horizontalArrangement = Arrangement.spacedBy(4.dp),
                verticalArrangement = Arrangement.spacedBy(4.dp)
            ) {
                registeredProducts.forEach { (id, type) ->
                    FilterChip(
                        selected = true,
                        onClick = { },
                        label = { Text("$id (${type.name.take(3)})") },
                        colors = FilterChipDefaults.filterChipColors(
                            selectedContainerColor = when (type) {
                                ConsumableType.CONSUMABLE -> MaterialTheme.colorScheme.primary.copy(alpha = 0.2f)
                                ConsumableType.NON_CONSUMABLE -> MaterialTheme.colorScheme.secondary.copy(alpha = 0.2f)
                                ConsumableType.SUBSCRIPTION -> MaterialTheme.colorScheme.tertiary.copy(alpha = 0.2f)
                            }
                        )
                    )
                }
            }
        }

        HorizontalDivider()

        // Query Buttons
        FlowRow(
            modifier = Modifier.fillMaxWidth(),
            horizontalArrangement = Arrangement.spacedBy(8.dp),
            verticalArrangement = Arrangement.spacedBy(8.dp),
            maxItemsInEachRow = 2
        ) {
            ActionButton(
                onClick = {
                    val ids = registeredProducts
                        .filter { it.second != ConsumableType.SUBSCRIPTION }
                        .map { it.first }
                    if (ids.isNotEmpty()) {
                        onQueryProducts(ids, ProductType.INAPP)
                    }
                },
                icon = Icons.Default.Refresh,
                label = "Query INAPP",
                containerColor = MaterialTheme.colorScheme.primaryContainer,
                contentColor = MaterialTheme.colorScheme.onPrimaryContainer,
                modifier = Modifier.weight(1f)
            )
            ActionButton(
                onClick = {
                    val ids = registeredProducts
                        .filter { it.second == ConsumableType.SUBSCRIPTION }
                        .map { it.first }
                    if (ids.isNotEmpty()) {
                        onQueryProducts(ids, ProductType.SUBS)
                    }
                },
                icon = Icons.Default.Refresh,
                label = "Query SUBS",
                containerColor = MaterialTheme.colorScheme.tertiaryContainer,
                contentColor = MaterialTheme.colorScheme.onTertiaryContainer,
                modifier = Modifier.weight(1f)
            )
            ActionButton(
                onClick = { onQueryPurchases(ProductType.INAPP) },
                icon = Icons.Default.ShoppingCart,
                label = "Get INAPP",
                containerColor = MaterialTheme.colorScheme.secondaryContainer,
                contentColor = MaterialTheme.colorScheme.onSecondaryContainer,
                modifier = Modifier.weight(1f)
            )
            ActionButton(
                onClick = { onQueryPurchases(ProductType.SUBS) },
                icon = Icons.Default.ShoppingCart,
                label = "Get SUBS",
                containerColor = MaterialTheme.colorScheme.secondaryContainer,
                contentColor = MaterialTheme.colorScheme.onSecondaryContainer,
                modifier = Modifier.weight(1f)
            )
        }

        // Restore Purchases Button
        ActionButton(
            onClick = onRestorePurchases,
            icon = Icons.Default.Refresh,
            label = "Restore Purchases",
            containerColor = MaterialTheme.colorScheme.primaryContainer,
            contentColor = MaterialTheme.colorScheme.onPrimaryContainer,
            modifier = Modifier.fillMaxWidth()
        )

        HorizontalDivider()

        // Get Product Purchase Status Section
        Text(
            text = "Product Purchase Status",
            style = MaterialTheme.typography.labelMedium,
            color = MaterialTheme.colorScheme.onSurfaceVariant
        )

        OutlinedTextField(
            value = statusProductIdInput,
            onValueChange = { statusProductIdInput = it },
            modifier = Modifier.fillMaxWidth(),
            label = { Text("Product ID") },
            placeholder = { Text("e.g., premium_upgrade") },
            singleLine = true
        )

        ActionButton(
            onClick = {
                if (statusProductIdInput.isNotEmpty()) {
                    onGetProductPurchaseStatus(statusProductIdInput)
                }
            },
            icon = Icons.Default.Search,
            label = "Check Purchase Status",
            containerColor = MaterialTheme.colorScheme.secondaryContainer,
            contentColor = MaterialTheme.colorScheme.onSecondaryContainer,
            modifier = Modifier.fillMaxWidth()
        )

        // Display Product Purchase Status Result
        productPurchaseStatus?.let { status ->
            ProductPurchaseStatusCard(status = status)
        }

        HorizontalDivider()

        // Error Display
        billingError?.let { (error, message) ->
            Card(
                modifier = Modifier.fillMaxWidth(),
                colors = CardDefaults.cardColors(
                    containerColor = MaterialTheme.colorScheme.errorContainer
                ),
                shape = RoundedCornerShape(8.dp)
            ) {
                Column(
                    modifier = Modifier.padding(12.dp)
                ) {
                    Text(
                        text = "Billing Error: ${error.name}",
                        style = MaterialTheme.typography.labelMedium,
                        color = MaterialTheme.colorScheme.onErrorContainer
                    )
                    Text(
                        text = message,
                        style = MaterialTheme.typography.bodySmall,
                        color = MaterialTheme.colorScheme.onErrorContainer
                    )
                }
            }
        }

        // Products List
        if (products.isNotEmpty()) {
            HorizontalDivider()
            Text(
                text = "Available Products (${products.size})",
                style = MaterialTheme.typography.labelMedium,
                color = MaterialTheme.colorScheme.onSurfaceVariant
            )
            products.forEach { product ->
                ProductCard(
                    product = product,
                    onPurchase = { onPurchase(product) }
                )
            }
        }

        // Purchases List
        if (purchases.isNotEmpty()) {
            HorizontalDivider()
            Text(
                text = "Purchases (${purchases.size})",
                style = MaterialTheme.typography.labelMedium,
                color = MaterialTheme.colorScheme.onSurfaceVariant
            )
            purchases.forEach { purchase ->
                PurchaseCard(
                    purchase = purchase,
                    onAcknowledge = { onAcknowledge(purchase.purchaseToken) },
                    onConsume = { onConsume(purchase.purchaseToken) }
                )
            }
        }
    }
}

@OptIn(ExperimentalLayoutApi::class)
@Composable
private fun ProductCard(
    product: NoctuaProductDetails,
    onPurchase: () -> Unit
) {
    Card(
        modifier = Modifier.fillMaxWidth(),
        colors = CardDefaults.cardColors(
            containerColor = MaterialTheme.colorScheme.surfaceVariant.copy(alpha = 0.5f)
        ),
        shape = RoundedCornerShape(8.dp)
    ) {
        Column(
            modifier = Modifier.padding(12.dp),
            verticalArrangement = Arrangement.spacedBy(8.dp)
        ) {
            Text(
                text = product.title,
                style = MaterialTheme.typography.bodyMedium,
                fontWeight = androidx.compose.ui.text.font.FontWeight.Medium
            )
            Text(
                text = product.description,
                style = MaterialTheme.typography.bodySmall,
                color = MaterialTheme.colorScheme.onSurfaceVariant,
                maxLines = 2,
                overflow = TextOverflow.Ellipsis
            )
            FlowRow(
                horizontalArrangement = Arrangement.spacedBy(8.dp),
                verticalArrangement = Arrangement.spacedBy(4.dp)
            ) {
                FilterChip(
                    selected = true,
                    onClick = { },
                    label = { Text(product.formattedPrice) },
                    colors = FilterChipDefaults.filterChipColors(
                        selectedContainerColor = MaterialTheme.colorScheme.primaryContainer,
                        selectedLabelColor = MaterialTheme.colorScheme.onPrimaryContainer
                    )
                )
                FilterChip(
                    selected = false,
                    onClick = { },
                    label = { Text(if (product.productType == ProductType.INAPP) "INAPP" else "SUBS") },
                    colors = FilterChipDefaults.filterChipColors(
                        containerColor = MaterialTheme.colorScheme.secondaryContainer,
                        labelColor = MaterialTheme.colorScheme.onSecondaryContainer
                    )
                )
            }
            ActionButton(
                onClick = onPurchase,
                icon = Icons.Default.Add,
                label = "Purchase",
                containerColor = MaterialTheme.colorScheme.primary,
                contentColor = MaterialTheme.colorScheme.onPrimary,
                modifier = Modifier.fillMaxWidth()
            )
        }
    }
}

@OptIn(ExperimentalLayoutApi::class)
@Composable
private fun PurchaseCard(
    purchase: NoctuaPurchaseResult,
    onAcknowledge: () -> Unit,
    onConsume: () -> Unit
) {
    Card(
        modifier = Modifier.fillMaxWidth(),
        colors = CardDefaults.cardColors(
            containerColor = when {
                purchase.isPurchased() -> MaterialTheme.colorScheme.primaryContainer.copy(alpha = 0.3f)
                purchase.isPending() -> MaterialTheme.colorScheme.tertiaryContainer.copy(alpha = 0.3f)
                else -> MaterialTheme.colorScheme.surfaceVariant.copy(alpha = 0.5f)
            }
        ),
        shape = RoundedCornerShape(8.dp)
    ) {
        Column(
            modifier = Modifier.padding(12.dp),
            verticalArrangement = Arrangement.spacedBy(8.dp)
        ) {
            Text(
                text = "Product: ${purchase.productId}",
                style = MaterialTheme.typography.bodyMedium,
                fontWeight = androidx.compose.ui.text.font.FontWeight.Medium
            )
            Text(
                text = "State: ${purchase.purchaseState.name}",
                style = MaterialTheme.typography.bodySmall,
                color = MaterialTheme.colorScheme.onSurfaceVariant
            )
            Text(
                text = "Token: ${purchase.purchaseToken.take(20)}...",
                style = MaterialTheme.typography.bodySmall,
                color = MaterialTheme.colorScheme.onSurfaceVariant,
                maxLines = 1,
                overflow = TextOverflow.Ellipsis
            )
            FlowRow(
                horizontalArrangement = Arrangement.spacedBy(8.dp),
                verticalArrangement = Arrangement.spacedBy(4.dp)
            ) {
                FilterChip(
                    selected = purchase.isAcknowledged,
                    onClick = { },
                    label = { Text(if (purchase.isAcknowledged) "Acknowledged" else "Not Acknowledged") },
                    colors = FilterChipDefaults.filterChipColors(
                        selectedContainerColor = MaterialTheme.colorScheme.secondaryContainer,
                        selectedLabelColor = MaterialTheme.colorScheme.onSecondaryContainer
                    )
                )
                FilterChip(
                    selected = purchase.quantity > 1,
                    onClick = { },
                    label = { Text("Qty: ${purchase.quantity}") },
                    colors = FilterChipDefaults.filterChipColors(
                        containerColor = MaterialTheme.colorScheme.tertiaryContainer,
                        labelColor = MaterialTheme.colorScheme.onTertiaryContainer
                    )
                )
            }

            if (purchase.isPurchased()) {
                FlowRow(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.spacedBy(8.dp)
                ) {
                    if (!purchase.isAcknowledged) {
                        ActionButton(
                            onClick = onAcknowledge,
                            icon = Icons.Default.Check,
                            label = "Acknowledge",
                            containerColor = MaterialTheme.colorScheme.secondaryContainer,
                            contentColor = MaterialTheme.colorScheme.onSecondaryContainer,
                            modifier = Modifier.weight(1f)
                        )
                    }
                    ActionButton(
                        onClick = onConsume,
                        icon = Icons.Default.Delete,
                        label = "Consume",
                        containerColor = MaterialTheme.colorScheme.errorContainer,
                        contentColor = MaterialTheme.colorScheme.onErrorContainer,
                        modifier = Modifier.weight(1f)
                    )
                }
            }
        }
    }
}

@OptIn(ExperimentalLayoutApi::class)
@Composable
private fun ProductPurchaseStatusCard(
    status: NoctuaProductPurchaseStatus
) {
    Card(
        modifier = Modifier.fillMaxWidth(),
        colors = CardDefaults.cardColors(
            containerColor = if (status.isPurchased)
                MaterialTheme.colorScheme.primaryContainer.copy(alpha = 0.3f)
            else
                MaterialTheme.colorScheme.surfaceVariant.copy(alpha = 0.5f)
        ),
        shape = RoundedCornerShape(8.dp)
    ) {
        Column(
            modifier = Modifier.padding(12.dp),
            verticalArrangement = Arrangement.spacedBy(8.dp)
        ) {
            Text(
                text = "Product: ${status.productId}",
                style = MaterialTheme.typography.bodyMedium,
                fontWeight = androidx.compose.ui.text.font.FontWeight.Medium
            )
            FlowRow(
                horizontalArrangement = Arrangement.spacedBy(8.dp),
                verticalArrangement = Arrangement.spacedBy(4.dp)
            ) {
                FilterChip(
                    selected = status.isPurchased,
                    onClick = { },
                    label = { Text(if (status.isPurchased) "Purchased" else "Not Purchased") },
                    colors = FilterChipDefaults.filterChipColors(
                        selectedContainerColor = MaterialTheme.colorScheme.primary.copy(alpha = 0.2f),
                        containerColor = MaterialTheme.colorScheme.surfaceVariant
                    )
                )
                FilterChip(
                    selected = status.isAcknowledged,
                    onClick = { },
                    label = { Text(if (status.isAcknowledged) "Acknowledged" else "Not Acknowledged") },
                    colors = FilterChipDefaults.filterChipColors(
                        selectedContainerColor = MaterialTheme.colorScheme.secondary.copy(alpha = 0.2f),
                        containerColor = MaterialTheme.colorScheme.surfaceVariant
                    )
                )
                FilterChip(
                    selected = false,
                    onClick = { },
                    label = { Text("State: ${status.purchaseState.name}") },
                    colors = FilterChipDefaults.filterChipColors(
                        containerColor = MaterialTheme.colorScheme.tertiaryContainer
                    )
                )
            }
            if (status.isPurchased) {
                if (status.orderId != null) {
                    Text(
                        text = "Order: ${status.orderId}",
                        style = MaterialTheme.typography.bodySmall,
                        color = MaterialTheme.colorScheme.onSurfaceVariant
                    )
                }
                if (status.purchaseToken.isNotEmpty()) {
                    Text(
                        text = "Token: ${status.purchaseToken.take(20)}...",
                        style = MaterialTheme.typography.bodySmall,
                        color = MaterialTheme.colorScheme.onSurfaceVariant,
                        maxLines = 1,
                        overflow = TextOverflow.Ellipsis
                    )
                }
                if (status.isAutoRenewing) {
                    FilterChip(
                        selected = true,
                        onClick = { },
                        label = { Text("Auto-Renewing") },
                        colors = FilterChipDefaults.filterChipColors(
                            selectedContainerColor = MaterialTheme.colorScheme.tertiary.copy(alpha = 0.2f)
                        )
                    )
                }
            }
        }
    }
}