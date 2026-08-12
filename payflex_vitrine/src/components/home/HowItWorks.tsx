import Image from "next/image";
import { Reveal } from "@/components/motion/Reveal";
import { SectionHeader } from "@/components/ui/SectionHeader";
import { steps } from "@/lib/site-data";

export function HowItWorks() {
  return (
    <section className="section-spacing">
      <div className="mx-auto max-w-7xl px-4 lg:px-6">
        <SectionHeader
          eyebrow="Comment ça marche"
          title="Trois étapes pour vous équiper"
          description="De la sélection de votre kit à sa remise, PayFlex vous accompagne à chaque étape."
          align="center"
        />

        <div className="relative grid gap-6 md:grid-cols-3">
          {/* Ligne de liaison */}
          <div className="pointer-events-none absolute left-[16%] right-[16%] top-24 hidden h-px bg-gradient-to-r from-[var(--pf-primary)]/20 via-[var(--pf-secondary)]/40 to-[var(--pf-primary)]/20 md:block" />

          {steps.map((s, i) => (
            <Reveal key={s.step} delay={i * 0.1}>
              <div className="premium-card relative h-full text-center">
                <div className="relative mx-auto mb-5 flex h-40 w-40 items-center justify-center">
                  <div className="absolute inset-0 rounded-full bg-gradient-to-br from-[var(--pf-primary)]/10 to-[var(--pf-secondary)]/10" />
                  <Image src={s.image} alt={s.title} width={160} height={160} className="relative object-contain" />
                </div>
                <span className="absolute right-5 top-5 font-display text-4xl font-bold text-slate-100 dark:text-white/10">
                  {s.step}
                </span>
                <h3 className="text-xl font-bold">{s.title}</h3>
                <p className="mt-2 text-sm leading-relaxed text-[var(--pf-muted)]">{s.description}</p>
              </div>
            </Reveal>
          ))}
        </div>
      </div>
    </section>
  );
}
