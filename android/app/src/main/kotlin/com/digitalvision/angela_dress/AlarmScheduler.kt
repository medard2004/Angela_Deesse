package com.digitalvision.angela_dress

import android.app.AlarmManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent

object AlarmScheduler {
    fun replacePlan(context: Context, items: List<NativeAlarmPlanItem>) {
        val alarmManager = context.getSystemService(Context.ALARM_SERVICE) as? AlarmManager ?: return
        val currentPlan = AlarmStorage.getPlan(context)

        // Annuler les alarmes existantes du plan précédent
        for (item in currentPlan) {
            val intent = Intent(context, AlarmReceiver::class.java).apply {
                action = "com.digitalvision.angela_dress.ALARM_TRIGGER"
            }
            val pendingIntent = PendingIntent.getBroadcast(
                context,
                item.id,
                intent,
                PendingIntent.FLAG_NO_CREATE or PendingIntent.FLAG_IMMUTABLE
            )
            if (pendingIntent != null) {
                alarmManager.cancel(pendingIntent)
                pendingIntent.cancel()
            }
        }

        // Sauvegarder le nouveau plan
        AlarmStorage.savePlan(context, items)

        // Programmer chaque alarme
        val now = System.currentTimeMillis()
        for (item in items) {
            if (item.scheduledAtMs > now) {
                scheduleAlarmItem(context, alarmManager, item)
            }
        }
    }

    fun scheduleAlarmItem(context: Context, alarmManager: AlarmManager, item: NativeAlarmPlanItem) {
        val intent = Intent(context, AlarmReceiver::class.java).apply {
            action = "com.digitalvision.angela_dress.ALARM_TRIGGER"
            putExtra("alarm_id", item.id)
            putExtra("title", item.title)
            putExtra("body", item.body)
            putStringArrayListExtra("alert_keys", ArrayList(item.alertKeys))
        }

        val pendingIntent = PendingIntent.getBroadcast(
            context,
            item.id,
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        val showIntent = Intent(context, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
        }
        val showPendingIntent = PendingIntent.getActivity(
            context,
            item.id,
            showIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        val alarmClockInfo = AlarmManager.AlarmClockInfo(item.scheduledAtMs, showPendingIntent)
        try {
            alarmManager.setAlarmClock(alarmClockInfo, pendingIntent)
        } catch (_: SecurityException) {
            // Fallback si permission USE_EXACT_ALARM manquante
            try {
                alarmManager.setExactAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, item.scheduledAtMs, pendingIntent)
            } catch (_: Exception) {}
        }
    }

    fun snoozeAlarm(context: Context, alarmId: Int, title: String, body: String, alertKeys: List<String>, minutes: Int = 10) {
        val alarmManager = context.getSystemService(Context.ALARM_SERVICE) as? AlarmManager ?: return
        val snoozeTimeMs = System.currentTimeMillis() + (minutes * 60 * 1000L)
        val snoozeId = (alarmId or 0x40000000) and 0x7FFFFFFF

        val item = NativeAlarmPlanItem(
            id = snoozeId,
            scheduledAtMs = snoozeTimeMs,
            title = title,
            body = body,
            alertKeys = alertKeys
        )
        scheduleAlarmItem(context, alarmManager, item)
    }
}

