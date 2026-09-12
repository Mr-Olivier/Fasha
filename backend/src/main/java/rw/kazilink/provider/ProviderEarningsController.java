package rw.kazilink.provider;

import lombok.RequiredArgsConstructor;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;
import java.util.UUID;

/** D8 - "Completed jobs & earnings". [period] is "month" or "all"; anything else is treated as "all". */
@RestController
@RequestMapping("/api/providers/me")
@RequiredArgsConstructor
public class ProviderEarningsController {

    private final ProviderEarningsService providerEarningsService;

    @GetMapping("/earnings")
    @PreAuthorize("hasRole('PROVIDER')")
    public EarningsSummaryResponse getEarnings(
            @AuthenticationPrincipal UUID userId,
            @RequestParam(defaultValue = "all") String period
    ) {
        return providerEarningsService.getSummary(userId, period);
    }

    @GetMapping("/completed-jobs")
    @PreAuthorize("hasRole('PROVIDER')")
    public List<CompletedJobResponse> getCompletedJobs(
            @AuthenticationPrincipal UUID userId,
            @RequestParam(defaultValue = "all") String period
    ) {
        return providerEarningsService.listCompletedJobs(userId, period);
    }
}
