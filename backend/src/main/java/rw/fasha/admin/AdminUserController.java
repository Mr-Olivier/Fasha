package rw.fasha.admin;

import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PatchMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.ResponseStatus;
import org.springframework.web.bind.annotation.RestController;
import rw.fasha.user.Role;

import java.util.List;
import java.util.UUID;

/**
 * Admin's account-management screen(s) - Customers and Providers both read
 * this same endpoint (filtered by role) and act through the same
 * suspend/resume/delete endpoints below, since "manage an account" means
 * the same thing regardless of which role it belongs to. Class-level
 * @PreAuthorize since every method here is admin-only, same reasoning as
 * every other Admin* controller.
 */
@RestController
@RequestMapping("/api/admin/users")
@RequiredArgsConstructor
@PreAuthorize("hasRole('ADMIN')")
public class AdminUserController {

    private final AdminUserService adminUserService;

    @GetMapping
    public List<AdminUserResponse> list(@RequestParam(required = false) Role role) {
        return adminUserService.list(role);
    }

    @PatchMapping("/{id}/status")
    public AdminUserResponse setStatus(
            @AuthenticationPrincipal UUID adminUserId,
            @PathVariable UUID id,
            @Valid @RequestBody UserStatusRequest request
    ) {
        return adminUserService.setStatus(adminUserId, id, request.status());
    }

    @DeleteMapping("/{id}")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    public void delete(@AuthenticationPrincipal UUID adminUserId, @PathVariable UUID id) {
        adminUserService.delete(adminUserId, id);
    }
}
