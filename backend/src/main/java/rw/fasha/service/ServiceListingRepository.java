package rw.fasha.service;

import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.UUID;

public interface ServiceListingRepository extends JpaRepository<ServiceListing, UUID> {

    List<ServiceListing> findByProviderProfileId(UUID providerProfileId);

    /** Powers a provider's own public detail page - a hidden service is excluded, same as an inactive category. */
    List<ServiceListing> findByProviderProfileIdAndVisibleTrue(UUID providerProfileId);

    /** Powers GET /api/providers?categoryId=... - which providers offer something in this category. */
    List<ServiceListing> findByCategoryId(UUID categoryId);

    /** Same as findByCategoryId, but a hidden service can't make its provider surface under "offers X" search either. */
    List<ServiceListing> findByCategoryIdAndVisibleTrue(UUID categoryId);

    /** Powers GET /api/providers?maxPrice=... - every visible service, so ProviderProfileService can compute each provider's cheapest one in memory. */
    List<ServiceListing> findByVisibleTrue();

    /** Powers the admin provider-approval list's "services listed" count. */
    long countByProviderProfileId(UUID providerProfileId);

    /** Guards AdminCategoryService.delete() - a category still used by a service can't be removed. */
    boolean existsByCategoryId(UUID categoryId);
}
