package rw.kazilink.email;

import org.springframework.boot.context.properties.ConfigurationProperties;

/** Typed binding for the "app.brevo.*" keys in application.yml - see JwtProperties for why @ConfigurationProperties instead of scattered @Value fields. */
@ConfigurationProperties(prefix = "app.brevo")
public record BrevoProperties(String apiKey, String senderEmail, String senderName) {

    /** BrevoEmailService falls back to logging the code instead of calling the API when this is blank - lets local dev work with no Brevo account at all. */
    public boolean isConfigured() {
        return apiKey != null && !apiKey.isBlank();
    }
}
