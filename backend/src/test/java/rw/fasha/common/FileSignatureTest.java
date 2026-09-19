package rw.fasha.common;

import org.junit.jupiter.api.Test;

import static org.assertj.core.api.Assertions.assertThat;

/**
 * Confirms FileSignature actually verifies bytes rather than just trusting
 * the label it's given - the whole point of the magic-byte check
 * SecureFileStorageService/AvatarStorageService rely on to reject a file
 * whose real content doesn't match its claimed Content-Type.
 */
class FileSignatureTest {

    @Test
    void matches_acceptsARealJpegHeader() {
        byte[] header = {(byte) 0xFF, (byte) 0xD8, (byte) 0xFF, (byte) 0xE0, 0, 0, 0, 0};
        assertThat(FileSignature.matches("image/jpeg", header)).isTrue();
    }

    @Test
    void matches_acceptsARealPngHeader() {
        byte[] header = {(byte) 0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A};
        assertThat(FileSignature.matches("image/png", header)).isTrue();
    }

    @Test
    void matches_acceptsARealPdfHeader() {
        byte[] header = "%PDF-1.7 rest of file".getBytes();
        assertThat(FileSignature.matches("application/pdf", header)).isTrue();
    }

    @Test
    void matches_acceptsARealWebpHeader() {
        // RIFF <4-byte size> WEBP
        byte[] header = {0x52, 0x49, 0x46, 0x46, 0, 0, 0, 0, 0x57, 0x45, 0x42, 0x50};
        assertThat(FileSignature.matches("image/webp", header)).isTrue();
    }

    @Test
    void matches_rejectsAFileClaimingToBeJpegButIsntOne() {
        // A plain text/script file, mislabeled - exactly the bypass this exists to catch.
        byte[] header = "#!/bin/sh\necho hi".getBytes();
        assertThat(FileSignature.matches("image/jpeg", header)).isFalse();
    }

    @Test
    void matches_rejectsAnUnrecognizedContentType() {
        byte[] header = {(byte) 0xFF, (byte) 0xD8, (byte) 0xFF};
        assertThat(FileSignature.matches("image/gif", header)).isFalse();
    }

    @Test
    void matches_rejectsAHeaderShorterThanTheSignature() {
        assertThat(FileSignature.matches("image/png", new byte[]{(byte) 0x89, 0x50})).isFalse();
    }
}
