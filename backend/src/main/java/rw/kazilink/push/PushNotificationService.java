package rw.kazilink.push;

import com.google.auth.oauth2.GoogleCredentials;
import com.google.firebase.FirebaseApp;
import com.google.firebase.FirebaseOptions;
import com.google.firebase.messaging.FirebaseMessaging;
import com.google.firebase.messaging.FirebaseMessagingException;
import com.google.firebase.messaging.Message;
import com.google.firebase.messaging.MessagingErrorCode;
import com.google.firebase.messaging.Notification;
import lombok.RequiredArgsConstructor;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.scheduling.annotation.Async;
import org.springframework.stereotype.Service;

import java.io.FileInputStream;
import java.io.IOException;
import java.util.List;
import java.util.UUID;

/**
 * Sends a real push notification (via Firebase Cloud Messaging) alongside
 * every in-app Notification row NotificationService.create() writes - see
 * that class for where this is called from. If app.firebase.credentials-path
 * isn't set (FirebaseProperties.isConfigured() is false), this logs what it
 * would have sent instead of touching Firebase at all - the same "dev
 * fallback" BrevoEmailService already uses for OTP emails, so local
 * development and CI never need a real Firebase project just to exercise
 * the notification flows.
 *
 * Firebase itself is initialized lazily, on first use, not at startup -
 * this is deliberate: BackendApplication should boot cleanly whether or
 * not push notifications are configured, exactly like it already does for
 * Brevo/Google Sign-In, rather than failing to start over an optional
 * integration.
 *
 * {@code @Async} for the same reason as BrevoEmailService.sendOtpEmail:
 * this is a real network call to a third party, and the caller (usually
 * BookingService reacting to a status change) shouldn't have to wait on it.
 */
@Service
@RequiredArgsConstructor
public class PushNotificationService {

    private static final Logger log = LoggerFactory.getLogger(PushNotificationService.class);
    private static final String FIREBASE_APP_NAME = "kazilink-push";

    private final FirebaseProperties firebaseProperties;
    private final DeviceTokenRepository deviceTokenRepository;

    private volatile FirebaseApp firebaseApp;
    private volatile boolean initAttempted = false;

    @Async
    public void sendToUser(UUID userId, String title, String body) {
        List<DeviceToken> tokens = deviceTokenRepository.findByUserId(userId);
        if (tokens.isEmpty()) return;

        FirebaseMessaging messaging = messagingOrNull();
        if (messaging == null) {
            log.info("Firebase not configured - would have pushed to {} device(s) for user {}: {}", tokens.size(), userId, title);
            return;
        }

        for (DeviceToken deviceToken : tokens) {
            try {
                Message message = Message.builder()
                        .setToken(deviceToken.getToken())
                        .setNotification(Notification.builder().setTitle(title).setBody(body).build())
                        .build();
                messaging.send(message);
            } catch (FirebaseMessagingException e) {
                if (e.getMessagingErrorCode() == MessagingErrorCode.UNREGISTERED) {
                    // Firebase itself is telling us this token will never
                    // accept another push (app uninstalled, or replaced by a
                    // newer token for the same install) - clean it up instead
                    // of retrying it forever on every future notification.
                    deviceTokenRepository.delete(deviceToken);
                } else {
                    log.error("Failed to send push notification to device {} for user {}", deviceToken.getId(), userId, e);
                }
            }
        }
    }

    /** Null if unconfigured, or if the configured credentials file failed to load - either way, only ever attempted once (not re-tried on every single push). */
    private FirebaseMessaging messagingOrNull() {
        FirebaseApp app = firebaseApp;
        if (app != null) return FirebaseMessaging.getInstance(app);
        if (initAttempted || !firebaseProperties.isConfigured()) return null;

        synchronized (this) {
            if (initAttempted) {
                return firebaseApp == null ? null : FirebaseMessaging.getInstance(firebaseApp);
            }
            initAttempted = true;
            try (FileInputStream credentials = new FileInputStream(firebaseProperties.credentialsPath())) {
                FirebaseOptions options = FirebaseOptions.builder()
                        .setCredentials(GoogleCredentials.fromStream(credentials))
                        .build();
                firebaseApp = FirebaseApp.initializeApp(options, FIREBASE_APP_NAME);
                log.info("Firebase initialized for push notifications from {}", firebaseProperties.credentialsPath());
            } catch (IOException e) {
                log.error("Failed to initialize Firebase from {} - push notifications will be logged only", firebaseProperties.credentialsPath(), e);
                return null;
            }
            return FirebaseMessaging.getInstance(firebaseApp);
        }
    }
}
