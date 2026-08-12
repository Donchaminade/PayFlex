#!/usr/bin/env bash
# ---------------------------------------------------------------------------
# PayFlex — script d'installation Cloud Agent (idempotent).
#
# Prépare l'environnement de développement complet :
#   - dépendances système (JDK 17, Maven, MariaDB) ;
#   - base de données `payflexdb` + utilisateur applicatif ;
#   - build du backend Spring Boot (jar) ;
#   - application des migrations Flyway + mot de passe admin de dev (admin123) ;
#   - dépendances du site vitrine Next.js.
#
# NB : le backend cible MariaDB (les migrations utilisent la syntaxe
#      `ADD COLUMN IF NOT EXISTS` propre à MariaDB, non supportée par MySQL 8).
# ---------------------------------------------------------------------------
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO_ROOT"

JAVA17_HOME=/usr/lib/jvm/java-17-openjdk-amd64
DB_NAME=payflexdb
DB_USER=payflex
DB_PASSWORD=payflex

echo "==> [1/6] Dépendances système (JDK 17, Maven, MariaDB)"
if ! command -v mvn >/dev/null 2>&1 \
   || ! command -v mariadbd >/dev/null 2>&1 \
   || [ ! -d "$JAVA17_HOME" ]; then
  sudo apt-get update -y
  sudo DEBIAN_FRONTEND=noninteractive apt-get install -y \
    openjdk-17-jdk maven mariadb-server
fi
sudo update-alternatives --set java "$JAVA17_HOME/bin/java" || true
sudo update-alternatives --set javac "$JAVA17_HOME/bin/javac" || true
export JAVA_HOME="$JAVA17_HOME"

echo "==> [2/6] Démarrage de MariaDB"
sudo service mariadb start || true
for _ in $(seq 1 30); do
  sudo mariadb -e "SELECT 1" >/dev/null 2>&1 && break
  sleep 1
done

echo "==> [3/6] Base de données et utilisateur applicatif (idempotent)"
sudo mariadb <<SQL
CREATE DATABASE IF NOT EXISTS ${DB_NAME} CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE USER IF NOT EXISTS '${DB_USER}'@'localhost' IDENTIFIED BY '${DB_PASSWORD}';
CREATE USER IF NOT EXISTS '${DB_USER}'@'127.0.0.1' IDENTIFIED BY '${DB_PASSWORD}';
GRANT ALL PRIVILEGES ON ${DB_NAME}.* TO '${DB_USER}'@'localhost';
GRANT ALL PRIVILEGES ON ${DB_NAME}.* TO '${DB_USER}'@'127.0.0.1';
FLUSH PRIVILEGES;
SQL

echo "==> [4/6] Build du backend Spring Boot"
( cd payflex_backend && mvn -B -DskipTests package )

echo "==> [5/6] Application des migrations Flyway + admin de dev"
# Démarre le backend le temps d'appliquer les migrations Flyway (versionnées =
# rejeu sans effet), puis fixe un mot de passe admin de DEV connu (admin123)
# car la migration V54 remplace le mot de passe seed par un hash non documenté.
BACKEND_JAR="$(ls payflex_backend/target/payflex_backend-*.jar | grep -v '\.original$' | head -1)"
BACKEND_JAR_NAME="$(basename "$BACKEND_JAR")"
(
  cd payflex_backend
  PAYFLEX_DB_URL="jdbc:mysql://127.0.0.1:3306/${DB_NAME}?createDatabaseIfNotExist=true&useSSL=false&allowPublicKeyRetrieval=true&serverTimezone=UTC" \
  PAYFLEX_DB_USER="${DB_USER}" \
  PAYFLEX_DB_PASSWORD="${DB_PASSWORD}" \
  PAYFLEX_PUBLIC_URL="http://localhost:8088" \
  PAYFLEX_VAULT_KEY="payflex-dev-vault-key-change-me" \
  java -jar "target/${BACKEND_JAR_NAME}" > /tmp/payflex-migrate.log 2>&1 &
  echo $! > /tmp/payflex-migrate.pid
)
# Attendre que l'API réponde (migrations appliquées)
for _ in $(seq 1 60); do
  curl -sf http://localhost:8088/api/mobile/health >/dev/null 2>&1 && break
  sleep 2
done
# Mot de passe admin de DEV (bcrypt de "admin123") — usage local uniquement.
DEV_ADMIN_HASH='$2b$10$GUqUUHmV1GQykHmfn1pGtO5rreFImOAVMzaNkkso7SBnDPzwwCUem'
sudo mariadb "${DB_NAME}" \
  -e "UPDATE admin_users SET password='${DEV_ADMIN_HASH}' WHERE username='admin';" || true
# Arrêt du backend temporaire (start.sh / terminal le relancera proprement)
if [ -f /tmp/payflex-migrate.pid ]; then
  kill "$(cat /tmp/payflex-migrate.pid)" 2>/dev/null || true
  wait "$(cat /tmp/payflex-migrate.pid)" 2>/dev/null || true
  rm -f /tmp/payflex-migrate.pid
fi

echo "==> [6/6] Dépendances du site vitrine (Next.js)"
( cd payflex_vitrine && npm ci )

echo "==> Installation terminée."
