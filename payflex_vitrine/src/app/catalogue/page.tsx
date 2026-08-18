"use client";

import Link from "next/link";
import { useMemo, useState } from "react";
import { PageHeader } from "@/components/layout/PageHeader";
import { ProductCard } from "@/components/shared/ProductCard";
import { PlayStoreButton } from "@/components/shared/PlayStoreButton";
import { getCategories, products } from "@/lib/site-data";

export default function CataloguePage() {
  const categories = getCategories();
  const [filter, setFilter] = useState("Tous");

  const filtered = useMemo(
    () => (filter === "Tous" ? products : products.filter((p) => p.category === filter)),
    [filter]
  );

  return (
    <>
      <PageHeader
        title="Catalogue"
        crumbs={[
          { label: "Accueil", href: "/" },
          { label: "Pages", href: "/catalogue" },
          { label: "Catalogue" },
        ]}
      />
      <section className="py-20">
        <div className="mx-auto max-w-7xl px-4 lg:px-6">
          <div className="mx-auto mb-10 max-w-2xl text-center">
            <p className="section-title justify-center">Nos Produits</p>
            <h2 className="mt-3 font-display text-3xl font-bold md:text-4xl">Catalogue des kits et outils</h2>
            <p className="mt-4 text-[var(--pf-muted)]">
              Des équipements certifiés pour chaque métier, finançables via l&apos;application PayFlex.
            </p>
          </div>
          <div className="mb-10 flex flex-wrap justify-center gap-2">
            {categories.map((cat) => (
              <button
                key={cat}
                type="button"
                onClick={() => setFilter(cat)}
                className={`rounded-full px-5 py-2 text-sm font-semibold transition ${
                  filter === cat
                    ? "bg-[var(--pf-primary)] text-white shadow-[0_12px_30px_-12px_rgba(11,74,158,0.6)] hover:bg-[var(--pf-secondary)] hover:text-[#0b1f3a]"
                    : "border border-slate-200/70 bg-white/70 text-slate-700 hover:border-transparent hover:bg-[var(--pf-secondary)] hover:text-[#0b1f3a] dark:border-white/10 dark:bg-white/5 dark:text-slate-200 dark:hover:bg-[var(--pf-secondary)] dark:hover:text-[#0b1f3a]"
                }`}
              >
                {cat}
              </button>
            ))}
          </div>
          <div className="grid gap-6 sm:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4">
            {filtered.map((p) => (
              <ProductCard key={p.id} product={p} />
            ))}
          </div>

          <div className="relative mt-16 overflow-hidden rounded-[2rem] bg-gradient-to-r from-[#062a5c] to-[var(--pf-primary)] p-10 text-center text-white">
            <h3 className="font-display text-2xl font-bold md:text-3xl">Financez votre kit dès aujourd&apos;hui</h3>
            <p className="mt-2 text-white/80">Téléchargez PayFlex et cotisez à votre rythme via Mobile Money.</p>
            <div className="mt-6 flex flex-wrap justify-center gap-4">
              <PlayStoreButton variant="light" />
              <Link href="/contact" className="btn-pf-secondary">Nous contacter</Link>
            </div>
          </div>
        </div>
      </section>
    </>
  );
}
