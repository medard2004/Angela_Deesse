package com.digitalvision.angela_dress

import org.json.JSONArray
import org.json.JSONObject

data class AlarmEvent(
    val id: String,
    val alarmId: Int,
    val alertKeys: List<String>,
    val outcome: String, // "fired", "opened", "stopped", "snoozed", "missed"
    val timestampMs: Long,
    val source: String, // "native_activity", "notification_action", "timeout_5min", "boot_missed"
    val snoozeCount: Int = 0
) {
    fun toJson(): JSONObject {
        return JSONObject().apply {
            put("id", id)
            put("alarmId", alarmId)
            put("alertKeys", JSONArray(alertKeys))
            put("outcome", outcome)
            put("timestampMs", timestampMs)
            put("source", source)
            put("snoozeCount", snoozeCount)
        }
    }

    companion object {
        fun fromJson(json: JSONObject): AlarmEvent {
            val keysArray = json.optJSONArray("alertKeys") ?: JSONArray()
            val keysList = mutableListOf<String>()
            for (i in 0 until keysArray.length()) {
                keysList.add(keysArray.getString(i))
            }
            return AlarmEvent(
                id = json.getString("id"),
                alarmId = json.getInt("alarmId"),
                alertKeys = keysList,
                outcome = json.getString("outcome"),
                timestampMs = json.getLong("timestampMs"),
                source = json.getString("source"),
                snoozeCount = json.optInt("snoozeCount", 0)
            )
        }
    }
}

data class NativeAlarmPlanItem(
    val id: Int,
    val scheduledAtMs: Long,
    val title: String,
    val body: String,
    val alertKeys: List<String>
) {
    fun toJson(): JSONObject {
        return JSONObject().apply {
            put("id", id)
            put("scheduledAtMs", scheduledAtMs)
            put("title", title)
            put("body", body)
            put("alertKeys", JSONArray(alertKeys))
        }
    }

    companion object {
        fun fromJson(json: JSONObject): NativeAlarmPlanItem {
            val keysArray = json.optJSONArray("alertKeys") ?: JSONArray()
            val keysList = mutableListOf<String>()
            for (i in 0 until keysArray.length()) {
                keysList.add(keysArray.getString(i))
            }
            return NativeAlarmPlanItem(
                id = json.getInt("id"),
                scheduledAtMs = json.getLong("scheduledAtMs"),
                title = json.getString("title"),
                body = json.getString("body"),
                alertKeys = keysList
            )
        }
    }
}

