package rw.kazilink.provider;

import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.ArgumentCaptor;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import rw.kazilink.review.ReviewRepository;
import rw.kazilink.service.ServiceListing;
import rw.kazilink.service.ServiceListingRepository;
import rw.kazilink.user.UserRepository;

import java.math.BigDecimal;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class ProviderProfileServiceTest {

    @Mock
    private ProviderProfileRepository providerProfileRepository;

    @Mock
    private ServiceListingRepository serviceListingRepository;

    @Mock
    private ReviewRepository reviewRepository;

    @Mock
    private UserRepository userRepository;

    @InjectMocks
    private ProviderProfileService providerProfileService;

    @Test
    void getMyProfile_throwsWhenNoProfileExists() {
        UUID userId = UUID.randomUUID();
        when(providerProfileRepository.findByUserId(userId)).thenReturn(Optional.empty());

        assertThatThrownBy(() -> providerProfileService.getMyProfile(userId))
                .isInstanceOf(ProviderProfileNotFoundException.class);
    }

    @Test
    void getMyProfile_returnsExistingProfile() {
        UUID userId = UUID.randomUUID();
        ProviderProfile profile = new ProviderProfile(userId, "Alice's Repairs", "Phone repair", "Kigali", null);
        when(providerProfileRepository.findByUserId(userId)).thenReturn(Optional.of(profile));

        ProviderProfileResponse response = providerProfileService.getMyProfile(userId);

        assertThat(response.businessName()).isEqualTo("Alice's Repairs");
        assertThat(response.verificationStatus()).isEqualTo(VerificationStatus.PENDING);
    }

    @Test
    void getMyProfile_hasNoRatingWhenThereAreNoReviewsYet() {
        UUID userId = UUID.randomUUID();
        ProviderProfile profile = new ProviderProfile(userId, "Alice's Repairs", null, null, null);
        when(providerProfileRepository.findByUserId(userId)).thenReturn(Optional.of(profile));
        when(reviewRepository.findAverageRatingByProviderProfileId(profile.getId())).thenReturn(Optional.empty());
        when(reviewRepository.countByProviderProfileId(profile.getId())).thenReturn(0L);

        ProviderProfileResponse response = providerProfileService.getMyProfile(userId);

        assertThat(response.averageRating()).isNull();
        assertThat(response.reviewCount()).isZero();
    }

    @Test
    void getMyProfile_includesTheAverageRatingOnceThereAreReviews() {
        UUID userId = UUID.randomUUID();
        ProviderProfile profile = new ProviderProfile(userId, "Alice's Repairs", null, null, null);
        when(providerProfileRepository.findByUserId(userId)).thenReturn(Optional.of(profile));
        when(reviewRepository.findAverageRatingByProviderProfileId(profile.getId())).thenReturn(Optional.of(4.5));
        when(reviewRepository.countByProviderProfileId(profile.getId())).thenReturn(2L);

        ProviderProfileResponse response = providerProfileService.getMyProfile(userId);

        assertThat(response.averageRating()).isEqualTo(4.5);
        assertThat(response.reviewCount()).isEqualTo(2L);
    }

    @Test
    void upsertMyProfile_createsANewProfileWhenNoneExists() {
        UUID userId = UUID.randomUUID();
        when(providerProfileRepository.findByUserId(userId)).thenReturn(Optional.empty());

        var request = new UpsertProviderProfileRequest("Alice's Repairs", "Phone repair", "Kigali", null, null, null);
        ProviderProfileResponse response = providerProfileService.upsertMyProfile(userId, request);

        assertThat(response.userId()).isEqualTo(userId);
        assertThat(response.businessName()).isEqualTo("Alice's Repairs");
        assertThat(response.verificationStatus()).isEqualTo(VerificationStatus.PENDING);

        var captor = ArgumentCaptor.forClass(ProviderProfile.class);
        verify(providerProfileRepository).saveAndFlush(captor.capture());
        assertThat(captor.getValue().getUserId()).isEqualTo(userId);
    }

    @Test
    void upsertMyProfile_updatesFieldsOnAnExistingProfileRatherThanCreatingANewOne() {
        UUID userId = UUID.randomUUID();
        ProviderProfile existing = new ProviderProfile(userId, "Old Name", "Old description", "Huye", null);
        when(providerProfileRepository.findByUserId(userId)).thenReturn(Optional.of(existing));

        var request = new UpsertProviderProfileRequest("New Name", "New description", "Kigali", "https://example.com/pic.jpg", null, null);
        providerProfileService.upsertMyProfile(userId, request);

        var captor = ArgumentCaptor.forClass(ProviderProfile.class);
        verify(providerProfileRepository).saveAndFlush(captor.capture());
        // Same object identity as `existing`, not a freshly constructed one.
        assertThat(captor.getValue()).isSameAs(existing);
        assertThat(captor.getValue().getBusinessName()).isEqualTo("New Name");
        assertThat(captor.getValue().getLocation()).isEqualTo("Kigali");
    }

    @Test
    void browseProviders_excludesProvidersThatArentApproved() {
        when(providerProfileRepository.findByVerificationStatus(VerificationStatus.APPROVED)).thenReturn(List.of());

        List<ProviderProfileResponse> results = providerProfileService.browseProviders(null, null);

        assertThat(results).isEmpty();
    }

    @Test
    void browseProviders_withNoCategoryFilterReturnsEveryApprovedProvider() {
        ProviderProfile approved = new ProviderProfile(UUID.randomUUID(), "Alice's Repairs", null, null, null);
        when(providerProfileRepository.findByVerificationStatus(VerificationStatus.APPROVED)).thenReturn(List.of(approved));

        List<ProviderProfileResponse> results = providerProfileService.browseProviders(null, null);

        assertThat(results).hasSize(1);
        assertThat(results.get(0).businessName()).isEqualTo("Alice's Repairs");
    }

    @Test
    void browseProviders_withACategoryFilterOnlyReturnsProvidersOfferingSomethingInIt() {
        ProviderProfile inCategory = new ProviderProfile(UUID.randomUUID(), "Alice's Repairs", null, null, null);
        inCategory.setId(UUID.randomUUID());
        ProviderProfile notInCategory = new ProviderProfile(UUID.randomUUID(), "Bob's Tailoring", null, null, null);
        notInCategory.setId(UUID.randomUUID());
        UUID categoryId = UUID.randomUUID();
        when(providerProfileRepository.findByVerificationStatus(VerificationStatus.APPROVED))
                .thenReturn(List.of(inCategory, notInCategory));
        when(serviceListingRepository.findByCategoryIdAndVisibleTrue(categoryId)).thenReturn(List.of(
                new ServiceListing(inCategory.getId(), categoryId, "Phone repair", null, BigDecimal.TEN)));

        List<ProviderProfileResponse> results = providerProfileService.browseProviders(categoryId, null);

        assertThat(results).hasSize(1);
        assertThat(results.get(0).businessName()).isEqualTo("Alice's Repairs");
    }

    @Test
    void browseProviders_searchMatchesBusinessNameCaseInsensitively() {
        ProviderProfile alice = new ProviderProfile(UUID.randomUUID(), "Alice's Repairs", null, null, null);
        ProviderProfile bob = new ProviderProfile(UUID.randomUUID(), "Bob's Tailoring", null, null, null);
        when(providerProfileRepository.findByVerificationStatus(VerificationStatus.APPROVED))
                .thenReturn(List.of(alice, bob));

        List<ProviderProfileResponse> results = providerProfileService.browseProviders(null, "alice");

        assertThat(results).hasSize(1);
        assertThat(results.get(0).businessName()).isEqualTo("Alice's Repairs");
    }

    @Test
    void browseProviders_searchMatchesLocationWhenBusinessNameDoesnt() {
        ProviderProfile inKigali = new ProviderProfile(UUID.randomUUID(), "Alice's Repairs", null, "Kigali", null);
        ProviderProfile inHuye = new ProviderProfile(UUID.randomUUID(), "Bob's Tailoring", null, "Huye", null);
        when(providerProfileRepository.findByVerificationStatus(VerificationStatus.APPROVED))
                .thenReturn(List.of(inKigali, inHuye));

        List<ProviderProfileResponse> results = providerProfileService.browseProviders(null, "kigali");

        assertThat(results).hasSize(1);
        assertThat(results.get(0).businessName()).isEqualTo("Alice's Repairs");
    }

    @Test
    void browseProviders_blankSearchIsTreatedAsNoFilter() {
        ProviderProfile approved = new ProviderProfile(UUID.randomUUID(), "Alice's Repairs", null, null, null);
        when(providerProfileRepository.findByVerificationStatus(VerificationStatus.APPROVED)).thenReturn(List.of(approved));

        List<ProviderProfileResponse> results = providerProfileService.browseProviders(null, "   ");

        assertThat(results).hasSize(1);
    }

    @Test
    void browseProviders_categoryAndSearchCombineRatherThanEitherAlone() {
        ProviderProfile matchesBoth = new ProviderProfile(UUID.randomUUID(), "Alice's Repairs", null, null, null);
        matchesBoth.setId(UUID.randomUUID());
        ProviderProfile matchesCategoryOnly = new ProviderProfile(UUID.randomUUID(), "Bob's Repairs", null, null, null);
        matchesCategoryOnly.setId(UUID.randomUUID());
        UUID categoryId = UUID.randomUUID();
        when(providerProfileRepository.findByVerificationStatus(VerificationStatus.APPROVED))
                .thenReturn(List.of(matchesBoth, matchesCategoryOnly));
        when(serviceListingRepository.findByCategoryIdAndVisibleTrue(categoryId)).thenReturn(List.of(
                new ServiceListing(matchesBoth.getId(), categoryId, "Phone repair", null, BigDecimal.TEN),
                new ServiceListing(matchesCategoryOnly.getId(), categoryId, "Phone repair", null, BigDecimal.TEN)));

        List<ProviderProfileResponse> results = providerProfileService.browseProviders(categoryId, "alice");

        assertThat(results).hasSize(1);
        assertThat(results.get(0).businessName()).isEqualTo("Alice's Repairs");
    }

    @Test
    void browseProviders_excludesAnApprovedProviderWhoseOwnerAccountIsSuspended() {
        UUID activeOwnerId = UUID.randomUUID();
        UUID suspendedOwnerId = UUID.randomUUID();
        ProviderProfile activeProvider = new ProviderProfile(activeOwnerId, "Alice's Repairs", null, null, null);
        ProviderProfile suspendedProvider = new ProviderProfile(suspendedOwnerId, "Bob's Tailoring", null, null, null);
        when(providerProfileRepository.findByVerificationStatus(VerificationStatus.APPROVED))
                .thenReturn(List.of(activeProvider, suspendedProvider));
        when(userRepository.findAllById(List.of(activeOwnerId, suspendedOwnerId))).thenReturn(List.of(
                new rw.kazilink.user.User("Alice", "alice@example.com", null, "hash", rw.kazilink.user.Role.PROVIDER),
                suspendedUser(suspendedOwnerId)
        ));

        List<ProviderProfileResponse> results = providerProfileService.browseProviders(null, null);

        assertThat(results).hasSize(1);
        assertThat(results.get(0).businessName()).isEqualTo("Alice's Repairs");
    }

    @Test
    void getProviderDetail_throwsWhenTheOwnerAccountIsSuspended() {
        UUID providerProfileId = UUID.randomUUID();
        UUID ownerId = UUID.randomUUID();
        ProviderProfile approved = new ProviderProfile(ownerId, "Alice's Repairs", null, null, null);
        approved.setId(providerProfileId);
        approved.setVerificationStatus(VerificationStatus.APPROVED);
        when(providerProfileRepository.findById(providerProfileId)).thenReturn(Optional.of(approved));
        when(userRepository.findById(ownerId)).thenReturn(Optional.of(suspendedUser(ownerId)));

        assertThatThrownBy(() -> providerProfileService.getProviderDetail(providerProfileId))
                .isInstanceOf(ProviderNotFoundException.class);
    }

    private rw.kazilink.user.User suspendedUser(UUID id) {
        rw.kazilink.user.User user = new rw.kazilink.user.User("Bob", "bob@example.com", null, "hash", rw.kazilink.user.Role.PROVIDER);
        user.setId(id);
        user.setStatus(rw.kazilink.user.UserStatus.SUSPENDED);
        return user;
    }

    @Test
    void getProviderDetail_throwsForAProviderThatIsNotApproved() {
        ProviderProfile pending = new ProviderProfile(UUID.randomUUID(), "Alice's Repairs", null, null, null);
        UUID providerProfileId = UUID.randomUUID();
        when(providerProfileRepository.findById(providerProfileId)).thenReturn(Optional.of(pending));

        assertThatThrownBy(() -> providerProfileService.getProviderDetail(providerProfileId))
                .isInstanceOf(ProviderNotFoundException.class);
    }

    @Test
    void getProviderDetail_returnsTheProfileWithItsServices() {
        UUID providerProfileId = UUID.randomUUID();
        ProviderProfile approved = new ProviderProfile(UUID.randomUUID(), "Alice's Repairs", null, null, null);
        approved.setId(providerProfileId);
        approved.setVerificationStatus(VerificationStatus.APPROVED);
        when(providerProfileRepository.findById(providerProfileId)).thenReturn(Optional.of(approved));
        when(serviceListingRepository.findByProviderProfileIdAndVisibleTrue(providerProfileId)).thenReturn(List.of(
                new ServiceListing(providerProfileId, UUID.randomUUID(), "Phone repair", "Screens & batteries", BigDecimal.TEN)));

        ProviderDetailResponse detail = providerProfileService.getProviderDetail(providerProfileId);

        assertThat(detail.profile().businessName()).isEqualTo("Alice's Repairs");
        assertThat(detail.services()).hasSize(1);
        assertThat(detail.services().get(0).name()).isEqualTo("Phone repair");
    }
}
