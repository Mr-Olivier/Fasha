package rw.kazilink.chat;

import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import rw.kazilink.booking.Booking;
import rw.kazilink.booking.BookingNotFoundException;
import rw.kazilink.booking.BookingRepository;
import rw.kazilink.notification.NotificationService;
import rw.kazilink.provider.ProviderProfileNotFoundException;
import rw.kazilink.provider.ProviderProfileRepository;
import rw.kazilink.user.User;
import rw.kazilink.user.UserNotFoundException;
import rw.kazilink.user.UserRepository;

import java.util.List;
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

    public List<MessageResponse> list(UUID callerId, UUID bookingId) {
        findAccessibleBooking(callerId, bookingId);
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

        User sender = userRepository.findById(callerId).orElseThrow(UserNotFoundException::new);
        UUID recipientId = resolveOtherParty(callerId, booking);
        notificationService.create(recipientId, "New message from " + sender.getName(), preview(body), bookingId);

        return toResponse(message);
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

    private String preview(String body) {
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
                message.getCreatedAt()
        );
    }
}
