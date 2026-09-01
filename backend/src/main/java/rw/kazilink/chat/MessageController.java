package rw.kazilink.chat;

import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.ResponseStatus;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;
import java.util.UUID;

/**
 * No @PreAuthorize role check, same reasoning as BookingController's GET
 * endpoints - either a customer or a provider legitimately calls this, and
 * MessageService.findAccessibleBooking already confirms the caller is one
 * of this specific booking's two parties before doing anything else.
 */
@RestController
@RequiredArgsConstructor
public class MessageController {

    private final MessageService messageService;

    @GetMapping("/api/bookings/{bookingId}/messages")
    public List<MessageResponse> list(@AuthenticationPrincipal UUID userId, @PathVariable UUID bookingId) {
        return messageService.list(userId, bookingId);
    }

    @PostMapping("/api/bookings/{bookingId}/messages")
    @ResponseStatus(HttpStatus.CREATED)
    public MessageResponse send(
            @AuthenticationPrincipal UUID userId,
            @PathVariable UUID bookingId,
            @Valid @RequestBody SendMessageRequest request
    ) {
        return messageService.send(userId, bookingId, request.body());
    }
}
