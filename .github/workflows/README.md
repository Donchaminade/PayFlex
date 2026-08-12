# CI/CD — PayFlex

Ce dossier contient les workflows GitHub Actions du dépôt. Ils sont volontairement
séparés par composant (backend / mobile) et ne se déclenchent que lorsque les
fichiers du composant concerné changent (filtre `paths`).

## `backend-ci.yml`

Déclencheur : push/PR touchant `payflex_backend/**`.

Étapes :

1. Checkout du dépôt.
2. Installation du JDK **17** (Temurin) — version alignée sur `<java.version>`
   dans `payflex_backend/pom.xml` (Spring Boot 3.4.5).
3. Cache des dépendances Maven (`~/.m2`) via `actions/cache`, clé basée sur le
   hash de `pom.xml` — évite de retélécharger tout le repo Maven à chaque run.
4. `mvn -B -DskipTests compile` — compilation rapide, sans tests.
5. `mvn -B test` — exécution des tests.

> Le module ne contient pas encore de tests au moment de la création de ce
> workflow. Ce n'est pas bloquant : Surefire ne fait pas échouer le build en
> l'absence de tests (`failIfNoTests=false` par défaut). Le job passera au vert
> dès aujourd'hui, puis exécutera réellement les tests dès qu'ils seront ajoutés.

## `mobile-ci.yml`

Déclencheur : push/PR touchant `payflex_mobile/**`.

Étapes :

1. Checkout du dépôt.
2. Installation de Flutter **3.38.9** (version exacte lue dans
   `payflex_mobile/.fvmrc`) via `subosito/flutter-action@v2` — pas besoin
   d'installer FVM lui-même en CI, l'action installe directement le SDK pinné.
3. `flutter pub get`
4. `flutter analyze` — échoue le job sur les erreurs d'analyse, mais tolère les
   warnings/infos préexistants (pas de `--fatal-infos`/`--fatal-warnings`, pour
   ne pas casser la CI sur les ~181 warnings déjà documentés dans le projet).
5. `flutter test`

## Reproduire l'équivalent en local

### Backend seul (sans Docker)

```powershell
cd payflex_backend
mvn -B -DskipTests compile
mvn -B test
```

### Mobile seul (sans Docker)

```powershell
cd payflex_mobile
fvm flutter pub get
fvm flutter analyze
fvm flutter test
```

### Environnement complet backend + MySQL (Docker)

Un `docker-compose.yml` à la racine du dépôt fournit un environnement de
dev/staging reproductible (service `backend` buildé depuis
`payflex_backend/Dockerfile` + service `mysql` avec volume persistant et
healthcheck) :

```powershell
copy .env.example .env
# Éditer .env (voir commentaires du fichier — mêmes noms de variables que
# payflex_backend/.env.example)
docker compose up --build
```

- Backend : http://localhost:8088 (santé : `/api/mobile/health`, admin : `/admin`)
- MySQL : `localhost:3306` (base `payflexdb`)

Le service `backend` attend que `mysql` soit en état `healthy`
(`depends_on.condition: service_healthy`) avant de démarrer, pour éviter les
erreurs de connexion au premier lancement.
