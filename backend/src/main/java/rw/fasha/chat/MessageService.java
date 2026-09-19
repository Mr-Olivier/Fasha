package rw.fasha.chat;

import lombok.RequiredArgsConstructor;
import org.springframework.core.io.Resource;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.multipart.MultipartFile;
import rw.fasha.booking.Booking;
import rw.fasha.booking.BookingNotFoundException;
import rw.fasha.booking.BookingRepository;
import rw.fasha.common.SecureFileStorageService;
import rw.fasha.notification.NotificationService;
import rw.fasha.provider.ProviderProfileNotFoundException;
import rw.fasha.provider.ProviderProfileRepository;
import rw.fasha.user.User;
import rw.fasha.user.UserNotFoundException;
import rw.fasha.user.UserRepository;

import java.util.List;
import java.util.Objects;
import java.util.UUID;

/**
 * Business rules for a booking's chat. A booking id alone is never enough -
 * every method re-derives whether the caller is actually one of the two
 * parties (the customer, or the user who owns the provider profile), same
 * "don't reveal what you can't touch" reasoning as BookingService.
 */
@Service
@RequiredArgsConstructor
public class MessageService {

    private static final int NOTIFICATION_PREVIEW_LENGTH = 80;

    private final MessageRepository messageRepository;
    private final BookingRepository bookingRepository;
    private final ProviderProfileRepository providerProfileRepository;
    private final UserRepository userRepository;
    private final NotificationService notificationService;
    private final ChatWebSocketHandler chatWebSocketHandler;
    private final SecureFileStorageService fileStorageService;

    @Transactional
    public List<MessageResponse> list(UUID callerId, UUID bookingId) {
        findAccessibleBooking(callerId, bookingId);
        markOtherPartyMessagesRead(callerId, bookingId);
        return messageRepository.findByBookingIdOrderByCreatedAtAsc(bookingId).stream()
                .map(this::toResponse)
                .toList();
    }

    @Transactional
    public MessageResponse send(UUID callerId, UUID bookingId, String body) {
        Booking booking = findAccessibleBooking(callerId, bookingId);
        if (!booking.getStatus().allowsContact()) {
            throw new MessagingNotAllowedException();
        }

        Message message = messageRepository.save(new Message(bookingId, callerId, body));
        return afterSend(callerId, booking, message);
    }

    /**
     * A photo or short video instead of (or alongside) text - "share what
     * the issue looks like" from ChatScreen, the same idea as a booking
     * photo but scoped to one message in the conversation rather than the
     * booking as a whole. [caption] is the optional text alongside it.
     */
    @Transactional
    public MessageResponse sendAttachment(UUID callerId, UUID bookingId, MultipartFile file, String caption) {
        Booking booking = findAccessibleBooking(callerId, bookingId);
        if (!booking.getStatus().allowsContact()) {
            throw new MessagingNotAllowedException();
        }

        MessageAttachmentType attachmentType = attachmentTypeOf(file.getContentType());
        String storagePath = fileStorageService.store("chat-attachments", bookingId.toString(), file);
        String body = (caption == null || caption.isBlank()) ? null : caption.trim();
        Message message = messageRepository.save(new Message(bookingId, callerId, body, storagePath, attachmentType));
        return afterSend(callerId, booking, message);
    }

    /**
     * Permanently deletes this booking's ENTIRE conversation - every
     * message row and every attachment file on disk - for both parties,
     * same "WhatsApp Clear chat" idea but implemented as a real delete
     * rather than a per-user hide, since this app has nowhere else
     * (there's no per-device local copy) for the data to keep taking up
     * space otherwise. Irreversible; ChatScreen only calls this after an
     * explicit confirmation dialog.
     */
    @Transactional
    public void clearChat(UUID callerId, UUID bookingId) {
        findAccessibleBooking(callerId, bookingId);
        List<Message> messages = messageRepository.findByBookingIdOrderByCreatedAtAsc(bookingId);
        messages.stream()
                .map(Message::getAttachmentPath)
                .filter(Objects::nonNull)
                .forEach(fileStorageService::delete);
        messageRepository.deleteAll(messages);

        // Live delivery to whoever's got this chat open right now - same
        // "instant in-screen update" reasoning as afterSend's broadcast(),
        // just telling the other party's screen to empty out instead of
        // add a message.
        chatWebSocketHandler.broadcastCleared(bookingId);
    }

