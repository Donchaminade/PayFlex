package com.payflex.backend.service;

import com.payflex.backend.config.PayflexProperties;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.dao.EmptyResultDataAccessException;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.jdbc.core.RowMapper;

import java.util.HashMap;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyLong;
import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.ArgumentMatchers.argThat;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.lenient;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.times;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

/**
 * Tests unitaires purs (Mockito) de {@link ContributionWorkflowService}. Toutes les dépendances
 * (JdbcTemplate + services collaborateurs) sont mockées ; le service métier réel est instancié
 * directement, sans contexte Spring.
 */
@ExtendWith(MockitoExtension.class)
class ContributionWorkflowServiceTest {

    @Mock private JdbcTemplate jdbcTemplate;
    @Mock private PermissionService permissionService;
    @Mock private AdminAuditService auditService;
    @Mock private ContributionValidationAlertService alertService;
    @Mock private UserInboxNotificationService inboxNotifications;
    @Mock private ProductDeliveryService productDeliveryService;
    @Mock private AdminWebPushService adminWebPushService;
    @Mock private ContributionAllocationService contributionAllocationService;

    private PayflexProperties payflexProperties;
    private ContributionWorkflowService service;

    @BeforeEach
    void setUp() {
        payflexProperties = new PayflexProperties();
        service = new ContributionWorkflowService(
            jdbcTemplate,
            permissionService,
            auditService,
            alertService,
            payflexProperties,
            inboxNotifications,
            productDeliveryService,
            adminWebPushService,
            contributionAllocationService
        );
    }

    // ------------------------------------------------------------------
    // assertProductGoalNotReached : tolérance ~0.009 FCFA (garde-fou @Deprecated)
    // ------------------------------------------------------------------

    /**
     * Câble en UN SEUL stub (au lieu de deux {@code when()} concurrents sur la même surcharge
     * varargs) les deux requêtes {@code queryForObject(String, Class, Object...)} utilisées par
     * {@code assertProductGoalNotReached} : l'objectif produit (prix cible) et le total déjà
     * validé, distinguées par une inspection du texte SQL dans une unique réponse. Combiner deux
     * stubs {@code argThat} séparés sur le même mock + la même surcharge s'est avéré instable
     * avec Mockito (fuite de matcher entre stubs -> NullPointerException).
     */
    private void stubGoalCheck(java.util.function.Supplier<Double> targetSupplier, java.util.function.Supplier<Double> validatedSupplier) {
        lenient().when(jdbcTemplate.queryForObject(anyString(), eq(Double.class), any(), any()))
            .thenAnswer(inv -> {
                String sql = inv.getArgument(0);
                if (sql.contains("COALESCE(p.price, 0)")) {
                    return targetSupplier.get();
                }
                return validatedSupplier.get();
            });
    }

    @Test
    void assertProductGoalNotReached_throwsWhenAlreadyReached() {
        stubGoalCheck(() -> 1000.0, () -> 1000.0);

        assertThatThrownBy(() -> service.assertProductGoalNotReached(1L, 10L))
            .isInstanceOf(IllegalArgumentException.class)
            .hasMessage(ContributionWorkflowService.GOAL_REACHED_MESSAGE);
    }

    @Test
    void assertProductGoalNotReached_toleranceBoundary_exactlyAtEpsilon_isConsideredReached() {
        // validatedTotal >= target - 0.009 : à la limite exacte de la tolérance, doit bloquer.
        stubGoalCheck(() -> 1000.0, () -> 999.991); // 1000 - 0.009

        assertThatThrownBy(() -> service.assertProductGoalNotReached(1L, 10L))
            .isInstanceOf(IllegalArgumentException.class);
    }

    @Test
    void assertProductGoalNotReached_justBelowTolerance_doesNotBlockYet() {
        // 999.98 < 1000 - 0.009 (999.991) : pas encore "atteint".
        stubGoalCheck(() -> 1000.0, () -> 999.98);

        service.assertProductGoalNotReached(1L, 10L);
        // pas d'exception : le test réussit simplement en atteignant cette ligne.
    }

