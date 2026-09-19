package rw.fasha.admin;

import java.time.LocalDate;

/** One point on the admin dashboard's "User growth" chart - new customer/provider signups in the week starting `weekStart`. Admin signups are deliberately excluded - this chart is about real platform adoption. */
public record UserGrowthPoint(LocalDate weekStart, long newCustomers, long newProviders) {
}
