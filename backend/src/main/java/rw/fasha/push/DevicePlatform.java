package rw.fasha.push;

/** Mirrors the Flutter app's own idea of which platform registered a token - purely informational, never branches push-sending logic on it. */
public enum DevicePlatform {
    ANDROID,
    WEB
}
