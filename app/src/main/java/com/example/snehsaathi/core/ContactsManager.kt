package com.example.snehsaathi.core

import android.content.Context
import android.content.SharedPreferences
import com.google.gson.Gson
import com.google.gson.reflect.TypeToken

data class Contact(val name: String, val number: String)

object ContactsManager {
    private const val PREFS_NAME = "snehsaathi_contacts"
    private const val KEY_CONTACTS = "contacts_list"

    private fun getPrefs(context: Context): SharedPreferences {
        return context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
    }

    fun getContacts(context: Context): List<Contact> {
        val json = getPrefs(context).getString(KEY_CONTACTS, null)
        if (json.isNullOrEmpty()) return emptyList()
        val type = object : TypeToken<List<Contact>>() {}.type
        return Gson().fromJson(json, type)
    }

    fun saveContact(context: Context, contact: Contact) {
        val currentContacts = getContacts(context).toMutableList()
        currentContacts.add(contact)
        val json = Gson().toJson(currentContacts)
        getPrefs(context).edit().putString(KEY_CONTACTS, json).apply()
    }
    
    fun removeContact(context: Context, contact: Contact) {
        val currentContacts = getContacts(context).toMutableList()
        currentContacts.remove(contact)
        val json = Gson().toJson(currentContacts)
        getPrefs(context).edit().putString(KEY_CONTACTS, json).apply()
    }
}
