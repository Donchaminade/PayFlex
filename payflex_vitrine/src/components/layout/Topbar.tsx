import Link from "next/link";
import { Clock, Mail, MapPin, Phone } from "lucide-react";
import { appConfig, siteConfig } from "@/lib/site-data";

export function Topbar() {
  return (
    <div className="hidden border-b border-slate-200/70 bg-[var(--pf-surface)]/70 backdrop-blur lg:block dark:border-white/10 dark:bg-white/[0.02]">
      <div className="mx-auto flex max-w-7xl items-center justify-between gap-4 px-4 py-2 text-xs text-[var(--pf-muted)] lg:px-8">
        <div className="flex items-center gap-5">
          <span className="flex items-center gap-1.5">
            <MapPin className="h-3.5 w-3.5 text-[var(--pf-primary)]" />
            {siteConfig.address}
          </span>
          <span className="flex items-center gap-1.5">
            <Clock className="h-3.5 w-3.5 text-[var(--pf-primary)]" />
            Lun – Sam · 08:00 – 19:00
          </span>
        </div>
        <div className="flex items-center gap-5 font-semibold text-slate-700 dark:text-slate-200">
          <a href={`tel:${siteConfig.phone.replace(/\s/g, "")}`} className="flex items-center gap-1.5 transition hover:text-[var(--pf-primary)]">
            <Phone className="h-3.5 w-3.5" />
            {siteConfig.phoneDisplay}
          </a>
          <a href={`mailto:${siteConfig.email}`} className="flex items-center gap-1.5 transition hover:text-[var(--pf-primary)]">
            <Mail className="h-3.5 w-3.5" />
            {siteConfig.email}
          </a>
          <Link
            href={appConfig.playStoreUrl}
            target="_blank"
            rel="noopener noreferrer"
            className="rounded-full bg-[var(--pf-secondary)] px-3 py-1 font-bold text-[var(--pf-dark)] transition hover:brightness-105"
          >
            Google Play
          </Link>
        </div>
      </div>
    </div>
  );
}
