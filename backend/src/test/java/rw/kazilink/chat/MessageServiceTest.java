package rw.kazilink.chat;

import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import rw.kazilink.booking.Booking;
import rw.kazilink.booking.BookingNotFoundException;
import rw.kazilink.booking.BookingRepository;
import rw.kazilink.booking.BookingStatus;
import rw.kazilink.notification.NotificationService;
import rw.kazilink.provider.ProviderProfile;
import rw.kazilink.provider.ProviderProfileRepository;
import rw.kazilink.user.Role;
import rw.kazilink.user.User;
import rw.kazilink.user.UserRepository;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class MessageServiceTest {

    @Mock
    private MessageRepository messageRepository;

    @Mock
    private BookingRepository bookingRepository;

    @Mock
    private ProviderProfileRepository providerProfileRepository;

    @Mock
    private UserRepository userRepository;

    @Mock
    private NotificationService notificationService;

    @InjectMocks
    private MessageService messageService;

    private final UUID customerId = UUID.randomUUID();
    private final UUID providerUserId = UUID.randomUUID();
    private final UUID providerProfileId = UUID.randomUUID();
    private final UUID bookingId = UUID.randomUUID();
    private final UUID strangerId = UUID.randomUUID();

    private Booking acceptedBooking() {
        Booking booking = new Booking(customerId, providerProfileId, UUID.randomUUID(), "note", null, null, null);
        booking.setId(bookingId);
        booking.setStatus(BookingStatus.ACCEPTED);
        return booking;
    }

    private ProviderProfile providerProfile() {
        ProviderProfile profile = new ProviderProfile(providerUserId, "Dave's Plumbing", "Pipes", "Kigali", null);
        profile.setId(providerProfileId);
        return profile;
    }

    @Test
    void list_returnsMessagesWhenTheCallerIsTheCustomer() {
        Booking booking = acceptedBooking();
        when(bookingRepository.findById(bookingId)).thenReturn(Optional.of(booking));
        when(providerProfileRepository.findByUserId(customerId)).thenReturn(Optional.empty());
        Message message = new Message(bookingId, customerId, "Hi there");
        when(messageRepository.findByBookingIdOrderByCreatedAtAsc(bookingId)).thenReturn(List.of(message));
        when(userRepository.findById(customerId))
                .thenReturn(Optional.of(new User("Emma Client", "emma@example.com", "0788111222", "hash", Role.CUSTOMER)));

        List<MessageResponse> result = messageService.list(customerId, bookingId);

        assertThat(result).hasSize(1);
        assertThat(result.get(0).body()).isEqualTo("Hi there");
        assertThat(result.get(0).senderName()).isEqualTo("Emma Client");
    }

    @Test
    void list_returnsMessagesWhenTheCallerOwnsTheProviderProfile() {
        Booking booking = acceptedBooking();
        when(bookingRepository.findById(bookingId)).thenReturn(Optional.of(booking));
        when(providerProfileRepository.findByUserId(providerUserId)).thenReturn(Optional.of(providerProfile()));
        when(messageRepository.findByBookingIdOrderByCreatedAtAsc(bookingId)).thenReturn(List.of());

        List<MessageResponse> result = messageService.list(providerUserId, bookingId);

        assertThat(result).isEmpty();
    }

    @Test
    void list_throwsWhenTheCallerIsNeitherPartyOfTheBooking() {
        Booking booking = acceptedBooking();
        when(bookingRepository.findById(bookingId)).thenReturn(Optional.of(booking));
        when(providerProfileRepository.findByUserId(strangerId)).thenReturn(Optional.empty());

        assertThatThrownBy(() -> messageService.list(strangerId, bookingId))
                .isInstanceOf(BookingNotFoundException.class);
    }

    @Test
    void list_throwsWhenTheBookingDoesNotExist() {
        when(bookingRepository.findById(bookingId)).thenReturn(Optional.empty());

        assertThatThrownBy(() -> messageService.list(customerId, bookingId))
                .isInstanceOf(BookingNotFoundException.class);
    }

    @Test
    void send_savesTheMessageAndNotifiesTheProviderWhenTheCustomerSends() {
        Booking booking = acceptedBooking();
        when(bookingRepository.findById(bookingId)).thenReturn(Optional.of(booking));
        when(providerProfileRepository.findByUserId(customerId)).thenReturn(Optional.empty());
        when(messageRepository.save(any(Message.class))).thenAnswer(invocation -> invocation.getArgument(0));
        when(userRepository.findById(customerId))
                .thenReturn(Optional.of(new User("Emma Client", "emma@example.com", "0788111222", "hash", Role.CUSTOMER)));
        when(providerProfileRepository.findById(providerProfileId)).thenReturn(Optional.of(providerProfile()));

        MessageResponse response = messageService.send(customerId, bookingId, "When can you come?");

        assertThat(response.body()).isEqualTo("When can you come?");
        assertThat(response.senderId()).isEqualTo(customerId);
        verify(notificationService).create(eq(providerUserId), any(), any(), eq(bookingId));
    }

    @Test
    void send_notifiesTheCustomerWhenTheProviderSends() {
        Booking booking = acceptedBooking();
        when(bookingRepository.findById(bookingId)).thenReturn(Optional.of(booking));
        when(providerProfileRepository.findByUserId(providerUserId)).thenReturn(Optional.of(providerProfile()));
        when(messageRepository.save(any(Message.class))).thenAnswer(invocation -> invocation.getArgument(0));
        when(userRepository.findById(providerUserId))
                .thenReturn(Optional.of(new User("Dave", "dave@example.com", "0788333444", "hash", Role.PROVIDER)));

        messageService.send(providerUserId, bookingId, "On my way");

        verify(notificationService).create(eq(customerId), any(), any(), eq(bookingId));
    }

    @Test
    void send_throwsWhenTheBookingStatusDoesNotAllowContact() {
        Booking booking = acceptedBooking();
        booking.setStatus(BookingStatus.REQUESTED);
        when(bookingRepository.findById(bookingId)).thenReturn(Optional.of(booking));
        when(providerProfileRepository.findByUserId(customerId)).thenReturn(Optional.empty());

        assertThatThrownBy(() -> messageService.send(customerId, bookingId, "Hello?"))
                .isInstanceOf(MessagingNotAllowedException.class);
        verify(messageRepository, never()).save(any());
    }

    @Test
    void send_throwsWhenTheCallerIsNeitherPartyOfTheBooking() {
        Booking booking = acceptedBooking();
        when(bookingRepository.findById(bookingId)).thenReturn(Optional.of(booking));
        when(providerProfileRepository.findByUserId(strangerId)).thenReturn(Optional.empty());

        assertThatThrownBy(() -> messageService.send(strangerId, bookingId, "Hello?"))
                .isInstanceOf(BookingNotFoundException.class);
        verify(messageRepository, never()).save(any());
    }
}
