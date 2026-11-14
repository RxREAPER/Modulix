# Flutter Wrapper
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.**  { *; }

# Modulix App & Native Receivers
-keep class com.modulix.app.** { *; }
-keep class com.modulix.app.MainActivity { *; }
-keep class com.modulix.app.TimerAlarmReceiver { *; }

# Desugaring & Java 8+ APIs
-dontwarn java.time.**
-dontwarn java.lang.invoke.**

# SQLite / sqflite plugin
-keep class com.tekartik.sqflite.** { *; }

# Flutter Local Notifications
-keep class com.dexterous.flutterlocalnotifications.** { *; }

# Audio Players
-keep class xyz.luan.audioplayers.** { *; }

# Play Core deferred components (unused Flutter embedding references)
-dontwarn com.google.android.play.core.splitcompat.**
-dontwarn com.google.android.play.core.splitinstall.**
-dontwarn com.google.android.play.core.tasks.**

