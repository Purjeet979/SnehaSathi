package com.example.snehsaathi.features.medication

import android.content.Context
import androidx.hilt.work.HiltWorker
import androidx.work.CoroutineWorker
import androidx.work.WorkerParameters
import com.example.snehsaathi.core.notifications.AppNotificationManager
import com.example.snehsaathi.core.tts.OfflineTtsManager
import dagger.assisted.Assisted
import dagger.assisted.AssistedInject

@HiltWorker
class MedicationReminderWorker @AssistedInject constructor(
    @Assisted context: Context,
    @Assisted params: WorkerParameters,
    private val offlineTtsManager: OfflineTtsManager,
    private val notificationManager: AppNotificationManager
) : CoroutineWorker(context, params) {

    override suspend fun doWork(): Result {
        val medName = inputData.getString("med_name") ?: return Result.failure()
        val message = "दवाई का समय हो गया है। $medName लेना मत भूलिए।"
        
        // Works offline — no network needed
        offlineTtsManager.speak(message)
        notificationManager.showMedicationNotification(medName)
        
        return Result.success()
    }
}
