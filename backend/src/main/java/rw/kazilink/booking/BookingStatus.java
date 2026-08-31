package rw.kazilink.booking;

/**
 * The booking lifecycle (see README.md section 7's state diagram).
 *
 * REQUESTED --> ACCEPTED --> IN_PROGRESS --> COMPLETED
 *      \--> REJECTED          \--> CANCELLED (customer, while still eligible)
 *      \--> CANCELLED
 *
 * There's no REVIEWED state yet - the README's diagram has COMPLETED lead
 * into a review step, but reviews are a separate, not-yet-built feature.
 * COMPLETED is the last state for now; adding REVIEWED later is a simple,
 * additive change once that feature exists.
 */
public enum BookingStatus {
    REQUESTED,
    ACCEPTED,
    REJECTED,
    IN_PROGRESS,
    COMPLETED,
    CANCELLED
}
