package rw.kazilink.common;

import java.util.Arrays;

/**
 * Verifies a file's actual bytes match the type it claims to be, instead
 * of trusting the client-supplied Content-Type header alone (what
 * SecureFileStorageService and AvatarStorageService did before this
 * existed). A client can set any Content-Type it likes on a multipart
 * upload - this closes that gap by checking the handful of leading bytes
 * every common format is required to start with ("magic bytes"), the same
 * technique `file`(1)/`libmagic` and most upload scanners use.
 *
 * Deliberately only recognizes the small set of types this app actually
 * accepts (JPEG/PNG/WEBP/PDF/MP4/MOV) - it's a gate, not a general-purpose
 * file type detector.
 */
public final class FileSignature {

    private FileSignature() {
    }

    private static final byte[] JPEG = {(byte) 0xFF, (byte) 0xD8, (byte) 0xFF};
    private static final byte[] PNG = {(byte) 0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A};
    private static final byte[] PDF = {0x25, 0x50, 0x44, 0x46}; // "%PDF"
    private static final byte[] RIFF = {0x52, 0x49, 0x46, 0x46}; // "RIFF" - WEBP is RIFF....WEBP
    private static final byte[] WEBP = {0x57, 0x45, 0x42, 0x50}; // "WEBP", at offset 8
    private static final byte[] FTYP = {0x66, 0x74, 0x79, 0x70}; // "ftyp", at offset 4 - the ISO base media box every MP4/MOV recording starts with

    /** @return true if `header` (the file's first bytes - 16+ is enough for every format above) actually starts with the claimed contentType's signature. */
    public static boolean matches(String contentType, byte[] header) {
        if (contentType == null) return false;
        return switch (contentType) {
            case "image/jpeg" -> startsWith(header, JPEG);
            case "image/png" -> startsWith(header, PNG);
            case "image/webp" -> startsWith(header, RIFF) && header.length >= 12 && startsWith(Arrays.copyOfRange(header, 8, 12), WEBP);
            case "application/pdf" -> startsWith(header, PDF);
            case "video/mp4", "video/quicktime" ->
                    header.length >= 8 && startsWith(Arrays.copyOfRange(header, 4, 8), FTYP);
            // Anything else (e.g. image/gif) has no signature to check
            // here, so it's rejected rather than waved through unverified
            // - callers should only ever claim one of the types above.
            default -> false;
        };
    }

    private static boolean startsWith(byte[] data, byte[] prefix) {
        if (data.length < prefix.length) return false;
        for (int i = 0; i < prefix.length; i++) {
            if (data[i] != prefix[i]) return false;
        }
        return true;
    }
}
