package rw.fasha.review;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

public interface ReviewRepository extends JpaRepository<Review, UUID> {

    boolean existsByBookingId(UUID bookingId);

    List<Review> findByProviderProfileIdOrderByCreatedAtDesc(UUID providerProfileId);

    /** Powers the star rating shown in provider search/detail - null (via Optional) when a provider has no reviews yet. */
    @Query("SELECT AVG(r.rating) FROM Review r WHERE r.providerProfileId = :providerProfileId")
    Optional<Double> findAverageRatingByProviderProfileId(UUID providerProfileId);

    long countByProviderProfileId(UUID providerProfileId);
}
