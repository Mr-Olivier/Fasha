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
    REVIEWED
}
