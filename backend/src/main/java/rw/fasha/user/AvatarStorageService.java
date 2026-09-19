package rw.fasha.user;

import com.cloudinary.Cloudinary;
import com.cloudinary.utils.ObjectUtils;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Component;
import org.springframework.web.multipart.MultipartFile;
import rw.fasha.common.FileSignature;

import java.io.IOException;
import java.io.InputStream;
import java.io.UncheckedIOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.util.Map;
import java.util.Set;
import java.util.UUID;

/**
 * Saves uploaded avatar/category-icon/provider-photo images - one class
 * for all three (see UserService, AdminCategoryService,
 * ProviderProfileService) since they're the same trust level (public,
 * customer-facing images) and the same validation rules, so there's no
 * reason for 3 near-identical classes.
 *
 * Uploads to Cloudinary when app.cloudinary.cloud-name is set (see
 * CloudinaryProperties), otherwise falls back to local disk under
 * app.uploads-dir - the same "optional third-party integration" pattern
 * PushNotificationService/BrevoEmailService already use, so local dev and
 * CI work with no Cloudinary account at all. Cloudinary is the one
 * actually meant for production: local disk doesn't survive a redeploy on
 * most hosts and has no CDN in front of it.
 *
 * Kept as its own class (rather than inline in its 3 callers)
 * specifically so their tests can mock it - unit tests shouldn't need to
 * touch the real filesystem or a real Cloudinary account to check
 * business logic.
 */
@Component
public class AvatarStorageService {

    private static final Set<String> ACCEPTED_CONTENT_TYPES = Set.of("image/jpeg", "image/png", "image/webp");

    private final Path avatarsDir;
    private final CloudinaryProperties cloudinaryProperties;

    private volatile Cloudinary cloudinary;

    public AvatarStorageService(@Value("${app.uploads-dir:uploads}") String uploadsDir, CloudinaryProperties cloudinaryProperties) {
        this.avatarsDir = Path.of(uploadsDir, "avatars").toAbsolutePath();
        this.cloudinaryProperties = cloudinaryProperties;
    }

    /**
     * Returns the URL the saved file is now reachable at - an absolute
     * Cloudinary URL (e.g. "https://res.cloudinary.com/...") when
     * configured, otherwise a local path like "/uploads/avatars/&lt;name&gt;".
     * See ApiClient.resolveMediaUrl on the Flutter side for why callers
     * must not assume one shape or the other.
     */
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

        String publicId = userId + "-" + System.currentTimeMillis();
        return cloudinaryProperties.isConfigured() ? uploadToCloudinary(file, publicId) : storeLocally(file, contentType, publicId);
    }

    private String uploadToCloudinary(MultipartFile file, String publicId) {
        try {
            Map<?, ?> result = cloudinary().uploader().upload(file.getBytes(), ObjectUtils.asMap(
                    "public_id", publicId,
                    "folder", "fasha/avatars",
                    "resource_type", "image"
            ));
            return (String) result.get("secure_url");
        } catch (IOException e) {
            throw new UncheckedIOException("Failed to upload avatar to Cloudinary", e);
        }
    }

    private String storeLocally(MultipartFile file, String contentType, String publicId) {
        try {
            Files.createDirectories(avatarsDir);
            String filename = publicId + extensionFor(contentType);
            file.transferTo(avatarsDir.resolve(filename));
            return "/uploads/avatars/" + filename;
        } catch (IOException e) {
            throw new UncheckedIOException("Failed to save uploaded avatar", e);
        }
    }

    /** Built lazily, only once - same reasoning as PushNotificationService.messagingOrNull(): the app should boot cleanly whether or not this is configured. */
    private Cloudinary cloudinary() {
        Cloudinary instance = cloudinary;
        if (instance == null) {
            synchronized (this) {
                instance = cloudinary;
                if (instance == null) {
                    instance = new Cloudinary(ObjectUtils.asMap(
                            "cloud_name", cloudinaryProperties.cloudName(),
                            "api_key", cloudinaryProperties.apiKey(),
                            "api_secret", cloudinaryProperties.apiSecret(),
                            "secure", true
                    ));
                    cloudinary = instance;
                }
            }
        }
        return instance;
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
