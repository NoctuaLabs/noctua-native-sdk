package com.noctuagames.sdk.utils

import org.junit.Assert.*
import org.junit.Test

class UtilsTest {

    // -----------------------------------------------
    // toSafeJsonDouble
    // -----------------------------------------------

    @Test
    fun `toSafeJsonDouble returns value for normal double`() {
        val value: Double? = 1.5
        assertEquals(1.5, value.toSafeJsonDouble()!!, 0.001)
    }

    @Test
    fun `toSafeJsonDouble returns value for zero`() {
        val value: Double? = 0.0
        assertEquals(0.0, value.toSafeJsonDouble()!!, 0.001)
    }

    @Test
    fun `toSafeJsonDouble returns value for negative double`() {
        val value: Double? = -99.9
        assertEquals(-99.9, value.toSafeJsonDouble()!!, 0.001)
    }

    @Test
    fun `toSafeJsonDouble returns null for NaN`() {
        val value: Double? = Double.NaN
        assertNull(value.toSafeJsonDouble())
    }

    @Test
    fun `toSafeJsonDouble returns null for positive infinity`() {
        val value: Double? = Double.POSITIVE_INFINITY
        assertNull(value.toSafeJsonDouble())
    }

    @Test
    fun `toSafeJsonDouble returns null for negative infinity`() {
        val value: Double? = Double.NEGATIVE_INFINITY
        assertNull(value.toSafeJsonDouble())
    }

    @Test
    fun `toSafeJsonDouble returns null for null input`() {
        val value: Double? = null
        assertNull(value.toSafeJsonDouble())
    }

    @Test
    fun `toSafeJsonDouble preserves precision`() {
        val value: Double? = 0.123456789
        assertEquals(0.123456789, value.toSafeJsonDouble()!!, 0.0000001)
    }

    @Test
    fun `toSafeJsonDouble handles MAX_VALUE`() {
        val value: Double? = Double.MAX_VALUE
        assertEquals(Double.MAX_VALUE, value.toSafeJsonDouble()!!, 0.001)
    }

    @Test
    fun `toSafeJsonDouble handles MIN_VALUE`() {
        val value: Double? = Double.MIN_VALUE
        assertEquals(Double.MIN_VALUE, value.toSafeJsonDouble()!!, 0.0)
    }
}
