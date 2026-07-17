# Politique de confidentialité — hébergement public & Data Safety (Google Play)

Ce document explique ce qu'il reste à faire, **avant toute soumission sur Google Play Console**,
pour rendre l'application conforme aux exigences de confidentialité du store.

## 1. Pourquoi un écran in-app ne suffit pas

L'app contient déjà un écran `Politique de confidentialité` complet et à jour
(`lib/features/profile/privacy_policy_screen.dart`, accessible depuis Profil chez le client et
l'agent). **C'est nécessaire mais pas suffisant.**

Google Play Console **exige une URL publique** (accessible sans l'app, depuis n'importe quel
navigateur) pointant vers la politique de confidentialité, renseignée dans :

> Play Console → Votre app → Présence sur le store → Contenu de l'app → Politique de
> confidentialité

Sans cette URL, la fiche Play Store ne peut pas être publiée.

## 2. Où héberger le texte

Le texte source à publier est celui de `privacy_policy_screen.dart` (à garder synchronisé si la
politique évolue). Deux options simples, du plus rapide au plus définitif :

### Option A — GitHub Pages (gratuit, rapide, recommandé pour démarrer)

1. Créer un dépôt public (ou un dossier `docs/` dans un dépôt existant) avec un fichier
   `index.html` reprenant le texte de la politique.
2. Dans les paramètres du dépôt GitHub : **Settings → Pages → Deploy from a branch**, choisir la
   branche et le dossier (`/docs` ou `/ (root)`).
3. GitHub fournit une URL du type `https://<utilisateur>.github.io/<repo>/` — c'est cette URL à
   coller dans Play Console.
4. Limite : dépend du compte GitHub de l'organisation ; à migrer vers l'option B une fois le
   domaine PayFlex disponible.

### Option B — Page statique sur le futur domaine backend PayFlex (recommandé à terme)

Une fois le nom de domaine du backend PayFlex disponible (ex. `https://api.payflex.tg` ou
équivalent) :

1. Ajouter une route publique simple côté backend (ex. `GET /legal/privacy`) qui sert une page
   HTML statique reprenant le même texte.
2. Publier l'URL finale, par ex. `https://payflex.tg/politique-de-confidentialite` ou
   `https://api.payflex.tg/legal/privacy`.
3. Avantage : une seule source de vérité si on branche aussi le lien déjà présent dans l'écran
   d'inscription (`registration_screen.dart`, système `fetchLegalDocuments` / `/api/mobile/legal/documents`),
   qui est déjà piloté par le backend — cette route publique peut réutiliser exactement ce contenu.

> Ce document ne modifie ni ne crée cette route backend : il s'agit d'une tâche backend distincte,
> hors périmètre de ce chantier mobile. À faire par la personne/l'équipe responsable du backend.

## 3. Checklist avant soumission

- [ ] Politique de confidentialité publiée sur une URL publique stable (Option A ou B)
- [ ] URL renseignée dans Play Console → Contenu de l'app → Politique de confidentialité
- [ ] Texte de l'URL publique identique (ou au moins cohérent) avec l'écran in-app
- [ ] Formulaire **Data Safety** (Sécurité des données) rempli dans Play Console (voir section 4)
- [ ] Date de dernière mise à jour visible sur la page publique

## 4. Brouillon du formulaire Data Safety (Play Console)

⚠️ Ce brouillon est basé sur ce que l'app collecte **réellement**, d'après le code (inscription,
profil, notifications push, paiement). Il doit être vérifié et complété par la personne qui
soumet l'app (responsabilité légale de la déclaration Play Console), notamment pour confirmer les
pratiques de partage avec le partenaire de paiement mobile money.

### Est-ce que l'app collecte ou partage des données utilisateur ?
**Oui.**

### Types de données à déclarer

| Catégorie Play Console        | Données concrètes PayFlex                                                                 | Collectée | Partagée | Obligatoire ? |
|--------------------------------|---------------------------------------------------------------------------------------------|-----------|----------|---------------|
| Informations personnelles      | Nom complet, numéro de téléphone, e-mail (facultatif), genre                                | Oui       | Non*     | Oui (inscription) |
| Informations financières        | Historique de cotisations, adhésion, épargne bonus, montants payés                          | Oui       | Non*     | Oui (usage du service) |
| Photos                          | Photo de profil, photo de pièce d'identité                                                  | Oui       | Non      | Oui (inscription) |
| Identifiants                    | Code PIN et mot de passe — **hachés côté serveur (BCrypt), jamais stockés en clair**         | Oui       | Non      | Oui (connexion) |
| Messages                        | Contenu des échanges avec le support (chat intégré), signalements                           | Oui       | Non      | Non (usage optionnel) |
| Identifiants d'appareil         | Jeton de notification push (FCM token)                                                      | Oui, si notifications activées | Oui (Firebase, pour l'acheminement) | Non (désactivable dans Profil > Notifications) |
| Position (localisation)         | **Non collectée** — aucune géolocalisation dans l'app                                        | Non       | —        | —              |
| Contacts                        | **Non collectés**                                                                             | Non       | —        | —              |
| Journaux d'utilisation/diagnostics | Journaux techniques d'erreurs/appels réseau (sans contenu personnel au-delà de ce qui précède) | Oui   | Non      | Non            |

\* Le numéro de téléphone et les informations de paiement nécessaires à la transaction sont transmis
au partenaire de paiement mobile money (PayDunya) **uniquement lorsque l'utilisateur choisit ce
mode de paiement**. À confirmer/ajuster précisément dans Play Console selon la documentation à
jour de PayDunya au moment de la soumission (leur statut de sous-traitant, hébergement, etc.).

### Pratiques de sécurité à cocher

- Les données sont chiffrées en transit (HTTPS) — à confirmer une fois le domaine de production
  en place avec certificat TLS.
- Les utilisateurs peuvent demander la suppression de leurs données (via le support PayFlex —
  cf. section « Vos droits » de la politique de confidentialité).
- Les identifiants (PIN, mot de passe) sont hachés (BCrypt), jamais stockés en clair.

### Ce qu'il reste à faire au moment de la soumission

1. Reprendre ce tableau directement dans le formulaire Data Safety de Play Console (l'UI Google
   découpe ces informations en plusieurs écrans successifs).
2. Confirmer avec l'équipe backend le statut exact de PayDunya (sous-traitant vs. destinataire
   tiers) pour cocher correctement les cases de partage.
3. Vérifier que l'URL de politique de confidentialité (section 2) est en ligne **avant** de
   soumettre le formulaire, car Play Console peut la revalider automatiquement.
