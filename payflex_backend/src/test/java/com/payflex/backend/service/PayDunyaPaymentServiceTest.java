package com.payflex.backend.service;

import com.payflex.backend.config.PayflexProperties;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.dao.EmptyResultDataAccessException;
import org.springframework.jdbc.core.JdbcTemplate;

import java.util.Optional;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyLong;
import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.ArgumentMatchers.argThat;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.lenient;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.times;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

/**
 * Tests unitaires purs (Mockito) de {@link PayDunyaPaymentService}, centrés sur la protection
 * anti-usurpation de {@code handleIpn} : on ne fait JAMAIS confiance au contenu brut de l'IPN
 * (ici réduit à un jeton) — seul le second appel serveur {@code fetchInvoiceStatus} (interrogeant
 * PayDunya directement) fait foi pour valider réellement une cotisation.
 */
@ExtendWith(MockitoExtension.class)
class PayDunyaPaymentServiceTest {

    @Mock private JdbcTemplate jdbcTemplate;
    @Mock private PayDunyaService payDunyaService;
    @Mock private ContributionWorkflowService contributionWorkflowService;
    @Mock private ContributionValidationAlertService alertService;
    @Mock private AdminAuditService auditService;
    @Mock private ClientAdhesionService clientAdhesionService;
    @Mock private ContributionAllocationService contributionAllocationService;

    private PayDunyaPaymentService service;

    @BeforeEach
    void setUp() {
        PayflexProperties properties = new PayflexProperties();
        properties.getPaydunya().setEnabled(true);
        properties.getPaydunya().setMasterKey("m");
        properties.getPaydunya().setPrivateKey("p");
        properties.getPaydunya().setToken("t");
        service = new PayDunyaPaymentService(
            jdbcTemplate,
            payDunyaService,
            contributionWorkflowService,
            alertService,
            auditService,
            clientAdhesionService,
            contributionAllocationService,
            properties
        );
    }

    /**
     * Câble en UN SEUL stub (au lieu de deux {@code when()} concurrents sur la même surcharge
     * varargs {@code queryForObject(String, Class, Object...)}) la résolution du jeton PayDunya,
     * qu'il s'agisse d'un jeton d'adhésion ({@code users.adhesion_paydunya_token}) ou d'un jeton de
     * cotisation ({@code contributions.paydunya_token}) — distingués par inspection du texte SQL.
     * Deux stubs {@code argThat} séparés sur le même mock + la même surcharge se sont avérés
     * instables avec Mockito (fuite de matcher entre stubs -> NullPointerException).
     *
     * @param isAdhesionToken si {@code true}, {@code resultId} est renvoyé pour la requête
     *                        d'adhésion et la requête de cotisation échoue (introuvable) ; sinon
     *                        l'inverse. Si {@code resultId} est {@code null}, les deux requêtes
     *                        échouent (jeton totalement inconnu).
     */
    private void stubTokenLookup(boolean isAdhesionToken, Long resultId) {
        lenient().when(jdbcTemplate.queryForObject(anyString(), eq(Long.class), any()))
            .thenAnswer(inv -> {
                String sql = inv.getArgument(0);
                boolean adhesionQuery = sql.contains("FROM users WHERE adhesion_paydunya_token");
                if (adhesionQuery == isAdhesionToken && resultId != null) {
                    return resultId;
                }
                throw new EmptyResultDataAccessException(1);
            });
    }

    @Test
    void handleIpn_validatesContribution_onlyWhenSecondCallConfirmsCompleted() {
        String token = "tok-123";
        stubTokenLookup(false, 42L);
        when(payDunyaService.fetchInvoiceStatus(token)).thenReturn(Optional.of("completed"));

        service.handleIpn(token);

        verify(contributionWorkflowService).validateByPaydunya(42L, token);
        verify(alertService).create(eq(42L), eq(ContributionValidationAlertService.TYPE_PAYDUNYA_APPROVED), anyString());
        verify(jdbcTemplate, never()).update(argThat(sql -> sql.contains("status = 'rejected'")), any(), any());
    }

    @Test
    void handleIpn_doesNotValidate_whenSecondCallReturnsDifferentStatus_antiSpoofing() {
        // "IPN reçu" (on a un token) mais le second appel serveur (l'unique source de vérité)
        // renvoie un statut NON confirmé : la cotisation ne doit JAMAIS être validée sur la seule
        // base de la réception de l'IPN.
        String token = "tok-456";
        stubTokenLookup(false, 43L);
        when(payDunyaService.fetchInvoiceStatus(token)).thenReturn(Optional.of("pending"));

        service.handleIpn(token);

        verify(contributionWorkflowService, never()).validateByPaydunya(anyLong(), anyString());
        verify(jdbcTemplate, never()).update(argThat(sql -> sql.contains("status = 'rejected'")), any(), any());
    }

