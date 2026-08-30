package rw.kazilink.service;

import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import rw.kazilink.category.CategoryRepository;
import rw.kazilink.provider.ProviderProfileNotFoundException;
import rw.kazilink.provider.ProviderProfileRepository;

import java.util.List;
import java.util.UUID;

@Service
@RequiredArgsConstructor
public class ServiceListingService {

    private final ServiceListingRepository serviceListingRepository;
    private final ProviderProfileRepository providerProfileRepository;
    private final CategoryRepository categoryRepository;

    public List<ServiceListingResponse> listMyServices(UUID userId) {
        UUID providerProfileId = resolveProviderProfileId(userId);
        return serviceListingRepository.findByProviderProfileId(providerProfileId).stream()
                .map(this::toResponse)
                .toList();
    }

    @Transactional
    public ServiceListingResponse addService(UUID userId, UpsertServiceListingRequest request) {
        UUID providerProfileId = resolveProviderProfileId(userId);
        requireCategoryExists(request.categoryId());

        ServiceListing listing = new ServiceListing(
                providerProfileId, request.categoryId(), request.name(), request.description(), request.price());
        serviceListingRepository.save(listing);
        return toResponse(listing);
    }

    @Transactional
    public ServiceListingResponse updateService(UUID userId, UUID serviceId, UpsertServiceListingRequest request) {
        UUID providerProfileId = resolveProviderProfileId(userId);
        requireCategoryExists(request.categoryId());

        ServiceListing listing = serviceListingRepository.findById(serviceId)
                .filter(existing -> existing.getProviderProfileId().equals(providerProfileId))
                .orElseThrow(ServiceListingNotFoundException::new);

        listing.setCategoryId(request.categoryId());
        listing.setName(request.name());
        listing.setDescription(request.description());
        listing.setPrice(request.price());

        serviceListingRepository.save(listing);
        return toResponse(listing);
    }

    /** A provider must have created their profile (Feature 3) before they can list any services. */
    private UUID resolveProviderProfileId(UUID userId) {
        return providerProfileRepository.findByUserId(userId)
                .orElseThrow(ProviderProfileNotFoundException::new)
                .getId();
    }

    private void requireCategoryExists(UUID categoryId) {
        if (!categoryRepository.existsById(categoryId)) {
            throw new InvalidCategoryException();
        }
    }

    private ServiceListingResponse toResponse(ServiceListing listing) {
        return new ServiceListingResponse(
                listing.getId(),
                listing.getProviderProfileId(),
                listing.getCategoryId(),
                listing.getName(),
                listing.getDescription(),
                listing.getPrice(),
                listing.getCreatedAt()
        );
    }
}
