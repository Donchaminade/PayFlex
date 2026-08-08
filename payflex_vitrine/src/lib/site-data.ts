export const siteConfig = {
  name: "PayFlex",
  tagline: "Équipez-vous, cotisez à votre rythme",
  phone: "+228 90 00 00 00",
  phoneDisplay: "+228 90 00 00 00",
  email: "contact@payflex.com",
  address: "123 Rue de l'avenir, Lomé, Togo",
};

/** Application mobile — disponibilité et preuve sociale */
export const appConfig = {
  playStoreUrl: "https://play.google.com/store/apps/details?id=com.payflex.app",
  iosComingSoon: true,
  rating: "4.8",
  reviews: "1 200+",
  downloads: "30 000+",
  version: "Android 7.0+",
};

export const navItems = [
  { href: "/", label: "Accueil" },
  {
    label: "À Propos",
    children: [
      { href: "/about", label: "À Propos de Nous" },
      { href: "/feature", label: "Fonctionnalités" },
      { href: "/about#team", label: "Notre Équipe" },
      { href: "/about#testimonials", label: "Témoignages" },
    ],
  },
  { href: "/service", label: "Services" },
  { href: "/catalogue", label: "Catalogue" },
  { href: "/contact", label: "Contact" },
] as const;

/** Étapes du parcours — « Comment ça marche » */
export const steps = [
  {
    step: "01",
    title: "Choisissez votre kit",
    description:
      "Parcourez le catalogue et sélectionnez les outils et équipements adaptés à votre métier.",
    image: "/img/step-1-choisir.png",
  },
  {
    step: "02",
    title: "Cotisez à votre rythme",
    description:
      "Payez chaque jour un petit montant via Mobile Money, sans pression ni engagement lourd.",
    image: "/img/step-2-cotiser.png",
  },
  {
    step: "03",
    title: "Recevez votre matériel",
    description:
      "Une fois l'objectif atteint, votre kit certifié vous est remis. Vous êtes prêt à travailler.",
    image: "/img/step-3-recevoir.png",
  },
];

export const services = [
  {
    title: "Acquisition d'outils et de kits",
    description:
      "Accédez à une large gamme d'outils et de kits de travail de qualité, sélectionnés auprès de fournisseurs locaux fiables.",
    image: "/img/service-1.jpg",
    href: "/catalogue",
    icon: "tools" as const,
  },
  {
    title: "Paiement échelonné et flexible",
    description:
      "Payez à votre rythme grâce au Mobile Money et acquérez vos équipements sans pression financière.",
    image: "/img/service-2.jpg",
    href: "/feature",
    icon: "wallet" as const,
  },
  {
    title: "Accompagnement et support",
    description:
      "Conseils personnalisés et support client accessible pour une expérience simple et fiable.",
    image: "/img/service-3.jpg",
    href: "/contact",
    icon: "headphones" as const,
  },
];

export const products = [
  { id: "1", slug: "kit-demarrage-mecanique", name: "Kit de Démarrage Mécanique", category: "Mécanique", price: "150 000 FCFA", monthly: "À partir de 5000 XOF/mois", image: "/img/kit-mecanique.png", description: "L'essentiel pour tout mécanicien débutant avec des outils de précision." },
  { id: "2", slug: "kit-coiffure-pro", name: "Kit de Coiffure Professionnel", category: "Coiffure", price: "120 000 FCFA", monthly: "À partir de 3000 XOF/mois", image: "/img/kit-coiffure.png", description: "Tondeuses, ciseaux et accessoires de qualité pour salons modernes." },
  { id: "3", slug: "machine-coudre-creative", name: "Machine à Coudre Créative", category: "Couture", price: "250 000 FCFA", monthly: "À partir de 4000 XOF/mois", image: "/img/kit-couture.png", description: "Idéale pour les créations complexes et robustes sur tous tissus." },
  { id: "4", slug: "outils-plomberie", name: "Ensemble d'Outils de Plomberie", category: "Plomberie", price: "180 000 FCFA", monthly: "À partir de 4500 XOF/mois", image: "/img/kit-plomberie.png", description: "Tout le nécessaire pour les installations et réparations sanitaires." },
  { id: "5", slug: "diagnostic-auto", name: "Mallette de Diagnostic Auto", category: "Mécanique", price: "350 000 FCFA", monthly: "Sur devis", image: "/img/kit-mecanique.png", description: "Valise de diagnostic électronique multimarque haute précision." },
  { id: "6", slug: "casque-sechage", name: "Casque de Séchage sur Pied", category: "Coiffure", price: "95 000 FCFA", monthly: "Sur devis", image: "/img/kit-coiffure.png", description: "Séchage rapide et homogène en milieu professionnel." },
  { id: "7", slug: "surjeteuse-pro", name: "Surjeteuse Professionnelle", category: "Couture", price: "320 000 FCFA", monthly: "Sur devis", image: "/img/kit-couture.png", description: "Finitions impeccables pour tous vos ouvrages de couture." },
  { id: "8", slug: "kit-solaire", name: "Kit Énergie Solaire", category: "Solaire", price: "450 000 FCFA", monthly: "Sur devis", image: "/img/kit-solaire.png", description: "Panneaux et onduleur pour une autonomie énergétique durable." },
];

