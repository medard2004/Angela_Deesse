package com.digitalvision.angela_dress

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.content.pm.ServiceInfo
import android.media.AudioAttributes
import android.media.AudioManager
import android.media.MediaPlayer
import android.net.Uri
import android.os.Build
import android.os.Handler
import android.os.IBinder
import android.os.Looper
import android.os.PowerManager
import android.os.VibrationEffect
import android.os.Vibrator
import android.os.VibratorManager
import androidx.core.app.NotificationCompat
import androidx.core.app.NotificationManagerCompat
import java.util.UUID

class AlarmService : Service() {

    companion object {
        const val ACTION_START_ALARM = "com.digitalvision.angela_dress.START_ALARM"
        const val ACTION_STOP_ALARM = "com.digitalvision.angela_dress.STOP_ALARM"
        const val ACTION_DISMISS = "com.digitalvision.angela_dress.DISMISS"
        const val ACTION_SNOOZE = "com.digitalvision.angela_dress.SNOOZE"

        const val CHANNEL_ALARM_ID = "alarmes_douces_v3"
        const val CHANNEL_STANDARD_ID = "notifications_standard_v1"
        const val NOTIFICATION_ID = 9999

        const val TIMEOUT_MS = 5 * 60 * 1000L // 5 minutes (300 secondes)
    }

    private var mediaPlayer: MediaPlayer? = null
    private var vibrator: Vibrator? = null
    private var wakeLock: PowerManager.WakeLock? = null
    private val handler = Handler(Looper.getMainLooper())

    private var currentAlarmId: Int = 0
    private var currentTitle: String = "Rappel"
    private var currentBody: String = ""
    private var currentAlertKeys: List<String> = emptyList()

    private var isRingerReceiverRegistered: Boolean = false
    private val ringerReceiver = object : BroadcastReceiver() {
        override fun onReceive(context: Context?, intent: Intent?) {
            if (intent?.action == AudioManager.RINGER_MODE_CHANGED_ACTION) {
                updateAudioAndVibrationForRingerMode()
            }
        }
    }

    private val timeoutRunnable = Runnable {
        onTimeoutMissed()
    }

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        if (intent == null) return START_NOT_STICKY

        when (intent.action) {
            ACTION_START_ALARM -> {
                currentAlarmId = intent.getIntExtra("alarm_id", 0)
                currentTitle = intent.getStringExtra("title") ?: "Rappel"
                currentBody = intent.getStringExtra("body") ?: ""
                currentAlertKeys = intent.getStringArrayListExtra("alert_keys") ?: emptyList()
                startAlarmForeground()
            }
            ACTION_STOP_ALARM -> {
                val outcome = intent.getStringExtra("outcome") ?: "stopped"
                val source = intent.getStringExtra("source") ?: "service_action"
                stopAlarmAndFinish(outcome, source)
            }
        }

