-- Identity-verification documents a provider submits so admin can confirm
-- they're a real person/business before approving them - see
-- ProviderDocumentService. Three fixed, known document types, so plain
-- columns rather than a child table (unlike booking_photos, which is a
-- genuine, unbounded list).
--
-- Every path is an OPAQUE path into the private upload directory (see
-- SecureFileStorageService), never a public URL - these are sensitive
-- personal documents (a government ID, a selfie), only ever served to the
-- owning provider or an admin, through an authenticated endpoint. All
-- nullable: a provider may not have submitted any yet, and the trade
-- certificate is optional even after submitting.
ALTER TABLE provider_profiles ADD COLUMN id_document_path VARCHAR(500);
ALTER TABLE provider_profiles ADD COLUMN trade_certificate_path VARCHAR(500);
ALTER TABLE provider_profiles ADD COLUMN selfie_with_id_path VARCHAR(500);

-- When the provider last hit "Submit for review" - lets the admin queue
-- show which pending providers actually have something to look at yet,
-- and lets ProviderDocumentService tell a fresh signup ("never submitted")
-- apart from someone waiting on a decision.
ALTER TABLE provider_profiles ADD COLUMN documents_submitted_at TIMESTAMP;
