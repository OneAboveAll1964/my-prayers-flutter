# Keep flutter_local_notifications reflective machinery (receivers, scheduled
# notification serialization, action handlers).
-keep class com.dexterous.** { *; }
-dontwarn com.dexterous.**

# Gson — flutter_local_notifications uses it to (de)serialize scheduled
# notification details to disk via SharedPreferences.
-keepattributes Signature
-keepattributes *Annotation*
-keepattributes EnclosingMethod
-keepattributes InnerClasses
-dontwarn sun.misc.**
-keep class com.google.gson.** { *; }
-keep class * extends com.google.gson.TypeAdapter
-keep class * implements com.google.gson.TypeAdapterFactory
-keep class * implements com.google.gson.JsonSerializer
-keep class * implements com.google.gson.JsonDeserializer
-keepclassmembers,allowobfuscation class * {
    @com.google.gson.annotations.SerializedName <fields>;
}

# Core library desugaring (java.time.* shim).
-keep class j$.** { *; }
-dontwarn j$.**

# Our own widget machinery — referenced from layout XML and intent filters.
-keep class com.shkomaghdid.sakina.** { *; }

# AndroidX work / lifecycle
-keep class androidx.work.** { *; }
-keep class androidx.lifecycle.DefaultLifecycleObserver

# audioplayers
-keep class xyz.luan.audioplayers.** { *; }

# permission_handler
-keep class com.baseflow.permissionhandler.** { *; }

# geolocator
-keep class com.baseflow.geolocator.** { *; }

# home_widget plugin (Android-side)
-keep class es.antonborri.home_widget.** { *; }

# sqflite
-keep class com.tekartik.sqflite.** { *; }

# flutter_compass
-keep class hemanthraj.flutter_compass.** { *; }

# Generic — keep WidgetKit/AppWidget receivers + services intact
-keep class * extends android.appwidget.AppWidgetProvider { *; }
-keep class * extends android.app.Service { *; }
-keep class * extends android.content.BroadcastReceiver { *; }
