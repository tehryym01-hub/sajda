package\ com\.sajda\.dataplus

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.os.Build
import android.util.Log
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.engine.FlutterEngineCache
import io.flutter.embedding.engine.dart.DartExecutor
import io.flutter.plugin.common.MethodChannel
import java.util.concurrent.Executors

class PrayerNotificationBootReceiver : BroadcastReceiver() {
    private val TAG = "PrayerBootReceiver"
    private val CHANNEL = "com\.sajda\.dataplus/prayer_notifications"

    override fun onReceive(context: Context, intent: Intent) {
        val action = intent.action ?: return
        if (action == Intent.ACTION_BOOT_COMPLETED ||
            action == Intent.ACTION_MY_PACKAGE_REPLACED ||
            action == "android.intent.action.QUICKBOOT_POWERON" ||
            action == "com.htc.intent.action.QUICKBOOT_POWERON"
        ) {
            Log.d(TAG, "Boot completed - rescheduling prayer notifications")

            // Get or create FlutterEngine
            val engine = FlutterEngineCache.getInstance().get("prayer_engine") ?: FlutterEngine(context).apply {
                this.dartExecutor.executeDartEntrypoint(
                    DartExecutor.DartEntrypoint.createDefault()
                )
                FlutterEngineCache.getInstance().put("prayer_engine", this)
            }

            val channel = MethodChannel(engine.dartExecutor.binaryMessenger, CHANNEL)
            
            // Use a background thread for the async call
            Executors.newSingleThreadExecutor().execute {
                try {
                    val result = channel.invokeMethod("reschedulePrayerNotifications", null)
                    Log.d(TAG, "Prayer notifications rescheduled: $result")
                } catch (e: Exception) {
                    Log.e(TAG, "Failed to reschedule prayer notifications", e)
                }
            }
        }
    }
}

