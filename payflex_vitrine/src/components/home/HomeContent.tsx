import Image from "next/image";
import Link from "next/link";
import { ArrowRight, Check } from "lucide-react";
import { Hero } from "@/components/home/Hero";
import { HowItWorks } from "@/components/home/HowItWorks";
import { AppDownload } from "@/components/home/AppDownload";
import { ImageCollage } from "@/components/home/ImageCollage";
import { GalleryMasonry } from "@/components/home/GalleryMasonry";
import { Reveal } from "@/components/motion/Reveal";
import { SectionHeader } from "@/components/ui/SectionHeader";
import { ProductCard } from "@/components/shared/ProductCard";
import { StatsGrid } from "@/components/shared/StatsGrid";
import { TeamSection } from "@/components/shared/TeamSection";
import { TestimonialsSection } from "@/components/shared/TestimonialsSection";
import { PlayStoreButton } from "@/components/shared/PlayStoreButton";
import { aboutIcons, serviceIcons } from "@/lib/icons";
import { products, services, stats, whyChoose } from "@/lib/site-data";

export function HomeContent() {
  const featured = products.slice(0, 4);

  return (
    <>
      <Hero />

      {/* Bandeau de chiffres */}
      <section className="relative">
        <div className="mx-auto max-w-7xl px-4 lg:px-6">
          <div className="soft-card grid grid-cols-2 gap-4 p-6 sm:p-8 lg:grid-cols-4">
            {stats.map((s, i) => (
              <Reveal key={s.label} delay={i * 0.06}>
                <div className="text-center">
                  <p className="font-display text-3xl font-bold text-[var(--pf-primary)] dark:text-[var(--pf-secondary)] md:text-4xl">
                    {s.value}
                  </p>
                  <p className="mt-1 text-xs font-semibold uppercase tracking-wide text-[var(--pf-muted)]">{s.label}</p>
                </div>
              </Reveal>
            ))}
          </div>
        </div>
      </section>

      {/* À propos */}
      <section id="apropos" className="section-spacing">
        <div className="mx-auto grid max-w-7xl items-center gap-14 px-4 lg:grid-cols-2 lg:px-6">
          <ImageCollage />
          <Reveal direction="right">
            <p className="section-title">À Propos de Nous</p>
            <h2 className="mt-4 text-3xl font-bold tracking-tight md:text-4xl">Découvrez PayFlex et notre mission</h2>
            <p className="mt-5 leading-relaxed text-[var(--pf-muted)]">
              PayFlex est une plateforme numérique conçue pour les jeunes apprentis et artisans, leur permettant
              d&apos;acquérir les outils et kits essentiels grâce à des paiements échelonnés adaptés à leurs revenus.
            </p>
            <div className="mt-8 grid gap-4 sm:grid-cols-2">
              {[
                { icon: aboutIcons.flexibility, title: "Accessibilité et flexibilité", text: "Payez en plusieurs fois, selon vos revenus." },
                { icon: aboutIcons.quality, title: "Qualité et fiabilité", text: "Des outils et kits certifiés avec garanties." },
              ].map((item) => (
                <div key={item.title} className="soft-card flex gap-4 p-4">
                  <div className="icon-box">
                    <item.icon className="h-5 w-5" />
                  </div>
                  <div>
                    <h5 className="font-bold">{item.title}</h5>
                    <p className="mt-1 text-sm text-[var(--pf-muted)]">{item.text}</p>
                  </div>
                </div>
              ))}
            </div>
            <Link href="/about" className="btn-pf-primary mt-8">
              En savoir plus <ArrowRight className="h-4 w-4" />
            </Link>
          </Reveal>
        </div>
      </section>

      <HowItWorks />

      {/* Services */}
      <section className="section-spacing bg-[var(--pf-surface)]/60 dark:bg-white/[0.02]">
        <div className="mx-auto max-w-7xl px-4 lg:px-6">
          <SectionHeader
            eyebrow="Nos Services"
            title="Des services conçus pour votre réussite"
            description="De l'acquisition du kit au suivi de vos cotisations, PayFlex vous accompagne."
          />
          <div className="grid gap-6 md:grid-cols-3">
            {services.map((s, i) => {
              const Icon = serviceIcons[s.icon];
              return (
                <Reveal key={s.title} delay={i * 0.08}>
                  <article className="group premium-card overflow-hidden !p-0">
                    <div className="relative h-52 overflow-hidden">
                      <Image src={s.image} alt={s.title} fill className="object-cover transition duration-700 group-hover:scale-105" />
                      <div className="absolute inset-0 bg-gradient-to-t from-black/30 to-transparent" />
                      <div className="absolute left-4 top-4 flex h-11 w-11 items-center justify-center rounded-2xl bg-white/95 text-[var(--pf-primary)] shadow-lg">
                        <Icon className="h-5 w-5" />
                      </div>
                    </div>
                    <div className="p-6">
                      <h5 className="text-lg font-bold">{s.title}</h5>
                      <p className="mt-2 text-sm leading-relaxed text-[var(--pf-muted)]">{s.description}</p>
                      <Link
                        href={s.href}
                        className="mt-4 inline-flex items-center gap-1 text-sm font-bold text-[var(--pf-primary)] transition hover:gap-2 dark:text-[var(--pf-secondary)]"
                      >
                        En savoir plus <ArrowRight className="h-4 w-4" />
                      </Link>
                    </div>
                  </article>
                </Reveal>
              );
            })}
          </div>
        </div>
      </section>

      <AppDownload />

      {/* Catalogue */}
      <section className="section-spacing">
        <div className="mx-auto max-w-7xl px-4 lg:px-6">
          <SectionHeader
            eyebrow="Nos Produits"
            title="Des kits et outils pour chaque métier"
            description="Une sélection d'équipements certifiés, prêts à financer via l'application."
          />
          <div className="grid gap-6 sm:grid-cols-2 lg:grid-cols-4">
            {featured.map((p, i) => (
              <Reveal key={p.id} delay={i * 0.06}>
                <ProductCard product={p} />
              </Reveal>
            ))}
          </div>
          <Reveal className="mt-12 text-center">
            <Link href="/catalogue" className="btn-pf-primary">
              Voir tout le catalogue <ArrowRight className="h-4 w-4" />
            </Link>
          </Reveal>
        </div>
      </section>

      {/* Pourquoi nous choisir + stats */}
      <section className="section-spacing bg-[var(--pf-surface)]/60 dark:bg-white/[0.02]">
        <div className="mx-auto grid max-w-7xl items-center gap-14 px-4 lg:grid-cols-2 lg:px-6">
          <Reveal>
            <p className="section-title">Pourquoi Nous Choisir</p>
            <h2 className="mt-4 text-3xl font-bold tracking-tight md:text-4xl">Les avantages PayFlex pour votre avenir</h2>
            <p className="mt-4 text-[var(--pf-muted)]">
              Une technologie pensée pour la réalité du terrain : simple, sécurisée et proche de vous.
            </p>
            <ul className="mt-8 space-y-3">
              {whyChoose.map((item) => (
                <li key={item} className="soft-card flex items-center gap-4 p-4">
                  <span className="flex h-10 w-10 shrink-0 items-center justify-center rounded-full bg-[var(--pf-primary)] text-white">
                    <Check className="h-5 w-5" strokeWidth={2.5} />
                  </span>
                  <span className="font-medium">{item}</span>
                </li>
              ))}
            </ul>
            <Link href="/feature" className="btn-pf-primary mt-8">
              Toutes les fonctionnalités <ArrowRight className="h-4 w-4" />
            </Link>
          </Reveal>
          <StatsGrid />
        </div>
      </section>

      {/* Galerie */}
      <section className="section-spacing">
        <SectionHeader
          eyebrow="Galerie"
          title="PayFlex sur le terrain"
          description="Apprentis, artisans et équipes en action."
          align="center"
        />
        <GalleryMasonry />
      </section>

      <TestimonialsSection />
      <TeamSection />

      {/* CTA final */}
      <section className="section-spacing pt-0">
        <div className="mx-auto max-w-7xl px-4 lg:px-6">
          <div className="relative overflow-hidden rounded-[2.5rem] border border-slate-200/70 bg-white/90 px-6 py-14 text-center shadow-[0_30px_80px_-40px_rgba(11,31,58,0.4)] backdrop-blur dark:border-white/10 dark:bg-white/[0.04] md:px-14">
            <div className="pointer-events-none absolute inset-0 -z-10">
              <div className="blob absolute -left-10 -top-10 h-64 w-64 rounded-full bg-[var(--pf-primary)]/15" />
              <div className="blob absolute -bottom-10 -right-10 h-64 w-64 rounded-full bg-[var(--pf-secondary)]/20" />
            </div>
            <h2 className="font-display text-3xl font-bold md:text-4xl">Prêt à démarrer votre métier ?</h2>
            <p className="mx-auto mt-3 max-w-xl text-[var(--pf-muted)]">
              Téléchargez l&apos;application PayFlex et commencez à cotiser dès aujourd&apos;hui.
            </p>
            <div className="mt-8 flex flex-wrap justify-center gap-4">
              <PlayStoreButton />
              <Link href="/contact" className="btn-pf-outline">Nous contacter</Link>
            </div>
          </div>
        </div>
      </section>
    </>
  );
}
