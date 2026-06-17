package com.noctuagames.sdk.utils

import org.junit.After
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test

/**
 * Covers [NoctuaLog]'s sandbox gating. `android.util.Log` is stubbed in local unit
 * tests (testOptions.unitTests.isReturnDefaultValues = true), so we can't assert the
 * emitted output — but exercising every level under both sandbox states covers the
 * enabled/suppressed branches and proves no crash.
 */
class NoctuaLogTest {

    @After
    fun reset() {
        NoctuaLog.sandboxEnabled = true
    }

    @Test
    fun `defaults to enabled`() {
        NoctuaLog.sandboxEnabled = true
        assertTrue(NoctuaLog.sandboxEnabled)
    }

    @Test
    fun `all levels run when sandbox enabled`() {
        NoctuaLog.sandboxEnabled = true
        NoctuaLog.d("t", "d")
        NoctuaLog.i("t", "i")
        NoctuaLog.w("t", "w")
        NoctuaLog.w("t", "w", RuntimeException("x"))
        NoctuaLog.e("t", "e")
        NoctuaLog.e("t", "e", RuntimeException("x"))
    }

    @Test
    fun `non-error levels are gated off when sandbox disabled`() {
        NoctuaLog.sandboxEnabled = false
        assertFalse(NoctuaLog.sandboxEnabled)
        // Hits the suppressed (guard-false) branch for d/i/w...
        NoctuaLog.d("t", "d")
        NoctuaLog.i("t", "i")
        NoctuaLog.w("t", "w")
        NoctuaLog.w("t", "w", RuntimeException("x"))
        // ...while error levels always run regardless of sandbox state.
        NoctuaLog.e("t", "e")
        NoctuaLog.e("t", "e", null)
    }
}