    public Resource downloadAttachment(UUID callerId, UUID bookingId, UUID messageId) {
        findAccessibleBooking(callerId, bookingId);
        Message message = messageRepository.findById(messageId)
                .filter(m -> m.getBookingId().equals(bookingId) && m.getAttachmentPath() != null)
                .orElseThrow(BookingNotFoundException::new);
        return fileStorageService.load(message.getAttachmentPath());
    }

    /** Shared tail of send()/sendAttachment(): notify the other party, broadcast live, hand back the response. */
    private MessageResponse afterSend(UUID callerId, Booking booking, Message message) {
        User sender = userRepository.findById(callerId).orElseThrow(UserNotFoundException::new);
        UUID recipientId = resolveOtherParty(callerId, booking);
        notificationService.create(recipientId, "New message from " + sender.getName(), preview(message), booking.getId());

        MessageResponse response = toResponse(message);
        // Live delivery to whoever's already connected to this booking's
        // chat (ChatScreen's WebSocket) - the notification above is the
        // durable "you have a new message" signal for someone not looking
        // at the screen right now; this is the instant in-screen update.
        chatWebSocketHandler.broadcast(message.getBookingId(), response);
        return response;
    }

    private MessageAttachmentType attachmentTypeOf(String contentType) {
        if (contentType != null && contentType.startsWith("video/")) return MessageAttachmentType.VIDEO;
        return MessageAttachmentType.IMAGE;
    }

    /** Called every time either party opens this conversation - catches up the ✓✓ read receipt on whatever the OTHER party sent since it was last opened. A no-op, not an error, when there's nothing new to mark. */
    private void markOtherPartyMessagesRead(UUID callerId, UUID bookingId) {
        List<Message> unread = messageRepository.findByBookingIdAndSenderIdNotAndReadFalse(bookingId, callerId);
        if (unread.isEmpty()) return;

        unread.forEach(Message::markRead);
        messageRepository.saveAll(unread);

        // Tells the SENDER's side live, if they still have this booking's
        // chat open, so their ✓✓ updates without needing to reopen it -
        // same broadcast() used for a brand new message, just re-sent now
        // that its `read` flag has flipped.
        unread.forEach(message -> chatWebSocketHandler.broadcast(bookingId, toResponse(message)));
    }

    /** Also throws BookingNotFoundException for a booking that exists but belongs to neither of the caller's roles - same "not found" as a genuinely missing id, so probing random ids reveals nothing. */
    private Booking findAccessibleBooking(UUID callerId, UUID bookingId) {
        Booking booking = bookingRepository.findById(bookingId).orElseThrow(BookingNotFoundException::new);
        boolean isCustomer = booking.getCustomerId().equals(callerId);
        boolean isProvider = providerProfileRepository.findByUserId(callerId)
                .map(profile -> profile.getId().equals(booking.getProviderProfileId()))
                .orElse(false);
        if (!isCustomer && !isProvider) {
            throw new BookingNotFoundException();
        }
        return booking;
    }

    private UUID resolveOtherParty(UUID callerId, Booking booking) {
        if (booking.getCustomerId().equals(callerId)) {
            return providerProfileRepository.findById(booking.getProviderProfileId())
                    .orElseThrow(ProviderProfileNotFoundException::new)
                    .getUserId();
        }
        return booking.getCustomerId();
    }

    /** [message]'s body if it has one, else a generic description of its attachment - a photo-only message still needs SOME text for the recipient's notification. */
    private String preview(Message message) {
        String body = message.getBody();
        if (body == null) {
            return message.getAttachmentType() == MessageAttachmentType.VIDEO ? "📹 Video" : "📷 Photo";
        }
        return body.length() <= NOTIFICATION_PREVIEW_LENGTH ? body : body.substring(0, NOTIFICATION_PREVIEW_LENGTH - 3) + "...";
    }

    private MessageResponse toResponse(Message message) {
        User sender = userRepository.findById(message.getSenderId()).orElseThrow(UserNotFoundException::new);
        return new MessageResponse(
                message.getId(),
                message.getBookingId(),
                message.getSenderId(),
                sender.getName(),
                message.getBody(),
                message.getAttachmentType(),
                message.getCreatedAt(),
                message.isRead()
        );
    }
}
