package com.payflex.backend.service;

import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.jdbc.core.JdbcTemplate;

import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.concurrent.atomic.AtomicLong;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.within;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.lenient;
import static org.mockito.Mockito.when;

/**
 * Tests unitaires purs (Mockito) de la cascade de répartition automatique des cotisations
 * sur les produits actifs d'un client. Aucun contexte Spring : {@link JdbcTemplate} et
 * {@link ProductDeliveryService} sont mockés, le service est instancié directement.
 */
@ExtendWith(MockitoExtension.class)
class ContributionAllocationServiceTest {

    @Mock
    private JdbcTemplate jdbcTemplate;

    @Mock
    private ProductDeliveryService productDeliveryService;

    private ContributionAllocationService service;

    private void init() {
        service = new ContributionAllocationService(jdbcTemplate, productDeliveryService);
    }

    /** Stub générique de la lecture de la cotisation (snapshot) par {@code loadSnapshot}. */
    private void stubSnapshot(long contributionId, long userId, long productId, double amount) {
        Map<String, Object> row = new LinkedHashMap<>();
        row.put("id", contributionId);
        row.put("user_id", userId);
        row.put("product_id", productId);
        row.put("agent_id", null);
        row.put("amount", amount);
        row.put("payment_mode", "mobile_money");
        row.put("reference_code", "REF-" + contributionId);
        row.put("payment_provider", "paydunya");
        lenient().when(jdbcTemplate.queryForMap(anyString(), any())).thenReturn(row);
    }

    /** Fournit des identifiants de ligne uniques et croissants pour LAST_INSERT_ID(). */
    private void stubGeneratedIds(long startAt) {
        AtomicLong counter = new AtomicLong(startAt);
        lenient().when(jdbcTemplate.queryForObject(eq("SELECT LAST_INSERT_ID()"), eq(Long.class)))
            .thenAnswer(inv -> counter.getAndIncrement());
    }

    private ProductDeliveryService.ProductProgress progress(long productId, String name, double price, double validated) {
        return new ProductDeliveryService.ProductProgress(productId, name, price, validated, validated >= price && price > 0);
    }

    @Test
    void allocateAndValidate_simpleCase_amountWithinRemaining_doesNotSplit() {
        init();
        stubSnapshot(1L, 100L, 10L, 1000);
        when(productDeliveryService.listProductProgress(100L))
            .thenReturn(List.of(progress(10L, "Formation", 5000, 2000)));

        ContributionAllocationService.AllocationOutcome outcome = service.allocateAndValidate(1L);

        assertThat(outcome.wasSplit()).isFalse();
        assertThat(outcome.allocationGroupId()).isNull();
        assertThat(outcome.unallocatedSurplusFcfa()).isEqualTo(0.0);
        assertThat(outcome.lines()).hasSize(1);
        ContributionAllocationService.AllocationLine line = outcome.lines().get(0);
        assertThat(line.productId()).isEqualTo(10L);
        assertThat(line.amountFcfa()).isEqualTo(1000.0, within(0.001));
        assertThat(line.goalReachedNow()).isFalse();
        assertThat(line.contributionId()).isEqualTo(1L);
    }

    @Test
    void allocateAndValidate_amountExactlyEqualsRemaining_doesNotSplit() {
        init();
        // Montant qui complète EXACTEMENT le reste à payer : toujours un cas "simple", pas de cascade.
        stubSnapshot(1L, 100L, 10L, 3000);
        when(productDeliveryService.listProductProgress(100L))
            .thenReturn(List.of(progress(10L, "Formation", 5000, 2000)));

        ContributionAllocationService.AllocationOutcome outcome = service.allocateAndValidate(1L);

        assertThat(outcome.wasSplit()).isFalse();
        assertThat(outcome.lines()).hasSize(1);
        assertThat(outcome.lines().get(0).goalReachedNow()).isTrue();
        assertThat(outcome.unallocatedSurplusFcfa()).isEqualTo(0.0);
    }

    @Test
    void allocateAndValidate_cascadeOverTwoProducts_splitsSurplusToSecondProduct() {
        init();
        stubSnapshot(1L, 100L, 10L, 2500);
        stubGeneratedIds(500L);
        when(productDeliveryService.listProductProgress(100L)).thenReturn(List.of(
            progress(10L, "Produit cible", 5000, 4000),   // reste 1000
            progress(20L, "Autre produit", 3000, 0)         // reste 3000
        ));

        ContributionAllocationService.AllocationOutcome outcome = service.allocateAndValidate(1L);

        assertThat(outcome.wasSplit()).isTrue();
        assertThat(outcome.allocationGroupId()).isNotNull();
        assertThat(outcome.unallocatedSurplusFcfa()).isEqualTo(0.0);
        assertThat(outcome.lines()).hasSize(2);

        ContributionAllocationService.AllocationLine first = outcome.lines().get(0);
        assertThat(first.productId()).isEqualTo(10L);
        assertThat(first.amountFcfa()).isEqualTo(1000.0, within(0.001));
        assertThat(first.goalReachedNow()).isTrue();
        // La 1ère tranche réutilise la cotisation ancre.
        assertThat(first.contributionId()).isEqualTo(1L);

        ContributionAllocationService.AllocationLine second = outcome.lines().get(1);
        assertThat(second.productId()).isEqualTo(20L);
        assertThat(second.amountFcfa()).isEqualTo(1500.0, within(0.001));
        assertThat(second.goalReachedNow()).isFalse();
        // Les tranches suivantes sont de nouvelles cotisations.
        assertThat(second.contributionId()).isNotEqualTo(1L);
    }