export const team = [
  { name: "HIBA Divine", role: "Chef Projet & Founder", bio: "Économiste & spécialiste en transformation digitale", icon: "tie" },
  { name: "Chaminade Dondah ADJOLOU", role: "Développeur Web & Mobile", bio: "Co-Founder", icon: "code" },
  { name: "Équipe Terrain", role: "Agents de proximité", bio: "Collecte et accompagnement des apprentis", icon: "user" },
  { name: "Support Client", role: "Relation & assistance", bio: "À votre écoute 6j/7", icon: "user" },
];

export const testimonials = [
  { name: "Afi", role: "Apprentie coiffeuse • Lomé", text: "Grâce à PayFlex, j'ai enfin pu acheter mon propre kit de coiffure. Le paiement en plusieurs fois m'a vraiment aidé à démarrer mon activité sans stress." },
  { name: "Kodjo", role: "Artisan mécanicien • Kara", text: "Je recommande PayFlex à tous les jeunes artisans. La plateforme est simple à utiliser et les outils sont de très bonne qualité." },
  { name: "Esinam", role: "Apprentie couturière • Sokodé", text: "Le support client est très réactif. On se sent vraiment accompagné du début à la fin." },
];

export const stats = [
  { value: "45 000", label: "Apprentis / an", icon: "users", color: "primary" },
  { value: "57", label: "Métiers couverts", icon: "award", color: "secondary" },
  { value: "30 000", label: "Utilisateurs", icon: "userCircle", color: "info" },
  { value: "5", label: "Villes", icon: "mapPin", color: "success" },
];

export function getProductById(id: string) {
  return products.find((p) => p.id === id || p.slug === id);
}

export function getCategories() {
  return ["Tous", ...Array.from(new Set(products.map((p) => p.category)))];
}

export const whyChoose = [
  "Accompagnement et conseils personnalisés",
  "Services complémentaires (maintenance, location, etc.)",
  "Une communauté de professionnels pour échanger",
  "Des kits certifiés avec garanties",
];

/** Galerie terrain — sans mockups app / téléphone */
export const galleryImages = [
  { src: "/img/images/WhatsApp Image 2026-04-07 at 18.39.55.jpeg", tall: true },
  { src: "/img/images/WhatsApp Image 2026-04-07 at 18.39.57.jpeg", tall: false },
  { src: "/img/service-1.jpg", tall: false },
  { src: "/img/images/WhatsApp Image 2026-04-07 at 18.39.56 (1).jpeg", tall: true },
  { src: "/img/service-2.jpg", tall: false },
  { src: "/img/images/WhatsApp Image 2026-04-07 at 18.39.57 (1).jpeg", tall: false },
  { src: "/img/service-3.jpg", tall: true },
  { src: "/img/gallery-ai-5.png", tall: false },
];

export const featureBlocks = [
  {
    title: "Paiement échelonné",
    description: "Payez à votre rythme via Mobile Money et acquérez vos outils sans pression.",
    icon: "wallet",
  },
  {
    title: "Catalogue certifié",
    description: "Des kits et équipements sélectionnés auprès de fournisseurs locaux fiables.",
    icon: "package",
  },
  {
    title: "Suivi en temps réel",
    description: "Visualisez vos cotisations et l'avancement vers l'acquisition de votre kit.",
    icon: "chart",
  },
  {
    title: "Support dédié",
    description: "Une équipe à votre écoute pour vous accompagner à chaque étape.",
    icon: "headphones",
  },
];

/** Points forts de l'application mobile (section téléchargement) */
export const appHighlights = [
  "Tableau de bord clair de vos cotisations",
  "Paiement Mobile Money intégré et sécurisé",
  "Notifications à chaque cotisation validée",
  "Calendrier de suivi et rattrapage des jours",
];

export const faq = [
  {
    q: "Comment fonctionne le paiement échelonné ?",
    a: "Vous choisissez un kit, définissez une cotisation journalière et payez à votre rythme via Mobile Money. Une fois l'objectif atteint, votre matériel vous est remis.",
  },
  {
    q: "L'application est-elle gratuite ?",
    a: "Oui, l'application PayFlex est gratuite au téléchargement sur le Play Store. Vous ne payez que vos cotisations pour l'acquisition de votre kit.",
  },
  {
    q: "Quels moyens de paiement sont acceptés ?",
    a: "Le Mobile Money (Flooz, T-Money / Mixx by Yas) ainsi que le paiement en espèces auprès de nos agents de terrain.",
  },
  {
    q: "Dans quelles villes PayFlex est-il disponible ?",
    a: "PayFlex est présent dans 5 villes du Togo et étend progressivement sa couverture.",
  },
];
