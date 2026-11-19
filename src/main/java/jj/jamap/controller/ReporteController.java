package jj.jamap.controller;

import jakarta.validation.Valid;
import java.util.List;
import jj.jamap.dto.CrearReporteRequest;
import jj.jamap.dto.CrearReporteResponse;
import jj.jamap.dto.MiReporteResponse;
import jj.jamap.service.ReporteService;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestHeader;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

/**
 * Endpoints REST para crear reportes ciudadanos (con deduplicacion) y consultar los propios.
 */
@RestController
@RequestMapping("/reportes")
public class ReporteController {

    // UID temporal mientras se integra Firebase Authentication en la Fase B4
    private static final String DEFAULT_DEMO_UID = "demo-ciudadano-01";

    private final ReporteService reporteService;

    public ReporteController(ReporteService reporteService) {
        this.reporteService = reporteService;
    }

    @PostMapping
    public ResponseEntity<CrearReporteResponse> crear(
            @Valid @RequestBody CrearReporteRequest request,
            @RequestHeader(value = "X-User-Uid", required = false) String userUid
    ) {
        String uidEfectivo = resolverUid(userUid);
        CrearReporteResponse response = reporteService.crearReporte(request, uidEfectivo);
        return ResponseEntity.status(HttpStatus.CREATED).body(response);
    }

    @GetMapping("/mios")
    public ResponseEntity<List<MiReporteResponse>> listarMios(
            @RequestHeader(value = "X-User-Uid", required = false) String userUid
    ) {
        return ResponseEntity.ok(reporteService.listarMios(resolverUid(userUid)));
    }

    private String resolverUid(String userUid) {
        return (userUid != null && !userUid.isBlank()) ? userUid.trim() : DEFAULT_DEMO_UID;
    }
}
