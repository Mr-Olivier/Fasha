package rw.kazilink.service;

/**
 * How long a service typically takes, shown to the customer before they
 * book. A small fixed set, same reasoning as BookingStatus - a plain enum
 * column rather than a lookup table.
 */
public enum ServiceDuration {
    ONE_TO_TWO_HOURS,
    HALF_DAY,
    FULL_DAY
}
