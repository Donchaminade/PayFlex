package com.payflex.backend.service;

import org.springframework.dao.EmptyResultDataAccessException;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.Map;

/**
 * Remboursement/annulation d'une cotisation client déjà VALIDÉE (erreur de montant, changement
 * d'avis, etc.). Distinct du remboursement de DETTE AGENT ({@link ContributionWorkflowService}
 * {@code recordAgentDebtRepayment}), qui concerne la caisse de l'agent, pas un versement client.
 *
 * <p><b>Choix de conception — répartition multi-produits</b> : si la cotisation appartient à un
 * groupe de répartition automatique ({@code allocation_group_id} non nul, voir
 * {@link ContributionAllocationService}), le remboursement porte TOUJOURS sur l'INTÉGRALITÉ du
 * groupe (toutes les lignes {@code contributions} liées à ce groupe), jamais sur une seule ligne
 * isolée. Rembourser une seule ligne d'un groupe laisserait un état incohérent : le montant total
 * réellement reçu du client (et donc à lui restituer) correspond au versement d'origine, pas à
 * une seule ligne éclatée par produit — le client ne raisonne d'ailleurs qu'en un seul paiement.</p>
 */
@Service
public class ContributionRefundService {

    public static final String STATUS_REFUNDED = "refunded";

    private final JdbcTemplate jdbcTemplate;
    private final AdminAuditService auditService;
    private final UserInboxNotificationService inboxNotifications;
    private final ContributionValidationAlertService alertService;

    public ContributionRefundService(
        JdbcTemplate jdbcTemplate,
        AdminAuditService auditService,
        UserInboxNotificationService inboxNotifications,
        ContributionValidationAlertService alertService
    ) {
        this.jdbcTemplate = jdbcTemplate;
        this.auditService = auditService;
        this.inboxNotifications = inboxNotifications;
        this.alertService = alertService;
    }

    public record RefundResult(
        long clientUserId,
        long refundedCount,
        long totalRefundedFcfa,
        Long allocationGroupId
    ) {}

    @Transactional
    public RefundResult refund(long contributionId, String reason, String adminUsername) {
        if (reason == null || reason.trim().length() < 5) {
            throw new IllegalArgumentException("Un motif de remboursement (au moins 5 caractères) est obligatoire.");
        }
        Map<String, Object> row;
        try {
            row = jdbcTemplate.queryForMap(
                "SELECT id, user_id, amount, status, allocation_group_id FROM contributions WHERE id = ?",
                contributionId
            );
        } catch (EmptyResultDataAccessException ex) {
            throw new IllegalArgumentException("Cotisation introuvable.");
        }
        if (!"validated".equals(row.get("status"))) {
            throw new IllegalArgumentException("Seule une cotisation VALIDÉE peut être remboursée.");
        }
        String cleanReason = reason.trim();
        String actor = adminUsername == null || adminUsername.isBlank() ? "centre" : adminUsername.trim();
        long clientUserId = ((Number) row.get("user_id")).longValue();
        Object groupIdObj = row.get("allocation_group_id");

        RefundResult result;
        if (groupIdObj != null) {
            long groupId = ((Number) groupIdObj).longValue();
            result = refundAllocationGroupLines(groupId, clientUserId, cleanReason, actor);
        } else {
            double amount = ((Number) row.get("amount")).doubleValue();
            markRefunded(contributionId, cleanReason, actor);
            result = new RefundResult(clientUserId, 1, Math.round(amount), null);
        }

        notify(clientUserId, result, contributionId, cleanReason, actor);
        return result;
    }

    /**
     * Rembourse l'intégralité d'un groupe de répartition automatique multi-produits en une seule
     * opération (voir choix de conception documenté sur la classe).
     */
    private RefundResult refundAllocationGroupLines(long groupId, long clientUserId, String reason, String actor) {
        List<Long> lineIds = jdbcTemplate.query(
            "SELECT contribution_id FROM contribution_allocations WHERE allocation_group_id = ? ORDER BY id ASC",
            (rs, i) -> rs.getLong(1),
            groupId
        );
        if (lineIds.isEmpty()) {
            throw new IllegalArgumentException("Groupe de répartition introuvable ou déjà vide.");
        }
        long totalRefunded = 0;
        long refundedCount = 0;
        for (Long lineId : lineIds) {
            Map<String, Object> line;
            try {
                line = jdbcTemplate.queryForMap("SELECT amount, status FROM contributions WHERE id = ?", lineId);
            } catch (EmptyResultDataAccessException ex) {
                continue;
            }
            if (!"validated".equals(line.get("status"))) {
                // Ligne déjà remboursée/dans un autre état : on ne la retouche pas mais on continue
                // le groupe pour rester cohérent avec les autres lignes encore validées.
                continue;
            }
            markRefunded(lineId, reason, actor);
            totalRefunded += Math.round(((Number) line.get("amount")).doubleValue());
            refundedCount++;
        }
        if (refundedCount == 0) {
            throw new IllegalArgumentException("Toutes les lignes de ce groupe de répartition sont déjà remboursées ou non validées.");
        }
        return new RefundResult(clientUserId, refundedCount, totalRefunded, groupId);
    }

    private void markRefunded(long contributionId, String reason, String actor) {
        jdbcTemplate.update(
            """
            UPDATE contributions
            SET status = ?, refund_reason = ?, refunded_at = NOW(), refunded_by = ?
            WHERE id = ?
            """,
            STATUS_REFUNDED,
            reason,
            actor,
            contributionId
        );
    }

    private void notify(long clientUserId, RefundResult result, long contributionId, String reason, String actor) {
        long amountFcfa = result.totalRefundedFcfa();
        String groupSuffix = result.allocationGroupId() != null
            ? " (répartition multi-produits, groupe #" + result.allocationGroupId() + ", " + result.refundedCount() + " ligne(s))"
            : "";
        String clientMsg = "Votre versement de " + amountFcfa
            + " FCFA a été remboursé/annulé par le centre PayFlex. Motif : " + reason;
        inboxNotifications.notifyUser(
            clientUserId,
            "contribution_refunded",
            "Cotisation remboursée",
            clientMsg,
            contributionId
        );
        inboxNotifications.notifyAssignedAgentOnly(
            clientUserId,
            "contribution_refunded",
            "Remboursement — {client}",
            "Le centre a remboursé/annulé un versement de {client} (" + amountFcfa + " FCFA). Motif : " + reason,
            contributionId
        );
        auditService.logEquipe(
            actor,
            "Remboursement de la cotisation #" + contributionId + groupSuffix + " — " + amountFcfa
                + " FCFA au total — motif : " + reason
        );
        auditService.logClient(
            clientUserId,
            "Cotisation de " + amountFcfa + " FCFA remboursée/annulée par le centre. Motif : " + reason
        );
        alertService.createGeneral(
            ContributionValidationAlertService.TYPE_CONTRIBUTION_REFUNDED,
            "Remboursement enregistré pour la cotisation #" + contributionId + groupSuffix + " — " + amountFcfa
                + " FCFA — motif : " + reason
        );
    }
}
