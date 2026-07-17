-- Remboursement/annulation de cotisation (traçabilité) : le statut 'refunded' est une simple valeur
-- de la colonne VARCHAR(40) existante `contributions.status` (aucune contrainte CHECK en base),
-- donc aucune migration de colonne n'est nécessaire pour le statut lui-même. On ajoute uniquement
-- les colonnes de traçabilité du remboursement.
ALTER TABLE contributions
    ADD COLUMN refund_reason VARCHAR(500) NULL,
    ADD COLUMN refunded_at TIMESTAMP NULL,
    ADD COLUMN refunded_by VARCHAR(120) NULL;

-- Conformité RGPD : persistance du consentement CGU/confidentialité côté compte actif et côté
-- demande d'inscription (avant activation). Défaut FALSE : toute inscription déjà en base (ou créée
-- par un client mobile pas encore mis à jour pour transmettre ce champ) est considérée comme non
-- confirmée explicitement, sans pour autant bloquer les comptes déjà actifs rétroactivement.
ALTER TABLE users
    ADD COLUMN terms_accepted BOOLEAN NOT NULL DEFAULT FALSE;

ALTER TABLE registration_requests
    ADD COLUMN terms_accepted BOOLEAN NOT NULL DEFAULT FALSE;
