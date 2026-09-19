package rw.fasha.admin;

import lombok.RequiredArgsConstructor;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;

/** Read side of the admin audit trail - see V21's migration comment and AdminAuditService for what gets recorded. */
@RestController
@RequestMapping("/api/admin/audit-log")
@RequiredArgsConstructor
@PreAuthorize("hasRole('ADMIN')")
public class AdminAuditController {

    private final AdminAuditService adminAuditService;

    @GetMapping
    public List<AdminAuditLogResponse> list(@RequestParam(defaultValue = "50") int limit) {
        return adminAuditService.listRecent(limit);
    }
}
