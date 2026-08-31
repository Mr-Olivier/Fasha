package rw.kazilink.provider;

import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

public interface ProviderProfileRepository extends JpaRepository<ProviderProfile, UUID> {

    Optional<ProviderProfile> findByUserId(UUID userId);

    /** Powers GET /api/providers - only APPROVED providers are ever publicly browsable. */
    List<ProviderProfile> findByVerificationStatus(VerificationStatus verificationStatus);
}
