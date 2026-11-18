package jj.jamap.exception;

import static org.assertj.core.api.Assertions.assertThat;

import org.junit.jupiter.api.Test;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.mock.web.MockHttpServletRequest;

class GlobalExceptionHandlerTest {

    private final GlobalExceptionHandler handler = new GlobalExceptionHandler();

    @Test
    void handleNotFoundReturns404WithConsistentBody() {
        MockHttpServletRequest request = new MockHttpServletRequest("GET", "/api/incidencias/42");

        ResponseEntity<ApiError> response = handler.handleNotFound(
                new ResourceNotFoundException("Incidencia", 42L),
                request
        );

        assertThat(response.getStatusCode()).isEqualTo(HttpStatus.NOT_FOUND);
        assertThat(response.getBody()).isNotNull();
        assertThat(response.getBody().status()).isEqualTo(404);
        assertThat(response.getBody().message()).isEqualTo("Incidencia no encontrado con id: 42");
        assertThat(response.getBody().path()).isEqualTo("/api/incidencias/42");
        assertThat(response.getBody().details()).isEmpty();
    }

    @Test
    void handleIllegalArgumentReturns400WithMessage() {
        MockHttpServletRequest request = new MockHttpServletRequest("GET", "/api/incidencias/cercanas");

        ResponseEntity<ApiError> response = handler.handleIllegalArgument(
                new IllegalArgumentException("Radio inválido"),
                request
        );

        assertThat(response.getStatusCode()).isEqualTo(HttpStatus.BAD_REQUEST);
        assertThat(response.getBody()).isNotNull();
        assertThat(response.getBody().status()).isEqualTo(400);
        assertThat(response.getBody().message()).isEqualTo("Radio inválido");
        assertThat(response.getBody().path()).isEqualTo("/api/incidencias/cercanas");
    }

    @Test
    void handleGenericReturns500WithoutLeakingInternalDetails() {
        MockHttpServletRequest request = new MockHttpServletRequest("POST", "/api/reportes");

        ResponseEntity<ApiError> response = handler.handleGeneric(
                new RuntimeException("secret stack detail"),
                request
        );

        assertThat(response.getStatusCode()).isEqualTo(HttpStatus.INTERNAL_SERVER_ERROR);
        assertThat(response.getBody()).isNotNull();
        assertThat(response.getBody().status()).isEqualTo(500);
        assertThat(response.getBody().message()).isEqualTo("Error interno del servidor.");
        assertThat(response.getBody().message()).doesNotContain("secret stack detail");
        assertThat(response.getBody().path()).isEqualTo("/api/reportes");
    }
}
