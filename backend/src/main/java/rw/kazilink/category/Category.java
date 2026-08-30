package rw.kazilink.category;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import lombok.Getter;
import lombok.NoArgsConstructor;

import java.util.UUID;

/**
 * Read-only from the application's point of view - no controller/service
 * anywhere calls categoryRepository.save(...); every row comes from
 * Flyway's seed migration (V5) instead. No setters - nothing ever edits a
 * Category in place (that's an admin feature, not built yet). The
 * all-args constructor below exists for tests to build fixture instances,
 * not because the app itself constructs new ones.
 */
@Entity
@Table(name = "categories")
@Getter
@NoArgsConstructor
public class Category {

    @Id
    @GeneratedValue
    private UUID id;

    @Column(nullable = false, unique = true, length = 100)
    private String name;

    @Column(length = 500)
    private String description;

    public Category(String name, String description) {
        this.name = name;
        this.description = description;
    }
}
