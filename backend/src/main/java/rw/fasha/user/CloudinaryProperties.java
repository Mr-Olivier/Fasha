package rw.fasha.user;

import org.springframework.boot.context.properties.ConfigurationProperties;

/** Typed binding for the "app.cloudinary.*" keys in application.yml - see BrevoProperties for the same pattern applied to another optional third-party integration. */
@ConfigurationProperties(prefix = "app.cloudinary")
public record CloudinaryProperties(String cloudName, String apiKey, String apiSecret) {

    /** AvatarStorageService falls back to saving to local disk when this is blank - lets local dev and CI work with no Cloudinary account at all. */
    public boolean isConfigured() {
        return cloudName != null && !cloudName.isBlank();
    }
}
