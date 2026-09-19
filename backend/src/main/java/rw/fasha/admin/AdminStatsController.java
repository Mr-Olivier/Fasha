package rw.fasha.admin;

import lombok.RequiredArgsConstructor;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;

/** Backs the admin Overview screen's stat row and dashboard charts - see README.md section 10. */
@RestController
@RequestMapping("/api/admin/stats")
@RequiredArgsConstructor
@PreAuthorize("hasRole('ADMIN')")
public class AdminStatsController {

    private final AdminStatsService adminStatsService;

    @GetMapping
    public AdminStatsResponse getStats() {
        return adminStatsService.getStats();
    }

    @GetMapping("/bookings-trend")
    public List<BookingTrendPoint> getBookingsTrend(@RequestParam(defaultValue = "30") int days) {
        return adminStatsService.getBookingsTrend(days);
    }

    @GetMapping("/user-growth")
    public List<UserGrowthPoint> getUserGrowth(@RequestParam(defaultValue = "12") int weeks) {
        return adminStatsService.getUserGrowth(weeks);
    }
}
