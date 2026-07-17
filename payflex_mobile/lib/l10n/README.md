# Internationalisation (i18n) — PayFlex Mobile

## État actuel (scaffold, pas encore d'extraction complète)

Ce dossier contient l'**infrastructure** d'internationalisation, pas une traduction complète de
l'app. À ce stade :

- Une seule locale est active : **`fr`** (français).
- Un jeu **volontairement réduit** de ~17 clés représentatives existe dans `app_fr.arb`, à titre
  de preuve de concept (écrans/messages les plus utilisés + quelques messages d'erreur génériques
  déjà identifiés comme « non techniques » dans l'audit UX).
- Le reste de l'application (99% des écrans) contient encore des chaînes françaises **en dur**,
  intentionnellement non touchées ici — extraire l'intégralité des chaînes est un chantier séparé,
  plus long, à traiter progressivement (voir section « Prochaines étapes »).

## ⚠️ Point d'attention : génération de code bloquée par `pubspec.yaml`

`flutter gen-l10n` (Flutter 3.38.x) refuse de générer du code tant que
`flutter: generate: true` n'est pas présent dans `pubspec.yaml` :

```yaml
flutter:
  generate: true
```

Au moment où ce scaffold a été créé, `pubspec.yaml` était la propriété d'un autre chantier en
cours (édition interdite pour éviter les collisions). Les fichiers générés
(`lib/l10n/generated/app_localizations.dart` et `app_localizations_fr.dart`) ont donc été **écrits
à la main**, en reproduisant fidèlement le format standard produit par `flutter gen-l10n`.

**Action de suivi requise :** dès que `pubspec.yaml` peut être modifié, ajoutez `generate: true`
sous la section `flutter:`, puis régénérez proprement :

```powershell
cd payflex_mobile
fvm flutter gen-l10n
```

Le contenu régénéré doit être équivalent à celui déjà présent (même clés, mêmes valeurs). Vous
pouvez alors supprimer ce commentaire de mise en garde une fois vérifié.

## Structure

```
payflex_mobile/
├── l10n.yaml                          # config flutter gen-l10n
└── lib/l10n/
    ├── app_fr.arb                     # source de vérité : clés + valeurs FR (template)
    ├── README.md                      # ce fichier
    └── generated/
        ├── app_localizations.dart     # classe abstraite + delegate (générée ou écrite à la main, voir ci-dessus)
        └── app_localizations_fr.dart  # implémentation FR
```

`main.dart` référence déjà `AppLocalizations.localizationsDelegates` et
`AppLocalizations.supportedLocales` (locale unique `fr` pour l'instant) — rien à faire côté
`main.dart` pour ajouter de nouvelles clés FR.

## Comment continuer l'extraction progressive des chaînes en dur

L'app entière est actuellement en français codé en dur (`Text('Se connecter')`, etc.). Pour
migrer un écran vers ce système, procédez fichier par fichier :

1. Repérer les chaînes visibles par l'utilisateur dans l'écran (`Text(...)`,
   `SnackBar(content: Text(...))`, messages de dialogue, etc.).
2. Ajouter une clé correspondante dans `lib/l10n/app_fr.arb` si elle n'existe pas déjà (respectez
   le style `camelCase` et ajoutez toujours la métadonnée `@cléName` avec une `description` — cela
   aide les futurs traducteurs Ewe/Kabiyè à comprendre le contexte sans voir le code).
3. Régénérer (`fvm flutter gen-l10n`, une fois `generate: true` actif — voir avertissement
   ci-dessus) ou mettre à jour manuellement `app_localizations.dart` / `app_localizations_fr.dart`
   en suivant exactement le même style que les clés existantes.
4. Dans le widget, remplacer la chaîne en dur :

   ```dart
   // Avant
   const Text('Se connecter')

   // Après
   Text(AppLocalizations.of(context)!.loginButton)
   ```

5. Traiter les écrans par ordre de priorité : écrans les plus utilisés d'abord (connexion,
   tableau de bord, cotisation), puis messages d'erreur non techniques, puis le reste.
6. Ne migrez PAS les textes qui contiennent déjà des données dynamiques complexes (montants FCFA,
   noms d'agents, etc.) dans ce premier passage sauf si vous êtes à l'aise avec les placeholders
   ICU des fichiers `.arb` (`"greeting": "Bonjour {name}"`) — privilégiez d'abord les libellés
   statiques (boutons, titres, messages génériques).

## Comment ajouter une langue locale togolaise (Ewe / Kabiyè) le jour venu

1. Créer un nouveau fichier ARB à côté de `app_fr.arb`, par exemple :
   - `lib/l10n/app_ee.arb` pour l'**Ewe**
   - `lib/l10n/app_kbp.arb` pour le **Kabiyè**

   Chaque fichier doit contenir **les mêmes clés** que `app_fr.arb` (même structure), avec les
   valeurs traduites et `"@@locale": "ee"` (ou `"kbp"`) en en-tête.

2. Régénérer (`fvm flutter gen-l10n`) — cela crée automatiquement
   `app_localizations_ee.dart` / `app_localizations_kbp.dart` et met à jour
   `lookupAppLocalizations` dans `app_localizations.dart`.

3. Dans `lib/main.dart`, ajouter la locale à la liste des locales supportées :

   ```dart
   supportedLocales: AppLocalizations.supportedLocales, // déjà généré à partir des .arb
   // ou, si vous gérez la liste manuellement :
   supportedLocales: const [Locale('fr'), Locale('ee'), Locale('kbp')],
   ```

4. Ajouter un sélecteur de langue dans les paramètres/profil (à créer) pour permettre à
   l'utilisateur de choisir sa langue — actuellement l'app est figée sur `Locale('fr')` dans
   `main.dart` (`locale: const Locale('fr')`), il faudra le rendre dynamique (ex. via un
   `Riverpod` provider persistant, à l'image de `uiScaleProvider`).

## Pourquoi ce chantier est resté un scaffold (et pas une extraction complète)

L'extraction complète de toutes les chaînes en dur de l'application (des dizaines d'écrans,
probablement plusieurs centaines de chaînes) est un chantier à part entière, avec son propre
risque de régression visuelle/textuelle. Ce scaffold pose les fondations (config, structure,
convention de nommage, exemple fonctionnel) sans bloquer les autres chantiers en cours sur le
reste de l'app.
