package com.example.snehsaathi.features.security

import android.content.Context
import androidx.hilt.work.HiltWorker
import androidx.work.Worker
import androidx.work.WorkerParameters
import com.example.snehsaathi.core.notifications.AppNotificationManager
import dagger.assisted.Assisted
import dagger.assisted.AssistedInject

@HiltWorker
class SecurityReminderWorker @AssistedInject constructor(
    @Assisted context: Context,
    @Assisted params: WorkerParameters,
    private val notificationManager: AppNotificationManager
) : Worker(context, params) {

    override fun doWork(): Result {
        notificationManager.showSecurityNotification()
        return Result.success()
    }
}
