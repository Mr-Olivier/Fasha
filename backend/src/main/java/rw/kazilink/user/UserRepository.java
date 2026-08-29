package rw.kazilink.user;

import org.springframework.data.jpa.repository.JpaRepository;

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
}
