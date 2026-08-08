import Image from "next/image";
import Link from "next/link";
import { Globe, Mail, MapPin, Phone, Send, Share2 } from "lucide-react";
import { siteConfig } from "@/lib/site-data";
import { PlayStoreButton } from "@/components/shared/PlayStoreButton";

const socials = [Share2, Globe, Send];

export function Footer() {
  return (
    <>
      <footer className="mt-24 bg-gradient-to-br from-[#062a5c] via-[var(--pf-primary)] to-[#0a3d7a] text-white">
        <div className="mx-auto max-w-7xl px-4 py-16 lg:px-6">
          {/* Bandeau app */}
          <div className="mb-12 flex flex-col items-start justify-between gap-6 rounded-3xl border border-white/10 bg-white/5 p-6 backdrop-blur md:flex-row md:items-center md:p-8">
            <div>
              <Image src="/img/logo.png" alt="PayFlex" width={150} height={52} className="h-11 w-auto brightness-0 invert" />
              <p className="mt-3 max-w-md text-sm text-white/70">
                {siteConfig.tagline} — cotisation progressive pour artisans et apprentis au Togo.
              </p>
            </div>
            <div className="flex flex-col gap-3">
              <span className="text-xs font-semibold uppercase tracking-wide text-white/60">Téléchargez l&apos;application</span>
              <PlayStoreButton variant="light" />
            </div>
          </div>

          <div className="grid gap-10 md:grid-cols-2 lg:grid-cols-4">
            <div>
              <h5 className="mb-4 text-lg font-bold">Notre Bureau</h5>
              <p className="mb-2 flex items-start gap-2 text-sm text-white/80">
                <MapPin className="mt-0.5 h-4 w-4 shrink-0" />
                {siteConfig.address}
              </p>
              <p className="mb-2 flex items-center gap-2 text-sm text-white/80">
                <Phone className="h-4 w-4" />
                {siteConfig.phoneDisplay}
              </p>
              <p className="flex items-center gap-2 text-sm text-white/80">
                <Mail className="h-4 w-4" />
                {siteConfig.email}
              </p>
              <div className="mt-4 flex gap-2">
                {socials.map((Icon, i) => (
                  <a
                    key={i}
                    href="#"
                    className="flex h-9 w-9 items-center justify-center rounded-full bg-white/10 text-white transition hover:bg-[var(--pf-secondary)] hover:text-[var(--pf-dark)]"
                    aria-label="Réseau social"
                  >
                    <Icon className="h-4 w-4" />
                  </a>
                ))}
              </div>
            </div>
            <div>
              <h5 className="mb-4 text-lg font-bold">Navigation</h5>
              <div className="flex flex-col gap-2 text-sm">
                <Link href="/about" className="text-white/80 transition hover:text-[var(--pf-secondary)]">À Propos de Nous</Link>
                <Link href="/service" className="text-white/80 transition hover:text-[var(--pf-secondary)]">Nos Services</Link>
                <Link href="/catalogue" className="text-white/80 transition hover:text-[var(--pf-secondary)]">Catalogue</Link>
                <Link href="/feature" className="text-white/80 transition hover:text-[var(--pf-secondary)]">Fonctionnalités</Link>
                <Link href="/contact" className="text-white/80 transition hover:text-[var(--pf-secondary)]">Contact</Link>
              </div>
            </div>
            <div>
              <h5 className="mb-4 text-lg font-bold">Horaires</h5>
              <div className="space-y-3 text-sm text-white/80">
                <div>
                  <p>Lundi - Vendredi</p>
                  <p className="font-semibold text-white">09:00 - 19:00</p>
                </div>
                <div>
                  <p>Samedi</p>
                  <p className="font-semibold text-white">09:00 - 12:00</p>
                </div>
                <div>
                  <p>Dimanche</p>
                  <p className="font-semibold text-white">Fermé</p>
                </div>
              </div>
            </div>
            <div>
              <h5 className="mb-4 text-lg font-bold">Newsletter</h5>
              <p className="mb-4 text-sm text-white/80">Inscrivez-vous pour recevoir les dernières actualités PayFlex.</p>
              <div className="relative">
                <input
                  type="email"
                  placeholder="Votre email"
                  className="w-full rounded-full border border-white/20 bg-white/10 py-3 pl-4 pr-28 text-sm text-white placeholder:text-white/50 outline-none focus:border-[var(--pf-secondary)]"
                />
                <button type="button" className="absolute right-1 top-1 rounded-full bg-[var(--pf-secondary)] px-4 py-2 text-xs font-bold text-[var(--pf-dark)]">
                  S&apos;inscrire
                </button>
              </div>
            </div>
          </div>
        </div>
      </footer>
      <div className="border-t border-white/10 bg-[#041c3d] py-4 text-center text-sm text-white/70">
        <div className="mx-auto flex max-w-7xl flex-col items-center justify-between gap-2 px-4 md:flex-row">
          <span>© {new Date().getFullYear()} {siteConfig.name}, Tous Droits Réservés.</span>
          <span>Cotisation progressive pour artisans · Lomé, Togo</span>
        </div>
      </div>
    </>
  );
}
