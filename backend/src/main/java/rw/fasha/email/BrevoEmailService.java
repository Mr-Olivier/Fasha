package rw.fasha.email;

import lombok.RequiredArgsConstructor;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.scheduling.annotation.Async;
import org.springframework.stereotype.Service;
import org.springframework.web.client.RestClient;

import java.util.List;
import java.util.Map;

/**
 * Sends OTP emails through Brevo's transactional email API
 * (https://api.brevo.com/v3/smtp/email). If app.brevo.api-key isn't set
 * (BrevoProperties.isConfigured() is false), this logs the code instead of
 * calling the API at all - the same "dev fallback" this project already
 * used for the old dev-mode reset token, so local development never needs
 * a real Brevo account just to exercise the OTP flows.
 *
 * {@code @Async} (see BackendApplication's {@code @EnableAsync}): this
 * real network call to a third party must never make register()/
 * forgotPassword() wait on it - the client should get its response the
 * moment the OTP row is saved, exactly as fast as login(). This was a
 * real bug found during manual testing: Brevo added a real ~1.5s round
 * trip register() didn't have when it just logged a dev-mode token, and
 * over an already-marginal USB debug tunnel that was enough to make some
 * registration attempts fail outright.
 *
 * A failed send (bad key, Brevo outage, ...) is logged but never thrown -
 * being async makes that doubly true, since there's no caller left to
 * propagate an exception to by the time this runs.
 */
@Service
@RequiredArgsConstructor
public class BrevoEmailService {

    private static final Logger log = LoggerFactory.getLogger(BrevoEmailService.class);
    private static final String BREVO_ENDPOINT = "https://api.brevo.com/v3/smtp/email";

    private final BrevoProperties brevoProperties;
    private final RestClient restClient = RestClient.create();

    @Async
    public void sendOtpEmail(String toEmail, String toName, String subject, String heading, String code) {
        if (!brevoProperties.isConfigured()) {
            log.info("BREVO_API_KEY not set - dev-mode, would have emailed {} this {} code: {}", toEmail, subject, code);
            return;
        }

        try {
            restClient.post()
                    .uri(BREVO_ENDPOINT)
                    .header("api-key", brevoProperties.apiKey())
                    .header("Content-Type", "application/json")
                    .header("Accept", "application/json")
                    .body(Map.of(
                            "sender", Map.of("name", brevoProperties.senderName(), "email", brevoProperties.senderEmail()),
                            "to", List.of(Map.of("email", toEmail, "name", toName)),
                            "subject", subject,
                            "htmlContent", htmlBody(heading, code)
                    ))
                    .retrieve()
                    .toBodilessEntity();
            log.info("Sent OTP email to {} via Brevo ({})", toEmail, subject);
        } catch (Exception e) {
            log.error("Failed to send OTP email to {} via Brevo", toEmail, e);
        }
    }

    private String htmlBody(String heading, String code) {
        return """
                <div style="font-family:sans-serif;max-width:480px;margin:0 auto">
                  <h2 style="color:#0B6B4F">%s</h2>
                  <p style="font-size:32px;font-weight:700;letter-spacing:.3em;color:#132420">%s</p>
                  <p style="color:#6E7A73">This code expires in 10 minutes. If you didn't request it, you can ignore this email.</p>
                </div>
                """.formatted(heading, code);
    }
}
