package rw.kazilink.booking;

import java.math.BigDecimal;
import java.time.Instant;
import java.time.LocalDate;
import java.util.List;
import java.util.UUID;

/**
 * What the app gets back for a booking. Includes denormalized display
 * fields (customerName, providerBusinessName, serviceName, servicePrice)
 * so "My Bookings" / "Incoming Requests" list screens can render a useful
 * card without a separate round-trip per booking - see
 * BookingService.toResponse() for where these get looked up.
 *
 * customerPhone/providerPhone let the two parties call each other once a
 * booking is accepted - either can be null if that user never set a phone
 * number. In-app chat (rw.kazilink.chat) is the other way, keyed off this
 * same booking id instead of living on this response.
 */
public record BookingResponse(
        UUID id,
        UUID customerId,
        String customerName,
        String customerPhone,
        UUID providerProfileId,
        String providerBusinessName,
        String providerPhone,
        UUID serviceListingId,
        String serviceName,
        BigDecimal servicePrice,
        String note,
        LocalDate requestedDate,
        String address,
        TimeWindow timeWindow,
        BookingStatus status,
        String workNote,
        String cancellationReason,
        List<BookingStatusHistoryEntry> statusHistory,
        Instant createdAt,
        Instant updatedAt
) {
}
