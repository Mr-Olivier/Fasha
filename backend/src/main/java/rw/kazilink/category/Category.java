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
 * Read-only from the application's point of view - rows come from Flyway's
 * seed migration (V5) only. No setters, no constructor that takes fields:
 * there's nothing in this codebase that creates or edits a Category (that's
 * an admin feature, not built yet), so we don't give it an API it doesn't
 * need.
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
}
