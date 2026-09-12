-- Photos attached to a booking - either the customer's own evidence of the
-- problem (attached when they create the request) or the provider's proof
-- of the finished work (attached while the job is in progress). Both kinds
-- share one table, distinguished by uploaded_by_role, because they're the
-- same shape of data (an image tied to a booking) and are always displayed
-- together on the same screens (request detail, active job).
--
-- storage_path is an OPAQUE path into the private upload directory (see
-- SecureFileStorageService) - never a public URL. These photos are only
-- ever served to the booking's own customer or provider, streamed through
-- an authenticated endpoint, never through the public /uploads/** path
-- avatars use.
CREATE TABLE booking_photos (
    id                UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    booking_id        UUID         NOT NULL REFERENCES bookings (id),
    uploaded_by_role  VARCHAR(20)  NOT NULL,
    storage_path      VARCHAR(500) NOT NULL,
    created_at        TIMESTAMP    NOT NULL
);

CREATE INDEX idx_booking_photos_booking_id ON booking_photos (booking_id);
