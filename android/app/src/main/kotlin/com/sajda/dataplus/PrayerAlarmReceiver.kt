package com.sajda.dataplus

import android.app.AlarmManager
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.graphics.Bitmap
import android.graphics.Canvas
import android.media.AudioAttributes
import android.media.RingtoneManager
import android.net.Uri
import android.os.Build
import android.util.Log
import androidx.core.app.NotificationCompat

class PrayerAlarmReceiver : BroadcastReceiver() {

    override fun onReceive(context: Context, intent: Intent) {
        val prayerName = intent.getStringExtra(PrayerAlarmScheduler.EXTRA_PRAYER_NAME) ?: "Prayer"
        val isUrdu = intent.getBooleanExtra(PrayerAlarmScheduler.EXTRA_IS_URDU, false)
        val isReminder = intent.getBooleanExtra(PrayerAlarmScheduler.EXTRA_IS_REMINDER, false)
        val prayerTime = intent.getStringExtra(PrayerAlarmScheduler.EXTRA_PRAYER_TIME) ?: ""
        val city = intent.getStringExtra(PrayerAlarmScheduler.EXTRA_CITY) ?: ""
        val notificationId = intent.getIntExtra(PrayerAlarmScheduler.EXTRA_NOTIFICATION_ID, -1)
        val mode = intent.getStringExtra(PrayerAlarmScheduler.EXTRA_MODE) ?: "full"

        if (notificationId == -1) return

        Log.d(TAG, "Alarm received for: $prayerName (mode: $mode, reminder: $isReminder)")

        // Keep the chain alive: reschedule this alarm for tomorrow so azan
        // never stops firing even if the app isn't opened for days. The
        // precise schedule is refreshed whenever the app IS opened.
        try {
            PrayerAlarmScheduler.rescheduleNextDay(context, intent, notificationId)
        } catch (e: Exception) {
            Log.w(TAG, "Self-reschedule failed: ${e.message}")
        }

        try {
            showPrayerNotification(
                context, prayerName, isUrdu, isReminder, prayerTime,
                city, notificationId, mode
            )
        } catch (e: Exception) {
            Log.e(TAG, "Failed to show notification", e)
        }
    }

    private fun channelFor(isReminder: Boolean, mode: String): Pair<String, String> {
        return when {
            isReminder -> CHANNEL_REMINDER to "Prayer Reminders"
            mode == "silent" -> CHANNEL_SILENT to "Silent Prayer Alerts"
            else -> CHANNEL_AZAN to "Prayer Azan Alerts"
        }
    }

