package com.digitalvision.angela_dress

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.os.PowerManager
import androidx.core.content.ContextCompat
import java.util.UUID

class AlarmReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        val alarmId = intent.getIntExtra("alarm_id", 0)
        val title = intent.getStringExtra("title") ?: "Rappel"
        val body = intent.getStringExtra("body") ?: "Rappel d'atelier"
        val alertKeys = intent.getStringArrayListExtra("alert_keys") ?: arrayListOf()

        // Si l'application est au premier plan ET déverrouillée :
        // Déclencher le bandeau in-app sans service d'arrière-plan ni notification push !
        if (MainActivity.isForegroundAndUnlocked()) {
            val notified = MainActivity.notifyInAppAlarm(alarmId, title, body, alertKeys)
            if (notified) {
                // Enregistrer l'événement 'displayed' dans le journal des alarmes
                AlarmStorage.recordEvent(
                    context,
                    AlarmEvent(
                        id = UUID.randomUUID().toString(),
                        alarmId = alarmId,
                        alertKeys = alertKeys,
                        outcome = "displayed",
                        timestampMs = System.currentTimeMillis(),
                        source = "in_app_banner"
                    )
                )
                return
            }
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

