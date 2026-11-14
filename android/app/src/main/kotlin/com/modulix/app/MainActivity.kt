package com.modulix.app

import android.app.AlarmManager
import android.app.PendingIntent
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.media.AudioManager
import android.net.Uri
import android.os.Build
import android.os.PowerManager
import android.provider.Settings
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val channelBattery = "com.modulix.app/battery_optimization"
    private val channelAlarm = "com.modulix.app/alarm_clock"
    private val channelAudio = "com.modulix.app/audio_becoming_noisy"

    private var audioBecomingNoisyReceiver: BroadcastReceiver? = null
    private var audioChannel: MethodChannel? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // ── BATTERY OPTIMIZATION & OEM DETECTION ────────────────────────────
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelBattery).setMethodCallHandler { call, result ->
            when (call.method) {
                "isIgnoringBatteryOptimizations" -> {
                    try {
                        val powerManager = getSystemService(Context.POWER_SERVICE) as? PowerManager
                        val isIgnoring = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                            powerManager?.isIgnoringBatteryOptimizations(packageName) ?: false
                        } else {
                            true
                        }
                        result.success(isIgnoring)
                    } catch (e: Exception) {
                        result.success(false)
                    }
                }
                "requestIgnoreBatteryOptimizations" -> {
                    try {
                        val intent = Intent(Settings.ACTION_IGNORE_BATTERY_OPTIMIZATION_SETTINGS)
                        startActivity(intent)
                        result.success(true)
                    } catch (e: Exception) {
                        try {
                            val fallbackIntent = Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS).apply {
                                data = Uri.parse("package:$packageName")
                            }
                            startActivity(fallbackIntent)
                            result.success(true)
                        } catch (fallbackError: Exception) {
                            result.error("INTENT_ERROR", e.localizedMessage, null)
                        }
                    }
                }
                "openBatteryOptimizationSettings" -> {
                    try {
                        val intent = Intent(Settings.ACTION_IGNORE_BATTERY_OPTIMIZATION_SETTINGS)
                        startActivity(intent)
                        result.success(true)
                    } catch (e: Exception) {
                        result.error("INTENT_ERROR", e.localizedMessage, null)
                    }
                }
                "getDeviceManufacturer" -> {
                    result.success(Build.MANUFACTURER.lowercase())
                }
                "getDeviceModel" -> {
                    result.success(Build.MODEL)
                }
                "getAndroidVersion" -> {
                    result.success(Build.VERSION.SDK_INT)
                }
                else -> result.notImplemented()
            }
        }

        // ── NATIVE ALARM CLOCK (DEEP DOZE PIERCER) ──────────────────────────
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelAlarm).setMethodCallHandler { call, result ->
            when (call.method) {
                "canScheduleExactAlarms" -> {
                    try {
                        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                            val alarmManager = getSystemService(Context.ALARM_SERVICE) as? AlarmManager
                            result.success(alarmManager?.canScheduleExactAlarms() ?: true)
                        } else {
                            result.success(true)
                        }
                    } catch (e: Exception) {
                        result.success(true)
                    }
                }
                "scheduleAlarmClock" -> {
                    try {
                        val triggerMs = (call.argument<Number>("triggerMs"))?.toLong() ?: 0L
                        val title = call.argument<String>("title") ?: "Focus Session"
                        val isBreak = call.argument<Boolean>("isBreak") ?: false

                        val alarmManager = getSystemService(Context.ALARM_SERVICE) as? AlarmManager
                        if (alarmManager == null || triggerMs <= System.currentTimeMillis()) {
                            result.success(false)
                            return@setMethodCallHandler
                        }

                        val flagImmutable = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                            PendingIntent.FLAG_IMMUTABLE
                        } else {
                            0
                        }

                        // Intent opened when tapping the alarm clock icon on Lockscreen / AOD
                        val showIntent = Intent(this, MainActivity::class.java).apply {
                            flags = Intent.FLAG_ACTIVITY_SINGLE_TOP or Intent.FLAG_ACTIVITY_CLEAR_TOP
                            putExtra("route", "/timer")
                        }
                        val showPendingIntent = PendingIntent.getActivity(
                            this,
                            101,
                            showIntent,
                            PendingIntent.FLAG_UPDATE_CURRENT or flagImmutable
                        )

                        // Intent fired at the exact millisecond by AlarmManager
                        val triggerIntent = Intent(this, TimerAlarmReceiver::class.java).apply {
                            action = TimerAlarmReceiver.ACTION_TIMER_ALARM
                            putExtra(TimerAlarmReceiver.EXTRA_TITLE, title)
                            putExtra(TimerAlarmReceiver.EXTRA_IS_BREAK, isBreak)
                        }
                        val operationPendingIntent = PendingIntent.getBroadcast(
                            this,
                            TimerAlarmReceiver.NOTIFICATION_ID,
                            triggerIntent,
                            PendingIntent.FLAG_UPDATE_CURRENT or flagImmutable
                        )

                        val clockInfo = AlarmManager.AlarmClockInfo(triggerMs, showPendingIntent)
                        alarmManager.setAlarmClock(clockInfo, operationPendingIntent)
                        result.success(true)
                    } catch (e: SecurityException) {
                        result.error("SECURITY_EXCEPTION", e.localizedMessage, null)
                    } catch (e: Exception) {
                        result.error("ALARM_ERROR", e.localizedMessage, null)
                    }
                }
                "cancelAlarmClock" -> {
                    try {
                        val alarmManager = getSystemService(Context.ALARM_SERVICE) as? AlarmManager
                        val flagImmutable = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                            PendingIntent.FLAG_IMMUTABLE
                        } else {
                            0
                        }
                        val triggerIntent = Intent(this, TimerAlarmReceiver::class.java).apply {
                            action = TimerAlarmReceiver.ACTION_TIMER_ALARM
                        }
                        val operationPendingIntent = PendingIntent.getBroadcast(
                            this,
                            TimerAlarmReceiver.NOTIFICATION_ID,
                            triggerIntent,
                            PendingIntent.FLAG_UPDATE_CURRENT or flagImmutable
                        )
                        alarmManager?.cancel(operationPendingIntent)
                        result.success(true)
                    } catch (e: Exception) {
                        result.error("CANCEL_ERROR", e.localizedMessage, null)
                    }
                }
                "openExactAlarmSettings" -> {
                    try {
                        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                            val intent = Intent(Settings.ACTION_REQUEST_SCHEDULE_EXACT_ALARM).apply {
                                data = Uri.parse("package:$packageName")
                            }
                            startActivity(intent)
                            result.success(true)
                        } else {
                            result.success(true)
                        }
                    } catch (e: Exception) {
                        result.error("INTENT_ERROR", e.localizedMessage, null)
                    }
                }
                else -> result.notImplemented()
            }
        }

        // ── AUDIO BECOMING NOISY (HEADPHONE DISCONNECTION) ──────────────────
        audioChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelAudio)
        registerAudioBecomingNoisyReceiver()
    }

    private fun registerAudioBecomingNoisyReceiver() {
        if (audioBecomingNoisyReceiver != null) return
        audioBecomingNoisyReceiver = object : BroadcastReceiver() {
            override fun onReceive(context: Context?, intent: Intent?) {
                if (intent?.action == AudioManager.ACTION_AUDIO_BECOMING_NOISY) {
                    audioChannel?.invokeMethod("onAudioBecomingNoisy", null)
                }
            }
        }
        val filter = IntentFilter(AudioManager.ACTION_AUDIO_BECOMING_NOISY)
        registerReceiver(audioBecomingNoisyReceiver, filter)
    }

    private fun unregisterAudioBecomingNoisyReceiver() {
        audioBecomingNoisyReceiver?.let {
            try {
                unregisterReceiver(it)
            } catch (_: Exception) {}
            audioBecomingNoisyReceiver = null
        }
    }

    override fun onDestroy() {
        unregisterAudioBecomingNoisyReceiver()
        super.onDestroy()
    }
}
