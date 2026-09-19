package rw.fasha.booking;

/**
 * Which side of a booking attached a given BookingPhoto - a customer's
 * evidence of the problem (attached when creating the request) or a
 * provider's proof of the finished work (attached while IN_PROGRESS).
 */
public enum PhotoUploaderRole {
    CUSTOMER,
    PROVIDER
}
