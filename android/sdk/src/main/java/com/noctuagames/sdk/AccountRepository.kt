package com.noctuagames.sdk

import android.content.ContentResolver
import android.content.ContentValues
import android.content.Context
import android.content.pm.ApplicationInfo
import android.content.pm.PackageManager
import android.database.Cursor
import android.net.Uri
import android.util.Log
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import java.util.concurrent.ConcurrentHashMap


data class Account(
    val userId: Long,
    val gameId: Long,
    val rawData: String,
    val lastUpdated: Long
) {
    constructor(userId: Long, gameId: Long, rawData: String) : this(
        userId = userId,
        gameId = gameId,
        rawData = rawData,
        lastUpdated = System.currentTimeMillis()
    )
}

class AccountRepository(private val context: Context) {
    private val authority: String = "${context.packageName}.noctuaaccountprovider"
    private val TAG = this::class.simpleName
    private val contentUri: Uri = Uri.parse("content://${authority}/noctua_accounts")
    private val contentResolver = context.contentResolver
    private val otherAccounts: MutableMap<String, List<Account>> = ConcurrentHashMap()
    private val otherApps: List<String> = getOtherApps(context)

    suspend fun syncOtherAccounts() {
        Log.i(TAG, "${context.packageName} otherApps: $otherApps")

        for (otherApp in otherApps) {
            val otherAuthority = "$otherApp.noctuaaccountprovider"
            val uri = Uri.parse("content://$otherAuthority/noctua_accounts")
            val accounts = mutableListOf<Account>()

            withContext(Dispatchers.IO) {
                var cursor: Cursor? = null

                try {
                    cursor = contentResolver.query(uri, null, null, null, null)
                }
                catch (e: Exception) {
                    Log.w(TAG, "${e.javaClass.simpleName}: ${e.message}")

                    if (e.message?.contains("Permission Denial") == true) {
                        Log.w(TAG, "Permission denied for $uri")
                    }

                    return@withContext
                }

                if (cursor == null) {
                    Log.w(TAG, "Failed to query $uri")
                }

                cursor?.use {
                    while (it.moveToNext()) {
                        accounts.add(toAccount(it))
                    }
                }
            }

            Log.d(TAG, "found ${accounts.size} accounts in $otherAuthority")

            if (accounts.isNotEmpty()) {
                otherAccounts[otherAuthority] = accounts
            }
        }

        Log.d(TAG, "${context.packageName} otherAccounts: ${otherAccounts.keys}")
    }

    fun put(account: Account) {
        contentResolver.insert(contentUri, fromAccount(account))
    }

    fun getAll(): List<Account> {
        val cursor: Cursor? = context.contentResolver.query(contentUri, null, null, null, null)
        val accounts = mutableListOf<Account>()

        cursor?.use {
            while (it.moveToNext()) {
                accounts.add(toAccount(it))
            }
        }

        Log.d(TAG, "getAll ${accounts.size} accounts in $authority")

        otherAccounts.values.flatten().let { accounts.addAll(it) }

        Log.d(TAG, "getAll ${accounts.size} accounts in $authority and ${otherAccounts.keys}")

        return accounts
    }

    fun getSingle(userId: Long, gameId: Long): Account? {
        val selection = "user_id=? AND game_id=?"
        val args = arrayOf(userId.toString(), gameId.toString())
        val cursor: Cursor? = context.contentResolver.query(contentUri, null, selection, args, null)

        var account = cursor?.use {
            if (it.moveToNext()) toAccount(it) else null
        }

        if (account != null) {
            return account
        }

        return otherAccounts.values.flatten().find { it.userId == userId && it.gameId == gameId }
    }

    fun getByUserId(userId: Long): List<Account> {
        val selection = "user_id=?"
        val args = arrayOf(userId.toString())
        val cursor: Cursor? = contentResolver.query(contentUri, null, selection, args, null)
        val accounts = mutableListOf<Account>()

        cursor?.use {
            while (it.moveToNext()) {
                accounts.add(toAccount(it))
            }
        }

        otherAccounts.values.flatten().filter { it.userId == userId }.let { accounts.addAll(it) }

        return accounts
    }

    fun delete(userId: Long, gameId: Long): Int {
        val args = arrayOf(userId.toString(), gameId.toString())

        return contentResolver.delete(contentUri, "user_id=? AND game_id=?", args)
    }
}

private fun fromAccount(account: Account): ContentValues {
    return ContentValues().apply {
        put("user_id", account.userId)
        put("game_id", account.gameId)
        put("raw_data", account.rawData)
        put("last_updated", account.lastUpdated)
    }
}

private fun toAccount(cursor: Cursor): Account {
    return Account(
        userId = cursor.getLong(cursor.getColumnIndexOrThrow("user_id")),
        gameId = cursor.getLong(cursor.getColumnIndexOrThrow("game_id")),
        rawData = cursor.getString(cursor.getColumnIndexOrThrow("raw_data")),
        lastUpdated = cursor.getLong(cursor.getColumnIndexOrThrow("last_updated"))
    )
}

private fun getOtherApps(context: Context): List<String> {
    return context.packageManager.getInstalledPackages(PackageManager.GET_PROVIDERS)
        .filter { pkg ->
            pkg.providers?.any { it.authority == "${it.packageName}.noctuaaccountprovider" } == true &&
                pkg.packageName != context.packageName
        }
        .map { it.packageName }
}