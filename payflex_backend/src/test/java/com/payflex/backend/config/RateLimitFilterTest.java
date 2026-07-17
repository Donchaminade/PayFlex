package com.payflex.backend.config;

import jakarta.servlet.FilterChain;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.mock.web.MockHttpServletRequest;
import org.springframework.mock.web.MockHttpServletResponse;

import java.lang.reflect.Field;
import java.nio.charset.StandardCharsets;
import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.times;
import static org.mockito.Mockito.verify;

/**
 * Tests unitaires purs (pas de contexte Spring) de {@link RateLimitFilter} : le filtre est
 * instancié directement, les requêtes sont simulées avec {@code MockHttpServletRequest}.
 *
 * <p>Le filtre n'a pas d'horloge injectable (il appelle directement {@code System.currentTimeMillis()}
 * en interne — voir la javadoc de la classe testée) et les fenêtres réelles durent 5 minutes :
 * plutôt que d'attendre réellement 5 minutes ou de réinventer une architecture à horloge injectable
 * (hors périmètre de cette tâche), le test d'expiration de fenêtre manipule directement, via
 * réflexion, le champ interne {@code windowStartMillis} du compteur déjà créé par une requête réelle
 * — ce qui exerce fidèlement la même branche de code que l'écoulement réel du temps.</p>
 */
class RateLimitFilterTest {

    private RateLimitFilter filter;

    @BeforeEach
    void setUp() {
        filter = new RateLimitFilter();
    }

    private MockHttpServletRequest jsonLoginRequest(String identifier) {
        MockHttpServletRequest request = new MockHttpServletRequest("POST", "/api/mobile/auth/login");
        request.setContent(("{\"identifier\":\"" + identifier + "\"}").getBytes(StandardCharsets.UTF_8));
        request.setContentType("application/json");
        request.setRemoteAddr("10.0.0.1");
        return request;
    }

    private int sendOne(String identifier) throws Exception {
        MockHttpServletRequest request = jsonLoginRequest(identifier);
        MockHttpServletResponse response = new MockHttpServletResponse();
        FilterChain chain = mock(FilterChain.class);
        filter.doFilterInternal(request, response, chain);
        return response.getStatus();
    }

    @Test
    void allowsUpToConfiguredMaxAttempts_thenRejectsTheNextOne() throws Exception {
        // Règle /api/mobile/auth/login : 5 tentatives / 5 min (voir RateLimitFilter.RULES).
        for (int i = 1; i <= 5; i++) {
            MockHttpServletRequest request = jsonLoginRequest("alice");
            MockHttpServletResponse response = new MockHttpServletResponse();
            FilterChain chain = mock(FilterChain.class);

            filter.doFilterInternal(request, response, chain);

            verify(chain, times(1)).doFilter(org.mockito.ArgumentMatchers.any(), org.mockito.ArgumentMatchers.any());
            assertThat(response.getStatus()).isEqualTo(200);
        }

        MockHttpServletRequest sixthRequest = jsonLoginRequest("alice");
        MockHttpServletResponse sixthResponse = new MockHttpServletResponse();
        FilterChain sixthChain = mock(FilterChain.class);

        filter.doFilterInternal(sixthRequest, sixthResponse, sixthChain);

        verify(sixthChain, times(0)).doFilter(org.mockito.ArgumentMatchers.any(), org.mockito.ArgumentMatchers.any());
        assertThat(sixthResponse.getStatus()).isEqualTo(429);
        assertThat(sixthResponse.getContentAsString(StandardCharsets.UTF_8)).contains("Trop de tentatives");
    }

    @Test
    void differentIdentifiers_haveIndependentQuotas() throws Exception {
        for (int i = 1; i <= 5; i++) {
            assertThat(sendOne("alice")).isEqualTo(200);
        }
        assertThat(sendOne("alice")).isEqualTo(429);

        // "bob" n'a jamais fait de tentative : son quota est indépendant de celui d'"alice".
        assertThat(sendOne("bob")).isEqualTo(200);
    }

    @Test
    void unmatchedRoute_isNeverRateLimited() throws Exception {
        MockHttpServletRequest request = new MockHttpServletRequest("GET", "/api/mobile/catalog");
        request.setRemoteAddr("10.0.0.1");
        MockHttpServletResponse response = new MockHttpServletResponse();
        FilterChain chain = mock(FilterChain.class);

        for (int i = 0; i < 50; i++) {
            filter.doFilterInternal(request, response, chain);
        }

        verify(chain, times(50)).doFilter(org.mockito.ArgumentMatchers.any(), org.mockito.ArgumentMatchers.any());
    }

    @Test
    @SuppressWarnings("unchecked")
    void afterWindowExpires_counterResetsAndNewAttemptIsAccepted() throws Exception {
        for (int i = 1; i <= 5; i++) {
            assertThat(sendOne("carla")).isEqualTo(200);
        }
        assertThat(sendOne("carla")).isEqualTo(429);

        // Fait "vieillir" artificiellement la fenêtre du compteur interne (au-delà de 5 min)
        // pour simuler son expiration, sans attendre réellement et sans modifier RateLimitFilter.
        Field countersField = RateLimitFilter.class.getDeclaredField("counters");
        countersField.setAccessible(true);
        Map<String, Object> counters = (Map<String, Object>) countersField.get(filter);
        assertThat(counters).isNotEmpty();

        for (Map.Entry<String, Object> entry : counters.entrySet()) {
            if (!entry.getKey().contains("carla")) {
                continue;
            }
            Object counter = entry.getValue();
            Field windowStartField = counter.getClass().getDeclaredField("windowStartMillis");
            windowStartField.setAccessible(true);
            windowStartField.set(counter, System.currentTimeMillis() - (6 * 60_000L));
        }

        assertThat(sendOne("carla")).isEqualTo(200);
    }

    @Test
    void formLoginRoute_usesUsernameParameterAsIdentifier() throws Exception {
        for (int i = 1; i <= 5; i++) {
            MockHttpServletRequest request = new MockHttpServletRequest("POST", "/login");
            request.setParameter("username", "admin");
            request.setRemoteAddr("10.0.0.2");
            MockHttpServletResponse response = new MockHttpServletResponse();
            FilterChain chain = mock(FilterChain.class);
            filter.doFilterInternal(request, response, chain);
            assertThat(response.getStatus()).isEqualTo(200);
        }

        MockHttpServletRequest sixthRequest = new MockHttpServletRequest("POST", "/login");
        sixthRequest.setParameter("username", "admin");
        sixthRequest.setRemoteAddr("10.0.0.2");
        MockHttpServletResponse sixthResponse = new MockHttpServletResponse();
        FilterChain sixthChain = mock(FilterChain.class);
        filter.doFilterInternal(sixthRequest, sixthResponse, sixthChain);

        assertThat(sixthResponse.getStatus()).isEqualTo(429);
    }
}
