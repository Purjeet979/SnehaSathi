package com.example.snehsaathi.features.family

import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.Build
import androidx.core.app.NotificationCompat
import androidx.work.CoroutineWorker
import androidx.work.WorkerParameters
import com.example.snehsaathi.R
import com.example.snehsaathi.core.ContactsManager
import com.example.snehsaathi.core.SarvamClient
import com.example.snehsaathi.core.UserProfileManager
import com.example.snehsaathi.data.local.AppDatabase
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext

class GhostwriterWorker(
    private val context: Context,
    params: WorkerParameters
) : CoroutineWorker(context, params) {

    private var appDatabase: AppDatabase? = null

    override suspend fun doWork(): Result {
        return withContext(Dispatchers.IO) {
            try {
                val contacts = ContactsManager.getContacts(context)
                if (contacts.isEmpty()) return@withContext Result.success()

                val primaryContact = contacts.first()

                // Reuse the same DB reference — close on finish
                appDatabase = androidx.room.Room.databaseBuilder(
                    context,
                    AppDatabase::class.java, "snehsaathi-main.db"
                ).build()

                val memoryDao = appDatabase!!.memoryDao()
                val sevenDaysAgo = System.currentTimeMillis() - (7 * 24 * 60 * 60 * 1000L)
                val recentMemories = memoryDao.getRecent(sevenDaysAgo)

                if (recentMemories.isEmpty()) {
                    closeDb()
                    return@withContext Result.success()
                }

                val profile = UserProfileManager.getProfile(context)
                val relation = profile?.relation ?: "Dadi/Dada"

                val memoryTexts = recentMemories.take(10).joinToString("\n- ") { it.content }

                val prompt = """
                    Aap $relation hain. Pichle 7 din ki in baaton ka ek chhota, pyar bhara summary message banaiye jo WhatsApp par bheja ja sake apni family ko.
                    Sirf message ka text likhiye, koi introduction nahi.
                    Baatein:
                    - $memoryTexts
                """.trimIndent()

                val generatedMessage = SarvamClient.chat(
                    listOf(mapOf("role" to "user", "content" to prompt))
                )

                sendNotification(generatedMessage, primaryContact.number)
                closeDb()
                return@withContext Result.success()
            } catch (e: Exception) {
                e.printStackTrace()
                closeDb()
                return@withContext Result.failure()
            }
        }
    }

    private fun closeDb() {
        appDatabase?.close()
        appDatabase = null
    }

    private fun sendNotification(message: String, phone: String) {
        val notificationManager = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        val channelId = "ghostwriter_channel"

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                channelId,
                "Family Updates",
                NotificationManager.IMPORTANCE_HIGH
            )
            notificationManager.createNotificationChannel(channel)
        }

        // Deep link — opens WhatsApp app directly if installed
        val sendIntent = Intent(Intent.ACTION_VIEW).apply {
            data = Uri.parse("whatsapp://send?phone=$phone&text=${Uri.encode(message)}")
            flags = Intent.FLAG_ACTIVITY_NEW_TASK
        }

        val pendingIntent = PendingIntent.getActivity(
            context,
            0,
            sendIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        val notification = NotificationCompat.Builder(context, channelId)
            .setSmallIcon(R.mipmap.ic_launcher)
            .setContentTitle("साप्ताहिक संदेश (Weekly Update)")
            .setContentText("आपका साप्ताहिक संदेश तैयार है। WhatsApp पर भेजने के लिए टैप करें।")
            .setPriority(NotificationCompat.PRIORITY_HIGH)
            .setAutoCancel(true)
            .setContentIntent(pendingIntent)
            .build()

        notificationManager.notify(3001, notification)
    }
}
