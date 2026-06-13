package com.example.snehsaathi.data.local

import androidx.room.Database
import androidx.room.RoomDatabase
import com.example.snehsaathi.data.local.dao.ConversationDao
import com.example.snehsaathi.data.local.dao.HealthLogDao
import com.example.snehsaathi.data.local.dao.MedicationDao
import com.example.snehsaathi.data.local.dao.MemoryDao
import com.example.snehsaathi.data.local.entity.ConversationEntity
import com.example.snehsaathi.data.local.entity.HealthLogEntity
import com.example.snehsaathi.data.local.entity.MedicationEntity
import com.example.snehsaathi.data.local.entity.MemoryEntity

@Database(
    entities = [
        ConversationEntity::class,
        MemoryEntity::class,
        MedicationEntity::class,
        HealthLogEntity::class
    ],
    version = 1,
    exportSchema = false
)
abstract class AppDatabase : RoomDatabase() {
    abstract fun conversationDao(): ConversationDao
    abstract fun memoryDao(): MemoryDao
    abstract fun medicationDao(): MedicationDao
    abstract fun healthLogDao(): HealthLogDao
}
