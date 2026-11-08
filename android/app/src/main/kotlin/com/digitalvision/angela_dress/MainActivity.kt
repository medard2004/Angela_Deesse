package com.digitalvision.angela_dress

import android.app.AlarmManager
import android.app.NotificationManager
import android.content.Context
import android.content.Intent
import android.os.Build
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val ENGINE_CHANNEL = "com.digitalvision.angela_dress/alarm_engine"
    private var pendingOpenNotifications: Boolean = false

    override fun onCreate(savedInstanceState: android.os.Bundle?) {
        super.onCreate(savedInstanceState)
        handleIntent(intent)
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        handleIntent(intent)
    }

    private fun handleIntent(intent: Intent?) {
        if (intent?.getBooleanExtra("open_notifications", false) == true) {
            pendingOpenNotifications = true
        }
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, ENGINE_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "replacePlan" -> {
                    try {
                        val rawList = call.argument<List<Map<String, Any>>>("items") ?: emptyList()
                        val items = rawList.map { map ->
                            val id = (map["id"] as? Number)?.toInt() ?: 0
                            val scheduledAtMs = (map["scheduledAtMs"] as? Number)?.toLong() ?: 0L
                            val title = map["title"] as? String ?: ""
                            val body = map["body"] as? String ?: ""
                            @Suppress("UNCHECKED_CAST")
                            val alertKeys = (map["alertKeys"] as? List<String>) ?: emptyList()
                            NativeAlarmPlanItem(id, scheduledAtMs, title, body, alertKeys)
                        }
                        AlarmScheduler.replacePlan(applicationContext, items)
                        result.success(true)
                    } catch (e: Exception) {
                        result.error("PLAN_ERROR", e.message, null)
                    }
                }
                "drainEvents" -> {
                    try {
                        val events = AlarmStorage.drainEvents(applicationContext)
                        val list = events.map { event ->
                            mapOf(
                                "id" to event.id,
                                "alarmId" to event.alarmId,
                                "alertKeys" to event.alertKeys,
                                "outcome" to event.outcome,
                                "timestampMs" to event.timestampMs,
                                "source" to event.source,
                                "snoozeCount" to event.snoozeCount
                            )
                        }
                        result.success(list)
                    } catch (e: Exception) {
                        result.error("DRAIN_ERROR", e.message, null)
                    }
                }
                "canScheduleExactAlarms" -> {
                    val am = getSystemService(Context.ALARM_SERVICE) as? AlarmManager
                    val canExact = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                        am?.canScheduleExactAlarms() ?: true
                    } else {
                        true
                    }
                    result.success(canExact)
                }
                "canUseFullScreenIntent" -> {
                    val nm = getSystemService(Context.NOTIFICATION_SERVICE) as? NotificationManager
                    val canFullScreen = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.UPSIDE_DOWN_CAKE) {
                        nm?.canUseFullScreenIntent() ?: true
                    } else {
                        true
                    }
                    result.success(canFullScreen)
                }
                "stopAlarm" -> {
                    val serviceIntent = Intent(applicationContext, AlarmService::class.java).apply {
                        action = AlarmService.ACTION_STOP_ALARM
                        putExtra("outcome", "stopped")
                        putExtra("source", "dart_bridge")
                    }
                    startService(serviceIntent)
                    result.success(true)
                }
                "consumeOpenNotifications" -> {
                    val wasPending = pendingOpenNotifications
                    pendingOpenNotifications = false
                    result.success(wasPending)
                }
                else -> result.notImplemented()
            }
        }
    }
}
