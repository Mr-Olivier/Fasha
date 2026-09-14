# Multi-stage build: the "build" stage has the full JDK + Maven and produces
# a runnable jar; the final image only ever contains a slim JRE + that one
# jar. This keeps the shipped image small and avoids bundling the entire
# build toolchain (compilers, Maven's own dependency cache, source code)
# into what actually runs in production.

# --- Build stage -------------------------------------------------------
FROM eclipse-temurin:21-jdk-alpine AS build
WORKDIR /app

# Copy just the wrapper + POM first so Docker can cache the downloaded
# dependencies as their own layer - they only get re-downloaded when pom.xml
# actually changes, not on every source-code edit.
COPY .mvn/ .mvn/
COPY mvnw pom.xml ./
RUN ./mvnw -B dependency:go-offline

# Now copy the actual source and build. Tests are skipped here on purpose -
# they need a live Postgres connection (see BackendApplicationTests' own
# doc comment), which isn't available during an image build; CI/the
# developer's own machine is where `./mvnw test` actually runs.
COPY src/ src/
RUN ./mvnw -B -DskipTests package

# --- Runtime stage -------------------------------------------------------
FROM eclipse-temurin:21-jre-alpine
WORKDIR /app

# Runs as a dedicated non-root user rather than the container default
# (root) - if the app were ever compromised, it can't touch anything
# outside its own working directory.
RUN addgroup -S kazilink && adduser -S kazilink -G kazilink
USER kazilink

COPY --from=build /app/target/*.jar app.jar

EXPOSE 8081

# Spring Boot's relaxed environment-variable binding already maps a
# SERVER_PORT env var to server.port on its own (see application.yml's
# `${SERVER_PORT:8081}` for the equivalent local-dev override) - so
# whoever runs this image can change the port with `-e SERVER_PORT=...`
# without anything special here.
ENTRYPOINT ["java", "-jar", "app.jar"]