        return START_NOT_STICKY
    }

    private fun startAlarmForeground() {
        // GARDE-FOU ABSOLU : Si l'utilisateur a désactivé les notifications pour l'app,
        // Android bloque impitoyablement toute l'interface visuelle (notification et plein écran).
        // Il est strictement interdit de faire sonner le téléphone à l'aveugle !
        val notificationManager = NotificationManagerCompat.from(this)
        if (!notificationManager.areNotificationsEnabled()) {
            AlarmStorage.recordEvent(
                this,
                AlarmEvent(
                    id = UUID.randomUUID().toString(),
                    alarmId = currentAlarmId,
                    alertKeys = currentAlertKeys,
                    outcome = "suppressed_no_permission",
                    timestampMs = System.currentTimeMillis(),
                    source = "alarm_service_permission_check"
                )
            )
            stopSelf()
            return
        }

        createNotificationChannels()
        acquireWakeLock()

        val notification = buildForegroundNotification()

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            startForeground(
                NOTIFICATION_ID,
                notification,
                ServiceInfo.FOREGROUND_SERVICE_TYPE_MEDIA_PLAYBACK
            )
        } else {
            startForeground(NOTIFICATION_ID, notification)
        }

        // Écouter les changements de mode Silencieux/Vibreur/Normal en temps réel
        if (!isRingerReceiverRegistered) {
            try {
                registerReceiver(ringerReceiver, IntentFilter(AudioManager.RINGER_MODE_CHANGED_ACTION))
                isRingerReceiverRegistered = true
            } catch (_: Exception) {}
        }

        // Démarrer audio et vibration selon l'état actuel du téléphone
        updateAudioAndVibrationForRingerMode()

        // Démarre l'activité d'alarme plein écran si possible
        launchAlarmActivity()

        // Planifie la minuterie d'arrêt de 5 minutes
        handler.removeCallbacks(timeoutRunnable)
        handler.postDelayed(timeoutRunnable, TIMEOUT_MS)
    }

    private fun updateAudioAndVibrationForRingerMode() {
        val audioManager = getSystemService(Context.AUDIO_SERVICE) as? AudioManager
        val ringerMode = audioManager?.ringerMode ?: AudioManager.RINGER_MODE_NORMAL

        when (ringerMode) {
            AudioManager.RINGER_MODE_SILENT -> {
                // Silencieux : ni son, ni vibration
                stopAudio()
                stopVibration()
            }
            AudioManager.RINGER_MODE_VIBRATE -> {
                // Vibreur : pas de son, vibration active
                stopAudio()
                if (vibrator == null) {
                    startVibration()
                }
            }
            AudioManager.RINGER_MODE_NORMAL -> {
                // Normal : son et vibration respectent les volumes du téléphone
                if (mediaPlayer == null) {
                    startAudio()
                }
                if (vibrator == null) {
                    startVibration()
                }
            }
        }
    }

    private fun launchAlarmActivity() {
        try {
            val activityIntent = Intent(this, AlarmActivity::class.java).apply {
                flags = Intent.FLAG_ACTIVITY_NEW_TASK or
                        Intent.FLAG_ACTIVITY_CLEAR_TOP or
                        Intent.FLAG_ACTIVITY_SINGLE_TOP
                putExtra("alarm_id", currentAlarmId)
                putExtra("title", currentTitle)
                putExtra("body", currentBody)
                putStringArrayListExtra("alert_keys", ArrayList(currentAlertKeys))
            }
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.UPSIDE_DOWN_CAKE) {
                val options = android.app.ActivityOptions.makeBasic().apply {
                    pendingIntentBackgroundActivityStartMode =
                        android.app.ActivityOptions.MODE_BACKGROUND_ACTIVITY_START_ALLOWED
                }
                startActivity(activityIntent, options.toBundle())
            } else {
                startActivity(activityIntent)
            }
        } catch (_: Exception) {
            // Si le lancement d'activité directe est restreint par l'OS,
            // le fullScreenIntent de la notification prend le relais
        }
    }

    private fun buildForegroundNotification(): Notification {
        // Intent pour ouvrir AlarmActivity (pour l'action Ouvrir, le clic sur la notification et le plein écran)
        val openIntent = Intent(this, AlarmActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
            putExtra("alarm_id", currentAlarmId)
            putExtra("title", currentTitle)
            putExtra("body", currentBody)
            putStringArrayListExtra("alert_keys", ArrayList(currentAlertKeys))
        }
        val openPendingIntent = PendingIntent.getActivity(
            this,
            currentAlarmId,
            openIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        // Action Arrêter -> arrête l'alarme sans ouvrir l'appli
        val dismissIntent = Intent(this, AlarmActionReceiver::class.java).apply {
            action = ACTION_DISMISS
            putExtra("alarm_id", currentAlarmId)
            putExtra("title", currentTitle)
            putExtra("body", currentBody)
            putStringArrayListExtra("alert_keys", ArrayList(currentAlertKeys))
        }
        val dismissPendingIntent = PendingIntent.getBroadcast(
            this,
            currentAlarmId + 1,
            dismissIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        // Action Reporter 10m -> arrête la sonnerie et replanifie à +10 minutes
        val snoozeIntent = Intent(this, AlarmActionReceiver::class.java).apply {
            action = ACTION_SNOOZE
            putExtra("alarm_id", currentAlarmId)
            putExtra("title", currentTitle)
            putExtra("body", currentBody)
            putStringArrayListExtra("alert_keys", ArrayList(currentAlertKeys))
        }
        val snoozePendingIntent = PendingIntent.getBroadcast(
            this,
            currentAlarmId + 2,
            snoozeIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        return NotificationCompat.Builder(this, CHANNEL_ALARM_ID)
            .setSmallIcon(R.drawable.ic_stat_notification)
            .setContentTitle(currentTitle)
            .setContentText(currentBody)
            .setPriority(NotificationCompat.PRIORITY_MAX)
            .setCategory(NotificationCompat.CATEGORY_ALARM)
            .setFullScreenIntent(openPendingIntent, true)
            .setContentIntent(openPendingIntent)
            .setOngoing(true)
            .setAutoCancel(false)
            .setVisibility(NotificationCompat.VISIBILITY_PUBLIC)
            .addAction(0, "Arrêter", dismissPendingIntent)
            .addAction(0, "Reporter 10m", snoozePendingIntent)
            .addAction(0, "Ouvrir", openPendingIntent)
            .build()
    }

    private fun startAudio() {
        stopAudio()
        try {
            val audioManager = getSystemService(Context.AUDIO_SERVICE) as? AudioManager
            val ringerMode = audioManager?.ringerMode ?: AudioManager.RINGER_MODE_NORMAL

            // Respect strict du mode Silencieux ou Vibreur du téléphone : aucun son
            if (ringerMode == AudioManager.RINGER_MODE_SILENT || ringerMode == AudioManager.RINGER_MODE_VIBRATE) {
                return
            }

            // Vérifier le volume défini par l'utilisateur sur le téléphone
            val ringVol = audioManager?.getStreamVolume(AudioManager.STREAM_RING) ?: 1
            val notifVol = audioManager?.getStreamVolume(AudioManager.STREAM_NOTIFICATION) ?: 1
            val alarmVol = audioManager?.getStreamVolume(AudioManager.STREAM_ALARM) ?: 1
            if (ringVol == 0 && notifVol == 0 && alarmVol == 0) {
                return
            }

            val soundResId = resources.getIdentifier("gentle_alarm", "raw", packageName)
            val soundUri = if (soundResId != 0) {
                Uri.parse("android.resource://$packageName/$soundResId")
            } else {
                android.provider.Settings.System.DEFAULT_ALARM_ALERT_URI
            }

            mediaPlayer = MediaPlayer().apply {
                setAudioAttributes(
                    AudioAttributes.Builder()
                        .setUsage(AudioAttributes.USAGE_NOTIFICATION_RINGTONE)
                        .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION)
                        .build()
                )
                setDataSource(applicationContext, soundUri)
                isLooping = true
                // Volume géré à 100% par le niveau sonore du téléphone
                setVolume(1.0f, 1.0f)
                prepare()
                start()
            }
        } catch (_: Exception) {}
    }

    private fun startVibration() {
        stopVibration()
        try {
            val audioManager = getSystemService(Context.AUDIO_SERVICE) as? AudioManager
            val ringerMode = audioManager?.ringerMode ?: AudioManager.RINGER_MODE_NORMAL

            // En mode Silencieux strict : ne pas faire vibrer
            if (ringerMode == AudioManager.RINGER_MODE_SILENT) {
                return
            }

            // En mode Vibreur ou Normal : activer la vibration
            vibrator = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                val vibratorManager = getSystemService(Context.VIBRATOR_MANAGER_SERVICE) as? VibratorManager
                vibratorManager?.defaultVibrator
            } else {
                @Suppress("DEPRECATION")
                getSystemService(Context.VIBRATOR_SERVICE) as? Vibrator
            }

            val pattern = longArrayOf(0, 1000, 1000) // vibre 1s, pause 1s
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                vibrator?.vibrate(VibrationEffect.createWaveform(pattern, 0))
            } else {
                @Suppress("DEPRECATION")
                vibrator?.vibrate(pattern, 0)
            }
        } catch (_: Exception) {}
    }

    private fun stopAudio() {
        try {
            mediaPlayer?.let {
                if (it.isPlaying) it.stop()
                it.reset()
                it.release()
            }
        } catch (_: Exception) {}
        mediaPlayer = null
    }

    private fun stopVibration() {
        try {
            vibrator?.cancel()
        } catch (_: Exception) {}
        vibrator = null
    }

    private fun acquireWakeLock() {
        if (wakeLock == null) {
            val pm = getSystemService(Context.POWER_SERVICE) as? PowerManager
            wakeLock = pm?.newWakeLock(PowerManager.PARTIAL_WAKE_LOCK, "angela:alarm_service_wake_lock")
            wakeLock?.acquire(TIMEOUT_MS + 30000L) // 5.5 minutes max de sécurité
        }
    }

    private fun releaseWakeLock() {
        try {
            if (wakeLock?.isHeld == true) {
                wakeLock?.release()
            }
        } catch (_: Exception) {}
        wakeLock = null
    }

    private fun onTimeoutMissed() {
        // Enregistrer l'issue 'missed'
        AlarmStorage.recordEvent(
            this,
            AlarmEvent(
                id = UUID.randomUUID().toString(),
                alarmId = currentAlarmId,
                alertKeys = currentAlertKeys,
                outcome = "missed",
                timestampMs = System.currentTimeMillis(),
                source = "timeout_5min"
            )
        )

        // Poster la notification « Alarme manquée »
        postMissedNotification()

        // Arrêter le service
        cleanupAndStop()
    }

    private fun postMissedNotification() {
        val notificationManager = getSystemService(Context.NOTIFICATION_SERVICE) as? NotificationManager ?: return

        val openIntent = Intent(this, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
            putExtra("open_notifications", true)
        }
        val openPendingIntent = PendingIntent.getActivity(
            this,
            currentAlarmId + 10,
            openIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        val notification = NotificationCompat.Builder(this, CHANNEL_STANDARD_ID)
            .setSmallIcon(R.drawable.ic_stat_notification)
            .setContentTitle("Alarme manquée")
            .setContentText(currentTitle)
            .setPriority(NotificationCompat.PRIORITY_HIGH)
            .setCategory(NotificationCompat.CATEGORY_REMINDER)
            .setContentIntent(openPendingIntent)
            .setAutoCancel(true)
            .build()

        notificationManager.notify(currentAlarmId + 100, notification)
    }

    fun stopAlarmAndFinish(outcome: String, source: String) {
        handler.removeCallbacks(timeoutRunnable)

        AlarmStorage.recordEvent(
            this,
            AlarmEvent(
                id = UUID.randomUUID().toString(),
                alarmId = currentAlarmId,
                alertKeys = currentAlertKeys,
                outcome = outcome,
                timestampMs = System.currentTimeMillis(),
                source = source
            )
        )

        cleanupAndStop()
    }

    private fun cleanupAndStop() {
        if (isRingerReceiverRegistered) {
            try {
                unregisterReceiver(ringerReceiver)
            } catch (_: Exception) {}
            isRingerReceiverRegistered = false
        }
        stopAudio()
        stopVibration()
        releaseWakeLock()
        stopForeground(STOP_FOREGROUND_REMOVE)
        stopSelf()
    }

    private fun createNotificationChannels() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val nm = getSystemService(Context.NOTIFICATION_SERVICE) as? NotificationManager ?: return

            val alarmChannel = NotificationChannel(
                CHANNEL_ALARM_ID,
                "Alarmes d'atelier (Mélodie douce)",
                NotificationManager.IMPORTANCE_HIGH
            ).apply {
                description = "Sonnerie douce et plein écran pour les essayages et livraisons"
                enableVibration(true)
                setSound(null, null) // Le son est géré directement par le MediaPlayer du service
            }

            val standardChannel = NotificationChannel(
                CHANNEL_STANDARD_ID,
                "Notifications simples",
                NotificationManager.IMPORTANCE_HIGH
            ).apply {
                description = "Notifications discrètes pour les rappels de production"
                enableVibration(true)
            }

            nm.createNotificationChannel(alarmChannel)
            nm.createNotificationChannel(standardChannel)
        }
    }

    override fun onDestroy() {
        cleanupAndStop()
        super.onDestroy()
    }
}

