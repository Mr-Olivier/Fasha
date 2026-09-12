package rw.kazilink.common;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.core.io.FileSystemResource;
import org.springframework.core.io.Resource;
import org.springframework.stereotype.Component;
import org.springframework.web.multipart.MultipartFile;

import java.io.IOException;
import java.io.UncheckedIOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.util.UUID;

/**
 * Saves sensitive uploaded files (KYC documents, booking photos) to local
 * disk, under app.secure-uploads-dir - deliberately parallel to
 * AvatarStorageService, but for files that must NEVER be reachable through
 * a public URL the way avatars are. See application.yml's doc comment on
 * secure-uploads-dir for why this is a sibling directory, not a
 * subdirectory, of the public uploads-dir.
 *
 * Callers get back an OPAQUE relative path to persist in their own entity
 * (e.g. ProviderProfile.idDocumentPath, BookingPhoto.storagePath) - never a
 * URL. Reading a file back always goes through a controller method that
 * checks the caller is allowed to see it first, then streams the Resource
 * this returns - there is no static resource handler for this directory.
 */
@Component
public class SecureFileStorageService {

    private final Path rootDir;

    public SecureFileStorageService(@Value("${app.secure-uploads-dir:secure-uploads}") String secureUploadsDir) {
        this.rootDir = Path.of(secureUploadsDir).toAbsolutePath();
    }

    /**
     * @param subfolder groups related files (e.g. "kyc", "booking-photos") so they don't all land in one flat directory
     * @param filenamePrefix identifies whose file this is (e.g. a provider profile id, a booking id) - purely for a human skimming the disk, not parsed back
     * @return the opaque relative path (subfolder/filename) to persist in the caller's own entity column
     */
    public String store(String subfolder, String filenamePrefix, MultipartFile file) {
        if (file.isEmpty()) {
            throw new InvalidSecureUploadException("Please choose a file to upload.");
        }
        String contentType = file.getContentType();
        boolean isImage = contentType != null && contentType.startsWith("image/");
        boolean isPdf = "application/pdf".equals(contentType);
        if (!isImage && !isPdf) {
            throw new InvalidSecureUploadException("Only images (JPEG, PNG, WebP, ...) or a PDF can be uploaded here.");
        }

        try {
            Path targetDir = rootDir.resolve(subfolder);
            Files.createDirectories(targetDir);
            String filename = filenamePrefix + "-" + UUID.randomUUID() + extensionFor(contentType);
            file.transferTo(targetDir.resolve(filename));
            return subfolder + "/" + filename;
        } catch (IOException e) {
            throw new UncheckedIOException("Failed to save uploaded file", e);
        }
    }

    /** @param relativePath exactly what {@link #store} returned - never accept this raw from a client, only ever from a trusted entity column */
    public Resource load(String relativePath) {
        return new FileSystemResource(rootDir.resolve(relativePath));
    }

    private String extensionFor(String contentType) {
        return switch (contentType) {
            case "image/png" -> ".png";
            case "image/webp" -> ".webp";
            case "application/pdf" -> ".pdf";
            default -> ".jpg";
        };
    }
}
