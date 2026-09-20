package com.sajda.dataplus

import android.app.AlarmManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.os.Build
import android.util.Log

/**
 * Shared AlarmManager scheduling for prayer azan + reminders.
 *
 * - Schedules at absolute epoch millis (timezone-correct instants computed
 *   on the Dart side), NOT wall-clock hour/minute, so the alarm fires at
 *   the right moment even when the device timezone differs from the
 *   selected location.
 * - Uses exact alarms when the user granted SCHEDULE_EXACT_ALARM and
 *   silently falls back to inexact `setAndAllowWhileIdle` otherwise —
 *   scheduling NEVER hard-fails just because the permission is missing
 *   (inexact alarms may drift a few minutes in Doze).
 * - Every scheduled intent carries all its own extras (including the
 *   trigger instant) so [PrayerAlarmReceiver] can reschedule itself +24h
 *   and keep azan firing even if the app isn't opened for days.
 */
object PrayerAlarmScheduler {
    private const val TAG = "PrayerAlarmScheduler"

    const val EXTRA_PRAYER_NAME = "prayer_name"
    const val EXTRA_IS_URDU = "is_urdu"
    const val EXTRA_IS_REMINDER = "is_reminder"
    const val EXTRA_PRAYER_TIME = "prayer_time"
    const val EXTRA_NOTIFICATION_ID = "notification_id"
    const val EXTRA_MODE = "mode"
    const val EXTRA_TRIGGER_AT_MILLIS = "trigger_at_millis"
    const val EXTRA_CITY = "city"

    fun buildIntent(
        context: Context,
        prayerName: String,
        triggerAtMillis: Long,
        prayerTime: String,
        isUrdu: Boolean,
        isReminder: Boolean,
        mode: String,
        notificationId: Int,
        city: String?
    ): Intent = Intent(context, PrayerAlarmReceiver::class.java).apply {
        putExtra(EXTRA_PRAYER_NAME, prayerName)
        putExtra(EXTRA_TRIGGER_AT_MILLIS, triggerAtMillis)
        putExtra(EXTRA_PRAYER_TIME, prayerTime)
        putExtra(EXTRA_IS_URDU, isUrdu)
        putExtra(EXTRA_IS_REMINDER, isReminder)
        putExtra(EXTRA_MODE, mode)
        putExtra(EXTRA_NOTIFICATION_ID, notificationId)
        if (!city.isNullOrEmpty()) putExtra(EXTRA_CITY, city)
    }

    /** Returns true if an alarm was actually scheduled (exact OR inexact). */
    fun schedule(context: Context, intent: Intent, notificationId: Int): Boolean {
        return try {
            val alarmManager = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
            val pendingIntent = PendingIntent.getBroadcast(
                context,
                notificationId,
                intent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )
            val triggerAt = intent.getLongExtra(EXTRA_TRIGGER_AT_MILLIS, 0L)

            val canExact = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                alarmManager.canScheduleExactAlarms()
            } else {
                true
            }

            if (canExact && Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                alarmManager.setExactAndAllowWhileIdle(
                    AlarmManager.RTC_WAKEUP, triggerAt, pendingIntent
                )
            } else if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                // Exact-alarm permission not granted: fall back to a
                // battery-friendly inexact alarm instead of failing — the
                // azan may drift a few minutes in Doze, but it still fires.
                alarmManager.setAndAllowWhileIdle(
                    AlarmManager.RTC_WAKEUP, triggerAt, pendingIntent
                )
            } else {
                alarmManager.setExact(AlarmManager.RTC_WAKEUP, triggerAt, pendingIntent)
            }

            Log.d(TAG, "Alarm #$notificationId scheduled at $triggerAt (exact=$canExact)")
            true
        } catch (e: Exception) {
            Log.e(TAG, "Failed to schedule alarm #${'$'}notificationId", e)
            false
        }
    }

    /** Schedules the same alarm one day later (self-rescheduling chain). */
    fun rescheduleNextDay(context: Context, intent: Intent, notificationId: Int): Boolean {
        val next = Intent(intent).apply {
            putExtra(
                EXTRA_TRIGGER_AT_MILLIS,
                intent.getLongExtra(EXTRA_TRIGGER_AT_MILLIS, 0L) + DAY_MILLIS
            )
        }
        return schedule(context, next, notificationId)
    }

    fun cancel(context: Context, notificationId: Int) {
        try {
            val alarmManager = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
            val intent = Intent(context, PrayerAlarmReceiver::class.java)
            val pendingIntent = PendingIntent.getBroadcast(
                context,
                notificationId,
                intent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )
            alarmManager.cancel(pendingIntent)
            pendingIntent.cancel()
        } catch (e: Exception) {
            Log.e(TAG, "Failed to cancel alarm #$notificationId", e)
        }
    }

    fun cancelAll(context: Context) {
        for (id in 9000 until 9010) cancel(context, id)
        for (id in 8000 until 8010) cancel(context, id)
    }

    private const val DAY_MILLIS = 24L * 60L * 60L * 1000L
}
