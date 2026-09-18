package com.sajda.dataplus

import android.app.NotificationManager
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.util.Log

/// Cancels the ongoing azan notification — fired by the "Stop Azan"
/// notification action, or by the 4-minute auto-stop alarm.
class AzanStopReceiver : BroadcastReceiver() {

    override fun onReceive(context: Context, intent: Intent) {
        val id = intent.getIntExtra(EXTRA_NOTIFICATION_ID, -1)
        if (id == -1) {
            Log.w(TAG, "Stop received without notification id")
            return
        }
        val nm = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        nm.cancel(id)
        Log.d(TAG, "Azan notification stopped (id: $id)")
    }

    companion object {
        const val EXTRA_NOTIFICATION_ID = "notification_id"
        private const val TAG = "AzanStopReceiver"
    }
}
