# Firebase Auth / google_sign_in / audioplayers / cached_network_image all
# ship their own consumer ProGuard rules bundled in their AARs — R8 applies
# those automatically, nothing to hand-write here for them.

# Flutter's embedding references Play Core (deferred-components) classes
# that this app never actually uses (no split installs configured) — R8
# fails the build on the missing classes without this, a common first-time
# minification gotcha, not a real risk since the code path is unreachable.
-dontwarn com.google.android.play.core.**