    private fun ensureChannel(
        context: Context,
        notificationManager: NotificationManager,
        id: String,
        name: String,
        isReminder: Boolean,
        isSilent: Boolean
    ) {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return
        if (notificationManager.getNotificationChannel(id) != null) return

        val channel = NotificationChannel(id, name, NotificationManager.IMPORTANCE_HIGH).apply {
            lockscreenVisibility = android.app.Notification.VISIBILITY_PUBLIC
            if (isSilent) {
                setSound(null, null)
                enableVibration(false)
            } else if (isReminder) {
                // Short default notification sound — NEVER the full adhan.
                setSound(
                    RingtoneManager.getDefaultUri(RingtoneManager.TYPE_NOTIFICATION),
                    AudioAttributes.Builder()
                        .setUsage(AudioAttributes.USAGE_NOTIFICATION)
                        .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION)
                        .build()
                )
                enableVibration(true)
                vibrationPattern = longArrayOf(0, 300, 200, 300)
            } else {
                // Full azan on the alarm stream, like a real alarm clock.
                setSound(
                    Uri.parse("android.resource://${context.packageName}/raw/adhan"),
                    AudioAttributes.Builder()
                        .setUsage(AudioAttributes.USAGE_ALARM)
                        .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION)
                        .build()
                )
                enableVibration(true)
                vibrationPattern = longArrayOf(0, 800, 400, 800)
            }
        }
        notificationManager.createNotificationChannel(channel)
    }

    private fun appIconBitmap(context: Context): Bitmap? {
        return try {
            val drawable = context.applicationInfo.loadIcon(context.packageManager)
            val bmp = Bitmap.createBitmap(
                drawable.intrinsicWidth.coerceAtLeast(1),
                drawable.intrinsicHeight.coerceAtLeast(1),
                Bitmap.Config.ARGB_8888
            )
            val canvas = Canvas(bmp)
            drawable.setBounds(0, 0, canvas.width, canvas.height)
            drawable.draw(canvas)
            bmp
        } catch (e: Exception) {
            null
        }
    }

    private fun showPrayerNotification(
        context: Context,
        prayerName: String,
        isUrdu: Boolean,
        isReminder: Boolean,
        prayerTime: String,
        city: String,
        notificationId: Int,
        mode: String
    ) {
        val notificationManager =
            context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager

        val (channelId, channelName) = channelFor(isReminder, mode)
        val isSilentAzan = !isReminder && mode == "silent"
        val isAzan = !isReminder && mode == "full"
        ensureChannel(context, notificationManager, channelId, channelName, isReminder, isSilentAzan)

        val citySuffix = if (city.isNotEmpty()) {
            if (isUrdu) " — $city" else " — $city"
        } else ""

        val title: String
        val body: String
        if (isReminder) {
            title = if (isUrdu) {
                "$prayerName میں صرف 10 منٹ باقی"
            } else {
                "$prayerName in 10 minutes"
            }
            body = if (isUrdu) {
                "وضو کی تیاری کریں$citySuffix"
            } else {
                "Prepare for prayer — wudu and get ready$citySuffix"
            }
        } else {
            title = if (isUrdu) {
                "$prayerName کا وقت ہو گیا — اللہ اکبر"
            } else {
                "$prayerName time — Allahu Akbar"
            }
            body = if (isUrdu) {
                "اللہ اکبر، اللہ اکبر — نماز کا وقت شروع ہو گیا ہے$citySuffix"
            } else {
                "Allahu Akbar, Allahu Akbar — prayer time has started$citySuffix"
            }
        }

        val launchIntent = context.packageManager.getLaunchIntentForPackage(context.packageName)
        val contentPending = PendingIntent.getActivity(
            context,
            notificationId,
            launchIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        val builder = NotificationCompat.Builder(context, channelId)
            .setSmallIcon(R.drawable.ic_stat_mosque)
            .apply { appIconBitmap(context)?.let { setLargeIcon(it) } }
            .setContentTitle(title)
            .setContentText(body)
            .setStyle(
                NotificationCompat.BigTextStyle()
                    .bigText(if (isReminder) body else "$body\n${if (isUrdu) "وقت: $prayerTime" else "Time: $prayerTime"}")
            )
            .setContentIntent(contentPending)
            .setPriority(NotificationCompat.PRIORITY_HIGH)
            .setCategory(
                if (isAzan) NotificationCompat.CATEGORY_ALARM
                else NotificationCompat.CATEGORY_REMINDER
            )
            .setVisibility(NotificationCompat.VISIBILITY_PUBLIC)
            .setColor(BRAND_COLOR)
            .setAutoCancel(!isAzan)
            .setOngoing(isAzan)
            .setShowWhen(true)

        if (isAzan) {
            // Full-bleed branded alarm banner (allowed for CATEGORY_ALARM).
            builder.setColorized(true)
            if (!isSilentAzan) {
                builder.setVibrate(longArrayOf(0, 800, 400, 800))
            }

            val stopLabel = if (isUrdu) "اذان بند کریں" else "Stop Azan"
            val stopIntent = Intent(context, AzanStopReceiver::class.java).apply {
                putExtra(AzanStopReceiver.EXTRA_NOTIFICATION_ID, notificationId)
            }
            val stopPending = PendingIntent.getBroadcast(
                context,
                notificationId,
                stopIntent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )
            builder.addAction(0, stopLabel, stopPending)

            // Auto-stop after 4 minutes (adhan.ogg is ~3-4 min) — a
            // forgotten ongoing notification must not linger forever.
            try {
                val am = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
                val autoStop = PendingIntent.getBroadcast(
                    context,
                    notificationId + AUTO_STOP_REQUEST_OFFSET,
                    stopIntent,
                    PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
                )
                am.set(
                    AlarmManager.RTC,
                    System.currentTimeMillis() + 4 * 60 * 1000L,
                    autoStop
                )
            } catch (e: Exception) {
                Log.w(TAG, "Auto-stop schedule failed: ${e.message}")
            }
        }

        notificationManager.notify(notificationId, builder.build())
        Log.d(TAG, "Notification shown: $prayerName (id: $notificationId, azan=$isAzan, silent=$isSilentAzan)")
    }

    companion object {
        private const val TAG = "PrayerAlarmReceiver"
        private const val CHANNEL_AZAN = "prayer_azan_alerts"
        private const val CHANNEL_SILENT = "prayer_azan_silent"
        private const val CHANNEL_REMINDER = "prayer_reminders"
        private const val AUTO_STOP_REQUEST_OFFSET = 100000
        private val BRAND_COLOR = 0xFF0F4C35.toInt()
    }
}
