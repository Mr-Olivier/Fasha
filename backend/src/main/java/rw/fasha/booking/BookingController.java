package rw.fasha.booking;

import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PatchMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;
import java.util.UUID;

/**
 * GET endpoints here take a `role` query param (matching README.md's API
 * table) rather than @PreAuthorize, because either a customer OR a
 * provider legitimately calls them, just for a different slice of their
 * own bookings. That's still safe without a role check: every branch below
 * only ever looks up bookings scoped to the CALLER's own id (see
 * BookingService), so there's nothing to gain by lying about your role -
 * "role=provider" for a user with no provider profile just throws
 * ProviderProfileNotFoundException.
 */
@RestController
@RequestMapping("/api/bookings")
@RequiredArgsConstructor
public class BookingController {

    private final BookingService bookingService;

    @PostMapping
    @PreAuthorize("hasRole('CUSTOMER')")
    public ResponseEntity<BookingResponse> create(
            @AuthenticationPrincipal UUID userId,
            @Valid @RequestBody CreateBookingRequest request
    ) {
        return ResponseEntity.status(HttpStatus.CREATED).body(bookingService.createBooking(userId, request));
    }

    @GetMapping
    public List<BookingResponse> list(@AuthenticationPrincipal UUID userId, @RequestParam String role) {
        return switch (role) {
            case "customer" -> bookingService.listForCustomer(userId);
            case "provider" -> bookingService.listForProvider(userId);
            default -> throw new InvalidBookingRoleException();
        };
    }

    @GetMapping("/{id}")
    public BookingResponse getOne(@AuthenticationPrincipal UUID userId, @PathVariable UUID id, @RequestParam String role) {
        return switch (role) {
            case "customer" -> bookingService.getForCustomer(userId, id);
            case "provider" -> bookingService.getForProvider(userId, id);
            default -> throw new InvalidBookingRoleException();
        };
    }

    @PatchMapping("/{id}/accept")
    @PreAuthorize("hasRole('PROVIDER')")
    public BookingResponse accept(@AuthenticationPrincipal UUID userId, @PathVariable UUID id) {
        return bookingService.accept(userId, id);
    }

    @PatchMapping("/{id}/reject")
    @PreAuthorize("hasRole('PROVIDER')")
    public BookingResponse reject(@AuthenticationPrincipal UUID userId, @PathVariable UUID id) {
        return bookingService.reject(userId, id);
    }

    @PatchMapping("/{id}/start")
    @PreAuthorize("hasRole('PROVIDER')")
    public BookingResponse start(@AuthenticationPrincipal UUID userId, @PathVariable UUID id) {
        return bookingService.start(userId, id);
    }

    @PatchMapping("/{id}/complete")
    @PreAuthorize("hasRole('PROVIDER')")
    public BookingResponse complete(@AuthenticationPrincipal UUID userId, @PathVariable UUID id) {
        return bookingService.complete(userId, id);
    }

    @PatchMapping("/{id}/work-note")
    @PreAuthorize("hasRole('PROVIDER')")
    public BookingResponse updateWorkNote(
            @AuthenticationPrincipal UUID userId,
            @PathVariable UUID id,
            @Valid @RequestBody UpdateWorkNoteRequest request
    ) {
        return bookingService.updateWorkNote(userId, id, request.note());
    }

    @PatchMapping("/{id}/cancel")
    @PreAuthorize("hasRole('CUSTOMER')")
    public BookingResponse cancel(
            @AuthenticationPrincipal UUID userId,
            @PathVariable UUID id,
            @Valid @RequestBody(required = false) CancelBookingRequest request
    ) {
        return bookingService.cancel(userId, id, request == null ? null : request.reason());
    }
}