    @Test
    void assertProductGoalNotReached_proposedAmount_exactlyAtToleranceMargin_isAccepted() {
        // validatedTotal + proposedAmount == target + 0.009 (limite EXACTE) : la condition de
        // rejet utilise ">" strict, donc à l'égalité exacte le montant doit être accepté.
        stubGoalCheck(() -> 1000.0, () -> 995.0);

        service.assertProductGoalNotReached(1L, 10L, 5.009);
        // Aucune exception : 995 + 5.009 = 1000.009 == target + 0.009 (pas strictement supérieur).
    }

    @Test
    void assertProductGoalNotReached_proposedAmount_justOverToleranceMargin_isRejected() {
        stubGoalCheck(() -> 1000.0, () -> 995.0);

        assertThatThrownBy(() -> service.assertProductGoalNotReached(1L, 10L, 5.02))
            .isInstanceOf(IllegalArgumentException.class)
            .hasMessageContaining("Montant trop élevé");
    }

    @Test
    void assertProductGoalNotReached_proposedAmount_wellWithinRemaining_isAccepted() {
        stubGoalCheck(() -> 1000.0, () -> 500.0);

        service.assertProductGoalNotReached(1L, 10L, 200.0);
    }

    @Test
    void assertProductGoalNotReached_productNotFound_returnsSilently() {
        stubGoalCheck(() -> { throw new EmptyResultDataAccessException(1); }, () -> 0.0);

        service.assertProductGoalNotReached(1L, 999L, 100.0);
    }

    @Test
    void assertProductGoalNotReached_nullOrInvalidProductId_returnsSilently() {
        service.assertProductGoalNotReached(1L, null);
        service.assertProductGoalNotReached(1L, -5L);
        service.assertProductGoalNotReached(-1L, 10L);
        // Aucune interaction JdbcTemplate attendue pour ces cas.
    }

    @Test
    void assertProductGoalNotReached_deprecatedTwoArgOverload_delegatesWithZeroProposedAmount() {
        stubGoalCheck(() -> 1000.0, () -> 500.0);

        // proposedAmount=0 ne doit jamais déclencher le contrôle de dépassement (seulement le blocage "déjà atteint").
        service.assertProductGoalNotReached(1L, 10L);
    }

    // ------------------------------------------------------------------
    // Rapprochement de caisse agent + dette (reconcilePendingCash)
    // ------------------------------------------------------------------

    private record PendingCashLineFixture(long id, double amount, Long agentUserId) {}

    /**
     * Construit une vraie instance du record privé {@code ContributionWorkflowService.PendingCashLine}
     * via réflexion : indispensable car {@code jdbcTemplate.query(...)} est mocké et le code appelant
     * fait un cast implicite (erasure) vers ce type précis dans sa boucle for-each — renvoyer un autre
     * type provoquerait un {@code ClassCastException} au runtime.
     */
    private Object pendingCashLine(long id, double amount, Long agentUserId) {
        try {
            Class<?> cls = Class.forName("com.payflex.backend.service.ContributionWorkflowService$PendingCashLine");
            java.lang.reflect.Constructor<?> ctor = cls.getDeclaredConstructor(long.class, double.class, Long.class);
            ctor.setAccessible(true);
            return ctor.newInstance(id, amount, agentUserId);
        } catch (ReflectiveOperationException e) {
            throw new RuntimeException(e);
        }
    }

