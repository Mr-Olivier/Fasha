package rw.fasha.admin;

import java.time.Instant;
import java.util.UUID;

public record AdminAuditLogResponse(
        UUID id,
        String adminName,
        String action,
        String targetType,
        UUID targetId,
        String details,
        Instant createdAt
) {
}
