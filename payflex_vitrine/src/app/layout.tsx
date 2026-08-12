import type { Metadata } from "next";
import { Libre_Baskerville, Open_Sans } from "next/font/google";
import { Topbar } from "@/components/layout/Topbar";
import { Navbar } from "@/components/layout/Navbar";
import { Footer } from "@/components/layout/Footer";
import { BackToTop } from "@/components/layout/BackToTop";
import "./globals.css";

const openSans = Open_Sans({
  subsets: ["latin"],
  variable: "--font-open-sans",
});

const libre = Libre_Baskerville({
  weight: "700",
  subsets: ["latin"],
  variable: "--font-libre",
});

export const metadata: Metadata = {
  metadataBase: new URL("https://payflex.com"),
  title: {
    default: "PayFlex — Cotisation progressive pour artisans",
    template: "%s | PayFlex",
  },
  description:
    "PayFlex permet aux apprentis et artisans du Togo d'acquérir leurs outils professionnels grâce à un paiement échelonné via Mobile Money. Application disponible sur Google Play.",
  keywords: ["PayFlex", "artisans", "apprentis", "Togo", "Mobile Money", "cotisation", "outils", "Google Play"],
  icons: { icon: "/img/pflex.jpeg" },
  openGraph: {
    title: "PayFlex — Équipez-vous, cotisez à votre rythme",
    description:
      "Acquérez vos outils professionnels grâce au paiement échelonné via Mobile Money. Téléchargez PayFlex sur Google Play.",
    url: "https://payflex.com",
    siteName: "PayFlex",
    locale: "fr_FR",
    type: "website",
    images: [{ url: "/img/og-cover.png", width: 1200, height: 675, alt: "PayFlex" }],
  },
  twitter: {
    card: "summary_large_image",
    title: "PayFlex — Équipez-vous, cotisez à votre rythme",
    description: "Paiement échelonné via Mobile Money pour artisans et apprentis. Sur Google Play.",
    images: ["/img/og-cover.png"],
  },
};

export default function RootLayout({ children }: Readonly<{ children: React.ReactNode }>) {
  return (
    <html lang="fr" suppressHydrationWarning>
      <body className={`${openSans.variable} ${libre.variable} antialiased`}>
        <Topbar />
        <Navbar />
        <main>{children}</main>
        <Footer />
        <BackToTop />
      </body>
    </html>
  );
}
