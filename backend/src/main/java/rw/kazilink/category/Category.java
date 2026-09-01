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
 * Rows come from Flyway's seed migration (V5) plus whatever an admin has
 * since added/renamed via AdminCategoryService - the all-args constructor
 * below is also what both that service and tests use to build instances.
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

    public void rename(String name, String description) {
        this.name = name;
        this.description = description;
    }
}
