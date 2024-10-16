package com.noctuagames.sdk

import android.content.Context
import android.database.sqlite.SQLiteDatabase
import android.database.sqlite.SQLiteOpenHelper
import android.os.Environment
import java.io.File

class PackageDatabaseHelper(context: Context) :
    SQLiteOpenHelper(context, getDatabasePath(), null, DATABASE_VERSION) {

    override fun onCreate(db: SQLiteDatabase?) {
        db?.execSQL(SQL_CREATE_ENTRIES)
    }

    override fun onUpgrade(db: SQLiteDatabase?, oldVersion: Int, newVersion: Int) {
        db?.execSQL(SQL_DELETE_ENTRIES)

        if (db != null) {
            onCreate(db)
        }
    }

    companion object {
        private const val DATABASE_NAME = "noctua_packages.db"
        private const val DATABASE_VERSION = 1

        private const val SQL_CREATE_ENTRIES =
            """
            CREATE TABLE installed_packages (
                package_name TEXT PRIMARY KEY,
                last_success INTEGER,
                last_fail INTEGER
            )
            """

        private const val SQL_DELETE_ENTRIES = "DROP TABLE IF EXISTS installed_packages"

        fun getDatabasePath(): String {
            val externalStorageDir = Environment.getExternalStorageDirectory().resolve("Applications/noctua")

            if (!externalStorageDir.exists()) {
                externalStorageDir.mkdirs()
            }

            val dbFile = File("$externalStorageDir", DATABASE_NAME)

            return dbFile.absolutePath
        }
    }
}
