package rw.kazilink.booking;

import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import rw.kazilink.notification.NotificationService;
import rw.kazilink.provider.ProviderProfile;
import rw.kazilink.provider.ProviderProfileNotFoundException;
import rw.kazilink.provider.ProviderProfileRepository;
import rw.kazilink.service.ServiceListing;
import rw.kazilink.service.ServiceListingNotFoundException;
import rw.kazilink.service.ServiceListingRepository;
import rw.kazilink.user.Role;
import rw.kazilink.user.User;
import rw.kazilink.user.UserRepository;

import java.math.BigDecimal;
import java.util.Optional;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.Mockito.when;

/**
 * Unit tests for BookingService's status state machine (see
 * BookingStatus's doc comment for the diagram this enforces) and its
 * ownership checks - a booking should only ever be visible to, or
 * actionable by, the customer or provider it actually belongs to.
 */
@ExtendWith(MockitoExtension.class)
class BookingServiceTest {

    @Mock
    private BookingRepository bookingRepository;

    @Mock
    private ServiceListingRepository serviceListingRepository;

    @Mock
    private ProviderProfileRepository providerProfileRepository;

    @Mock
    private UserRepository userRepository;

    @Mock
    private NotificationService notificationService;

    @InjectMocks
    private BookingService bookingService;

    private final UUID customerId = UUID.randomUUID();
    private final UUID providerUserId = UUID.randomUUID();
    private final UUID providerProfileId = UUID.randomUUID();
    private final UUID serviceListingId = UUID.randomUUID();

    private void stubLookupsForToResponse(Booking booking) {
        User customer = new User("Alice Uwase", "alice@example.com", "0788111222", "hash", Role.CUSTOMER);
        ProviderProfile provider = new ProviderProfile(providerUserId, "Bob's Repairs", null, null, null);
        provider.setId(providerProfileId);
        User providerOwner = new User("Bob Provider", "bob@example.com", "0788333444", "hash", Role.PROVIDER);
        ServiceListing service = new ServiceListing(providerProfileId, UUID.randomUUID(), "Phone repair", null, BigDecimal.TEN);

        when(userRepository.findById(booking.getCustomerId())).thenReturn(Optional.of(customer));
        when(providerProfileRepository.findById(booking.getProviderProfileId())).thenReturn(Optional.of(provider));
        when(userRepository.findById(providerUserId)).thenReturn(Optional.of(providerOwner));
        when(serviceListingRepository.findById(booking.getServiceListingId())).thenReturn(Optional.of(service));
    }

    @Test
    void createBooking_startsInRequestedStatus() {
        // service.getId() feeds directly into the new Booking's
        // serviceListingId inside createBooking(), so it must be set here -
        // a real, persisted ServiceListing always has one; only a bare
        // `new ServiceListing(...)` in a test doesn't.
        ServiceListing service = new ServiceListing(providerProfileId, UUID.randomUUID(), "Phone repair", null, BigDecimal.TEN);
        service.setId(serviceListingId);
        when(serviceListingRepository.findById(serviceListingId)).thenReturn(Optional.of(service));

        User customer = new User("Alice Uwase", "alice@example.com", null, "hash", Role.CUSTOMER);
        ProviderProfile provider = new ProviderProfile(providerUserId, "Bob's Repairs", null, null, null);
        provider.setId(providerProfileId);
        User providerOwner = new User("Bob Provider", "bob@example.com", null, "hash", Role.PROVIDER);
        when(userRepository.findById(customerId)).thenReturn(Optional.of(customer));
        when(providerProfileRepository.findById(providerProfileId)).thenReturn(Optional.of(provider));
        when(userRepository.findById(providerUserId)).thenReturn(Optional.of(providerOwner));

        BookingResponse response = bookingService.createBooking(customerId, new CreateBookingRequest(serviceListingId, "Cracked screen", null));

        assertThat(response.status()).isEqualTo(BookingStatus.REQUESTED);
        assertThat(response.customerId()).isEqualTo(customerId);
        assertThat(response.providerProfileId()).isEqualTo(providerProfileId);
    }

    @Test
    void createBooking_rejectsAnUnknownServiceListing() {
        when(serviceListingRepository.findById(serviceListingId)).thenReturn(Optional.empty());

        assertThatThrownBy(() -> bookingService.createBooking(customerId, new CreateBookingRequest(serviceListingId, null, null)))
                .isInstanceOf(ServiceListingNotFoundException.class);
    }

    @Test
    void accept_movesARequestedBookingToAccepted() {
        Booking booking = new Booking(customerId, providerProfileId, serviceListingId, null, null);
        UUID bookingId = UUID.randomUUID();
        booking.setId(bookingId);
        ProviderProfile providerProfile = new ProviderProfile(providerUserId, "Bob's Repairs", null, null, null);
        providerProfile.setId(providerProfileId);
        when(providerProfileRepository.findByUserId(providerUserId)).thenReturn(Optional.of(providerProfile));
        when(bookingRepository.findById(bookingId)).thenReturn(Optional.of(booking));
        stubLookupsForToResponse(booking);

        BookingResponse response = bookingService.accept(providerUserId, bookingId);

        assertThat(response.status()).isEqualTo(BookingStatus.ACCEPTED);
    }

