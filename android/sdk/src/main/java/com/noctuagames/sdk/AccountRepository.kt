package com.noctuagames.sdk

import android.content.ContentValues
import android.content.Context
import android.database.Cursor
import android.database.sqlite.SQLiteConstraintException

data class Account(
    val userId: Long,
    val gameId: Long,
    val playerId: Long,
    val accessToken: String
)

class AccountRepository(private val context: Context) {
    fun put(account: Account) {
        val values = ContentValues().apply {
            put("userId", account.userId)
            put("gameId", account.gameId)
            put("playerId", account.playerId)
            put("accessToken", account.accessToken)
        }

        context.contentResolver.insert(AccountContentProvider.CONTENT_URI, values)
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
        val selection = "userId=? AND gameId=?"
        val args = arrayOf(userId.toString(), gameId.toString())
        val cursor: Cursor? = context.contentResolver.query(uri, null, selection, args, null)

        return cursor?.use {
            if (it.moveToNext()) toAccount(it) else null
        }
    }

    fun getByUserId(userId: Long): List<Account> {
        val uri = AccountContentProvider.CONTENT_URI
        val selection = "userId=?"
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
        val selection = "gameId=?"
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
            "userId=? AND gameId=?",
            arrayOf(userId.toString(), gameId.toString())
        )
    }
}

private fun toAccount(cursor: Cursor): Account {
    val userId = cursor.getLong(cursor.getColumnIndexOrThrow("userId"))
    val gameId = cursor.getLong(cursor.getColumnIndexOrThrow("gameId"))
    val playerId = cursor.getLong(cursor.getColumnIndexOrThrow("playerId"))
    val accessToken = cursor.getString(cursor.getColumnIndexOrThrow("accessToken"))

    return Account(userId, gameId, playerId, accessToken)
}