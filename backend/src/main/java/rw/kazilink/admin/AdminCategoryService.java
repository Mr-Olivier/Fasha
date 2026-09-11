package rw.kazilink.admin;

import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import rw.kazilink.booking.BookingRepository;
import rw.kazilink.category.Category;
import rw.kazilink.category.CategoryInUseException;
import rw.kazilink.category.CategoryNameAlreadyExistsException;
import rw.kazilink.category.CategoryNotFoundException;
import rw.kazilink.category.CategoryRepository;
import rw.kazilink.category.CategoryResponse;
import rw.kazilink.provider.ProviderProfileRepository;
import rw.kazilink.provider.VerificationStatus;
import rw.kazilink.service.ServiceListing;
import rw.kazilink.service.ServiceListingRepository;

import java.util.List;
import java.util.UUID;

@Service
@RequiredArgsConstructor
public class AdminCategoryService {

    private final CategoryRepository categoryRepository;
    private final ServiceListingRepository serviceListingRepository;
    private final ProviderProfileRepository providerProfileRepository;
    private final BookingRepository bookingRepository;
    private final AdminAuditService adminAuditService;

    @Transactional
    public CategoryResponse create(UUID adminUserId, String name, String description) {
        if (categoryRepository.existsByNameIgnoreCase(name)) {
            throw new CategoryNameAlreadyExistsException(name);
        }
        Category saved = categoryRepository.save(new Category(name, description));
        adminAuditService.record(adminUserId, "CATEGORY_CREATED", "CATEGORY", saved.getId(), name);
        return toResponse(saved);
    }

    @Transactional
    public CategoryResponse update(UUID adminUserId, UUID id, String name, String description) {
        Category category = categoryRepository.findById(id).orElseThrow(CategoryNotFoundException::new);
        if (categoryRepository.existsByNameIgnoreCaseAndIdNot(name, id)) {
            throw new CategoryNameAlreadyExistsException(name);
        }
        category.rename(name, description);
        CategoryResponse response = toResponse(categoryRepository.save(category));
        adminAuditService.record(adminUserId, "CATEGORY_UPDATED", "CATEGORY", id, name);
        return response;
    }

    @Transactional
    public void delete(UUID adminUserId, UUID id) {
        Category category = categoryRepository.findById(id).orElseThrow(CategoryNotFoundException::new);
        if (serviceListingRepository.existsByCategoryId(id)) {
            throw new CategoryInUseException();
        }
        categoryRepository.delete(category);
        adminAuditService.record(adminUserId, "CATEGORY_DELETED", "CATEGORY", id, category.getName());
    }

    /** Unlike the public listAll(), this includes hidden categories too - an admin needs to see them to un-hide them. */
    public List<AdminCategoryResponse> listAllForAdmin() {
        return categoryRepository.findAllByOrderByNameAsc().stream().map(this::toAdminResponse).toList();
    }

    @Transactional
    public AdminCategoryResponse setActive(UUID adminUserId, UUID id, boolean active) {
        Category category = categoryRepository.findById(id).orElseThrow(CategoryNotFoundException::new);
        category.setActive(active);
        AdminCategoryResponse response = toAdminResponse(categoryRepository.save(category));
        adminAuditService.record(adminUserId, active ? "CATEGORY_SHOWN" : "CATEGORY_HIDDEN", "CATEGORY", id, category.getName());
        return response;
    }

    private CategoryResponse toResponse(Category category) {
        return new CategoryResponse(category.getId(), category.getName(), category.getDescription());
    }

    /**
     * "Providers" only counts APPROVED ones (an admin cares about real,
     * customer-visible supply, not pending/rejected applications), while
     * "Bookings" counts every booking ever made against a service in this
     * category regardless of status - two separate queries per category is
     * fine at this scale (tens of categories, not thousands).
     */
    private AdminCategoryResponse toAdminResponse(Category category) {
        List<ServiceListing> services = serviceListingRepository.findByCategoryId(category.getId());
        List<UUID> providerProfileIds = services.stream().map(ServiceListing::getProviderProfileId).distinct().toList();
        long providerCount = providerProfileIds.isEmpty() ? 0 : providerProfileRepository.findAllById(providerProfileIds).stream()
                .filter(profile -> profile.getVerificationStatus() == VerificationStatus.APPROVED)
                .count();

        List<UUID> serviceIds = services.stream().map(ServiceListing::getId).toList();
        long bookingCount = serviceIds.isEmpty() ? 0 : bookingRepository.countByServiceListingIdIn(serviceIds);

        return new AdminCategoryResponse(
                category.getId(), category.getName(), category.getDescription(), category.isActive(), providerCount, bookingCount
        );
    }
}