    @Test
    void accept_rejectsABookingThatIsNotInRequestedStatus() {
        Booking booking = new Booking(customerId, providerProfileId, serviceListingId, null, null);
        booking.setStatus(BookingStatus.ACCEPTED);
        UUID bookingId = UUID.randomUUID();
        booking.setId(bookingId);
        ProviderProfile providerProfile = new ProviderProfile(providerUserId, "Bob's Repairs", null, null, null);
        providerProfile.setId(providerProfileId);
        when(providerProfileRepository.findByUserId(providerUserId)).thenReturn(Optional.of(providerProfile));
        when(bookingRepository.findById(bookingId)).thenReturn(Optional.of(booking));

        assertThatThrownBy(() -> bookingService.accept(providerUserId, bookingId))
                .isInstanceOf(InvalidBookingTransitionException.class);
    }

    @Test
    void accept_hidesABookingThatBelongsToADifferentProvider() {
        Booking booking = new Booking(customerId, UUID.randomUUID(), serviceListingId, null, null);
        UUID bookingId = UUID.randomUUID();
        booking.setId(bookingId);
        ProviderProfile someOtherProvider = new ProviderProfile(providerUserId, "Bob's Repairs", null, null, null);
        someOtherProvider.setId(providerProfileId);
        when(providerProfileRepository.findByUserId(providerUserId)).thenReturn(Optional.of(someOtherProvider));
        when(bookingRepository.findById(bookingId)).thenReturn(Optional.of(booking));

        assertThatThrownBy(() -> bookingService.accept(providerUserId, bookingId))
                .isInstanceOf(BookingNotFoundException.class);
    }

    @Test
    void accept_requiresTheCallerToHaveAProviderProfile() {
        UUID bookingId = UUID.randomUUID();
        when(providerProfileRepository.findByUserId(providerUserId)).thenReturn(Optional.empty());

        assertThatThrownBy(() -> bookingService.accept(providerUserId, bookingId))
                .isInstanceOf(ProviderProfileNotFoundException.class);
    }

    @Test
    void fullHappyPathLifecycle_requestedToAcceptedToInProgressToCompleted() {
        Booking booking = new Booking(customerId, providerProfileId, serviceListingId, null, null);
        UUID bookingId = UUID.randomUUID();
        booking.setId(bookingId);
        ProviderProfile providerProfile = new ProviderProfile(providerUserId, "Bob's Repairs", null, null, null);
        providerProfile.setId(providerProfileId);
        when(providerProfileRepository.findByUserId(providerUserId)).thenReturn(Optional.of(providerProfile));
        when(bookingRepository.findById(bookingId)).thenReturn(Optional.of(booking));
        stubLookupsForToResponse(booking);

        assertThat(bookingService.accept(providerUserId, bookingId).status()).isEqualTo(BookingStatus.ACCEPTED);
        assertThat(bookingService.start(providerUserId, bookingId).status()).isEqualTo(BookingStatus.IN_PROGRESS);
        assertThat(bookingService.complete(providerUserId, bookingId).status()).isEqualTo(BookingStatus.COMPLETED);
    }

    @Test
    void cancel_worksWhileStillRequested() {
        Booking booking = new Booking(customerId, providerProfileId, serviceListingId, null, null);
        UUID bookingId = UUID.randomUUID();
        booking.setId(bookingId);
        when(bookingRepository.findById(bookingId)).thenReturn(Optional.of(booking));
        stubLookupsForToResponse(booking);

        BookingResponse response = bookingService.cancel(customerId, bookingId);

        assertThat(response.status()).isEqualTo(BookingStatus.CANCELLED);
    }

    @Test
    void cancel_rejectsABookingThatIsAlreadyInProgress() {
        Booking booking = new Booking(customerId, providerProfileId, serviceListingId, null, null);
        booking.setStatus(BookingStatus.IN_PROGRESS);
        UUID bookingId = UUID.randomUUID();
        booking.setId(bookingId);
        when(bookingRepository.findById(bookingId)).thenReturn(Optional.of(booking));

        assertThatThrownBy(() -> bookingService.cancel(customerId, bookingId))
                .isInstanceOf(InvalidBookingTransitionException.class);
    }

    @Test
    void cancel_hidesABookingThatBelongsToADifferentCustomer() {
        Booking booking = new Booking(UUID.randomUUID(), providerProfileId, serviceListingId, null, null);
        UUID bookingId = UUID.randomUUID();
        booking.setId(bookingId);
        when(bookingRepository.findById(bookingId)).thenReturn(Optional.of(booking));

        assertThatThrownBy(() -> bookingService.cancel(customerId, bookingId))
                .isInstanceOf(BookingNotFoundException.class);
    }
}
