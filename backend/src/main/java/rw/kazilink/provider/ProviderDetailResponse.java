package rw.kazilink.provider;

import rw.kazilink.service.ServiceListingResponse;

import java.util.List;

/** What GET /api/providers/{id} returns - a provider's public profile plus the services they offer. */
public record ProviderDetailResponse(
        ProviderProfileResponse profile,
        List<ServiceListingResponse> services
) {
}
