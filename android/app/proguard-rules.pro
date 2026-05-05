# Budget Beacon — Android release ProGuard / R8 rules.
#
# The webview-driven runtime calls Capacitor and AndroidX classes via reflection,
# so we must keep enough surface to avoid silent runtime failures. Web assets
# (JS/CSS/HTML) live under assets/public and are not subject to R8.

# --- Stack traces & crash reporting ---
-keepattributes SourceFile,LineNumberTable
-renamesourcefileattribute SourceFile

# --- WebView JS bridge ---
# Capacitor exposes its bridge through @JavascriptInterface. Keep all such members.
-keepclassmembers class * {
    @android.webkit.JavascriptInterface <methods>;
}

# --- Capacitor core + plugins ---
# Capacitor uses runtime annotation scanning to discover plugins.
-keep class com.getcapacitor.** { *; }
-keep @com.getcapacitor.annotation.CapacitorPlugin class * { *; }
-keepclasseswithmembers class * {
    @com.getcapacitor.PluginMethod <methods>;
}
-keep class com.capacitorjs.** { *; }

# --- Cordova compatibility shim used by Capacitor ---
-keep class org.apache.cordova.** { *; }
-keep class com.outsystems.plugins.** { *; }

# --- AndroidX bridges that Capacitor reaches into ---
-keep class androidx.webkit.** { *; }
-keep class androidx.core.content.FileProvider { *; }
-dontwarn androidx.webkit.**

# --- Kotlin metadata (some Capacitor plugins are Kotlin) ---
-keep class kotlin.Metadata { *; }
-keep class kotlin.coroutines.Continuation
-dontwarn kotlin.**
-dontwarn kotlinx.**

# --- AndroidJUnit / Espresso (only present in androidTest variant) ---
-dontwarn org.junit.**
-dontwarn androidx.test.**

# --- Generic safety: don't strip annotations or InnerClasses (required for reflection) ---
-keepattributes *Annotation*,InnerClasses,EnclosingMethod,Signature

# --- Suppress warnings from optional Google Play Services (only loaded if google-services.json present) ---
-dontwarn com.google.android.gms.**
-dontwarn com.google.firebase.**
