package jj.jamap.controller;

import jakarta.validation.Valid;
import java.util.List;
import jj.jamap.domain.enums.EstadoIncidencia;
import jj.jamap.domain.enums.TipoIncidencia;
import jj.jamap.dto.ActualizarIncidenciaRequest;
import jj.jamap.dto.IncidenciaCercanaResponse;
import jj.jamap.dto.IncidenciaDetalleResponse;
import jj.jamap.dto.IncidenciaResumenResponse;
import jj.jamap.dto.PageResponse;
import jj.jamap.service.IncidenciaService;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;
import org.springframework.data.domain.Sort;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

/**
 * Endpoints REST para consultar, filtrar, editar y eliminar incidencias.
 */
@RestController
@RequestMapping("/incidencias")
public class IncidenciaController {

    private static final int MAX_PAGE_SIZE = 100;

    private final IncidenciaService incidenciaService;
    private final double radioPorDefecto;

    public IncidenciaController(
            IncidenciaService incidenciaService,
            @Value("${app.dedup.radio-metros:50}") double radioPorDefecto
    ) {
        this.incidenciaService = incidenciaService;
        this.radioPorDefecto = radioPorDefecto;
    }

    @GetMapping
    public ResponseEntity<PageResponse<IncidenciaResumenResponse>> listar(
            @RequestParam(required = false) TipoIncidencia tipo,
            @RequestParam(required = false) EstadoIncidencia estado,
            @RequestParam(required = false) String colonia,
            @RequestParam(required = false) String q,
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "10") int size
    ) {
        int paginaValida = Math.max(0, page);
        int tamanoValido = Math.min(Math.max(1, size), MAX_PAGE_SIZE);
        Sort ordenPorDefecto = Sort.by(
                Sort.Order.desc("prioridad"),
                Sort.Order.desc("fechaApertura")
        );
        Pageable pageable = PageRequest.of(paginaValida, tamanoValido, ordenPorDefecto);
        return ResponseEntity.ok(incidenciaService.listar(tipo, estado, colonia, q, pageable));
    }

    @GetMapping("/cercanas")
    public ResponseEntity<List<IncidenciaCercanaResponse>> buscarCercanas(
            @RequestParam double lat,
            @RequestParam double lng,
            @RequestParam(required = false) Double radio,
            @RequestParam(required = false) TipoIncidencia tipo
    ) {
        double radioEfectivo = radio != null ? radio : radioPorDefecto;
        return ResponseEntity.ok(incidenciaService.buscarCercanas(lat, lng, radioEfectivo, tipo));
    }

    @GetMapping("/{id}")
    public ResponseEntity<IncidenciaDetalleResponse> obtenerDetalle(@PathVariable Long id) {
        return ResponseEntity.ok(incidenciaService.obtenerDetalle(id));
    }

    @PutMapping("/{id}")
    public ResponseEntity<IncidenciaDetalleResponse> actualizar(
            @PathVariable Long id,
            @Valid @RequestBody ActualizarIncidenciaRequest request
    ) {
        return ResponseEntity.ok(incidenciaService.actualizar(id, request));
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<Void> eliminar(@PathVariable Long id) {
        incidenciaService.eliminar(id);
        return ResponseEntity.noContent().build();
    }
}
