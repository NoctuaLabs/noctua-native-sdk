package com.noctuagames.sdk

import android.content.ContentProvider
import android.content.ContentValues
import android.content.Context
import android.content.UriMatcher
import android.database.Cursor
import android.database.sqlite.SQLiteDatabase
import android.database.sqlite.SQLiteOpenHelper
import android.net.Uri

class AccountContentProvider : ContentProvider() {

    companion object {
        const val AUTHORITY = "com.noctuagames.sdk.provider"
        val CONTENT_URI: Uri = Uri.parse("content://$AUTHORITY/accounts")
    }

    private lateinit var dbHelper: DatabaseHelper

    override fun onCreate(): Boolean {
        dbHelper = DatabaseHelper(context!!)

        return true
    }

    override fun query(
        uri: Uri, projection: Array<out String>?, selection: String?,
        selectionArgs: Array<out String>?, sortOrder: String?
    ): Cursor? {
        return dbHelper
            .readableDatabase
            .query("accounts", projection, selection, selectionArgs, null, null, sortOrder)
    }

    override fun insert(uri: Uri, values: ContentValues?): Uri? {
        val db = dbHelper.writableDatabase
        val id = db.insert("accounts", null, values)

        context?.contentResolver?.notifyChange(uri, null)

        return Uri.withAppendedPath(CONTENT_URI, id.toString())
    }

    override fun update(
        uri: Uri,
        values: ContentValues?,
        selection: String?,
        selectionArgs: Array<out String>?
    ): Int {
        val count = dbHelper
            .writableDatabase
            .updateWithOnConflict(
                "accounts",
                values,
                selection,
                selectionArgs,
                SQLiteDatabase.CONFLICT_REPLACE
            )

        context?.contentResolver?.notifyChange(uri, null)

        return count
    }

    override fun delete(uri: Uri, selection: String?, selectionArgs: Array<out String>?): Int {
        val count = dbHelper
            .writableDatabase
            .delete("accounts", selection, selectionArgs)

        context?.contentResolver?.notifyChange(uri, null)

        return count
    }

    override fun getType(uri: Uri): String {
        return "vnd.android.cursor.dir/vnd.$AUTHORITY.accounts"
    }

    private class DatabaseHelper(context: Context) :
        SQLiteOpenHelper(context, "accounts.db", null, 1) {
        override fun onCreate(db: SQLiteDatabase) {
            db.execSQL(
                """
                CREATE TABLE accounts (
                    user_id INTEGER NOT NULL,
                    game_id INTEGER NOT NULL,
                    player_id INTEGER NOT NULL,
                    user_is_guest BOOLEAN,
                    user_nickname TEXT,
                    user_email TEXT, 
                    credential_id INTEGER,
                    credential_provider TEXT,
                    credential_display_text TEXT,
                    game_name TEXT,
                    game_platform_id INTEGER,
                    game_platform_name TEXT,
                    game_platform_bundle_id TEXT,
                    player_access_token TEXT NOT NULL,
                    player_username TEXT,
                    last_updated TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                    PRIMARY KEY (user_id, game_id) ON CONFLICT REPLACE
                )
            """
            )
        }

        override fun onUpgrade(db: SQLiteDatabase, oldVersion: Int, newVersion: Int) {
            db.execSQL("DROP TABLE IF EXISTS accounts")
            onCreate(db)
        }

        override fun onDowngrade(db: SQLiteDatabase, oldVersion: Int, newVersion: Int) {
            onUpgrade(db, oldVersion, newVersion)
        }
    }
}