-- Every destructive or account-affecting action an admin takes (suspend,
-- resume, delete, approve/reject a provider, add/hide/delete a category)
-- gets a permanent row here: who did it, to what, and when. Standard
-- practice for any admin panel with real account-management power - if a
-- customer or provider account is ever suspended or deleted by mistake,
-- this is how you find out which admin did it and when, not "nobody
-- knows".
--
-- No foreign key on target_id: it can point at a user, a provider profile,
-- or a category (see target_type), and the row must survive even if the
-- target itself is later deleted - an audit trail that vanishes along with
-- the thing it was auditing defeats the purpose.
CREATE TABLE admin_audit_log (
    id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    admin_user_id UUID NOT NULL REFERENCES users(id),
    action        VARCHAR(50) NOT NULL,
    target_type   VARCHAR(30) NOT NULL,
    target_id     UUID,
    details       VARCHAR(500),
    created_at    TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_admin_audit_log_created_at ON admin_audit_log(created_at DESC);
