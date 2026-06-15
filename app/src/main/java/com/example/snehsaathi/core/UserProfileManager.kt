package com.example.snehsaathi.core

import android.content.Context
import android.content.SharedPreferences

data class UserProfile(val name: String, val relation: String, val language: String = "hi", val dialect: String = "Standard", val city: String = "")

object UserProfileManager {
    private const val PREFS_NAME = "snehsaathi_user_profile"
    private const val KEY_NAME = "user_name"
    private const val KEY_RELATION = "user_relation"
    private const val KEY_LANGUAGE = "user_language"
    private const val KEY_DIALECT = "user_dialect"
    private const val KEY_CITY = "user_city"

    private fun getPrefs(context: Context): SharedPreferences {
        return context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
    }

    fun getProfile(context: Context): UserProfile? {
        val prefs = getPrefs(context)
        val name = prefs.getString(KEY_NAME, null)
        val relation = prefs.getString(KEY_RELATION, null)
        val language = prefs.getString(KEY_LANGUAGE, "hi") ?: "hi"
        val dialect = prefs.getString(KEY_DIALECT, "Standard") ?: "Standard"
        val city = prefs.getString(KEY_CITY, "") ?: ""
        
        return if (name != null && relation != null) {
            UserProfile(name, relation, language, dialect, city)
        } else {
            null
        }
    }

    fun saveProfile(context: Context, profile: UserProfile) {
        getPrefs(context).edit()
            .putString(KEY_NAME, profile.name)
            .putString(KEY_RELATION, profile.relation)
            .putString(KEY_LANGUAGE, profile.language)
            .putString(KEY_DIALECT, profile.dialect)
            .putString(KEY_CITY, profile.city)
            .apply()
    }

    fun updateLanguage(context: Context, language: String) {
        getPrefs(context).edit().putString(KEY_LANGUAGE, language).apply()
    }

    fun updateDialect(context: Context, dialect: String) {
        getPrefs(context).edit().putString(KEY_DIALECT, dialect).apply()
    }
    
    fun clearProfile(context: Context) {
        getPrefs(context).edit().clear().apply()
    }
}
