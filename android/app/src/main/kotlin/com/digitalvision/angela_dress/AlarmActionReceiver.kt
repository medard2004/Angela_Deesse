package com.digitalvision.angela_dress

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent

class AlarmActionReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        val action = intent.action ?: return
        val alarmId = intent.getIntExtra("alarm_id", 0)
        val title = intent.getStringExtra("title") ?: "Rappel"
        val body = intent.getStringExtra("body") ?: ""
        val alertKeys = intent.getStringArrayListExtra("alert_keys") ?: arrayListOf()

        when (action) {
            AlarmService.ACTION_DISMISS -> {
                val serviceIntent = Intent(context, AlarmService::class.java).apply {
                    this.action = AlarmService.ACTION_STOP_ALARM
                    putExtra("outcome", "stopped")
                    putExtra("source", "notification_action")
                }
                context.startService(serviceIntent)
            }
            AlarmService.ACTION_SNOOZE -> {
                val serviceIntent = Intent(context, AlarmService::class.java).apply {
                    this.action = AlarmService.ACTION_STOP_ALARM
                    putExtra("outcome", "snoozed")
                    putExtra("source", "notification_action")
                }
                context.startService(serviceIntent)
                AlarmScheduler.snoozeAlarm(context, alarmId, title, body, alertKeys, 10)
            }
        }
    }
}

