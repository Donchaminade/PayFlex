package com.payflex.backend.service;

import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.dao.EmptyResultDataAccessException;
import org.springframework.jdbc.core.JdbcTemplate;

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
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.times;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

/**
 * Tests unitaires purs (Mockito) de {@link SurplusRegularizationService} : régularisation manuelle
 * des excédents de cotisation non affectés automatiquement (voir {@link ContributionAllocationService}).
 */
@ExtendWith(MockitoExtension.class)
class SurplusRegularizationServiceTest {

    @Mock private JdbcTemplate jdbcTemplate;
    @Mock private ProductDeliveryService productDeliveryService;
    @Mock private UserInboxNotificationService inboxNotifications;

    private SurplusRegularizationService service;

    @BeforeEach
    void setUp() {
        service = new SurplusRegularizationService(jdbcTemplate, productDeliveryService, inboxNotifications);
    }

    private void stubUnassignedSurplus(long surplusId, long userId, double amountFcfa, Long allocationGroupId, String status) {
        Map<String, Object> row = new LinkedHashMap<>();
        row.put("id", surplusId);
        row.put("user_id", userId);
        row.put("amount_fcfa", amountFcfa);
        row.put("allocation_group_id", allocationGroupId);
        row.put("status", status);
        lenient().when(jdbcTemplate.queryForMap(anyString(), eq(surplusId))).thenReturn(row);
    }

    private ProductDeliveryService.ProductProgress activeProduct(long productId, String name, double price, double validated) {
        return new ProductDeliveryService.ProductProgress(productId, name, price, validated, validated >= price && price > 0);
    }

    @Test
    void reallocateToProduct_toActiveProduct_createsValidatedContributionAndMarksResolved() {
        stubUnassignedSurplus(50L, 200L, 1500, 77L, SurplusRegularizationService.STATUS_UNASSIGNED);
        when(productDeliveryService.listProductProgress(200L)).thenReturn(List.of(
            activeProduct(20L, "Produit B", 5000, 1000)
        ));
        when(jdbcTemplate.queryForObject(eq("SELECT LAST_INSERT_ID()"), eq(Long.class))).thenReturn(999L);

        service.reallocateToProduct(50L, 20L, "admin1");

        verify(jdbcTemplate).update(
            argThat(sql -> sql.contains("INSERT INTO contributions")),
            eq(200L), eq(20L), eq(1500.0), eq("PF-SURPLUS-50"), eq(77L)
        );
        verify(jdbcTemplate).update(
            argThat(sql -> sql.contains("UPDATE contribution_unallocated_surplus")),
            eq(SurplusRegularizationService.STATUS_REALLOCATED), eq("admin1"),
            argThat((String note) -> note.contains("Produit B")), eq(50L)
        );
        verify(inboxNotifications).notifyUser(
            eq(200L), anyString(), anyString(), argThat(body -> body.contains("1500") || body.contains("1 500")), eq(999L)
        );
    }

    @Test
    void reallocateToProduct_targetNotInClientActiveSelection_throwsAndDoesNotWrite() {
        stubUnassignedSurplus(50L, 200L, 1500, 77L, SurplusRegularizationService.STATUS_UNASSIGNED);
        when(productDeliveryService.listProductProgress(200L)).thenReturn(List.of(
            activeProduct(99L, "Autre produit", 5000, 1000)
        ));

        assertThatThrownBy(() -> service.reallocateToProduct(50L, 20L, "admin1"))
            .isInstanceOf(IllegalArgumentException.class)
            .hasMessageContaining("sélection active");

        verify(inboxNotifications, never()).notifyUser(anyLong(), anyString(), anyString(), anyString(), any());
    }

    @Test
    void reallocateToProduct_alreadyResolvedSurplus_throws() {
        stubUnassignedSurplus(50L, 200L, 1500, 77L, SurplusRegularizationService.STATUS_REALLOCATED);

        assertThatThrownBy(() -> service.reallocateToProduct(50L, 20L, "admin1"))
            .isInstanceOf(IllegalArgumentException.class)
            .hasMessageContaining("déjà été régularisé");
    }

    @Test
    void reallocateToProduct_unknownSurplus_throws() {
        lenient().when(jdbcTemplate.queryForMap(anyString(), eq(404L)))
            .thenThrow(new EmptyResultDataAccessException(1));

        assertThatThrownBy(() -> service.reallocateToProduct(404L, 20L, "admin1"))
            .isInstanceOf(IllegalArgumentException.class)
            .hasMessageContaining("introuvable");
    }

    @Test
    void markRefundedOutOfSystem_withExplicitNote_marksResolvedAndNotifiesClient() {
        stubUnassignedSurplus(51L, 201L, 800, null, SurplusRegularizationService.STATUS_UNASSIGNED);

        service.markRefundedOutOfSystem(51L, "Remboursé en espèces au guichet", "admin2");

        verify(jdbcTemplate).update(
            argThat(sql -> sql.contains("UPDATE contribution_unallocated_surplus")),
            eq(SurplusRegularizationService.STATUS_REFUNDED), eq("admin2"),
            eq("Remboursé en espèces au guichet"), eq(51L)
        );
        verify(inboxNotifications).notifyUser(eq(201L), anyString(), anyString(), argThat(body -> body.contains("Remboursé")), eq(null));
    }

    @Test
    void markRefundedOutOfSystem_blankNote_usesDefaultGeneratedNote() {
        stubUnassignedSurplus(52L, 202L, 300, null, SurplusRegularizationService.STATUS_UNASSIGNED);

        service.markRefundedOutOfSystem(52L, "  ", "admin3");

        verify(jdbcTemplate).update(
            argThat(sql -> sql.contains("UPDATE contribution_unallocated_surplus")),
            eq(SurplusRegularizationService.STATUS_REFUNDED), eq("admin3"),
            argThat((String note) -> note.contains("Traité hors système par admin3")), eq(52L)
        );
    }

    @Test
    void markRefundedOutOfSystem_alreadyResolved_throws() {
        stubUnassignedSurplus(53L, 203L, 300, null, SurplusRegularizationService.STATUS_REFUNDED);

        assertThatThrownBy(() -> service.markRefundedOutOfSystem(53L, "note", "admin3"))
            .isInstanceOf(IllegalArgumentException.class)
            .hasMessageContaining("déjà été régularisé");
    }

    @Test
    void activeProductChoicesForClient_excludesGoalReachedProducts() {
        when(productDeliveryService.listProductProgress(300L)).thenReturn(List.of(
            activeProduct(1L, "Complet", 1000, 1000),
            activeProduct(2L, "En cours", 2000, 500)
        ));

        List<SurplusRegularizationService.ActiveProductChoice> choices = service.activeProductChoicesForClient(300L);

        assertThat(choices).hasSize(1);
        assertThat(choices.get(0).productId()).isEqualTo(2L);
        assertThat(choices.get(0).remainingFcfa()).isEqualTo(1500.0);
    }

    @Test
    void countUnresolved_returnsZeroWhenNull() {
        when(jdbcTemplate.queryForObject(anyString(), eq(Long.class), eq(SurplusRegularizationService.STATUS_UNASSIGNED)))
            .thenReturn(null);

        assertThat(service.countUnresolved()).isEqualTo(0L);
    }
}
