package com.noctuagames.sdk.utils

import org.junit.Assert.*
import org.junit.Before
import org.junit.Test
import org.junit.runner.RunWith
import org.koin.core.context.stopKoin
import org.robolectric.RobolectricTestRunner
import org.robolectric.RuntimeEnvironment
import org.robolectric.annotation.Config

/**
 * Robolectric tests for [loadConfig].
 * Requires real Android Context to read assets/noctuagg.json.
 */
@RunWith(RobolectricTestRunner::class)
@Config(sdk = [34])
class UtilsRobolectricTest {

    @Before
    fun setUp() {
        try { stopKoin() } catch (_: Exception) {}
    }

    @Test
    fun `loadConfig reads noctuagg json from assets`() {
        val context = RuntimeEnvironment.getApplication()
        val config = loadConfig(context)

        assertNotNull(config)
        assertEquals("test-client-id", config.clientId)
        assertEquals(1L, config.gameId)
    }

    @Test
    fun `loadConfig returns null services when not in config`() {
        val context = RuntimeEnvironment.getApplication()
        val config = loadConfig(context)

        assertNull(config.adjust)
        assertNull(config.firebase)
        assertNull(config.facebook)
        assertNull(config.noctua)
    }
}
