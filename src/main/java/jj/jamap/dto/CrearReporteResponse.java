package jj.jamap.dto;

/**
 * Respuesta al crear un reporte: indica si se creo una incidencia NUEVO o se VINCULADO a una existente.
 */
public record CrearReporteResponse(
        String resultado,
        Double distanciaMetros,
        ReporteResponse reporte,
        IncidenciaResumenResponse incidencia
) {}
