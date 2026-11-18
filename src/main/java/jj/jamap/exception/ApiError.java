package jj.jamap.exception;

import java.time.Instant;
import java.util.Map;

/**
 * Formato JSON estandarizado para todas las respuestas de error de la API.
 */
public record ApiError(
        Instant timestamp,
        int status,
        String error,
        String message,
        String path,
        Map<String, String> details
) {

    public static ApiError of(int status, String error, String message, String path) {
        return new ApiError(Instant.now(), status, error, message, path, Map.of());
    }

    public static ApiError of(
            int status,
            String error,
            String message,
            String path,
            Map<String, String> details
    ) {
        return new ApiError(Instant.now(), status, error, message, path, details);
    }
}
