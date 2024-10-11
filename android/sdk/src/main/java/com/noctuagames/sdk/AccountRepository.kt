package com.noctuagames.sdk

import android.content.ContentValues
import android.content.Context
import android.database.Cursor


data class Account(
    val userId: Long,
    val gameId: Long,
    val playerId: Long,
    val userIsGuest: Boolean,
    val userNickname: String?,
    val userEmail: String?,
    val credentialId: Long?,
    val credentialProvider: String?,
    val credentialDisplayText: String?,
    val gameName: String?,
    val gamePlatformId: Long?,
    val gamePlatformName: String?,
    val gamePlatformBundleId: String?,
    val playerAccessToken: String,
    val playerUsername: String?,
    var lastUpdated: Long = System.currentTimeMillis()
)


class AccountRepository(private val context: Context) {
    fun put(account: Account) {
        account.lastUpdated = System.currentTimeMillis()
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
        put("player_id", account.playerId)
        put("user_is_guest", account.userIsGuest)
        put("user_nickname", account.userNickname)
        put("user_email", account.userEmail)
        put("credential_id", account.credentialId)
        put("credential_provider", account.credentialProvider)
        put("credential_display_text", account.credentialDisplayText)
        put("game_name", account.gameName)
        put("game_platform_id", account.gamePlatformId)
        put("game_platform_name", account.gamePlatformName)
        put("game_platform_bundle_id", account.gamePlatformBundleId)
        put("player_access_token", account.playerAccessToken)
        put("player_username", account.playerUsername)
        put("last_updated", account.lastUpdated)
    }
}

private fun toAccount(cursor: Cursor): Account {
    return Account(
        userId = cursor.getLong(cursor.getColumnIndexOrThrow("user_id")),
        gameId = cursor.getLong(cursor.getColumnIndexOrThrow("game_id")),
        playerId = cursor.getLong(cursor.getColumnIndexOrThrow("player_id")),
        userIsGuest = cursor.getInt(cursor.getColumnIndexOrThrow("user_is_guest")) > 0,
        userNickname = cursor.getString(cursor.getColumnIndexOrThrow("user_nickname")),
        userEmail = cursor.getString(cursor.getColumnIndexOrThrow("user_email")),
        credentialId = cursor.getLong(cursor.getColumnIndexOrThrow("credential_id")),
        credentialProvider = cursor.getString(cursor.getColumnIndexOrThrow("credential_provider")),
        credentialDisplayText = cursor.getString(cursor.getColumnIndexOrThrow("credential_display_text")),
        gameName = cursor.getString(cursor.getColumnIndexOrThrow("game_name")),
        gamePlatformId = cursor.getLong(cursor.getColumnIndexOrThrow("game_platform_id")),
        gamePlatformName = cursor.getString(cursor.getColumnIndexOrThrow("game_platform_name")),
        gamePlatformBundleId = cursor.getString(cursor.getColumnIndexOrThrow("game_platform_bundle_id")),
        playerAccessToken = cursor.getString(cursor.getColumnIndexOrThrow("player_access_token")),
        playerUsername = cursor.getString(cursor.getColumnIndexOrThrow("player_username")),
        lastUpdated = cursor.getLong(cursor.getColumnIndexOrThrow("last_updated"))
    )
}