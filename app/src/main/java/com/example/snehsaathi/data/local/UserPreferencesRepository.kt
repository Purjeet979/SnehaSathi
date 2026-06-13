package com.example.snehsaathi.data.local

import android.content.Context
import androidx.datastore.core.DataStore
import androidx.datastore.preferences.core.*
import androidx.datastore.preferences.preferencesDataStore
import dagger.hilt.android.qualifiers.ApplicationContext
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.map
import javax.inject.Inject
import javax.inject.Singleton

private val Context.dataStore: DataStore<Preferences> by preferencesDataStore("user_prefs")

@Singleton
class UserPreferencesRepository @Inject constructor(
    @ApplicationContext context: Context
) {
    private val dataStore = context.dataStore

    companion object {
        val DADI_NAME = stringPreferencesKey("dadi_name")
        val VOICE_SPEED = floatPreferencesKey("voice_speed")
        val FONT_SIZE_SCALE = floatPreferencesKey("font_size_scale")
        val EMERGENCY_CONTACT = stringPreferencesKey("emergency_contact")
        val MED_REMINDERS_ENABLED = booleanPreferencesKey("med_reminders")
    }

    val dadiName: Flow<String> = dataStore.data.map { it[DADI_NAME] ?: "Dadi" }
    val voiceSpeed: Flow<Float> = dataStore.data.map { it[VOICE_SPEED] ?: 1.1f }

    suspend fun setDadiName(name: String) {
        dataStore.edit { it[DADI_NAME] = name }
    }

    suspend fun setEmergencyContact(phone: String) {
        dataStore.edit { it[EMERGENCY_CONTACT] = phone }
    }
}
