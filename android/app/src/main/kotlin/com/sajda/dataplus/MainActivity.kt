package com.sajda.dataplus

import android.app.AlarmManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.os.Build
import android.os.VibrationEffect
import android.os.Vibrator
import android.os.VibratorManager
import android.util.Log
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private var pendingDeepLink: String? = null
    private var deepLinkChannel: MethodChannel? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        deepLinkChannel = MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "sajda/deeplink"
        ).also { channel ->
            channel.setMethodCallHandler { call, result ->
                when (call.method) {
                    "consumeLink" -> {
                        result.success(pendingDeepLink)
                        pendingDeepLink = null
                    }
                    else -> result.notImplemented()
                }
            }
        }

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "sajda/prayer_alarm"
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "scheduleAlarm" -> {
                    val prayerName = call.argument<String>("prayerName") ?: ""
                    val hour = call.argument<Int>("hour") ?: 0
                    val minute = call.argument<Int>("minute") ?: 0
                    val isUrdu = call.argument<Boolean>("isUrdu") ?: false
                    val isReminder = call.argument<Boolean>("isReminder") ?: false
                    val mode = call.argument<String>("mode") ?: "full"
                    val notificationId = call.argument<Int>("notificationId") ?: 9000

                    val success = schedulePrayerAlarm(
                        this, prayerName, hour, minute, isUrdu, isReminder, mode, notificationId
                    )
                    result.success(success)
                }

                "cancelAlarm" -> {
                    val notificationId = call.argument<Int>("notificationId") ?: 9000
                    cancelPrayerAlarm(this, notificationId)
                    result.success(true)
                }

                "cancelAllAlarms" -> {
                    cancelAllPrayerAlarms(this)
                    result.success(true)
                }

                "vibrate" -> {
                    val duration = call.argument<Long>("duration") ?: 50L
                    try {
                        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                            val vibratorManager = getSystemService(Context.VIBRATOR_MANAGER_SERVICE) as VibratorManager
                            val vibrator = vibratorManager.defaultVibrator
                            vibrator.vibrate(VibrationEffect.createOneShot(duration, VibrationEffect.DEFAULT_AMPLITUDE))
                        } else {
                            @Suppress("DEPRECATION")
                            val vibrator = getSystemService(Context.VIBRATOR_SERVICE) as Vibrator
                            @Suppress("DEPRECATION")
                            vibrator.vibrate(VibrationEffect.createOneShot(duration, VibrationEffect.DEFAULT_AMPLITUDE))
                        }
                        result.success(true)
                    } catch (e: Exception) {
                        result.success(false)
                    }
                }

                else -> result.notImplemented()
            }
        }
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        handleDeepLinkIntent(intent)
    }

    override fun onCreate(savedInstanceState: android.os.Bundle?) {
        super.onCreate(savedInstanceState)
        handleDeepLinkIntent(intent)
    }

    private fun handleDeepLinkIntent(intent: Intent?) {
        val data = intent?.data ?: return
        val isSajdaLink = data.scheme == "sajda" && (data.host == "join" || data.host == "restore")
        // Firebase email-link sign-in lands on https://<project>.firebaseapp.com/__/auth/action
        val isAuthLink = data.scheme == "https" &&
            (data.host == "sajda-b8dce.firebaseapp.com" || data.host == "sajda-b8dce.web.app") &&
            (data.path?.startsWith("/__/auth") == true || data.getQueryParameter("oobCode") != null)
        if (isSajdaLink || isAuthLink) {
            val link = data.toString()
            val handler = deepLinkChannel
            if (handler != null) {
                handler.invokeMethod("onLink", link)
            } else {
                pendingDeepLink = link
            }
        }
    }

    private fun schedulePrayerAlarm(
        context: Context,
        prayerName: String,
        hour: Int,
        minute: Int,
        isUrdu: Boolean,
        isReminder: Boolean,
        mode: String,
        notificationId: Int
    ): Boolean {
        try {
            val alarmManager = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
            val intent = Intent(context, PrayerAlarmReceiver::class.java).apply {
                putExtra(PrayerAlarmReceiver.EXTRA_PRAYER_NAME, prayerName)
                putExtra(PrayerAlarmReceiver.EXTRA_IS_URDU, isUrdu)
                putExtra(PrayerAlarmReceiver.EXTRA_IS_REMINDER, isReminder)
                putExtra(PrayerAlarmReceiver.EXTRA_PRAYER_TIME, String.format("%02d:%02d", hour, minute))
                putExtra(PrayerAlarmReceiver.EXTRA_NOTIFICATION_ID, notificationId)
                putExtra(PrayerAlarmReceiver.EXTRA_MODE, mode)
            }

            val pendingIntent = PendingIntent.getBroadcast(
                context,
                notificationId,
                intent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )

            val now = System.currentTimeMillis()
            val calendar = java.util.Calendar.getInstance().apply {
                set(java.util.Calendar.HOUR_OF_DAY, hour)
                set(java.util.Calendar.MINUTE, minute)
                set(java.util.Calendar.SECOND, 0)
                set(java.util.Calendar.MILLISECOND, 0)
                if (timeInMillis <= now) {
                    add(java.util.Calendar.DAY_OF_MONTH, 1)
                }
            }

            val triggerTime = calendar.timeInMillis

            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                val canSchedule = alarmManager.canScheduleExactAlarms()
                if (!canSchedule) {
                    Log.w(TAG, "Cannot schedule exact alarms - permission not granted")
                    return false
                }
            }

            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                alarmManager.setExactAndAllowWhileIdle(
                    AlarmManager.RTC_WAKEUP,
                    triggerTime,
                    pendingIntent
                )
            } else {
                alarmManager.setExact(AlarmManager.RTC_WAKEUP, triggerTime, pendingIntent)
            }

            Log.d(TAG, "Alarm scheduled for $prayerName at ${calendar.time} (id: $notificationId)")
            return true
        } catch (e: Exception) {
            Log.e(TAG, "Failed to schedule alarm for $prayerName", e)
            return false
        }
    }

    private fun cancelPrayerAlarm(context: Context, notificationId: Int) {
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
            Log.e(TAG, "Failed to cancel alarm", e)
        }
    }

    private fun cancelAllPrayerAlarms(context: Context) {
        for (id in 9000 until 9010) {
            cancelPrayerAlarm(context, id)
        }
        for (id in 8000 until 8010) {
            cancelPrayerAlarm(context, id)
        }
    }

    companion object {
        private const val TAG = "MainActivity"
    }
}

