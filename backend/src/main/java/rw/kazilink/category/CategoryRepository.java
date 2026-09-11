package rw.kazilink.category;

import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.UUID;

public interface CategoryRepository extends JpaRepository<Category, UUID> {

    List<Category> findAllByOrderByNameAsc();

    /** Powers the public GET /api/categories - a hidden category never reaches customers. */
    List<Category> findByActiveTrueOrderByNameAsc();

    boolean existsByNameIgnoreCase(String name);

    /** Used when renaming a category - excludes itself so keeping the same name doesn't false-positive as a clash. */
    boolean existsByNameIgnoreCaseAndIdNot(String name, UUID id);
}
