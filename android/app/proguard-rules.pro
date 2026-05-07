# Flutter Wrapper
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# Razorpay
-keep class com.razorpay.** {*;}
-dontwarn com.razorpay.**

# Supabase / Postgrest / GoTrue
-keep class io.supabase.** { *; }
-keep class io.github.jan.supabase.** { *; }
-dontwarn io.supabase.**
-dontwarn io.github.jan.supabase.**

# HTTP / OkHttp
-keep class okhttp3.** { *; }
-keep interface okhttp3.** { *; }
-dontwarn okhttp3.**
-dontwarn okio.**

# Image Picker
-keep class io.flutter.plugins.imagepicker.** { *; }

# General models (prevent shrinking of fields used in JSON)
-keepclassmembers class * {
  @com.google.gson.annotations.SerializedName <fields>;
}
-keep class com.blissfruitz.app.models.** { *; }

# Fix for geolocator/geocoding
-keep class com.baseflow.geolocator.** { *; }
-keep class com.baseflow.geocoding.** { *; }

# Google Play Core (Fix for R8 missing classes)
-keep class com.google.android.play.core.common.IntentSenderForResultStarter { *; }
-keep class com.google.android.play.core.tasks.** { *; }
-keep class com.google.android.play.core.install.** { *; }
-keep class com.google.android.play.core.appupdate.** { *; }
-keep class com.google.android.play.core.splitinstall.** { *; }
-keep class com.google.android.play.core.review.** { *; }
-dontwarn com.google.android.play.core.**

# Google Play Services
-keep class com.google.android.gms.location.** { *; }
-keep class com.google.android.gms.tasks.** { *; }
-dontwarn com.google.android.gms.**

# Kotlin Coroutines
-keep class kotlinx.coroutines.** { *; }
-dontwarn kotlinx.coroutines.**

# Protobuf
-dontwarn com.google.protobuf.**
-keep class com.google.protobuf.** { *; }

# Firebase
-keep class com.google.firebase.** { *; }
-dontwarn com.google.firebase.**
-keep class com.google.android.gms.internal.** { *; }
-dontwarn com.google.android.gms.internal.**

# Keep standard library attributes
-keepattributes Signature
-keepattributes *Annotation*
-keepattributes EnclosingMethod
-keepattributes InnerClasses
-keepattributes SourceFile,LineNumberTable
