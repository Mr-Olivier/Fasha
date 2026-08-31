package rw.kazilink.user;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Component;
import org.springframework.web.multipart.MultipartFile;

import java.io.IOException;
import java.io.UncheckedIOException;
import java.nio.file.Files;
import java.nio.file.Path;
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

    /** Returns the public URL path the saved file is now reachable at, e.g. "/uploads/avatars/&lt;name&gt;". */
    public String store(UUID userId, MultipartFile file) {
        if (file.isEmpty()) {
            throw new InvalidAvatarException("Please choose an image to upload.");
        }
        String contentType = file.getContentType();
        if (contentType == null || !contentType.startsWith("image/")) {
            throw new InvalidAvatarException("Only image files (JPEG, PNG, WebP, ...) can be used as an avatar.");
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

    private String extensionFor(String contentType) {
        return switch (contentType) {
            case "image/png" -> ".png";
            case "image/webp" -> ".webp";
            default -> ".jpg";
        };
    }
}
