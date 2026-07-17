package com.payflex.backend.config;

import com.github.benmanes.caffeine.cache.Caffeine;
import org.springframework.cache.CacheManager;
import org.springframework.cache.annotation.EnableCaching;
import org.springframework.cache.caffeine.CaffeineCacheManager;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

import java.util.concurrent.TimeUnit;

/**
 * Cache mémoire (Caffeine) pour les lectures peu volatiles et très fréquemment appelées.
 * <p>
 * TTL court (écriture) de 5 minutes + taille bornée : suffisant pour absorber les pics de
 * lecture (dashboard admin, résolution de permissions à chaque appel API mobile) sans risquer
 * de servir des données trop périmées après une modification côté admin.
 * <p>
 * Caches déclarés ici (noms utilisés par {@code @Cacheable}/{@code @CacheEvict}) :
 * <ul>
 *   <li>{@code productCategories} — catégories de produits actives (voir
 *       {@code ProductCategoryService#listAll()}), lues à chaque écran catalogue/admin,
 *       modifiées seulement via création/édition/suppression admin (rare).</li>
 *   <li>{@code userPermissions} — codes de permission résolus par utilisateur (voir
 *       {@code PermissionService#permissionCodesForUser(long)}), relus à quasiment chaque
 *       requête API mobile authentifiée, alors que les rôles/permissions changent rarement.</li>
 * </ul>
 */
@Configuration
@EnableCaching
public class CacheConfig {

    public static final String CACHE_PRODUCT_CATEGORIES = "productCategories";
    public static final String CACHE_USER_PERMISSIONS = "userPermissions";

    @Bean
    public CacheManager cacheManager() {
        CaffeineCacheManager cacheManager = new CaffeineCacheManager(
            CACHE_PRODUCT_CATEGORIES,
            CACHE_USER_PERMISSIONS
        );
        cacheManager.setCaffeine(
            Caffeine.newBuilder()
                .expireAfterWrite(10, TimeUnit.MINUTES)
                .maximumSize(2_000)
                .recordStats()
        );
        return cacheManager;
    }
}
