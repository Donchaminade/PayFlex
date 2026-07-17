package com.payflex.backend.service;

import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

/**
 * Désactivation d'agent avec garde-fous caisse/dette (voir {@code AdminCrudService.AgentStatusSnapshot}).
 *
 * <p><b>Choix de conception</b> : le passage {@code active=true → false} est refusé tant que
 * {@code cashDebtFcfa > 0} (caisse en attente non rapprochée ou dette agent active), sauf si
 * {@code force=true} est explicitement transmis (case de confirmation côté admin). Dans ce cas, la
 * désactivation est appliquée ET les clients actuellement rattachés à cet agent sont marqués
 * {@code assigned_agent_user_id = NULL} — déjà interprété comme « Non assigné » par l'UI clients
 * existante — pour rendre l'état orphelin visible et non silencieux. Aucune réassignation
 * automatique n'est effectuée (hors périmètre demandé).</p>
 */
@Service
public class AgentDeactivationService {

    private final AdminCrudService adminCrudService;
    private final AdminAuditService auditService;

    public AgentDeactivationService(AdminCrudService adminCrudService, AdminAuditService auditService) {
        this.adminCrudService = adminCrudService;
        this.auditService = auditService;
    }

    public record DeactivationOutcome(int orphanedClients, double cashDebtFcfa) {}

    /** Utilisé par le formulaire liste agents (zone + statut ensemble) — {@code force} non exposé côté liste. */
    @Transactional
    public DeactivationOutcome applyStatusChange(
        long agentId,
        Long zoneId,
        String zoneLabel,
        boolean active,
        boolean force,
        String actorLogin
    ) {
        AdminCrudService.AgentStatusSnapshot snapshot = guardBeforeChange(agentId, active, force);
        adminCrudService.updateAgent(agentId, zoneId, zoneLabel, active);
        return afterChange(snapshot, active, force, actorLogin);
    }

    /** Utilisé par la fiche agent détaillée : ne touche pas la zone, seulement le statut actif. */
    @Transactional
    public DeactivationOutcome setActiveOnly(long agentId, boolean active, boolean force, String actorLogin) {
        AdminCrudService.AgentStatusSnapshot snapshot = guardBeforeChange(agentId, active, force);
        adminCrudService.setAgentActive(agentId, active);
        return afterChange(snapshot, active, force, actorLogin);
    }

    private AdminCrudService.AgentStatusSnapshot guardBeforeChange(long agentId, boolean active, boolean force) {
        AdminCrudService.AgentStatusSnapshot snapshot = adminCrudService.getAgentStatusSnapshot(agentId);
        boolean isDeactivating = snapshot.active() && !active;
        if (isDeactivating && snapshot.cashDebtFcfa() > 0 && !force) {
            throw new IllegalArgumentException(
                "Impossible de désactiver « " + snapshot.fullName() + " » : caisse en attente / dette active de "
                    + Math.round(snapshot.cashDebtFcfa())
                    + " FCFA. Régularisez d'abord (rapprochement de caisse ou remboursement de dette) depuis sa "
                    + "fiche, ou confirmez la désactivation forcée."
            );
        }
        return snapshot;
    }

    private DeactivationOutcome afterChange(
        AdminCrudService.AgentStatusSnapshot snapshot,
        boolean active,
        boolean force,
        String actorLogin
    ) {
        boolean isDeactivating = snapshot.active() && !active;
        int orphanedCount = 0;
        if (isDeactivating && force) {
            orphanedCount = adminCrudService.orphanClientsForAgent(snapshot.userId());
            auditService.logEquipe(
                actorLogin,
                "Désactivation FORCÉE de l'agent « " + snapshot.fullName() + " » malgré caisse/dette de "
                    + Math.round(snapshot.cashDebtFcfa()) + " FCFA — " + orphanedCount
                    + " client(s) désormais sans agent assigné (à réaffecter manuellement)."
            );
        } else if (isDeactivating) {
            auditService.logEquipe(actorLogin, "Désactivation de l'agent « " + snapshot.fullName() + " ».");
        } else if (!snapshot.active() && active) {
            auditService.logEquipe(actorLogin, "Réactivation de l'agent « " + snapshot.fullName() + " ».");
        }
        return new DeactivationOutcome(orphanedCount, snapshot.cashDebtFcfa());
    }
}
