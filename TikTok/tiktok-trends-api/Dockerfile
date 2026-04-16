# ─── Build stage ──────────────────────────────────────────────────────────────
FROM eclipse-temurin:21-jdk AS build
WORKDIR /app

# Cache Maven dependencies in their own layer so source-only changes don't
# re-download the world. Render free-tier rebuild speed matters.
COPY pom.xml .
RUN apt-get update && apt-get install -y maven && \
    mvn -B -q dependency:go-offline

COPY src ./src
RUN mvn -B -q package -DskipTests

# ─── Runtime stage ────────────────────────────────────────────────────────────
FROM eclipse-temurin:21-jre
WORKDIR /app
COPY --from=build /app/target/*.jar app.jar

ENV SPRING_PROFILES_ACTIVE=demo
# Cap heap relative to container memory (Render free tier = 512 MB).
ENV JAVA_TOOL_OPTIONS="-XX:MaxRAMPercentage=75 -XX:InitialRAMPercentage=50"

EXPOSE 8080
ENTRYPOINT ["sh", "-c", "java -jar app.jar"]
