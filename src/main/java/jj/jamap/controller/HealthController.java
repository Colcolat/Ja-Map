package jj.jamap.controller;

import java.time.Instant;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

/**
 * Endpoint de verificacion rapida para comprobar que el backend esta activo.
 */
@RestController
@RequestMapping("/health")
public class HealthController {

    public record HealthResponse(String status, String service, Instant timestamp) {}

    @GetMapping
    public ResponseEntity<HealthResponse> health() {
        return ResponseEntity.ok(new HealthResponse("UP", "jamap", Instant.now()));
    }
}
