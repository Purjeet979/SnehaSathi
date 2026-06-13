package com.example.snehsaathi.core.notifications

import android.content.Context
import dagger.hilt.android.qualifiers.ApplicationContext
import javax.inject.Inject
import javax.inject.Singleton

@Singleton
class AppNotificationManager @Inject constructor(
    @ApplicationContext private val context: Context
) {
    fun showMedicationNotification(medName: String) {
        // Implementation for showing a notification using NotificationManager
    }
}
