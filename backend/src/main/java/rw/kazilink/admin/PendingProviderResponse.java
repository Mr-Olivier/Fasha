package rw.kazilink.admin;

import rw.kazilink.provider.VerificationStatus;

import java.time.Instant;
import java.util.UUID;

/**
 * One row in the admin "Review application" list/detail (README.md
 * section 10's GET /api/admin/providers). Denormalized with the owner's
 * name/email/phone and their service count so the admin app never needs a
 * second round-trip per provider just to render the list - same reasoning
 * as BookingResponse's denormalized fields.
 */
public record PendingProviderResponse(
        UUID id,
        String businessName,
        String description,
        String location,
        VerificationStatus verificationStatus,
        Instant appliedAt,
        String ownerName,
        String ownerEmail,
        String ownerPhone,
        long serviceCount
) {
}
