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

    /** Hidden categories still exist (services can reference them) but drop out of the public GET /api/categories list - see CategoryService.listAll. */
    @Column(name = "is_active", nullable = false)
    private boolean active = true;

    /** Null until an admin uploads one - see V36's doc comment. Public storage path (AvatarStorageService), never a private one. */
    @Column(name = "image_url", length = 500)
    private String imageUrl;

    public Category(String name, String description) {
        this.name = name;
        this.description = description;
    }

    public void rename(String name, String description) {
        this.name = name;
        this.description = description;
    }

    public void setActive(boolean active) {
        this.active = active;
    }

    public void setImageUrl(String imageUrl) {
        this.imageUrl = imageUrl;
    }
}
