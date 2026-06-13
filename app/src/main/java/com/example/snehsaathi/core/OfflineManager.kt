package com.example.snehsaathi.core

import android.content.Context
import androidx.room.Dao
import androidx.room.Database
import androidx.room.Entity
import androidx.room.Insert
import androidx.room.OnConflictStrategy
import androidx.room.PrimaryKey
import androidx.room.Query
import androidx.room.Room
import androidx.room.RoomDatabase
import java.util.UUID

@Entity(tableName = "cached_responses")
data class CachedResponse(
    @PrimaryKey val id: String = UUID.randomUUID().toString(),
    val userInput: String,
    val aiResponse: String,
    val timestamp: Long = System.currentTimeMillis()
)

@Dao
interface CachedResponseDao {
    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insert(response: CachedResponse)

    @Query("SELECT * FROM cached_responses ORDER BY timestamp DESC LIMIT 5")
    suspend fun getRecent(): List<CachedResponse>
}

@Database(entities = [CachedResponse::class], version = 1, exportSchema = false)
abstract class OfflineDatabase : RoomDatabase() {
    abstract fun cachedResponseDao(): CachedResponseDao
}

object OfflineManager {
    private var db: OfflineDatabase? = null

    fun init(context: Context) {
        if (db == null) {
            db = Room.databaseBuilder(
                context.applicationContext,
                OfflineDatabase::class.java, "snehsaathi-offline.db"
            )
                .fallbackToDestructiveMigration()
                .allowMainThreadQueries()
                .build()
        }
    }

    suspend fun getRecent(): List<CachedResponse> {
        return db?.cachedResponseDao()?.getRecent() ?: emptyList()
    }

    suspend fun insert(response: CachedResponse) {
        db?.cachedResponseDao()?.insert(response)
    }
}
