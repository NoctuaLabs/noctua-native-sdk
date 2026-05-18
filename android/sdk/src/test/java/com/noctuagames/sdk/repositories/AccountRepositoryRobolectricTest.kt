package com.noctuagames.sdk.repositories

import com.noctuagames.sdk.models.Account
import org.junit.Assert.*
import org.junit.Before
import org.junit.Test
import org.junit.runner.RunWith
import org.koin.core.context.stopKoin
import org.robolectric.RobolectricTestRunner
import org.robolectric.RuntimeEnvironment
import org.robolectric.annotation.Config

/**
 * Robolectric tests for [AccountRepository].
 * Requires real Android Context for Uri.parse(), ContentResolver, and PackageManager.
 */
@RunWith(RobolectricTestRunner::class)
@Config(sdk = [34])
class AccountRepositoryRobolectricTest {

    private lateinit var repository: AccountRepository

    @Before
    fun setUp() {
        try { stopKoin() } catch (_: Exception) {}
        val context = RuntimeEnvironment.getApplication()
        repository = AccountRepository(context)
    }

    @Test
    fun `repository can be instantiated with Robolectric context`() {
        assertNotNull(repository)
    }

    @Test
    fun `getAll returns empty list when no accounts exist`() {
        val all = repository.getAll()
        assertTrue(all.isEmpty())
    }

    @Test
    fun `put and getAll returns the inserted account`() {
        val account = Account(userId = 1L, gameId = 100L, rawData = "test_data", lastUpdated = 1000L)
        repository.put(account)
        val all = repository.getAll()
        assertTrue(all.any { it.userId == 1L && it.gameId == 100L })
    }

    @Test
    fun `getSingle returns correct account`() {
        val account = Account(userId = 2L, gameId = 200L, rawData = "single_test", lastUpdated = 2000L)
        repository.put(account)
        val result = repository.getSingle(2L, 200L)
        assertNotNull(result)
        assertEquals("single_test", result!!.rawData)
    }

    @Test
    fun `getSingle returns null for non-existent account`() {
        val result = repository.getSingle(999L, 999L)
        assertNull(result)
    }

    @Test
    fun `getByUserId returns matching accounts`() {
        repository.put(Account(userId = 3L, gameId = 300L, rawData = "a", lastUpdated = 1000L))
        repository.put(Account(userId = 3L, gameId = 301L, rawData = "b", lastUpdated = 1001L))
        repository.put(Account(userId = 4L, gameId = 400L, rawData = "c", lastUpdated = 1002L))

        val results = repository.getByUserId(3L)
        assertEquals(2, results.size)
        assertTrue(results.all { it.userId == 3L })
    }

    @Test
    fun `delete removes the account`() {
        repository.put(Account(userId = 5L, gameId = 500L, rawData = "delete_me", lastUpdated = 1000L))
        val deleted = repository.delete(5L, 500L)
        assertEquals(1, deleted)
        assertNull(repository.getSingle(5L, 500L))
    }

    @Test
    fun `delete returns 0 for non-existent account`() {
        val deleted = repository.delete(999L, 999L)
        assertEquals(0, deleted)
    }

    @Test
    fun `put with same userId and gameId replaces existing`() {
        repository.put(Account(userId = 6L, gameId = 600L, rawData = "original", lastUpdated = 1000L))
        repository.put(Account(userId = 6L, gameId = 600L, rawData = "replaced", lastUpdated = 2000L))
        val result = repository.getSingle(6L, 600L)
        assertNotNull(result)
        assertEquals("replaced", result!!.rawData)
    }
}
