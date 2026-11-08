package com.digitalvision.angela_dress

import org.json.JSONObject
import org.junit.Assert.*
import org.junit.Test

class AlarmEngineTest {

    @Test
    fun testNativeAlarmPlanItemSerialization() {
        val item = NativeAlarmPlanItem(
            id = 12345,
            scheduledAtMs = 1793980800000L,
            title = "Livraison demain",
            body = "2 commandes",
            alertKeys = listOf("livraison:demain:ord1:2026-11-08", "livraison:demain:ord2:2026-11-08")
        )

        val json = item.toJson()
        assertEquals(12345, json.getInt("id"))
        assertEquals(1793980800000L, json.getLong("scheduledAtMs"))
        assertEquals("Livraison demain", json.getString("title"))
        assertEquals("2 commandes", json.getString("body"))
        assertEquals(2, json.getJSONArray("alertKeys").length())

        val restored = NativeAlarmPlanItem.fromJson(json)
        assertEquals(item.id, restored.id)
        assertEquals(item.scheduledAtMs, restored.scheduledAtMs)
        assertEquals(item.title, restored.title)
        assertEquals(item.body, restored.body)
        assertEquals(item.alertKeys, restored.alertKeys)
    }

    @Test
    fun testAlarmEventTransitionsAndSerialization() {
        val now = 1793980800000L

        // 1. Événement fired (déclenchement)
        val firedEvent = AlarmEvent(
            id = "evt_fired_1",
            alarmId = 100,
            alertKeys = listOf("key1"),
            outcome = "fired",
            timestampMs = now,
            source = "alarm_receiver"
        )
        val firedJson = firedEvent.toJson()
        val restoredFired = AlarmEvent.fromJson(firedJson)
        assertEquals("fired", restoredFired.outcome)
        assertEquals("alarm_receiver", restoredFired.source)

        // 2. Événement stopped (utilisatrice appuie sur Arrêter)
        val stoppedEvent = AlarmEvent(
            id = "evt_stopped_1",
            alarmId = 100,
            alertKeys = listOf("key1"),
            outcome = "stopped",
            timestampMs = now + 15000L, // 15s après
            source = "alarm_activity"
        )
        assertEquals("stopped", stoppedEvent.outcome)
        assertEquals("alarm_activity", stoppedEvent.source)

        // 3. Événement snoozed (utilisatrice appuie sur Reporter 10 min)
        val snoozedEvent = AlarmEvent(
            id = "evt_snoozed_1",
            alarmId = 100,
            alertKeys = listOf("key1"),
            outcome = "snoozed",
            timestampMs = now + 20000L,
            source = "notification_action",
            snoozeCount = 1
        )
        assertEquals("snoozed", snoozedEvent.outcome)
        assertEquals(1, snoozedEvent.snoozeCount)

        // 4. Événement missed (expiration 5 min / 300s)
        val missedEvent = AlarmEvent(
            id = "evt_missed_1",
            alarmId = 100,
            alertKeys = listOf("key1"),
            outcome = "missed",
            timestampMs = now + 300000L,
            source = "timeout_5min"
        )
        assertEquals("missed", missedEvent.outcome)
        assertEquals("timeout_5min", missedEvent.source)
    }

    @Test
    fun testEventMailboxDeduplicationAndDrain() {
        val mailbox = mutableListOf<AlarmEvent>()

        fun record(event: AlarmEvent) {
            mailbox.removeAll { it.id == event.id }
            mailbox.add(event)
        }

        fun drain(): List<AlarmEvent> {
            val copy = ArrayList(mailbox)
            mailbox.clear()
            return copy
        }

        // Ajouter 3 événements
        val e1 = AlarmEvent("evt_1", 1, listOf("k1"), "fired", 1000L, "alarm_receiver")
        val e2 = AlarmEvent("evt_2", 1, listOf("k1"), "opened", 2000L, "alarm_activity")
        val e3 = AlarmEvent("evt_3", 1, listOf("k1"), "stopped", 3000L, "alarm_activity")

        record(e1)
        record(e2)
        record(e3)

        assertEquals(3, mailbox.size)

        // Dédoublonnage : réinsérer e2 avec un outcome mis à jour
        val e2Updated = AlarmEvent("evt_2", 1, listOf("k1"), "opened", 2500L, "alarm_activity")
        record(e2Updated)

        assertEquals(3, mailbox.size)
        assertEquals(2500L, mailbox.first { it.id == "evt_2" }.timestampMs)

        // Drainer la boîte aux lettres
        val drained = drain()
        assertEquals(3, drained.size)
        assertTrue(mailbox.isEmpty())

        // Un second drain est vide
        val drainedAgain = drain()
        assertTrue(drainedAgain.isEmpty())
    }

    @Test
    fun testTimeoutDurationIsFiveMinutes() {
        assertEquals(300000L, AlarmService.TIMEOUT_MS)
    }
}

