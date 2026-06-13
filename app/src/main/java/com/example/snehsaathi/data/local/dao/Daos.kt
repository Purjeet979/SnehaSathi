package com.example.snehsaathi.data.local.dao

import androidx.room.Dao
import androidx.room.Insert
import androidx.room.Query
import com.example.snehsaathi.data.local.entity.ConversationEntity
import com.example.snehsaathi.data.local.entity.HealthLogEntity
import com.example.snehsaathi.data.local.entity.MedicationEntity
import com.example.snehsaathi.data.local.entity.MemoryEntity

@Dao
interface MemoryDao {
    @Insert
    suspend fun insert(memory: MemoryEntity)

    @Query("SELECT * FROM memories")
    suspend fun getAll(): List<MemoryEntity>
}

@Dao
interface ConversationDao {
    @Insert
    suspend fun insert(conversation: ConversationEntity)

    @Query("SELECT * FROM conversations ORDER BY timestamp DESC")
    suspend fun getAll(): List<ConversationEntity>
}

@Dao
interface MedicationDao {
    @Insert
    suspend fun insert(medication: MedicationEntity)
}

@Dao
interface HealthLogDao {
    @Insert
    suspend fun insert(healthLog: HealthLogEntity)

    @Query("SELECT * FROM health_logs WHERE timestamp >= :sinceTimestamp ORDER BY timestamp DESC")
    suspend fun getRecentLogs(sinceTimestamp: Long): List<HealthLogEntity>
}
