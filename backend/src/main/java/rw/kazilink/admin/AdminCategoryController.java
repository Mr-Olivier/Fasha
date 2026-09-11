package rw.kazilink.admin;

import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PatchMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.ResponseStatus;
import org.springframework.web.bind.annotation.RestController;
import rw.kazilink.category.CategoryResponse;

import java.util.List;
import java.util.UUID;

/**
 * Write side of category management - the read side (GET /api/categories)
 * already existed and stays public, see SecurityConfig. Class-level
 * @PreAuthorize since every method here is admin-only, same reasoning as
 * AdminProviderController.
 */
@RestController
@RequestMapping("/api/admin/categories")
@RequiredArgsConstructor
@PreAuthorize("hasRole('ADMIN')")
public class AdminCategoryController {

    private final AdminCategoryService adminCategoryService;

    /** Richer than the public GET /api/categories: includes hidden categories plus provider/booking counts. */
    @GetMapping
    public List<AdminCategoryResponse> listAll() {
        return adminCategoryService.listAllForAdmin();
    }

    @PostMapping
    @ResponseStatus(HttpStatus.CREATED)
    public CategoryResponse create(@AuthenticationPrincipal UUID adminUserId, @Valid @RequestBody CategoryRequest request) {
        return adminCategoryService.create(adminUserId, request.name(), request.description());
    }

    @PatchMapping("/{id}")
    public CategoryResponse update(
            @AuthenticationPrincipal UUID adminUserId, @PathVariable UUID id, @Valid @RequestBody CategoryRequest request
    ) {
        return adminCategoryService.update(adminUserId, id, request.name(), request.description());
    }

    @DeleteMapping("/{id}")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    public void delete(@AuthenticationPrincipal UUID adminUserId, @PathVariable UUID id) {
        adminCategoryService.delete(adminUserId, id);
    }

    @PatchMapping("/{id}/visibility")
    public AdminCategoryResponse setVisibility(
            @AuthenticationPrincipal UUID adminUserId, @PathVariable UUID id, @Valid @RequestBody CategoryVisibilityRequest request
    ) {
        return adminCategoryService.setActive(adminUserId, id, request.active());
    }
}
