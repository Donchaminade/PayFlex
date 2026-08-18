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

const INTERVAL_MS = 5500;

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
    <div className="pointer-events-none absolute inset-0 -z-10 overflow-hidden" aria-hidden>
      {SLIDES.map((src, i) => (
        <Image
          key={src}
          src={src}
          alt=""
          fill
          priority={i === 0}
          sizes="100vw"
          className={`object-cover scale-110 blur-[28px] transition-opacity duration-[1400ms] ease-[cubic-bezier(0.22,1,0.36,1)] ${
            i === index ? "opacity-[0.42] dark:opacity-[0.28]" : "opacity-0"
          }`}
        />
      ))}
      <div className="absolute inset-0 bg-[var(--background)]/55 dark:bg-[var(--background)]/70" />
      <div className="absolute inset-0 bg-gradient-to-b from-[var(--background)]/30 via-transparent to-[var(--background)]" />
    </div>
  );
}
