#!/usr/bin/env bash
# ---------------------------------------------------------------------------
# PayFlex — script de démarrage Cloud Agent (exécuté à chaque boot).
#
# Réconcilie les services d'infrastructure requis par l'agent :
#   - démarre MariaDB (idempotent, tolère un service déjà lancé) ;
#   - attend que la base réponde.
#
# Les serveurs applicatifs (backend Spring Boot, vitrine Next.js) sont lancés
# comme terminaux persistants (cf. `terminals` dans environment.json) afin que
# leurs logs restent visibles et qu'ils soient facilement redémarrables.
# ---------------------------------------------------------------------------
set -euo pipefail

echo "==> Démarrage de MariaDB"
sudo service mariadb start || true

echo "==> Attente de la disponibilité de MariaDB"
for _ in $(seq 1 30); do
  if sudo mariadb -e "SELECT 1" >/dev/null 2>&1; then
    echo "MariaDB est prêt."
    exit 0
  fi
  sleep 1
done

echo "ERREUR : MariaDB n'a pas démarré à temps." >&2
exit 1
