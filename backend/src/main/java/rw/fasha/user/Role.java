package rw.fasha.user;

/**
 * The three roles from README.md section 3. Stored on the User entity as a
 * plain string in the database (see the migration's CHECK constraint) and
 * embedded in every JWT so the security layer can enforce permissions
 * without a database lookup on each request.
 */
public enum Role {
    CUSTOMER,
    PROVIDER,
    ADMIN
}
