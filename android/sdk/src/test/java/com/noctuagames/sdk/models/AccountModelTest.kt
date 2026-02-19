package com.noctuagames.sdk.models

import org.junit.Assert.*
import org.junit.Test

class AccountModelTest {

    @Test
    fun `Account stores all fields correctly`() {
        val account = Account(
            userId = 1L,
            gameId = 100L,
            rawData = "test_data",
            lastUpdated = 1700000000L
        )
        assertEquals(1L, account.userId)
        assertEquals(100L, account.gameId)
        assertEquals("test_data", account.rawData)
        assertEquals(1700000000L, account.lastUpdated)
    }

    @Test
    fun `Account secondary constructor sets lastUpdated automatically`() {
        val before = System.currentTimeMillis()
        val account = Account(
            userId = 2L,
            gameId = 200L,
            rawData = "auto_time"
        )
        val after = System.currentTimeMillis()

        assertEquals(2L, account.userId)
        assertEquals(200L, account.gameId)
        assertEquals("auto_time", account.rawData)
        assertTrue(account.lastUpdated in before..after)
    }

    @Test
    fun `Account data class equality works`() {
        val account1 = Account(userId = 1L, gameId = 100L, rawData = "data", lastUpdated = 1000L)
        val account2 = Account(userId = 1L, gameId = 100L, rawData = "data", lastUpdated = 1000L)
        val account3 = Account(userId = 2L, gameId = 100L, rawData = "data", lastUpdated = 1000L)

        assertEquals(account1, account2)
        assertNotEquals(account1, account3)
    }

    @Test
    fun `Account data class copy works`() {
        val original = Account(userId = 1L, gameId = 100L, rawData = "original", lastUpdated = 1000L)
        val copied = original.copy(rawData = "modified")

        assertEquals(1L, copied.userId)
        assertEquals(100L, copied.gameId)
        assertEquals("modified", copied.rawData)
        assertEquals(1000L, copied.lastUpdated)
    }
}
