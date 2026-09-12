package rw.kazilink.booking;

import jakarta.validation.constraints.Size;

/** Body for PATCH /api/bookings/{id}/work-note - the note a provider leaves while a job is IN_PROGRESS. */
public record UpdateWorkNoteRequest(
        @Size(max = 2000, message = "Work note must be at most 2000 characters")
        String note
) {
}
