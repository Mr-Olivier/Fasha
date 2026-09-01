package rw.kazilink.otp;

import org.springframework.data.jpa.repository.JpaRepository;

import java.util.Optional;
import java.util.UUID;

public interface OtpCodeRepository extends JpaRepository<OtpCode, UUID> {

    /** "Top ... OrderByCreatedAtDesc" so if a user somehow has two matching rows (extremely unlikely within the same short validity window), the most recently issued one wins. */
    Optional<OtpCode> findTopByUserIdAndPurposeAndCodeOrderByCreatedAtDesc(UUID userId, OtpPurpose purpose, String code);
}
