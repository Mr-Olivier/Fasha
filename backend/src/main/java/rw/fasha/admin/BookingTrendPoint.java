package rw.fasha.admin;

import java.time.LocalDate;

/** One point on the admin dashboard's "Bookings trend" line chart - how many bookings were made on `date`. */
public record BookingTrendPoint(LocalDate date, long count) {
}