    @Test
    void handleIpn_rejectsContribution_whenSecondCallReturnsCancelled() {
        String token = "tok-789";
        stubTokenLookup(false, 44L);
        when(payDunyaService.fetchInvoiceStatus(token)).thenReturn(Optional.of("cancelled"));
        when(jdbcTemplate.update(
            argThat(sql -> sql.contains("status = 'rejected'")),
            anyString(), eq(44L)
        )).thenReturn(1);

        service.handleIpn(token);

        verify(contributionWorkflowService, never()).validateByPaydunya(anyLong(), anyString());
        verify(contributionWorkflowService).notifyPaydunyaContributionCanceled(44L);
        verify(alertService).create(eq(44L), eq(ContributionValidationAlertService.TYPE_PAYDUNYA_CANCELED), anyString());
    }

    @Test
    void handleIpn_doesNothing_whenSecondCallCannotBeReached() {
        // fetchInvoiceStatus indisponible (Optional.empty()) : ni validation, ni rejet — on ne
        // décide jamais sans confirmation positive de l'appel serveur.
        String token = "tok-unreachable";
        stubTokenLookup(false, 45L);
        when(payDunyaService.fetchInvoiceStatus(token)).thenReturn(Optional.empty());

        service.handleIpn(token);

        verify(contributionWorkflowService, never()).validateByPaydunya(anyLong(), anyString());
        verify(contributionWorkflowService, never()).notifyPaydunyaContributionCanceled(anyLong());
    }

    @Test
    void handleIpn_unknownToken_doesNothing() {
        String token = "tok-unknown";
        stubTokenLookup(false, null);

        service.handleIpn(token);

        verify(payDunyaService, never()).fetchInvoiceStatus(anyString());
        verify(contributionWorkflowService, never()).validateByPaydunya(anyLong(), anyString());
    }

    @Test
    void handleIpn_blankOrNullToken_doesNothing() {
        service.handleIpn(null);
        service.handleIpn("  ");

        verify(payDunyaService, never()).fetchInvoiceStatus(anyString());
    }

    @Test
    void handleIpn_adhesionToken_marksAdhesionPaid_onlyWhenSecondCallConfirms() {
        String token = "tok-adhesion";
        stubTokenLookup(true, 77L);
        when(payDunyaService.fetchInvoiceStatus(token)).thenReturn(Optional.of("completed"));

        service.handleIpn(token);

        verify(clientAdhesionService).markAdhesionPaidByPaydunya(77L, token);
        verify(contributionWorkflowService, never()).validateByPaydunya(anyLong(), anyString());
    }

    @Test
    void handleIpn_adhesionToken_doesNotMarkPaid_whenSecondCallNotConfirmed() {
        String token = "tok-adhesion-2";
        stubTokenLookup(true, 78L);
        when(payDunyaService.fetchInvoiceStatus(token)).thenReturn(Optional.of("cancelled"));

        service.handleIpn(token);

        verify(clientAdhesionService, never()).markAdhesionPaidByPaydunya(anyLong(), anyString());
    }

    // ------------------------------------------------------------------
    // initMobileMoneyPayment : validations simples avant tout appel externe
    // ------------------------------------------------------------------

    @Test
    void initMobileMoneyPayment_zeroOrNegativeAmount_throwsWithoutCallingPayDunya() {
        when(payDunyaService.isConfigured()).thenReturn(true);

        assertThatThrownBy(() -> service.initMobileMoneyPayment(1L, 10L, null, 0))
            .isInstanceOf(IllegalArgumentException.class);
        assertThatThrownBy(() -> service.initMobileMoneyPayment(1L, 10L, null, -100))
            .isInstanceOf(IllegalArgumentException.class);

        verify(payDunyaService, never()).createCheckout(
            org.mockito.ArgumentMatchers.anyInt(), anyString(), anyString(), anyString(), anyString(), any(), any()
        );
    }

    @Test
    void initMobileMoneyPayment_payDunyaNotConfigured_returnsDisabledFlagWithoutDbWrite() {
        when(payDunyaService.isConfigured()).thenReturn(false);

        java.util.Map<String, Object> result = service.initMobileMoneyPayment(1L, 10L, null, 5000);

        assertThat(result).containsEntry("paydunyaEnabled", false);
        verify(jdbcTemplate, never()).update(anyString(), any(), any(), any(), any(), any());
    }
}
