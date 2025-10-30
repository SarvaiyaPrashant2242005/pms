# Razorpay
-keepattributes *Annotation*
-dontwarn com.razorpay.**
-keep class com.razorpay.** {*;}
-optimizations !method/inlining/short
-keepclasseswithmembers class * {
  public void onPayment*(...);
}

# ProGuard annotations
-dontwarn proguard.annotation.**
-keep class proguard.annotation.** { *; }

# Additional keep rules for Razorpay
-keep class org.json.** { *; }
-keepclassmembers class * {
    @android.webkit.JavascriptInterface <methods>;
}