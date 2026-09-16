-- Lets a chat message carry a photo or a short video instead of (or as well
-- as) text - "share what the issue looks like" from ChatScreen. body was
-- NOT NULL until now; an attachment-only message has nothing to put there,
-- so it becomes optional, guarded by the CHECK below so a message can never
-- end up with neither a body nor an attachment.
--
-- attachment_path is an OPAQUE path into the private upload directory (see
-- SecureFileStorageService), same "never a public URL, always streamed
-- through an authenticated endpoint" reasoning as booking_photos.storage_path -
-- a chat attachment is exactly as private as the conversation it's in.
ALTER TABLE messages ALTER COLUMN body DROP NOT NULL;
ALTER TABLE messages ADD COLUMN attachment_path VARCHAR(500);
ALTER TABLE messages ADD COLUMN attachment_type VARCHAR(20);
ALTER TABLE messages ADD CONSTRAINT messages_body_or_attachment
    CHECK (body IS NOT NULL OR attachment_path IS NOT NULL);