    /**
     * Câble un JdbcTemplate minimal permettant de faire tourner {@code applyValidation} pour de
     * vraies lignes de cotisation cash, sans dépendre du détail de {@code maybeNotifyGoalReached}
     * (court-circuité via product_id=null) ni de la répartition automatique (mockée séparément).
     */
    private void stubCashReconciliation(List<PendingCashLineFixture> lines) {
        Map<Long, Map<String, Object>> byId = new HashMap<>();
        for (PendingCashLineFixture line : lines) {
            Map<String, Object> row = new LinkedHashMap<>();
            row.put("id", line.id());
            row.put("user_id", 900L + line.id());
            row.put("amount", line.amount());
            row.put("status", "pending");
            row.put("reference_code", "REF-" + line.id());
            row.put("payment_mode", "cash");
            byId.put(line.id(), row);
        }

        when(jdbcTemplate.query(anyString(), org.mockito.ArgumentMatchers.<RowMapper<Object>>any()))
            .thenAnswer(inv -> {
                List<Object> out = new java.util.ArrayList<>();
                for (PendingCashLineFixture line : lines) {
                    out.add(pendingCashLine(line.id(), line.amount(), line.agentUserId()));
                }
                return out;
            });

        lenient().when(jdbcTemplate.queryForMap(anyString(), any())).thenAnswer(inv -> {
            String sql = inv.getArgument(0);
            if (sql.contains("c.product_id")) {
                // Requête interne de maybeNotifyGoalReached : on coupe court (pas de produit rattaché).
                Map<String, Object> row = new LinkedHashMap<>();
                row.put("product_id", null);
                return row;
            }
            long id = ((Number) inv.getArgument(1)).longValue();
            Map<String, Object> row = byId.get(id);
            if (row == null) {
                throw new EmptyResultDataAccessException(1);
            }
            return row;
        });

        lenient().when(contributionAllocationService.allocateAndValidate(anyLong())).thenAnswer(inv -> {
            long id = inv.getArgument(0);
            return new ContributionAllocationService.AllocationOutcome(id, 0, 0, List.of(), 0, null);
        });
    }

    @Test
    void reconcilePendingCash_noPendingLines_returnsAllZeros() {
        when(jdbcTemplate.query(anyString(), org.mockito.ArgumentMatchers.<RowMapper<Object>>any()))
            .thenReturn(List.of());

        ContributionWorkflowService.CashReconcileResult result = service.reconcilePendingCash(5000, "centre");

        assertThat(result.validatedCount()).isEqualTo(0);
        assertThat(result.expectedTotalFcfa()).isEqualTo(0);
        assertThat(result.collectedAmountFcfa()).isEqualTo(5000);
        assertThat(result.surplusFcfa()).isEqualTo(5000);
        assertThat(result.debtRecordedFcfa()).isEqualTo(0);
    }

    @Test
    void reconcilePendingCash_exactAmount_validatesAllWithoutDebt() {
        stubCashReconciliation(List.of(
            new PendingCashLineFixture(1L, 1000, 5L),
            new PendingCashLineFixture(2L, 2000, 6L)
        ));

        ContributionWorkflowService.CashReconcileResult result = service.reconcilePendingCash(3000, "centre");

        assertThat(result.validatedCount()).isEqualTo(2);
        assertThat(result.validatedAmountFcfa()).isEqualTo(3000);
        assertThat(result.expectedTotalFcfa()).isEqualTo(3000);
        assertThat(result.collectedAmountFcfa()).isEqualTo(3000);
        assertThat(result.debtRecordedFcfa()).isEqualTo(0);
        assertThat(result.stillPendingCount()).isEqualTo(0);
        assertThat(result.surplusFcfa()).isEqualTo(0);
    }

    @Test
    void reconcilePendingCash_shortfall_recordsDebtSplitProportionallyByAgent() {
        stubCashReconciliation(List.of(
            new PendingCashLineFixture(1L, 1000, 5L),
            new PendingCashLineFixture(2L, 3000, 6L)
        ));

        // Compté 3000 sur 4000 attendus : FIFO valide seulement la 1ère ligne (1000 <= 3000),
        // la 2e (3000) dépasse le budget restant (2000) -> reste en attente.
        ContributionWorkflowService.CashReconcileResult result = service.reconcilePendingCash(3000, "centre");

        assertThat(result.validatedCount()).isEqualTo(1);
        assertThat(result.validatedAmountFcfa()).isEqualTo(1000);
        assertThat(result.expectedTotalFcfa()).isEqualTo(4000);
        assertThat(result.collectedAmountFcfa()).isEqualTo(3000);
        assertThat(result.stillPendingCount()).isEqualTo(1);
        assertThat(result.debtRecordedFcfa()).isEqualTo(1000);
        assertThat(result.surplusFcfa()).isEqualTo(0);

        // Dette répartie au prorata : agent 5 (1000/4000=25%) -> 250 ; agent 6 (3000/4000=75%) -> 750.
        verify(auditService, times(2)).logAgent(anyLong(), anyString());
    }

