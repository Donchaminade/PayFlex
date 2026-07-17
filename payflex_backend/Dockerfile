# syntax=docker/dockerfile:1
#
# Build multi-stage pour payflex_backend (Spring Boot 3.4.5 / Java 17, cf. pom.xml).
#
# Usage :
#   docker build -t payflex-backend -f payflex_backend/Dockerfile payflex_backend
# (ou via docker-compose.yml à la racine du repo, qui définit déjà le bon contexte)

# ---------------------------------------------------------------------------
# Stage 1 : build Maven
# ---------------------------------------------------------------------------
FROM maven:3.9-eclipse-temurin-17 AS build

WORKDIR /build

# Couche de cache dépendances : copiée avant le code source pour éviter de
# retélécharger tout le repo Maven à chaque changement de code.
COPY pom.xml .
RUN mvn -B -q dependency:go-offline

COPY src ./src
RUN mvn -B -q -DskipTests package

# ---------------------------------------------------------------------------
# Stage 2 : runtime léger
# ---------------------------------------------------------------------------
FROM eclipse-temurin:17-jre-alpine AS runtime

# Utilisateur non-root pour l'exécution du jar
RUN addgroup -S payflex && adduser -S payflex -G payflex

WORKDIR /app

COPY --from=build /build/target/*.jar app.jar

# Dossiers montés en volume en prod (logs applicatifs, pièces jointes uploadées)
RUN mkdir -p /app/logs /app/uploads && chown -R payflex:payflex /app

USER payflex

# Port applicatif (server.port dans application.yml, défaut 8088)
EXPOSE 8088

ENTRYPOINT ["java", "-jar", "/app/app.jar"]
