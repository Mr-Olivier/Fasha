package rw.kazilink.booking;

/**
 * The booking lifecycle (see README.md section 7's state diagram).
 *
 * REQUESTED --> ACCEPTED --> IN_PROGRESS --> COMPLETED --> REVIEWED
 *      \--> REJECTED          \--> CANCELLED (customer, while still eligible)
 *      \--> CANCELLED
 *
 * REVIEWED is set automatically by ReviewService the moment a customer
 * successfully reviews a COMPLETED booking - there's no separate PATCH
 * transition endpoint for it (unlike accept/start/complete/cancel), since
 * "leaving a review" and "marking the booking reviewed" are the same event,
 * not two independent actions.
 */
public enum BookingStatus {
    REQUESTED,
    ACCEPTED,
    REJECTED,
    IN_PROGRESS,
    COMPLETED,
    CANCELLED,
    REVIEWED;

    /**
     * Whether the two parties have anything left to coordinate directly -
     * true from the moment a provider accepts through to after the review.
     * Shared by both ways they reach each other: the mobile call-contact
     * row (mirrored client-side per screen, since it's a pure display
     * decision) and MessageService, which actually enforces this one
     * server-side since sending a message is a real write, not just a UI
     * hide.
     */
    public boolean allowsContact() {
        return this == ACCEPTED || this == IN_PROGRESS || this == COMPLETED || this == REVIEWED;
    }
}
