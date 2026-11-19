package jj.jamap.dto;

/**
 * Incidencia abierta cercana a una ubicacion, incluyendo su distancia en metros.
 */
public record IncidenciaCercanaResponse(
        IncidenciaResumenResponse incidencia,
        double distanciaMetros
) {}
