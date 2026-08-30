package com.sajda.dataplus

import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.media.AudioAttributes
import android.net.Uri
import android.os.Build
import android.os.PowerManager
import android.util.Log
import androidx.core.app.NotificationCompat

class PrayerAlarmReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        val prayerName = intent.getStringExtra(EXTRA_PRAYER_NAME) ?: "Prayer"
        val isUrdu = intent.getBooleanExtra(EXTRA_IS_URDU, false)
        val isReminder = intent.getBooleanExtra(EXTRA_IS_REMINDER, false)
        val prayerTime = intent.getStringExtra(EXTRA_PRAYER_TIME) ?: ""
        val notificationId = intent.getIntExtra(EXTRA_NOTIFICATION_ID, -1)
        val mode = intent.getStringExtra(EXTRA_MODE) ?: "full"

        if (notificationId == -1) return

        Log.d(TAG, "Alarm received for: $prayerName (mode: $mode)")

        // Wake up screen
        try {
            val pm = context.getSystemService(Context.POWER_SERVICE) as PowerManager
            val wakeLock = pm.newWakeLock(
                PowerManager.FULL_WAKE_LOCK or PowerManager.ACQUIRE_CAUSES_WAKEUP or PowerManager.ON_AFTER_RELEASE,
                "sajda:azan_alarm"
            )
            wakeLock.acquire(10 * 1000L)
            wakeLock.release()
        } catch (e: Exception) {
            Log.e(TAG, "Failed to acquire wake lock", e)
        }

        try {
            showPrayerNotification(context, prayerName, isUrdu, isReminder, prayerTime, notificationId, mode)
        } catch (e: Exception) {
            Log.e(TAG, "Failed to show notification", e)
        }
    }

    private fun showPrayerNotification(
        context: Context,
        prayerName: String,
        isUrdu: Boolean,
        isReminder: Boolean,
        prayerTime: String,
        notificationId: Int,
        mode: String
    ) {
        val notificationManager = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager

        val channelId = if (isReminder) "prayer_reminders" else "prayer_azan_alerts"
        val channelName = if (isReminder) "Prayer Reminders" else "Prayer Azan Alerts"
        val title: String
        val body: String

        if (isUrdu) {
            if (isReminder) {
                title = "نماز میں صرف 10 منٹ باقی"
                body = "کاموں سے فارغ ہو جائیں، وقت پر نماز پڑھیں"
            } else {
                title = "$prayerName کا وقت ہو گیا - اللہ اکبر"
                body = "نماز کا وقت شروع ہو گیا ہے۔ اللہ اکبر، اللہ اکبر"
            }
        } else {
            if (isReminder) {
                title = "Only 10 minutes left for $prayerName"
                body = "Free yourself from work - pray on time"
            } else {
                title = "It's $prayerName time - Allahu Akbar"
                body = "Prayer time has started. Allahu Akbar, Allahu Akbar"
            }
        }

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val soundUri = Uri.parse("android.resource://${context.packageName}/raw/adhan")
            val audioAttributes = AudioAttributes.Builder()
                .setUsage(AudioAttributes.USAGE_ALARM)
                .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION)
                .build()

            val channel = NotificationChannel(
                channelId,
                channelName,
                NotificationManager.IMPORTANCE_HIGH
            ).apply {
                description = if (isReminder) {
                    "Reminder 10 minutes before every prayer time"
                } else {
                    "Azan sound at every prayer time"
                }
                setSound(soundUri, audioAttributes)
                lockscreenVisibility = android.app.Notification.VISIBILITY_PUBLIC
                if (mode == "full" && !isReminder) {
                    enableVibration(true)
                    vibrationPattern = longArrayOf(0, 800, 400, 800)
                } else {
                    enableVibration(true)
                    vibrationPattern = longArrayOf(0, 300, 200, 300)
                }
            }
            notificationManager.createNotificationChannel(channel)
        }

        val intent = context.packageManager.getLaunchIntentForPackage(context.packageName)
        val pendingIntent = PendingIntent.getActivity(
            context,
            notificationId,
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        val soundUri = Uri.parse("android.resource://${context.packageName}/raw/adhan")

        val notification = NotificationCompat.Builder(context, channelId)
            .setContentTitle(title)
            .setContentText(body)
            .setSmallIcon(context.applicationInfo.icon)
            .setContentIntent(pendingIntent)
            .setPriority(NotificationCompat.PRIORITY_HIGH)
            .setCategory(NotificationCompat.CATEGORY_ALARM)
            .setVisibility(NotificationCompat.VISIBILITY_PUBLIC)
            .setAutoCancel(true)
            .setSound(soundUri)
            .setVibrate(if (mode == "full" && !isReminder) longArrayOf(0, 800, 400, 800) else longArrayOf(0, 300, 200, 300))
            .build()

        notificationManager.notify(notificationId, notification)
        Log.d(TAG, "Notification shown: $prayerName (id: $notificationId)")
    }

    companion object {
        const val TAG = "PrayerAlarmReceiver"
        const val EXTRA_PRAYER_NAME = "prayer_name"
        const val EXTRA_IS_URDU = "is_urdu"
        const val EXTRA_IS_REMINDER = "is_reminder"
        const val EXTRA_PRAYER_TIME = "prayer_time"
        const val EXTRA_NOTIFICATION_ID = "notification_id"
        const val EXTRA_MODE = "mode"
    }
}

