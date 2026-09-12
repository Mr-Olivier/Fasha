package rw.kazilink.service;

/** Body for PATCH /api/providers/me/services/{id}/visibility - the "show in search" toggle on My Services. */
public record UpdateServiceVisibilityRequest(boolean visible) {
}
