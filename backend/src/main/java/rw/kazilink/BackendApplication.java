package rw.kazilink;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;

/**
 * Entry point of the KaziLink Rwanda backend API.
 *
 * {@code @SpringBootApplication} is shorthand for three annotations:
 *  - {@code @Configuration}: this class can define Spring beans.
 *  - {@code @EnableAutoConfiguration}: Spring Boot wires up sensible defaults
 *    (web server, JPA, security, etc.) based on the dependencies on the classpath.
 *  - {@code @ComponentScan}: Spring scans this package (rw.kazilink) and every
 *    sub-package - which is why our feature packages (auth, user, provider, ...)
 *    don't need to be registered anywhere manually.
 */
@SpringBootApplication
public class BackendApplication {

	public static void main(String[] args) {
		SpringApplication.run(BackendApplication.class, args);
	}

}
