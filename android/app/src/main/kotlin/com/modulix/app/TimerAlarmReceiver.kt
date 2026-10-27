package com.modulix.app

import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.media.AudioAttributes
import android.media.RingtoneManager
import android.os.Build
import android.os.PowerManager
import androidx.core.app.NotificationCompat
import androidx.core.app.NotificationManagerCompat

/**
 * High-priority broadcast receiver triggered by native AlarmManager.setAlarmClock.
 * Guaranteed to wake the CPU during Deep Doze and deliver the study completion alert.
 */
class TimerAlarmReceiver : BroadcastReceiver() {
    companion object {
        const val ACTION_TIMER_ALARM = "com.modulix.app.ACTION_TIMER_ALARM"
        const val EXTRA_TITLE = "extra_title"
        const val EXTRA_IS_BREAK = "extra_is_break"
        const val CHANNEL_ID = "flowmd_focus_timer_v2"
        const val NOTIFICATION_ID = 2001
    }

    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action != ACTION_TIMER_ALARM) return

        val isBreak = intent.getBooleanExtra(EXTRA_IS_BREAK, false)
        val rawTitle = intent.getStringExtra(EXTRA_TITLE)?.trim() ?: ""
        val title = if (rawTitle.isNotEmpty()) {
            rawTitle
        } else {
            if (isBreak) "Break Finished" else "Focus Session Complete"
        }
        val body = if (isBreak) {
            "Break time is over. Ready to resume study session?"
        } else {
            "Focus session complete. Time for a well-deserved break."
        }

        // Acquire a temporary 10-second partial wake lock to guarantee CPU processing
        val powerManager = context.getSystemService(Context.POWER_SERVICE) as? PowerManager
        val wakeLock = powerManager?.newWakeLock(
            PowerManager.PARTIAL_WAKE_LOCK,
            "modulix:timer_alarm_wakelock"
        )
        wakeLock?.acquire(10000L)

        try {
            ensureNotificationChannel(context)

            val openAppIntent = Intent(context, MainActivity::class.java).apply {
                flags = Intent.FLAG_ACTIVITY_SINGLE_TOP or Intent.FLAG_ACTIVITY_CLEAR_TOP
                putExtra("route", "/timer")
            }

            val flagImmutable = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                PendingIntent.FLAG_IMMUTABLE
            } else {
                0
            }
            val pendingIntent = PendingIntent.getActivity(
                context,
                NOTIFICATION_ID,
                openAppIntent,
                PendingIntent.FLAG_UPDATE_CURRENT or flagImmutable
            )

            val iconRes = context.resources.getIdentifier("ic_launcher", "mipmap", context.packageName).let {
                if (it != 0) it else android.R.drawable.ic_lock_idle_alarm
            }

            val defaultSound = RingtoneManager.getDefaultUri(RingtoneManager.TYPE_NOTIFICATION)

            val builder = NotificationCompat.Builder(context, CHANNEL_ID)
                .setSmallIcon(iconRes)
                .setContentTitle(title)
                .setContentText(body)
                .setStyle(NotificationCompat.BigTextStyle().bigText(body))
                .setPriority(NotificationCompat.PRIORITY_MAX)
                .setCategory(NotificationCompat.CATEGORY_ALARM)
                .setVisibility(NotificationCompat.VISIBILITY_PUBLIC)
                .setAutoCancel(true)
                .setContentIntent(pendingIntent)
                .setSound(defaultSound)
                .setVibrate(longArrayOf(0, 500, 250, 500, 250, 500))

            val notificationManager = NotificationManagerCompat.from(context)
            try {
                notificationManager.notify(NOTIFICATION_ID, builder.build())
            } catch (_: SecurityException) {
                // Defensive catch for Android 13+ if POST_NOTIFICATIONS was not granted
            }
        } finally {
            if (wakeLock?.isHeld == true) {
                wakeLock.release()
            }
        }
    }

    private fun ensureNotificationChannel(context: Context) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val manager = context.getSystemService(Context.NOTIFICATION_SERVICE) as? NotificationManager ?: return
            val existing = manager.getNotificationChannel(CHANNEL_ID)
            if (existing == null) {
                val soundUri = RingtoneManager.getDefaultUri(RingtoneManager.TYPE_NOTIFICATION)
                val attributes = AudioAttributes.Builder()
                    .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION)
                    .setUsage(AudioAttributes.USAGE_ALARM)
                    .build()

                val channel = NotificationChannel(
                    CHANNEL_ID,
                    "Focus Timer & Breaks",
                    NotificationManager.IMPORTANCE_HIGH
                ).apply {
                    description = "High-priority alerts when focus sessions and breaks finish"
                    enableVibration(true)
                    vibrationPattern = longArrayOf(0, 500, 250, 500, 250, 500)
                    setSound(soundUri, attributes)
                    lockscreenVisibility = android.app.Notification.VISIBILITY_PUBLIC
                }
                manager.createNotificationChannel(channel)
            }
        }
    }
}
