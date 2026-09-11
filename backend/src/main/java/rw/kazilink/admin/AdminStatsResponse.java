package rw.kazilink.admin;

/** The four numbers on the admin Overview screen's stat row. */
public record AdminStatsResponse(
        long pendingApprovals,
        long activeProviders,
        long totalCustomers,
        long bookingsLast30Days
) {
}
