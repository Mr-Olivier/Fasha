package rw.fasha.admin;

import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.ArgumentCaptor;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import rw.fasha.booking.BookingRepository;
import rw.fasha.category.Category;
import rw.fasha.category.CategoryInUseException;
import rw.fasha.category.CategoryNameAlreadyExistsException;
import rw.fasha.category.CategoryNotFoundException;
import rw.fasha.category.CategoryRepository;
import rw.fasha.category.CategoryResponse;
import rw.fasha.provider.ProviderProfile;
import rw.fasha.provider.ProviderProfileRepository;
import rw.fasha.provider.VerificationStatus;
import rw.fasha.service.ServiceListing;
import rw.fasha.service.ServiceListingRepository;

import java.math.BigDecimal;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class AdminCategoryServiceTest {

    @Mock
    private CategoryRepository categoryRepository;

    @Mock
    private ServiceListingRepository serviceListingRepository;

    @Mock
    private ProviderProfileRepository providerProfileRepository;

    @Mock
    private BookingRepository bookingRepository;

    @Mock
    private AdminAuditService adminAuditService;

    @InjectMocks
    private AdminCategoryService adminCategoryService;

    private final UUID categoryId = UUID.randomUUID();
    private final UUID adminUserId = UUID.randomUUID();

    @Test
    void create_savesANewCategoryWhenTheNameIsFree() {
        when(categoryRepository.existsByNameIgnoreCase("Plumber")).thenReturn(false);
        when(categoryRepository.save(any(Category.class))).thenAnswer(invocation -> invocation.getArgument(0));

        CategoryResponse response = adminCategoryService.create(adminUserId, "Plumber", "Pipe and tap repairs");

        assertThat(response.name()).isEqualTo("Plumber");
        assertThat(response.description()).isEqualTo("Pipe and tap repairs");
    }

    @Test
    void create_throwsWhenTheNameAlreadyExists() {
        when(categoryRepository.existsByNameIgnoreCase("Plumber")).thenReturn(true);

        assertThatThrownBy(() -> adminCategoryService.create(adminUserId, "Plumber", null))
                .isInstanceOf(CategoryNameAlreadyExistsException.class);
        verify(categoryRepository, never()).save(any());
    }

    @Test
    void update_renamesAnExistingCategory() {
        Category category = new Category("Cleaner", "Old description");
        when(categoryRepository.findById(categoryId)).thenReturn(Optional.of(category));
        when(categoryRepository.existsByNameIgnoreCaseAndIdNot("Home Cleaner", categoryId)).thenReturn(false);
        when(categoryRepository.save(any(Category.class))).thenAnswer(invocation -> invocation.getArgument(0));

        CategoryResponse response = adminCategoryService.update(adminUserId, categoryId, "Home Cleaner", "New description");

        assertThat(response.name()).isEqualTo("Home Cleaner");
        assertThat(response.description()).isEqualTo("New description");
    }

    @Test
    void update_throwsWhenTheCategoryDoesNotExist() {
        when(categoryRepository.findById(categoryId)).thenReturn(Optional.empty());

        assertThatThrownBy(() -> adminCategoryService.update(adminUserId, categoryId, "Whatever", null))
                .isInstanceOf(CategoryNotFoundException.class);
    }

    @Test
    void update_throwsWhenRenamingToANameAnotherCategoryAlreadyHas() {
        Category category = new Category("Cleaner", null);
        when(categoryRepository.findById(categoryId)).thenReturn(Optional.of(category));
        when(categoryRepository.existsByNameIgnoreCaseAndIdNot("Electrician", categoryId)).thenReturn(true);

        assertThatThrownBy(() -> adminCategoryService.update(adminUserId, categoryId, "Electrician", null))
                .isInstanceOf(CategoryNameAlreadyExistsException.class);
    }

    @Test
    void delete_removesACategoryNoServiceUses() {
        Category category = new Category("Cleaner", null);
        when(categoryRepository.findById(categoryId)).thenReturn(Optional.of(category));
        when(serviceListingRepository.existsByCategoryId(categoryId)).thenReturn(false);

        adminCategoryService.delete(adminUserId, categoryId);

        ArgumentCaptor<Category> captor = ArgumentCaptor.forClass(Category.class);
        verify(categoryRepository).delete(captor.capture());
        assertThat(captor.getValue()).isSameAs(category);
    }

    @Test
    void delete_throwsWhenAServiceStillUsesTheCategory() {
        Category category = new Category("Cleaner", null);
        when(categoryRepository.findById(categoryId)).thenReturn(Optional.of(category));
        when(serviceListingRepository.existsByCategoryId(categoryId)).thenReturn(true);

        assertThatThrownBy(() -> adminCategoryService.delete(adminUserId, categoryId))
                .isInstanceOf(CategoryInUseException.class);
        verify(categoryRepository, never()).delete(any());
    }

    @Test
    void delete_throwsWhenTheCategoryDoesNotExist() {
        when(categoryRepository.findById(categoryId)).thenReturn(Optional.empty());

        assertThatThrownBy(() -> adminCategoryService.delete(adminUserId, categoryId))
                .isInstanceOf(CategoryNotFoundException.class);
    }

    @Test
    void listAllForAdmin_countsOnlyApprovedProvidersButEveryBooking() {
        Category category = new Category("Plumber", "Pipe repairs");
        when(categoryRepository.findAllByOrderByNameAsc()).thenReturn(List.of(category));

        UUID approvedProviderId = UUID.randomUUID();
        UUID pendingProviderId = UUID.randomUUID();
        ServiceListing approvedProviderService = new ServiceListing(approvedProviderId, category.getId(), "Tap fix", null, BigDecimal.TEN);
        ServiceListing pendingProviderService = new ServiceListing(pendingProviderId, category.getId(), "Pipe fix", null, BigDecimal.TEN);
        when(serviceListingRepository.findByCategoryId(category.getId()))
                .thenReturn(List.of(approvedProviderService, pendingProviderService));

        ProviderProfile approvedProvider = new ProviderProfile(UUID.randomUUID(), "Approved Co", null, null, null);
        approvedProvider.setVerificationStatus(VerificationStatus.APPROVED);
        ProviderProfile pendingProvider = new ProviderProfile(UUID.randomUUID(), "Pending Co", null, null, null);
        pendingProvider.setVerificationStatus(VerificationStatus.PENDING);
        when(providerProfileRepository.findAllById(List.of(approvedProviderId, pendingProviderId)))
                .thenReturn(List.of(approvedProvider, pendingProvider));

        when(bookingRepository.countByServiceListingIdIn(any())).thenReturn(5L);

        List<AdminCategoryResponse> result = adminCategoryService.listAllForAdmin();

        assertThat(result).hasSize(1);
        assertThat(result.get(0).providerCount()).isEqualTo(1);
        assertThat(result.get(0).bookingCount()).isEqualTo(5);
        assertThat(result.get(0).active()).isTrue();
    }

    @Test
    void listAllForAdmin_zeroesCountsWhenNoServiceUsesTheCategory() {
        Category category = new Category("Empty", null);
        when(categoryRepository.findAllByOrderByNameAsc()).thenReturn(List.of(category));
        when(serviceListingRepository.findByCategoryId(category.getId())).thenReturn(List.of());

        List<AdminCategoryResponse> result = adminCategoryService.listAllForAdmin();

        assertThat(result.get(0).providerCount()).isZero();
        assertThat(result.get(0).bookingCount()).isZero();
        verify(providerProfileRepository, never()).findAllById(any());
        verify(bookingRepository, never()).countByServiceListingIdIn(any());
    }

    @Test
    void setActive_hidesACategoryFromCustomers() {
        Category category = new Category("Plumber", null);
        when(categoryRepository.findById(categoryId)).thenReturn(Optional.of(category));
        when(categoryRepository.save(category)).thenReturn(category);
        when(serviceListingRepository.findByCategoryId(category.getId())).thenReturn(List.of());

        AdminCategoryResponse response = adminCategoryService.setActive(adminUserId, categoryId, false);

        assertThat(response.active()).isFalse();
        assertThat(category.isActive()).isFalse();
    }

    @Test
    void setActive_throwsWhenTheCategoryDoesNotExist() {
        when(categoryRepository.findById(categoryId)).thenReturn(Optional.empty());

        assertThatThrownBy(() -> adminCategoryService.setActive(adminUserId, categoryId, false))
                .isInstanceOf(CategoryNotFoundException.class);
    }
}
