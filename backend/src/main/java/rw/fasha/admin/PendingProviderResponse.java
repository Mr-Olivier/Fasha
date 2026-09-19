package rw.fasha.admin;

import rw.fasha.provider.VerificationStatus;
import rw.fasha.user.UserStatus;

import java.time.Instant;
import java.util.UUID;

/**
 * One row in the admin "Review application" list/detail (README.md
 * section 10's GET /api/admin/providers). Denormalized with the owner's
 * name/email/phone and their service count so the admin app never needs a
 * second round-trip per provider just to render the list - same reasoning
 * as BookingResponse's denormalized fields.
 *
 * [ownerUserId]/[ownerAccountStatus] let the admin app suspend/resume/
 * delete this provider's underlying account (AdminUserController) right
 * from this same screen, without a second fetch.
 */
public record PendingProviderResponse(
        UUID id,
        String businessName,
        String description,
        String location,
        VerificationStatus verificationStatus,
        Instant appliedAt,
        UUID ownerUserId,
        String ownerName,
        String ownerEmail,
        String ownerPhone,
        UserStatus ownerAccountStatus,
        long serviceCount,
        /** Whether this provider has ever hit "Submit for review" on their KYC documents (D7) - just a hint for the admin queue, not a gate on approving. */
        boolean documentsSubmitted
) {
}
