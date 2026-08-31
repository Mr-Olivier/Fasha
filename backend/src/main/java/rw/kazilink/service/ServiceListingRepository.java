package rw.kazilink.service;

import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.UUID;

public interface ServiceListingRepository extends JpaRepository<ServiceListing, UUID> {

    List<ServiceListing> findByProviderProfileId(UUID providerProfileId);

    /** Powers GET /api/providers?categoryId=... - which providers offer something in this category. */
    List<ServiceListing> findByCategoryId(UUID categoryId);
}
