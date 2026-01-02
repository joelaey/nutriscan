# Flutter specific ProGuard rules
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }
-keep class io.flutter.embedding.** { *; }

# Google ML Kit
-keep class com.google.mlkit.** { *; }
-dontwarn com.google.mlkit.**

# Google Play Core (deferred components)
-dontwarn com.google.android.play.core.**

# Keep model classes
-keep class com.joelaey.nutriscan.** { *; }

# Image Cropper
-keep class com.yalantis.ucrop.** { *; }
-dontwarn com.yalantis.ucrop.**
