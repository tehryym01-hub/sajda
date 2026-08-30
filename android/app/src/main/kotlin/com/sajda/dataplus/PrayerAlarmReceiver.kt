package com.sajda.dataplus

import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.media.RingtoneManager
import android.net.Uri
import android.os.Build
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
            .setAutoCancel(true)
            .setSound(soundUri)
            .setVibrate(if (mode == "full" && !isReminder) longArrayOf(0, 800, 400, 800) else longArrayOf(0, 300, 200, 300))
            .setFullScreenIntent(pendingIntent, true)
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

