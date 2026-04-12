# Phase 1: Build Stage
FROM maven:3.9.6-eclipse-temurin-17 AS builder
WORKDIR /app
COPY pom.xml .
RUN mvn dependency:go-offline -B
COPY src ./src
RUN mvn clean package -DskipTests

# Phase 2: Runtime Stage
FROM eclipse-temurin:17-jre-alpine
WORKDIR /app

# Add a non-root user to run the application
RUN addgroup -S spring && adduser -S spring -G spring
USER spring:spring

# Copy built artifact
COPY --from=builder --chown=spring:spring /app/target/portal-0.0.1-SNAPSHOT.jar app.jar

# Expose the application port
EXPOSE 8080

ENTRYPOINT ["java", "-jar", "app.jar"]
