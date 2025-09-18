# Keep annotations used by SDKs
-keep class proguard.annotation.** { *; }

# Razorpay SDK recommended rules (defensive)
-keep class com.razorpay.** { *; }
-dontwarn com.razorpay.**

# Gson / reflection safety (common in SDKs)
-keepattributes Signature
-keepattributes *Annotation*
-keep class sun.misc.Unsafe { *; }
-dontwarn sun.misc.Unsafe

# OkHttp/Okio/Retrofit (if transitively present)
-dontwarn okhttp3.**
-dontwarn okio.**
-dontwarn retrofit2.**
-keep class okhttp3.** { *; }
-keep class okio.** { *; }
-keep class retrofit2.** { *; }
