package com.payflex.backend.config;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Configuration;
import org.springframework.web.servlet.config.annotation.CorsRegistry;
import org.springframework.web.servlet.config.annotation.WebMvcConfigurer;

import java.util.List;

/**
 * CORS — désactivé par défaut, prêt à l'emploi pour un futur front web séparé (PWA côté
 * client, back-office admin découplé, etc.) qui appellerait cette API depuis une autre origine.
 * <p>
 * Tant que {@code payflex.cors.allowed-origins} (variable d'environnement
 * {@code PAYFLEX_CORS_ALLOWED_ORIGINS}, liste séparée par des virgules) n'est pas renseignée,
 * la liste est vide et aucune configuration CORS n'est enregistrée : le comportement actuel
 * (pas de CORS, appels same-origin admin + API mobile native) est intégralement préservé.
 * <p>
 * Une fois des origines configurées, elles seules sont autorisées (jamais de wildcard {@code *}
 * ici, notamment parce que {@code allowCredentials(true)} l'interdit côté navigateur).
 */
@Configuration
public class CorsConfig implements WebMvcConfigurer {

    private final List<String> allowedOrigins;

    public CorsConfig(
        @Value("${payflex.cors.allowed-origins:}") List<String> allowedOrigins
    ) {
        this.allowedOrigins = allowedOrigins == null ? List.of() : allowedOrigins;
    }

    @Override
    public void addCorsMappings(CorsRegistry registry) {
        if (allowedOrigins.isEmpty()) {
            return;
        }
        registry.addMapping("/**")
            .allowedOrigins(allowedOrigins.toArray(new String[0]))
            .allowedMethods("GET", "POST", "PUT", "DELETE")
            .allowedHeaders("*")
            .allowCredentials(true)
            .maxAge(3600);
    }
}
