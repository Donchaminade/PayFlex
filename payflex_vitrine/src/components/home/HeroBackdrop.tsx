"use client";

import Image from "next/image";
import { useEffect, useState } from "react";
import { useReducedMotion } from "framer-motion";

const SLIDES = [
  "/img/hero-carousel-mecanique.png",
  "/img/hero-carousel-coiffure.png",
  "/img/hero-carousel-couture.png",
  "/img/hero-carousel-atelier.png",
] as const;

const INTERVAL_MS = 5000;

export function HeroBackdrop() {
  const reduced = useReducedMotion();
  const [index, setIndex] = useState(0);

  useEffect(() => {
    if (reduced) return;
    const id = window.setInterval(() => {
      setIndex((current) => (current + 1) % SLIDES.length);
    }, INTERVAL_MS);
    return () => window.clearInterval(id);
  }, [reduced]);

  return (
    <div className="pointer-events-none absolute inset-0 z-0 overflow-hidden" aria-hidden>
      {SLIDES.map((src, i) => (
        <Image
          key={src}
          src={src}
          alt=""
          fill
          priority={i === 0}
          sizes="100vw"
          className={`object-cover scale-105 blur-[6px] transition-opacity duration-[1200ms] ease-[cubic-bezier(0.22,1,0.36,1)] ${
            i === index ? "opacity-80" : "opacity-0"
          }`}
        />
      ))}
      <div className="absolute inset-0 bg-gradient-to-r from-[var(--background)] via-[var(--background)]/75 to-[var(--background)]/40" />
      <div className="absolute inset-0 bg-gradient-to-b from-[var(--background)]/20 via-transparent to-[var(--background)]" />
    </div>
  );
}