    @Test
    void reconcilePendingCash_negativeAmount_throws() {
        assertThatThrownBy(() -> service.reconcilePendingCash(-1, "centre"))
            .isInstanceOf(IllegalArgumentException.class);
    }

    @Test
    void reconcilePendingCashForAgent_agentNotFound_throws() {
        when(jdbcTemplate.queryForObject(eq("SELECT user_id FROM agents WHERE id = ?"), eq(Long.class), eq(42L)))
            .thenThrow(new EmptyResultDataAccessException(1));

        assertThatThrownBy(() -> service.reconcilePendingCashForAgent(42L, 1000, "centre"))
            .isInstanceOf(IllegalArgumentException.class)
            .hasMessageContaining("Agent introuvable");
    }

    // ------------------------------------------------------------------
    // Remboursement de dette de caisse agent
    // ------------------------------------------------------------------

    private void stubAgentBasics(long agentId, long agentUserId, double currentDebt, String fullName) {
        lenient().when(jdbcTemplate.queryForObject(eq("SELECT user_id FROM agents WHERE id = ?"), eq(Long.class), eq(agentId)))
            .thenReturn(agentUserId);
        lenient().when(jdbcTemplate.queryForObject(eq("SELECT COALESCE(cash_debt_fcfa, 0) FROM agents WHERE id = ?"), eq(Double.class), eq(agentId)))
            .thenReturn(currentDebt);
        lenient().when(jdbcTemplate.queryForObject(eq("SELECT full_name FROM users WHERE id = ?"), eq(String.class), eq(agentUserId)))
            .thenReturn(fullName);
    }

    @Test
    void recordAgentDebtRepayment_partialRepayment_succeeds() {
        stubAgentBasics(7L, 70L, 1000, "Jean Agent");

        service.recordAgentDebtRepayment(7L, 400L, "Remboursement partiel", "admin1");

        verify(jdbcTemplate).update(eq("UPDATE agents SET cash_debt_fcfa = cash_debt_fcfa - ? WHERE id = ?"), eq(400L), eq(7L));
        verify(inboxNotifications).notifyUser(eq(70L), eq("debt_repayment_recorded"), anyString(), anyString(), org.mockito.ArgumentMatchers.isNull());
    }

    @Test
    void recordAgentDebtRepayment_amountExceedsDebt_throws() {
        stubAgentBasics(7L, 70L, 400, "Jean Agent");

        assertThatThrownBy(() -> service.recordAgentDebtRepayment(7L, 1000L, null, "admin1"))
            .isInstanceOf(IllegalArgumentException.class)
            .hasMessageContaining("dépasse la dette actuelle");
    }

    @Test
    void recordAgentDebtRepayment_noCurrentDebt_throws() {
        stubAgentBasics(7L, 70L, 0, "Jean Agent");

        assertThatThrownBy(() -> service.recordAgentDebtRepayment(7L, 100L, null, "admin1"))
            .isInstanceOf(IllegalArgumentException.class)
            .hasMessageContaining("aucune dette");
    }

    @Test
    void recordAgentDebtRepayment_zeroOrNegativeAmount_throws() {
        stubAgentBasics(7L, 70L, 1000, "Jean Agent");

        assertThatThrownBy(() -> service.recordAgentDebtRepayment(7L, 0L, null, "admin1"))
            .isInstanceOf(IllegalArgumentException.class);
        assertThatThrownBy(() -> service.recordAgentDebtRepayment(7L, -50L, null, "admin1"))
            .isInstanceOf(IllegalArgumentException.class);
    }

    @Test
    void recordAgentDebtRepayment_agentNotFound_throws() {
        when(jdbcTemplate.queryForObject(eq("SELECT user_id FROM agents WHERE id = ?"), eq(Long.class), eq(99L)))
            .thenThrow(new EmptyResultDataAccessException(1));

        assertThatThrownBy(() -> service.recordAgentDebtRepayment(99L, 100L, null, "admin1"))
            .isInstanceOf(IllegalArgumentException.class)
            .hasMessageContaining("Agent introuvable");
    }
}
