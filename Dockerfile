# ─────────────────────────────────────────────────────────
# Multi-Stage Dockerfile — Java Spring Boot App
# For: Intel / AMD64 / Linux machines
# ─────────────────────────────────────────────────────────

# Stage 1: BUILD — compile and package the JAR
FROM maven:3.9.3-eclipse-temurin-17 AS builder
WORKDIR /app
COPY pom.xml .
COPY src ./src
RUN mvn clean package -DskipTests

# Stage 2: RUN — copy only the JAR into a minimal JRE image
FROM eclipse-temurin:17-jdk-alpine
WORKDIR /app
COPY --from=builder /app/target/*.jar app.jar
EXPOSE 8080
ENTRYPOINT ["java", "-jar", "app.jar"]
