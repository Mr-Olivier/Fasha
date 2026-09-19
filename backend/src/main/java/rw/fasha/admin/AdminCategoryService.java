package rw.fasha.admin;

import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.multipart.MultipartFile;
import rw.fasha.booking.BookingRepository;
import rw.fasha.category.Category;
import rw.fasha.category.CategoryInUseException;
import rw.fasha.category.CategoryNameAlreadyExistsException;
import rw.fasha.category.CategoryNotFoundException;
import rw.fasha.category.CategoryRepository;
import rw.fasha.category.CategoryResponse;
import rw.fasha.provider.ProviderProfileRepository;
import rw.fasha.provider.VerificationStatus;
import rw.fasha.service.ServiceListing;
import rw.fasha.service.ServiceListingRepository;
import rw.fasha.user.AvatarStorageService;

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
    private final AvatarStorageService avatarStorageService;

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

    /**
     * Replaces this category's icon with an uploaded image - reuses
     * AvatarStorageService rather than the private SecureFileStorageService
     * KYC documents use, since a category icon is meant to be publicly
     * visible in the app, same trust level as an avatar or a provider's
     * business photo. A category id (not a user id) is just the prefix
     * AvatarStorageService.store uses to name the file on disk - it has no
     * other meaning to that method.
     */
    @Transactional
    public AdminCategoryResponse uploadImage(UUID adminUserId, UUID id, MultipartFile file) {
        Category category = categoryRepository.findById(id).orElseThrow(CategoryNotFoundException::new);
        category.setImageUrl(avatarStorageService.store(id, file));
        AdminCategoryResponse response = toAdminResponse(categoryRepository.save(category));
        adminAuditService.record(adminUserId, "CATEGORY_IMAGE_UPLOADED", "CATEGORY", id, category.getName());
        return response;
    }

    /** Resets a category back to CategoryStyle's default icon - see Category.imageUrl's doc comment. */
    @Transactional
    public AdminCategoryResponse removeImage(UUID adminUserId, UUID id) {
        Category category = categoryRepository.findById(id).orElseThrow(CategoryNotFoundException::new);
        category.setImageUrl(null);
        AdminCategoryResponse response = toAdminResponse(categoryRepository.save(category));
        adminAuditService.record(adminUserId, "CATEGORY_IMAGE_REMOVED", "CATEGORY", id, category.getName());
        return response;
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
        return new CategoryResponse(category.getId(), category.getName(), category.getDescription(), category.getImageUrl());
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
                category.getId(), category.getName(), category.getDescription(), category.isActive(),
                providerCount, bookingCount, category.getImageUrl()
        );
    }
}
