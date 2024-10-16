package com.noctuagames.sdk

import android.content.ContentValues
import android.content.Context
import android.database.Cursor
import android.database.sqlite.SQLiteDatabase

data class PackageInfo(
    val packageName: String,
    val lastSuccess: Long? = System.currentTimeMillis(),
    val lastFail: Long? = null
)

class PackageRepository(context: Context) {
    private val dbHelper = PackageDatabaseHelper(context)

    fun insertOrUpdatePackage(packageInfo: PackageInfo) {
        val db = dbHelper.writableDatabase

        val values = ContentValues().apply {
            put("package_name", packageInfo.packageName)
            packageInfo.lastSuccess?.let { put("last_success", it) }
            packageInfo.lastFail?.let { put("last_fail", it) }
        }

        db.insertWithOnConflict("installed_packages", null, values, SQLiteDatabase.CONFLICT_REPLACE)
        db.close()
    }

    fun getPackageInfo(packageName: String): PackageInfo? {
        val db = dbHelper.readableDatabase
        val cursor: Cursor = db.query(
            "installed_packages",
            arrayOf("last_success", "last_fail"),
            "package_name = ?",
            arrayOf(packageName),
            null,
            null,
            null
        )

        val result = if (cursor.moveToFirst()) {
            PackageInfo(
                packageName,
                cursor.getLong(cursor.getColumnIndexOrThrow("last_success")),
                cursor.getLong(cursor.getColumnIndexOrThrow("last_fail"))
            )
        } else {
            null
        }

        cursor.close()
        db.close()

        return result
    }

    fun getAllPackageInfos(): List<PackageInfo> {
        val packageList = mutableListOf<PackageInfo>()
        val db = dbHelper.readableDatabase
        val cursor: Cursor = db.query(
            "installed_packages",
            arrayOf("package_name", "last_success", "last_fail"),
            null,
            null,
            null,
            null,
            null
        )

        with(cursor) {
            while (moveToNext()) {
                val packageName = getString(getColumnIndexOrThrow("package_name"))
                val lastSuccess = getLong(getColumnIndexOrThrow("last_success"))
                val lastFail = getLong(getColumnIndexOrThrow("last_fail"))
                packageList.add(PackageInfo(packageName, lastSuccess, lastFail))
            }
        }

        cursor.close()
        db.close()

        return packageList
    }

    fun removePackage(packageName: String) {
        val db = dbHelper.writableDatabase
        db.delete("installed_packages", "package_name = ?", arrayOf(packageName))
        db.close()
    }
}
