package com.digitalvision.angela_dress

import android.app.AlarmManager
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import java.util.UUID

class BootReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        val action = intent.action
        if (action == Intent.ACTION_BOOT_COMPLETED ||
            action == Intent.ACTION_MY_PACKAGE_REPLACED ||
            action == "android.intent.action.QUICKBOOT_POWERON" ||
            action == "com.htc.intent.action.QUICKBOOT_POWERON") {

            val alarmManager = context.getSystemService(Context.ALARM_SERVICE) as? AlarmManager ?: return
            val plan = AlarmStorage.getPlan(context)
            val now = System.currentTimeMillis()
            val oneDayAgo = now - (24 * 60 * 60 * 1000L)

            for (item in plan) {
                if (item.scheduledAtMs > now) {
                    // Alarme future : replanifier
                    AlarmScheduler.scheduleAlarmItem(context, alarmManager, item)
                } else if (item.scheduledAtMs >= oneDayAgo) {
                    // Alarme manquée pendant l'extinction (< 24h) : consigner missed
                    AlarmStorage.recordEvent(
                        context,
                        AlarmEvent(
                            id = UUID.randomUUID().toString(),
                            alarmId = item.id,
                            alertKeys = item.alertKeys,
                            outcome = "missed",
                            timestampMs = item.scheduledAtMs,
                            source = "boot_missed"
                        )
                    )
                }
            }
        }
    }
}

