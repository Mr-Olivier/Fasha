package rw.kazilink.user;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Component;
import org.springframework.web.multipart.MultipartFile;
import rw.kazilink.common.FileSignature;

import java.io.IOException;
import java.io.InputStream;
import java.io.UncheckedIOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.util.Set;
import java.util.UUID;

/**
 * Saves uploaded avatar images to local disk, under app.uploads-dir
 * (see application.yml). This project has no cloud storage account to
 * upload to, so local disk is the honest choice for an MVP - StaticResourceConfig
 * is what makes the saved files downloadable again, at the URL this
 * returns.
 *
 * Kept as its own class (rather than inline in UserService) specifically
 * so UserServiceTest can mock it - unit tests shouldn't need to touch the
 * real filesystem to check UserService's business logic.
 */
@Component
public class AvatarStorageService {

    private final Path avatarsDir;

    public AvatarStorageService(@Value("${app.uploads-dir:uploads}") String uploadsDir) {
        this.avatarsDir = Path.of(uploadsDir, "avatars").toAbsolutePath();
    }

    private static final Set<String> ACCEPTED_CONTENT_TYPES = Set.of("image/jpeg", "image/png", "image/webp");

    /** Returns the public URL path the saved file is now reachable at, e.g. "/uploads/avatars/&lt;name&gt;". */
    public String store(UUID userId, MultipartFile file) {
        if (file.isEmpty()) {
            throw new InvalidAvatarException("Please choose an image to upload.");
        }
        String contentType = file.getContentType();
        if (!ACCEPTED_CONTENT_TYPES.contains(contentType)) {
            throw new InvalidAvatarException("Only JPEG, PNG, or WebP images can be used as an avatar.");
        }
        // See SecureFileStorageService's identical check for why the
        // header bytes are verified against the claimed content type
        // rather than trusting the client-supplied header alone.
        if (!FileSignature.matches(contentType, readHeader(file))) {
            throw new InvalidAvatarException("This file's content doesn't match its claimed type.");
        }

        try {
            Files.createDirectories(avatarsDir);
            String filename = userId + "-" + System.currentTimeMillis() + extensionFor(contentType);
            file.transferTo(avatarsDir.resolve(filename));
            return "/uploads/avatars/" + filename;
        } catch (IOException e) {
            throw new UncheckedIOException("Failed to save uploaded avatar", e);
        }
    }

    private byte[] readHeader(MultipartFile file) {
        try (InputStream in = file.getInputStream()) {
            return in.readNBytes(16);
        } catch (IOException e) {
            throw new UncheckedIOException("Failed to read uploaded file", e);
        }
    }

    private String extensionFor(String contentType) {
        return switch (contentType) {
            case "image/png" -> ".png";
            case "image/webp" -> ".webp";
            default -> ".jpg";
        };
    }
}
