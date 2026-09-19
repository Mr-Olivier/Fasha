package rw.fasha.admin;

import org.springframework.http.HttpStatus;
import rw.fasha.common.ApplicationException;

/** Thrown by AdminUserService when a suspend/delete target is itself an ADMIN account - admins manage everyone else, never each other, through this endpoint (prevents one admin locking out or deleting another, by mistake or otherwise). */
public class CannotModifyAdminException extends ApplicationException {

    public CannotModifyAdminException() {
        super(HttpStatus.FORBIDDEN, "Admin accounts can't be suspended or deleted here.");
    }
}
