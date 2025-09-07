# Flutter/Plugin keep rules (conservative defaults)

# Keep Flutter classes
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# Keep Kotlin metadata (safe for reflection and incremental builds)
-keep class kotlin.Metadata { *; }

# Keep some androidx lifecycle classes often used by plugins
-keep class androidx.lifecycle.** { *; }

# Keep entry points for Activity/Service/BroadcastReceiver that might be reflected
-keep class ** extends android.app.Activity { *; }
-keep class ** extends android.app.Service { *; }
-keep class ** extends android.content.BroadcastReceiver { *; }
-keep class ** extends android.content.ContentProvider { *; }

# Do not warn on common reflection uses by plugins
-dontwarn io.flutter.**
-dontwarn androidx.lifecycle.**