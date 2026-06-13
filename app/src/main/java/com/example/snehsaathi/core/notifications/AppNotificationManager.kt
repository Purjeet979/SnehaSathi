package com.example.snehsaathi.core.notifications

import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.os.Build
import androidx.core.app.NotificationCompat
import com.example.snehsaathi.R
import com.example.snehsaathi.ui.main.MainActivity
import dagger.hilt.android.qualifiers.ApplicationContext
import javax.inject.Inject
import javax.inject.Singleton

@Singleton
class AppNotificationManager @Inject constructor(
    @ApplicationContext private val context: Context
) {
    private val notificationManager = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
    private val CHANNEL_ID = "sneh_saathi_reminders"

    init {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                CHANNEL_ID,
                "Reminders",
                NotificationManager.IMPORTANCE_HIGH
            ).apply {
                description = "Reminders for Medications and Security"
            }
            notificationManager.createNotificationChannel(channel)
        }
    }

    fun showMedicationNotification(medName: String) {
        val intent = Intent(context, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TASK
            putExtra("target_screen", "MEDS")
        }
        val pendingIntent = PendingIntent.getActivity(
            context, 100, intent, PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        val builder = NotificationCompat.Builder(context, CHANNEL_ID)
            .setSmallIcon(R.drawable.sneh_saathi_logo) // Using logo as fallback
            .setContentTitle("दवाई का समय (Medicine Time)")
            .setContentText("$medName लेने का समय हो गया है।")
            .setPriority(NotificationCompat.PRIORITY_HIGH)
            .setCategory(NotificationCompat.CATEGORY_ALARM)
            .setContentIntent(pendingIntent)
            .setAutoCancel(true)
            .setFullScreenIntent(pendingIntent, true) // Wakes up screen

        notificationManager.notify(1001, builder.build())
    }

    fun showSecurityNotification() {
        val intent = Intent(context, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TASK
            putExtra("target_screen", "SECURITY")
        }
        val pendingIntent = PendingIntent.getActivity(
            context, 101, intent, PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        val builder = NotificationCompat.Builder(context, CHANNEL_ID)
            .setSmallIcon(R.drawable.sneh_saathi_logo)
            .setContentTitle("सुरक्षा जाँच (Security Check)")
            .setContentText("रात हो गई है, दरवाज़ा और गैस चेक कर लें।")
            .setPriority(NotificationCompat.PRIORITY_HIGH)
            .setCategory(NotificationCompat.CATEGORY_ALARM)
            .setContentIntent(pendingIntent)
            .setAutoCancel(true)
            .setFullScreenIntent(pendingIntent, true) // Wakes up screen

        notificationManager.notify(1002, builder.build())
    }
}
