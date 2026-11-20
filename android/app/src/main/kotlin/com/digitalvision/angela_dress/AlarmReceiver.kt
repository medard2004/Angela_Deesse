package com.digitalvision.angela_dress

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.os.PowerManager
import androidx.core.app.NotificationManagerCompat
import androidx.core.content.ContextCompat
import java.util.UUID

class AlarmReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        val alarmId = intent.getIntExtra("alarm_id", 0)
        val title = intent.getStringExtra("title") ?: "Rappel"
        val body = intent.getStringExtra("body") ?: "Rappel d'atelier"
        val alertKeys = intent.getStringArrayListExtra("alert_keys") ?: arrayListOf()

        // GARDE-FOU ABSOLU : Ne JAMAIS faire sonner une alarme si les notifications sont désactivées !
        // Sans notification, Android bloque l'UI (bannière et plein écran). L'alarme serait inarrêtable.
        val notificationManager = NotificationManagerCompat.from(context)
        if (!notificationManager.areNotificationsEnabled()) {
            AlarmStorage.recordEvent(
                context,
                AlarmEvent(
                    id = UUID.randomUUID().toString(),
                    alarmId = alarmId,
                    alertKeys = alertKeys,
                    outcome = "blocked_missing_permission",
                    timestampMs = System.currentTimeMillis(),
                    source = "alarm_receiver_permission_check"
                )
            )
            return
        }

        // Réveil du CPU par un WakeLock partiel (15 secondes max pour démarrer le service)
        val powerManager = context.getSystemService(Context.POWER_SERVICE) as? PowerManager
        val wakeLock = powerManager?.newWakeLock(
            PowerManager.PARTIAL_WAKE_LOCK,
            "angela:alarm_receiver_wake_lock"
        )
        wakeLock?.acquire(15000L)

        // Enregistrer l'événement fired
        AlarmStorage.recordEvent(
            context,
            AlarmEvent(
                id = UUID.randomUUID().toString(),
                alarmId = alarmId,
                alertKeys = alertKeys,
                outcome = "fired",
                timestampMs = System.currentTimeMillis(),
                source = "alarm_receiver"
            )
        )

        val serviceIntent = Intent(context, AlarmService::class.java).apply {
            action = AlarmService.ACTION_START_ALARM
            putExtra("alarm_id", alarmId)
            putExtra("title", title)
            putExtra("body", body)
            putStringArrayListExtra("alert_keys", alertKeys)
        }

        ContextCompat.startForegroundService(context, serviceIntent)
    }
}

