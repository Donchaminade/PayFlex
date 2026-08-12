"use client";

import Image from "next/image";
import Link from "next/link";
import { motion } from "framer-motion";
import { ArrowUpRight } from "lucide-react";
import type { products } from "@/lib/site-data";

type Product = (typeof products)[number];

export function ProductCard({ product }: { product: Product }) {
  return (
    <motion.article
      whileHover={{ y: -6 }}
      transition={{ type: "spring", stiffness: 400, damping: 25 }}
      className="card-surface group flex h-full flex-col overflow-hidden transition-shadow duration-300 hover:[box-shadow:var(--pf-card-shadow-hover)]"
    >
      <div className="relative aspect-[4/3] overflow-hidden bg-gradient-to-br from-[var(--pf-surface)] to-white dark:from-white/[0.06] dark:to-transparent">
        <Image
          src={product.image}
          alt={product.name}
          fill
          className="object-contain p-4 transition duration-700 group-hover:scale-105"
          sizes="(max-width:768px) 50vw, 25vw"
        />
        <span className="absolute left-3 top-3 rounded-full bg-white/90 px-3 py-1 text-[11px] font-bold uppercase tracking-wide text-[var(--pf-primary)] shadow-sm backdrop-blur">
          {product.category}
        </span>
        <Link
          href={`/product/${product.id}`}
          aria-label={`Voir ${product.name}`}
          className="absolute bottom-3 right-3 flex h-10 w-10 translate-y-2 items-center justify-center rounded-full bg-[var(--pf-primary)] text-white opacity-0 shadow-lg transition-all duration-300 group-hover:translate-y-0 group-hover:opacity-100"
        >
          <ArrowUpRight className="h-5 w-5" />
        </Link>
      </div>
      <div className="flex flex-1 flex-col p-5">
        <Link href={`/product/${product.id}`} className="block text-lg font-bold tracking-tight transition hover:text-[var(--pf-primary)]">
          {product.name}
        </Link>
        <p className="mt-2 text-sm text-[var(--pf-muted)]">{product.price}</p>
        <p className="mt-auto pt-3 font-semibold text-[var(--pf-primary)] dark:text-[var(--pf-secondary)]">{product.monthly}</p>
      </div>
    </motion.article>
  );
}
