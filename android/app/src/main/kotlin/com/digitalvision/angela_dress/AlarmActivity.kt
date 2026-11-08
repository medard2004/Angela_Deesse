package com.digitalvision.angela_dress

import android.app.Activity
import android.content.Intent
import android.graphics.Color
import android.graphics.Typeface
import android.graphics.drawable.GradientDrawable
import android.os.Build
import android.os.Bundle
import android.view.Gravity
import android.view.View
import android.view.WindowManager
import android.widget.Button
import android.widget.LinearLayout
import android.widget.TextView
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale

class AlarmActivity : Activity() {

    private var alarmId: Int = 0
    private var titleText: String = "Rappel"
    private var bodyText: String = ""
    private var alertKeys: ArrayList<String> = arrayListOf()

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        // Configuration pour passer au-dessus de l'écran de verrouillage et allumer l'écran
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O_MR1) {
            setShowWhenLocked(true)
            setTurnScreenOn(true)
        } else {
            @Suppress("DEPRECATION")
            window.addFlags(
                WindowManager.LayoutParams.FLAG_SHOW_WHEN_LOCKED or
                WindowManager.LayoutParams.FLAG_TURN_SCREEN_ON or
                WindowManager.LayoutParams.FLAG_DISMISS_KEYGUARD or
                WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON
            )
        }

        alarmId = intent.getIntExtra("alarm_id", 0)
        titleText = intent.getStringExtra("title") ?: "Rappel"
        bodyText = intent.getStringExtra("body") ?: ""
        alertKeys = intent.getStringArrayListExtra("alert_keys") ?: arrayListOf()

        // Enregistrer l'événement 'opened'
        AlarmStorage.recordEvent(
            this,
            AlarmEvent(
                id = java.util.UUID.randomUUID().toString(),
                alarmId = alarmId,
                alertKeys = alertKeys,
                outcome = "opened",
                timestampMs = System.currentTimeMillis(),
                source = "alarm_activity"
            )
        )

        val root = createView()
        setContentView(root)
    }

    private fun createView(): View {
        val root = LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
            setBackgroundColor(Color.parseColor("#0B1021")) // Thème sombre profond
            gravity = Gravity.CENTER_HORIZONTAL
            setPadding(48, 80, 48, 80)
        }

        // Heure actuelle
        val timeFormat = SimpleDateFormat("HH:mm", Locale.getDefault())
        val timeTv = TextView(this).apply {
            text = timeFormat.format(Date())
            setTextColor(Color.WHITE)
            textSize = 56f
            typeface = Typeface.create("sans-serif-light", Typeface.NORMAL)
            gravity = Gravity.CENTER
            setPadding(0, 40, 0, 20)
        }
        root.addView(timeTv)

        // Titre public (ex: "Livraison demain")
        val titleTv = TextView(this).apply {
            text = titleText
            setTextColor(Color.WHITE)
            textSize = 24f
            typeface = Typeface.DEFAULT_BOLD
            gravity = Gravity.CENTER
            setPadding(0, 10, 0, 8)
        }
        root.addView(titleTv)

        // Corps public (ex: "2 commandes")
        val bodyTv = TextView(this).apply {
            text = bodyText
            setTextColor(Color.parseColor("#94A3B8")) // Slate gris doux
            textSize = 17f
            gravity = Gravity.CENTER
            setPadding(0, 0, 0, 80)
        }
        root.addView(bodyTv)

        // Espace flexible
        val spacer = View(this).apply {
            layoutParams = LinearLayout.LayoutParams(
                LinearLayout.LayoutParams.MATCH_PARENT,
                0,
                1.0f
            )
        }
        root.addView(spacer)

        // Bouton ARRÊTER (Rouge vif #DC2626)
        val stopBtn = Button(this).apply {
            text = "ARRÊTER"
            setTextColor(Color.WHITE)
            textSize = 17f
            typeface = Typeface.DEFAULT_BOLD
            val bg = GradientDrawable().apply {
                setColor(Color.parseColor("#DC2626"))
                cornerRadius = 28f
            }
            background = bg
            layoutParams = LinearLayout.LayoutParams(
                LinearLayout.LayoutParams.MATCH_PARENT,
                140
            ).apply {
                setMargins(0, 0, 0, 24)
            }
            setOnClickListener {
                stopAlarmAndFinish()
            }
        }
        root.addView(stopBtn)

        // Bouton REPORTER 10 min (Bleu roi #1747B8)
        val snoozeBtn = Button(this).apply {
            text = "REPORTER 10 min"
            setTextColor(Color.WHITE)
            textSize = 16f
            typeface = Typeface.DEFAULT_BOLD
            val bg = GradientDrawable().apply {
                setColor(Color.parseColor("#1747B8"))
                cornerRadius = 28f
            }
            background = bg
            layoutParams = LinearLayout.LayoutParams(
                LinearLayout.LayoutParams.MATCH_PARENT,
                140
            ).apply {
                setMargins(0, 0, 0, 36)
            }
            setOnClickListener {
                snoozeAlarmAndFinish()
            }
        }
        root.addView(snoozeBtn)

        // Bouton discret « Voir dans l'application »
        val viewInAppBtn = TextView(this).apply {
            text = "Voir dans l'application"
            setTextColor(Color.parseColor("#94A3B8"))
            textSize = 14f
            gravity = Gravity.CENTER
            setPadding(20, 20, 20, 20)
            setOnClickListener {
                openAppNotifications()
            }
        }
        root.addView(viewInAppBtn)

        return root
    }

    private fun stopAlarmAndFinish() {
        val serviceIntent = Intent(this, AlarmService::class.java).apply {
            action = AlarmService.ACTION_STOP_ALARM
            putExtra("outcome", "stopped")
            putExtra("source", "alarm_activity")
        }
        startService(serviceIntent)
        finish()
    }

    private fun snoozeAlarmAndFinish() {
        val serviceIntent = Intent(this, AlarmService::class.java).apply {
            action = AlarmService.ACTION_STOP_ALARM
            putExtra("outcome", "snoozed")
            putExtra("source", "alarm_activity")
        }
        startService(serviceIntent)
        AlarmScheduler.snoozeAlarm(this, alarmId, titleText, bodyText, alertKeys, 10)
        finish()
    }

    private fun openAppNotifications() {
        stopAlarmAndFinish()
        val appIntent = Intent(this, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
            putExtra("open_notifications", true)
        }
        startActivity(appIntent)
    }

    @Suppress("DEPRECATION")
    override fun onBackPressed() {
        stopAlarmAndFinish()
        super.onBackPressed()
    }
}

