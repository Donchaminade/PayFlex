import Image from "next/image";
import Link from "next/link";
import { notFound } from "next/navigation";
import type { Metadata } from "next";
import { Check } from "lucide-react";
import { PageHeader } from "@/components/layout/PageHeader";
import { ProductCard } from "@/components/shared/ProductCard";
import { PlayStoreButton } from "@/components/shared/PlayStoreButton";
import { getProductById, products } from "@/lib/site-data";

type Props = { params: Promise<{ id: string }> };

export async function generateMetadata({ params }: Props): Promise<Metadata> {
  const { id } = await params;
  const product = getProductById(id);
  return { title: product?.name ?? "Produit" };
}

export default async function ProductPage({ params }: Props) {
  const { id } = await params;
  const product = getProductById(id);
  if (!product) notFound();

  const related = products.filter((p) => p.category === product.category && p.id !== product.id).slice(0, 3);

  return (
    <>
      <PageHeader
        title={product.name}
        crumbs={[
          { label: "Accueil", href: "/" },
          { label: "Catalogue", href: "/catalogue" },
          { label: product.name },
        ]}
      />
      <section className="py-20">
        <div className="mx-auto grid max-w-7xl items-center gap-12 px-4 lg:grid-cols-2 lg:px-6">
          <div className="relative aspect-square overflow-hidden rounded-[2rem] border border-slate-200/70 bg-gradient-to-br from-[var(--pf-surface)] to-white shadow-[0_30px_80px_-40px_rgba(11,31,58,0.4)] dark:border-white/10 dark:from-white/[0.06] dark:to-transparent">
            <Image src={product.image} alt={product.name} fill className="object-contain p-10" priority />
          </div>
          <div>
            <span className="rounded-full bg-[var(--pf-primary)]/10 px-4 py-1 text-sm font-bold text-[var(--pf-primary)] dark:text-[var(--pf-secondary)]">
              {product.category}
            </span>
            <h2 className="mt-4 font-display text-3xl font-bold md:text-4xl">{product.name}</h2>
            <p className="mt-4 text-[var(--pf-muted)]">{product.description}</p>
            <div className="mt-8 flex flex-wrap items-end gap-x-8 gap-y-2">
              <div>
                <p className="text-xs font-semibold uppercase tracking-wide text-[var(--pf-muted)]">Prix total</p>
                <p className="text-2xl font-bold">{product.price}</p>
              </div>
              <div>
                <p className="text-xs font-semibold uppercase tracking-wide text-[var(--pf-muted)]">Cotisation</p>
                <p className="text-2xl font-bold text-[var(--pf-primary)] dark:text-[var(--pf-secondary)]">{product.monthly}</p>
              </div>
            </div>
            <ul className="mt-6 space-y-2 text-sm text-[var(--pf-muted)]">
              {["Kit certifié avec garantie", "Paiement échelonné via Mobile Money", "Remise après objectif atteint"].map((f) => (
                <li key={f} className="flex items-center gap-2">
                  <Check className="h-4 w-4 text-[var(--pf-primary)] dark:text-[var(--pf-secondary)]" strokeWidth={2.5} />
                  {f}
                </li>
              ))}
            </ul>
            <div className="mt-8 flex flex-wrap gap-4">
              <PlayStoreButton />
              <Link href="/contact" className="btn-pf-outline">Demander des informations</Link>
            </div>
          </div>
        </div>
        {related.length > 0 && (
          <div className="mx-auto mt-20 max-w-7xl px-4 lg:px-6">
            <h3 className="mb-8 text-2xl font-bold">Produits similaires</h3>
            <div className="grid gap-6 sm:grid-cols-2 lg:grid-cols-3">
              {related.map((p) => (
                <ProductCard key={p.id} product={p} />
              ))}
            </div>
          </div>
        )}
      </section>
    </>
  );
}
