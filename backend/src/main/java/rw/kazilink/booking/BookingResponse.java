package rw.kazilink.booking;

import java.math.BigDecimal;
import java.time.Instant;
import java.time.LocalDate;
import java.util.UUID;

/**
 * What the app gets back for a booking. Includes denormalized display
 * fields (customerName, providerBusinessName, serviceName, servicePrice)
 * so "My Bookings" / "Incoming Requests" list screens can render a useful
 * card without a separate round-trip per booking - see
 * BookingService.toResponse() for where these get looked up.
 *
 * customerPhone/providerPhone are the two parties' only way to actually
 * reach each other once a booking is accepted - there's no in-app chat.
 * Either can be null if that user never set a phone number.
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
        BookingStatus status,
        Instant createdAt,
        Instant updatedAt
) {
}
