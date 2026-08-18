# PayFlex — Site vitrine (Next.js)

Site vitrine public de PayFlex. Production : [https://payflex-one.vercel.app](https://payflex-one.vercel.app).

## Pages

| Route | Contenu |
|-------|---------|
| `/` | Accueil |
| `/about` | À propos (`#team`, `#testimonials`) |
| `/feature` | Fonctionnalités |
| `/service` | Services |
| `/catalogue` | Catalogue produits |
| `/product/[id]` | Fiche produit |
| `/contact` | Contact |

## Démarrage

```bash
cd payflex_vitrine
npm install
npm run dev
```

Ouvrir [http://localhost:3000](http://localhost:3000).

## Build production

```bash
npm run build
npm start
```

## Déploiement

Le projet Vercel `payflex` a pour racine ce dossier (`payflex_vitrine`). Déployer depuis ici :

```bash
npx vercel --prod
```

## Assets

Les images sont dans `public/img/`.
