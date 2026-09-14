package rw.kazilink.push;

import org.springframework.boot.context.properties.ConfigurationProperties;

/** Typed binding for the "app.firebase.*" keys in application.yml - see BrevoProperties for the same pattern applied to another optional third-party integration. */
@ConfigurationProperties(prefix = "app.firebase")
public record FirebaseProperties(String credentialsPath) {

    /** FirebaseConfig/PushNotificationService fall back to no-op/logging when this is blank - lets local dev and CI work with no real Firebase project at all. */
    public boolean isConfigured() {
        return credentialsPath != null && !credentialsPath.isBlank();
    }
}
