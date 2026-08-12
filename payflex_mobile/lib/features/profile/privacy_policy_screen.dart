import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/constants/app_colors.dart';

/// Politique de confidentialité PayFlex affichée dans l'application.
///
/// IMPORTANT — Google Play Console exige une URL publique (pas seulement un
/// écran in-app) pour la fiche du Play Store. Ce texte doit être publié tel
/// quel (ou synchronisé) sur une page web publique avant toute soumission.
/// Voir `payflex_mobile/PRIVACY_POLICY_HOSTING.md` pour la marche à suivre et
/// le brouillon du questionnaire Data Safety.
class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  static const _lastUpdated = '17 juillet 2026';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(
          'Politique de confidentialité',
          style: GoogleFonts.manrope(fontWeight: FontWeight.w800, color: AppColors.secondary),
        ),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.secondary,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
        children: [
          Text(
            'PayFlex',
            style: GoogleFonts.manrope(fontSize: 22, fontWeight: FontWeight.w900, color: AppColors.secondary),
          ),
          const SizedBox(height: 4),
          Text(
            'Dernière mise à jour : $_lastUpdated',
            style: GoogleFonts.inter(fontSize: 12, color: AppColors.secondary.withValues(alpha: 0.5)),
          ),
          const SizedBox(height: 20),
          _paragraph(
            'PayFlex (« nous », « l\'application ») propose des services de cotisation, '
            'd\'épargne et de suivi de tournée pour ses clients et ses agents au Togo. '
            'Cette politique explique quelles données nous collectons dans l\'application '
            'mobile, pourquoi, et comment elles sont protégées.',
          ),
          _section('1. Données que nous collectons'),
          _bullet(
            'Identité et contact',
            'Nom complet, numéro de téléphone, e-mail (facultatif), genre, ville et quartier '
            'déclarés — jamais votre position GPS : PayFlex ne collecte pas votre localisation.',
          ),
          _bullet(
            'Informations professionnelles',
            'Métier, lieu de travail (atelier/quartier), nom et téléphone de votre patron '
            'si vous êtes déclaré apprenti, et informations de formation le cas échéant.',
          ),
          _bullet(
            'Pièces justificatives',
            'Photo de profil et photo d\'une pièce d\'identité, envoyées lors de votre '
            'inscription pour vérifier votre dossier.',
          ),
          _bullet(
            'Identifiants de connexion',
            'Code PIN à 4 chiffres minimum et mot de passe de compte. Ils sont hachés '
            '(chiffrés à sens unique, méthode BCrypt) sur nos serveurs : PayFlex ne stocke '
            'jamais votre PIN ou mot de passe en clair et ne peut pas les « lire ».',
          ),
          _bullet(
            'Données financières',
            'Montants et historique de vos cotisations, adhésions, épargne bonus, produits '
            'souscrits, et — si vous payez par mobile money — les informations nécessaires '
            'au traitement du paiement par notre partenaire de paiement mobile money (PayDunya). '
            'PayFlex ne stocke pas les identifiants de votre compte mobile money.',
          ),
          _bullet(
            'Notifications',
            'Un jeton d\'appareil (FCM) est enregistré si vous autorisez les notifications, '
            'afin de vous envoyer des alertes (cotisation validée, message du centre, épargne '
            'bonus). Vous pouvez désactiver les alertes à tout moment depuis Profil > '
            'Notifications.',
          ),
          _bullet(
            'Messages et signalements',
            'Le contenu des messages échangés avec le support PayFlex (chat intégré) et des '
            'signalements que vous soumettez (ex. problème d\'adhésion).',
          ),
          _bullet(
            'Données techniques',
            'Journaux techniques limités (erreurs applicatives, appels réseau) utilisés pour '
            'diagnostiquer des problèmes, sans contenu personnel identifiable au-delà de ce qui '
            'précède.',
          ),
          _section('2. Ce que nous ne collectons pas'),
          _paragraph(
            'PayFlex ne collecte pas votre position géographique (GPS), ne demande pas accès à '
            'vos contacts, à vos photos hors de celles que vous choisissez d\'envoyer, ni à vos '
            'SMS.',
          ),
          _section('3. Pourquoi nous utilisons ces données'),
          _paragraph(
            'Créer et sécuriser votre compte, traiter vos cotisations et adhésions, calculer '
            'votre épargne bonus, vous assigner un agent PayFlex, vous informer par notification '
            'ou message, répondre à vos demandes de support, et respecter nos obligations '
            'légales et de lutte contre la fraude.',
          ),
          _section('4. Partage des données'),
          _paragraph(
            'Vos données sont partagées uniquement avec : l\'agent PayFlex qui vous est assigné '
            '(pour le suivi de vos cotisations), notre partenaire de paiement mobile money '
            '(PayDunya) lorsque vous choisissez ce mode de paiement, et nos hébergeurs '
            'techniques. Nous ne vendons pas vos données à des tiers.',
          ),
          _section('5. Conservation'),
          _paragraph(
            'Vos données sont conservées pendant la durée de votre relation avec PayFlex, puis '
            'archivées ou supprimées conformément à nos obligations légales et comptables.',
          ),
          _section('6. Vos droits'),
          _paragraph(
            'Vous pouvez demander à consulter, corriger ou faire supprimer vos données '
            'personnelles en contactant le support PayFlex depuis l\'application (Profil > Aide '
            '& support) ou votre agent assigné. Notez que certaines données (ex. historique de '
            'cotisation) peuvent devoir être conservées pour des raisons comptables ou légales.',
          ),
          _section('7. Sécurité'),
          _paragraph(
            'Les mots de passe et codes PIN sont hachés côté serveur (BCrypt). Les échanges '
            'entre l\'application et nos serveurs sont protégés. L\'accès aux données par notre '
            'équipe est limité à ce qui est nécessaire pour le support et l\'exploitation du '
            'service.',
          ),
          _section('8. Contact'),
          _paragraph(
            'Pour toute question sur cette politique ou vos données personnelles, utilisez le '
            'chat de support intégré à l\'application ou contactez votre agent PayFlex assigné.',
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.amber.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.amber.shade200),
            ),
            child: Text(
              'Ce texte doit également être publié sur une page web publique avant toute '
              'soumission de l\'application sur Google Play (voir PRIVACY_POLICY_HOSTING.md).',
              style: GoogleFonts.inter(fontSize: 12, color: Colors.amber.shade900, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }

  Widget _section(String title) => Padding(
        padding: const EdgeInsets.only(top: 20, bottom: 8),
        child: Text(
          title,
          style: GoogleFonts.manrope(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.secondary),
        ),
      );

  Widget _paragraph(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: Text(
          text,
          style: GoogleFonts.inter(fontSize: 13.5, height: 1.5, color: AppColors.secondary.withValues(alpha: 0.85)),
        ),
      );

  Widget _bullet(String title, String text) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '• $title',
              style: GoogleFonts.manrope(fontSize: 13.5, fontWeight: FontWeight.w800, color: AppColors.secondary),
            ),
            const SizedBox(height: 2),
            Padding(
              padding: const EdgeInsets.only(left: 10),
              child: Text(
                text,
                style: GoogleFonts.inter(fontSize: 13, height: 1.45, color: AppColors.secondary.withValues(alpha: 0.8)),
              ),
            ),
          ],
        ),
      );
}
