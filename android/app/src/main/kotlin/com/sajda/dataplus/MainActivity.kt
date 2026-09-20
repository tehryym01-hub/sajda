package com.sajda.dataplus

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
                    val triggerAtMillis = (call.argument<Number>("triggerAtMillis") ?: 0L).toLong()
                    val hour = call.argument<Int>("hour") ?: 0
                    val minute = call.argument<Int>("minute") ?: 0
                    val isUrdu = call.argument<Boolean>("isUrdu") ?: false
                    val isReminder = call.argument<Boolean>("isReminder") ?: false
                    val mode = call.argument<String>("mode") ?: "full"
                    val notificationId = call.argument<Int>("notificationId") ?: 9000
                    val city = call.argument<String>("city")

                    val intent = PrayerAlarmScheduler.buildIntent(
                        this, prayerName, triggerAtMillis,
                        String.format("%02d:%02d", hour, minute),
                        isUrdu, isReminder, mode, notificationId, city
                    )
                    val success = PrayerAlarmScheduler.schedule(this, intent, notificationId)
                    result.success(success)
                }

                "cancelAlarm" -> {
                    val notificationId = call.argument<Int>("notificationId") ?: 9000
                    PrayerAlarmScheduler.cancel(this, notificationId)
                    result.success(true)
                }

                "cancelAllAlarms" -> {
                    PrayerAlarmScheduler.cancelAll(this)
                    result.success(true)
                }

                "vibrate" -> {
                    // Dart ints decode as java Integer — an argument<Long>
                    // cast throws ClassCastException and used to die here
                    // SILENTLY (success(false)), which is why release builds
                    // never vibrated. Read as Number and convert.
                    val duration = (call.argument<Number>("duration") ?: 50L).toLong()
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
                        Log.w(TAG, "Native vibrate failed: ${e.message}")
                        // Report the failure so the Dart side can fall back
                        // to HapticFeedback instead of silently doing nothing.
                        result.error("VIBRATE_FAILED", e.message, null)
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

    companion object {
        private const val TAG = "MainActivity"
    }
}

