# Flutter-generated rules are automatically merged from the Flutter Gradle plugin.
# Keep this file minimal; add rules only when a specific plugin breaks after R8.

# just_audio / audio_session: preserve classes referenced via reflection.
-keep class com.google.android.exoplayer2.** { *; }
-dontwarn com.google.android.exoplayer2.**

# youtube_player_flutter removed; keep webview rules for any remaining web content.
-keepclassmembers class * {
    @android.webkit.JavascriptInterface <methods>;
}
-dontwarn okhttp3.**
-dontwarn okio.**

# General: keep resource shrinker safe for dynamically loaded assets.
-keepattributes *Annotation*
