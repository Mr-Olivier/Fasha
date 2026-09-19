package rw.fasha.admin;

import jakarta.validation.constraints.NotNull;

/** Body for PATCH /api/admin/providers/{id}/approve - true approves, false rejects. */
public record ProviderDecisionRequest(
        @NotNull(message = "approved is required")
        Boolean approved
) {
}
