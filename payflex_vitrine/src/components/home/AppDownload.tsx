import Image from "next/image";
import { Check, Smartphone } from "lucide-react";
import { Reveal } from "@/components/motion/Reveal";
import { PlayStoreButton } from "@/components/shared/PlayStoreButton";
import { appConfig, appHighlights } from "@/lib/site-data";

export function AppDownload() {
  return (
    <section id="app" className="section-spacing">
      <div className="mx-auto max-w-7xl px-4 lg:px-6">
        <div className="relative overflow-hidden rounded-[2.5rem] border border-white/10 bg-gradient-to-br from-[#062a5c] via-[var(--pf-primary)] to-[#0a3d7a] px-6 py-14 text-white shadow-[0_40px_100px_-40px_rgba(11,31,58,0.7)] md:px-14">
          {/* Décor */}
          <div className="pointer-events-none absolute inset-0">
            <div className="blob absolute -right-10 -top-10 h-72 w-72 rounded-full bg-[var(--pf-secondary)]/30" />
            <div className="blob absolute -bottom-16 left-1/3 h-72 w-72 rounded-full bg-white/10" />
          </div>

          <div className="relative grid items-center gap-12 lg:grid-cols-2">
            <Reveal>
              <span className="inline-flex items-center gap-2 rounded-full border border-white/20 bg-white/10 px-4 py-1.5 text-[11px] font-bold uppercase tracking-[0.18em] text-white backdrop-blur">
                <Smartphone className="h-3.5 w-3.5" />
                Application mobile
              </span>
              <h2 className="mt-5 font-display text-3xl font-bold leading-tight md:text-4xl">
                Téléchargez PayFlex et gérez vos cotisations où que vous soyez
              </h2>
              <p className="mt-4 max-w-lg text-white/75">
                Suivez votre progression, cotisez via Mobile Money et recevez une notification à
                chaque paiement validé. Disponible gratuitement sur Google Play.
              </p>

              <ul className="mt-7 grid gap-3 sm:grid-cols-2">
                {appHighlights.map((item) => (
                  <li key={item} className="flex items-start gap-2.5 text-sm text-white/90">
                    <span className="mt-0.5 flex h-5 w-5 shrink-0 items-center justify-center rounded-full bg-[var(--pf-secondary)] text-[var(--pf-dark)]">
                      <Check className="h-3 w-3" strokeWidth={3} />
                    </span>
                    {item}
                  </li>
                ))}
              </ul>

              <div className="mt-9 flex flex-wrap items-center gap-4">
                <PlayStoreButton variant="light" />
                {appConfig.iosComingSoon && (
                  <span className="text-sm font-medium text-white/60">iOS bientôt disponible</span>
                )}
              </div>
            </Reveal>

            <Reveal direction="right" delay={0.15}>
              <div className="relative">
                <div className="relative mx-auto aspect-[4/3] w-full max-w-lg overflow-hidden rounded-3xl">
                  <Image
                    src="/img/app-download-duo.png"
                    alt="Écrans de l'application PayFlex"
                    fill
                    className="object-contain drop-shadow-2xl"
                    sizes="(max-width:1024px) 90vw, 45vw"
                  />
                </div>
              </div>
            </Reveal>
          </div>
        </div>
      </div>
    </section>
  );
}
