package rw.fasha.user;

import org.springframework.data.jpa.repository.JpaRepository;

import java.time.Instant;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

/**
 * Spring Data JPA generates the implementation of this interface at
 * startup - we only declare the method signatures we need. JpaRepository
 * already gives us save(), findById(), findAll(), delete(), etc. for free.
 *
 * findByEmail/existsByEmail work purely from their method names: Spring
 * Data parses "findBy" + "Email" and builds
 * "SELECT * FROM users WHERE email = ?" automatically - no SQL or JPQL
 * needed for a query this simple.
 */
public interface UserRepository extends JpaRepository<User, UUID> {

    Optional<User> findByEmail(String email);

    boolean existsByEmail(String email);

    Optional<User> findByGoogleSub(String googleSub);

    /** Powers the admin overview's "Customers" stat. */
    long countByRole(Role role);

    /** Powers the admin Customers/Providers account list (GET /api/admin/users?role=...). */
    List<User> findByRoleOrderByCreatedAtDesc(Role role);

    /** Powers the admin "user growth" chart - new accounts per role since a given date. */
    List<User> findByCreatedAtAfter(Instant createdAfter);
}
