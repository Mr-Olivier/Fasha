package rw.fasha.provider;

import rw.fasha.user.Role;

import java.time.Instant;
import java.util.UUID;

public record VerificationMessageResponse(
        UUID id,
        UUID providerProfileId,
        UUID senderId,
        String senderName,
        Role senderRole,
        String body,
        Instant createdAt
) {
}
