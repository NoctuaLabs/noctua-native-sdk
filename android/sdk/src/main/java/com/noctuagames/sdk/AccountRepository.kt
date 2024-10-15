package com.noctuagames.sdk

import android.content.ContentValues
import android.content.Context
import android.database.Cursor


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
    fun put(account: Account) {
        context.contentResolver.insert(AccountContentProvider.CONTENT_URI, fromAccount(account))
    }

    fun getAll(): List<Account> {
        val uri = AccountContentProvider.CONTENT_URI
        val cursor: Cursor? = context.contentResolver.query(uri, null, null, null, null)
        val accounts = mutableListOf<Account>()

        cursor?.use {
            while (it.moveToNext()) {
                accounts.add(toAccount(it))
            }
        }

        return accounts
    }

    fun getSingle(userId: Long, gameId: Long): Account? {
        val uri = AccountContentProvider.CONTENT_URI
        val selection = "user_id=? AND game_id=?"
        val args = arrayOf(userId.toString(), gameId.toString())
        val cursor: Cursor? = context.contentResolver.query(uri, null, selection, args, null)

        return cursor?.use {
            if (it.moveToNext()) toAccount(it) else null
        }
    }

    fun getByUserId(userId: Long): List<Account> {
        val uri = AccountContentProvider.CONTENT_URI
        val selection = "user_id=?"
        val args = arrayOf(userId.toString())
        val cursor: Cursor? = context.contentResolver.query(uri, null, selection, args, null)
        val accounts = mutableListOf<Account>()

        cursor?.use {
            while (it.moveToNext()) {
                accounts.add(toAccount(it))
            }
        }

        return accounts
    }

    fun getByGameId(gameId: Long): List<Account> {
        val uri = AccountContentProvider.CONTENT_URI
        val selection = "game_id=?"
        val args = arrayOf(gameId.toString())
        val cursor: Cursor? = context.contentResolver.query(uri, null, selection, args, null)
        val accounts = mutableListOf<Account>()

        cursor?.use {
            while (it.moveToNext()) {
                accounts.add(toAccount(it))
            }
        }

        return accounts
    }

    fun delete(userId: Long, gameId: Long): Int {
        val uri = AccountContentProvider.CONTENT_URI

        return context.contentResolver.delete(
            uri,
            "user_id=? AND game_id=?",
            arrayOf(userId.toString(), gameId.toString())
        )
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