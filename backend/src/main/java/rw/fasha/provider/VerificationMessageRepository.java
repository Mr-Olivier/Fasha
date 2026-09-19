package rw.fasha.provider;

import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.UUID;

public interface VerificationMessageRepository extends JpaRepository<VerificationMessage, UUID> {

    List<VerificationMessage> findByProviderProfileIdOrderByCreatedAtAsc(UUID providerProfileId);
}
