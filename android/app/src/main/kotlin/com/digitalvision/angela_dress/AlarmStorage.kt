package com.digitalvision.angela_dress

import android.content.Context
import android.content.SharedPreferences
import org.json.JSONArray
import org.json.JSONObject

object AlarmStorage {
    private const val PREFS_NAME = "angela_alarm_engine_prefs"
    private const val KEY_PLAN = "alarm_plan_json"
    private const val KEY_EVENTS = "alarm_events_mailbox_json"

    private fun getPrefs(context: Context): SharedPreferences {
        return context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
    }

    @Synchronized
    fun savePlan(context: Context, items: List<NativeAlarmPlanItem>) {
        val array = JSONArray()
        items.forEach { array.put(it.toJson()) }
        getPrefs(context).edit().putString(KEY_PLAN, array.toString()).apply()
    }

    @Synchronized
    fun getPlan(context: Context): List<NativeAlarmPlanItem> {
        val raw = getPrefs(context).getString(KEY_PLAN, null) ?: return emptyList()
        val list = mutableListOf<NativeAlarmPlanItem>()
        try {
            val array = JSONArray(raw)
            for (i in 0 until array.length()) {
                list.add(NativeAlarmPlanItem.fromJson(array.getJSONObject(i)))
            }
        } catch (_: Exception) {}
        return list
    }

    @Synchronized
    fun recordEvent(context: Context, event: AlarmEvent) {
        val events = getEventsInternal(context).toMutableList()
        // Dédoublonnage sur id
        events.removeAll { it.id == event.id }
        events.add(event)
        val array = JSONArray()
        events.forEach { array.put(it.toJson()) }
        getPrefs(context).edit().putString(KEY_EVENTS, array.toString()).apply()
    }

    @Synchronized
    fun drainEvents(context: Context): List<AlarmEvent> {
        val events = getEventsInternal(context)
        getPrefs(context).edit().remove(KEY_EVENTS).apply()
        return events
    }

    private fun getEventsInternal(context: Context): List<AlarmEvent> {
        val raw = getPrefs(context).getString(KEY_EVENTS, null) ?: return emptyList()
        val list = mutableListOf<AlarmEvent>()
        try {
            val array = JSONArray(raw)
            for (i in 0 until array.length()) {
                list.add(AlarmEvent.fromJson(array.getJSONObject(i)))
            }
        } catch (_: Exception) {}
        return list
    }
}

