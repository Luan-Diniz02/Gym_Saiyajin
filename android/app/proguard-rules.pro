# Preserva classes do Flutter Local Notifications
-keep class com.dexterous.flutterlocalnotifications.** { *; }
-keep class androidx.core.app.NotificationCompat** { *; }

# Preserva campos da classe R para que getIdentifier funcione corretamente em runtime
-keepclassmembers class **.R$* {
    public static <fields>;
}

# Preserva recursos em drawable
-keep class **.R$drawable {
    public static <fields>;
}
