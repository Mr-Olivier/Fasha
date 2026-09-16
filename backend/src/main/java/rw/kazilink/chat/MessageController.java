package rw.kazilink.chat;

import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.core.io.Resource;
import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.ResponseStatus;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.multipart.MultipartFile;

import java.net.URLConnection;
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

    /** [caption] is optional free text alongside the photo/video - the multipart equivalent of {@link #send}'s body. */
    @PostMapping("/api/bookings/{bookingId}/messages/attachment")
    @ResponseStatus(HttpStatus.CREATED)
    public MessageResponse sendAttachment(
            @AuthenticationPrincipal UUID userId,
            @PathVariable UUID bookingId,
            @RequestParam("file") MultipartFile file,
            @RequestParam(value = "caption", required = false) String caption
    ) {
        return messageService.sendAttachment(userId, bookingId, file, caption);
    }

    @GetMapping("/api/bookings/{bookingId}/messages/{messageId}/attachment")
    public ResponseEntity<Resource> downloadAttachment(
            @AuthenticationPrincipal UUID userId,
            @PathVariable UUID bookingId,
            @PathVariable UUID messageId
    ) {
        Resource resource = messageService.downloadAttachment(userId, bookingId, messageId);
        String contentType = URLConnection.guessContentTypeFromName(resource.getFilename());
        return ResponseEntity.ok()
                .contentType(contentType != null ? MediaType.parseMediaType(contentType) : MediaType.APPLICATION_OCTET_STREAM)
                .body(resource);
    }

    /** "Clear chat" - permanently deletes every message and attachment in this booking's conversation for both parties. See MessageService.clearChat's doc comment. */
    @DeleteMapping("/api/bookings/{bookingId}/messages")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    public void clearChat(@AuthenticationPrincipal UUID userId, @PathVariable UUID bookingId) {
        messageService.clearChat(userId, bookingId);
    }
}
