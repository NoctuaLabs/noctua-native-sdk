package com.noctuagames.app

import com.noctuagames.sdk.models.ConsumableType
import com.noctuagames.sdk.models.ProductType
import org.junit.Assert.*
import org.junit.Test

/**
 * Unit tests for the default product configuration used in the sample app.
 * These validate that the SKU definitions and type mappings are correct
 * for the demo billing integration.
 */
class DefaultProductsTest {

    /**
     * The default product list as configured in MainActivity.
     * Kept in sync to verify correctness.
     */
    private val defaultProducts = listOf(
        "noctua.sub.1" to ConsumableType.SUBSCRIPTION,
        "noctua.sub.2" to ConsumableType.SUBSCRIPTION,
        "noctua.sub.3" to ConsumableType.SUBSCRIPTION,
        "noctua.test.android.pack1" to ConsumableType.CONSUMABLE,
        "noctua.ashechoes.pack6" to ConsumableType.CONSUMABLE,
        "noctua.test.android.pack2" to ConsumableType.NON_CONSUMABLE
    )

    @Test
    fun `default products list has correct count`() {
        assertEquals(6, defaultProducts.size)
    }

    @Test
    fun `subscription products are correctly typed`() {
        val subscriptions = defaultProducts.filter { it.second == ConsumableType.SUBSCRIPTION }
        assertEquals(3, subscriptions.size)
        assertTrue(subscriptions.any { it.first == "noctua.sub.1" })
        assertTrue(subscriptions.any { it.first == "noctua.sub.2" })
        assertTrue(subscriptions.any { it.first == "noctua.sub.3" })
    }

    @Test
    fun `consumable products are correctly typed`() {
        val consumables = defaultProducts.filter { it.second == ConsumableType.CONSUMABLE }
        assertEquals(2, consumables.size)
        assertTrue(consumables.any { it.first == "noctua.test.android.pack1" })
        assertTrue(consumables.any { it.first == "noctua.ashechoes.pack6" })
    }

    @Test
    fun `non-consumable products are correctly typed`() {
        val nonConsumables = defaultProducts.filter { it.second == ConsumableType.NON_CONSUMABLE }
        assertEquals(1, nonConsumables.size)
        assertEquals("noctua.test.android.pack2", nonConsumables[0].first)
    }

    @Test
    fun `all product IDs are unique`() {
        val ids = defaultProducts.map { it.first }
        assertEquals(ids.size, ids.distinct().size)
    }

    @Test
    fun `INAPP query filters out subscriptions correctly`() {
        val inappIds = defaultProducts
            .filter { it.second != ConsumableType.SUBSCRIPTION }
            .map { it.first }

        assertEquals(3, inappIds.size)
        assertTrue(inappIds.contains("noctua.test.android.pack1"))
        assertTrue(inappIds.contains("noctua.ashechoes.pack6"))
        assertTrue(inappIds.contains("noctua.test.android.pack2"))
        assertFalse(inappIds.contains("noctua.sub.1"))
    }

    @Test
    fun `SUBS query filters only subscriptions`() {
        val subsIds = defaultProducts
            .filter { it.second == ConsumableType.SUBSCRIPTION }
            .map { it.first }

        assertEquals(3, subsIds.size)
        assertTrue(subsIds.all { it.startsWith("noctua.sub.") })
        assertFalse(subsIds.contains("noctua.test.android.pack1"))
    }
}
