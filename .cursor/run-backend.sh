#!/usr/bin/env bash
# ---------------------------------------------------------------------------
# PayFlex — lancement du backend Spring Boot (terminal persistant).
#
# Auto-suffisant : garantit que MariaDB est démarré et prêt avant de lancer le
# backend, indépendamment du script `start`. Évite toute course entre le backend
# et une base non encore disponible au démarrage de l'agent.
# ---------------------------------------------------------------------------
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

echo "==> Vérification de MariaDB"
sudo service mariadb start || true
for _ in $(seq 1 30); do
  sudo mariadb -e "SELECT 1" >/dev/null 2>&1 && break
  sleep 1
done

cd "$REPO_ROOT/payflex_backend"
BACKEND_JAR_NAME="$(basename "$(ls target/payflex_backend-*.jar | grep -v '\.original$' | head -1)")"

export JAVA_HOME=/usr/lib/jvm/java-17-openjdk-amd64
export PAYFLEX_DB_URL="jdbc:mysql://127.0.0.1:3306/payflexdb?createDatabaseIfNotExist=true&useSSL=false&allowPublicKeyRetrieval=true&serverTimezone=UTC"
export PAYFLEX_DB_USER=payflex
export PAYFLEX_DB_PASSWORD=payflex
export PAYFLEX_PUBLIC_URL=http://localhost:8088
export PAYFLEX_VAULT_KEY=payflex-dev-vault-key-change-me

echo "==> Lancement du backend Spring Boot (:8088)"
exec java -jar "target/${BACKEND_JAR_NAME}"
