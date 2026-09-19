package rw.fasha.service;

import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import rw.fasha.category.CategoryRepository;
import rw.fasha.provider.ProviderProfileNotFoundException;
import rw.fasha.provider.ProviderProfileRepository;

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
                providerProfileId,
                request.categoryId(),
                request.name(),
                request.description(),
                request.price(),
                request.duration(),
                request.visible());
        serviceListingRepository.save(listing);
        return toResponse(listing);
    }

    @Transactional
    public ServiceListingResponse updateService(UUID userId, UUID serviceId, UpsertServiceListingRequest request) {
        ServiceListing listing = findOwned(userId, serviceId);
        requireCategoryExists(request.categoryId());

        listing.setCategoryId(request.categoryId());
        listing.setName(request.name());
        listing.setDescription(request.description());
        listing.setPrice(request.price());
        listing.setDuration(request.duration());
        listing.setVisible(request.visible());

        serviceListingRepository.save(listing);
        return toResponse(listing);
    }

    /** The quick on/off toggle on My Services - doesn't touch any of the service's other fields. */
    @Transactional
    public ServiceListingResponse setVisibility(UUID userId, UUID serviceId, boolean visible) {
        ServiceListing listing = findOwned(userId, serviceId);
        listing.setVisible(visible);
        serviceListingRepository.save(listing);
        return toResponse(listing);
    }

    private ServiceListing findOwned(UUID userId, UUID serviceId) {
        UUID providerProfileId = resolveProviderProfileId(userId);
        return serviceListingRepository.findById(serviceId)
                .filter(existing -> existing.getProviderProfileId().equals(providerProfileId))
                .orElseThrow(ServiceListingNotFoundException::new);
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
        return ServiceListingResponse.from(listing);
    }
}
