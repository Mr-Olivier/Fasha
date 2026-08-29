package rw.kazilink;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.boot.context.properties.ConfigurationPropertiesScan;

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
 *
 * {@code @ConfigurationPropertiesScan} does the same kind of automatic
 * discovery, but for @ConfigurationProperties classes like JwtProperties -
 * without it, we'd have to register each one by hand.
 */
@SpringBootApplication
@ConfigurationPropertiesScan
public class BackendApplication {

	public static void main(String[] args) {
		SpringApplication.run(BackendApplication.class, args);
	}

}