    @Test
    void allocateAndValidate_cascadeOverThreeProducts_exhaustsAllWithoutSurplus() {
        init();
        stubSnapshot(1L, 100L, 1L, 1600);
        stubGeneratedIds(700L);
        when(productDeliveryService.listProductProgress(100L)).thenReturn(List.of(
            progress(1L, "Produit A", 1000, 500),   // reste 500
            progress(2L, "Produit B", 1000, 700),   // reste 300
            progress(3L, "Produit C", 2000, 1000)   // reste 1000
        ));

        ContributionAllocationService.AllocationOutcome outcome = service.allocateAndValidate(1L);

        assertThat(outcome.wasSplit()).isTrue();
        assertThat(outcome.unallocatedSurplusFcfa()).isEqualTo(0.0);
        assertThat(outcome.lines()).hasSize(3);
        assertThat(outcome.lines().get(0).amountFcfa()).isEqualTo(500.0, within(0.001));
        assertThat(outcome.lines().get(0).goalReachedNow()).isTrue();
        assertThat(outcome.lines().get(1).amountFcfa()).isEqualTo(300.0, within(0.001));
        assertThat(outcome.lines().get(1).goalReachedNow()).isTrue();
        assertThat(outcome.lines().get(2).amountFcfa()).isEqualTo(800.0, within(0.001));
        assertThat(outcome.lines().get(2).goalReachedNow()).isFalse();
    }

    @Test
    void allocateAndValidate_noActiveProductCanAbsorb_createsUnallocatedSurplus() {
        init();
        stubSnapshot(1L, 100L, 10L, 500);
        stubGeneratedIds(900L);
        // Seul produit du client : déjà complet (reste = 0). Aucun autre produit actif.
        when(productDeliveryService.listProductProgress(100L))
            .thenReturn(List.of(progress(10L, "Produit complet", 1000, 1000)));

        ContributionAllocationService.AllocationOutcome outcome = service.allocateAndValidate(1L);

        assertThat(outcome.wasSplit()).isTrue();
        assertThat(outcome.lines()).isEmpty();
        assertThat(outcome.unallocatedSurplusFcfa()).isEqualTo(500.0, within(0.001));
    }

    @Test
    void allocateAndValidate_pathologicalManyProducts_boundedByMaxCascadeIterations() {
        init();
        double hugeAmount = 100_000;
        stubSnapshot(1L, 100L, 1L, hugeAmount);
        stubGeneratedIds(1000L);

        // 31 produits actifs (> MAX_CASCADE_ITERATIONS), chacun avec un reste de 10 FCFA :
        // sans le garde-fou, la cascade traiterait les 31 ; avec le garde-fou, elle doit
        // s'arrêter net à MAX_CASCADE_ITERATIONS (20) sans jamais boucler indéfiniment.
        List<ProductDeliveryService.ProductProgress> many = new java.util.ArrayList<>();
        for (long productId = 1; productId <= 31; productId++) {
            many.add(progress(productId, "Produit " + productId, 1010, 1000));
        }
        when(productDeliveryService.listProductProgress(100L)).thenReturn(many);

        ContributionAllocationService.AllocationOutcome outcome = service.allocateAndValidate(1L);

        assertThat(outcome.wasSplit()).isTrue();
        assertThat(outcome.lines()).hasSize(ContributionAllocationService.MAX_CASCADE_ITERATIONS);
        double expectedAllocated = ContributionAllocationService.MAX_CASCADE_ITERATIONS * 10.0;
        assertThat(outcome.unallocatedSurplusFcfa()).isEqualTo(hugeAmount - expectedAllocated, within(0.001));
    }

    @Test
    void allocateAndValidate_noProductAttached_validatesWithoutAllocation() {
        init();
        Map<String, Object> row = new LinkedHashMap<>();
        row.put("id", 1L);
        row.put("user_id", 100L);
        row.put("product_id", null);
        row.put("agent_id", null);
        row.put("amount", 1000.0);
        row.put("payment_mode", "cash");
        row.put("reference_code", "REF-1");
        row.put("payment_provider", null);
        lenient().when(jdbcTemplate.queryForMap(anyString(), any())).thenReturn(row);

        ContributionAllocationService.AllocationOutcome outcome = service.allocateAndValidate(1L);

        assertThat(outcome.wasSplit()).isFalse();
        assertThat(outcome.lines()).isEmpty();
        assertThat(outcome.unallocatedSurplusFcfa()).isEqualTo(0.0);
    }

    @Test
    void allocateAndValidate_missingContribution_throws() {
        init();
        lenient().when(jdbcTemplate.queryForMap(anyString(), any()))
            .thenThrow(new org.springframework.dao.EmptyResultDataAccessException(1));

        org.assertj.core.api.Assertions.assertThatThrownBy(() -> service.allocateAndValidate(999L))
            .isInstanceOf(IllegalArgumentException.class);
    }
}
