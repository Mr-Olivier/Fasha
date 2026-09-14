package rw.kazilink.booking;

/**
 * The rough time-of-day a customer prefers the provider show up, collected
 * on the Request Service form. A small fixed set, same reasoning as
 * ServiceDuration - a plain enum column rather than a lookup table.
 */
public enum TimeWindow {
    MORNING,
    AFTERNOON,
    EVENING
}
