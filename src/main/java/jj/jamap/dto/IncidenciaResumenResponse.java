package jj.jamap.dto;

import java.math.BigDecimal;
import java.time.Instant;
import jj.jamap.domain.entity.Incidencia;
import jj.jamap.domain.entity.Reporte;
import jj.jamap.domain.enums.EstadoIncidencia;
import jj.jamap.domain.enums.TipoIncidencia;

/**
 * Vista resumida de una incidencia para listados, catalogo y marcadores de mapa.
 */
public record IncidenciaResumenResponse(
        Long id,
        TipoIncidencia tipo,
        EstadoIncidencia estado,
        Double latitud,
        Double longitud,
        String calle,
        String numero,
        String cruzamiento1,
        String cruzamiento2,
        String colonia,
        Integer prioridad,
        BigDecimal costoEstimado,
        String asignadoA,
        String fotoPrincipalUrl,
        int totalReportes,
        Instant fechaApertura,
        Instant fechaCierre
) {

    public static IncidenciaResumenResponse from(Incidencia incidencia) {
        String fotoPrincipal = resolverFotoPrincipal(incidencia);
        return new IncidenciaResumenResponse(
                incidencia.getId(),
                incidencia.getTipo(),
                incidencia.getEstado(),
                incidencia.getLatitud(),
                incidencia.getLongitud(),
                incidencia.getCalle(),
                incidencia.getNumero(),
                incidencia.getCruzamiento1(),
                incidencia.getCruzamiento2(),
                incidencia.getColonia(),
                incidencia.getPrioridad(),
                incidencia.getCostoEstimado(),
                incidencia.getAsignadoA(),
                fotoPrincipal,
                incidencia.getReportes().size(),
                incidencia.getFechaApertura(),
                incidencia.getFechaCierre()
        );
    }

    private static String resolverFotoPrincipal(Incidencia incidencia) {
        if (incidencia.getFotoEvidenciaUrl() != null && !incidencia.getFotoEvidenciaUrl().isBlank()) {
            return incidencia.getFotoEvidenciaUrl();
        }
        return incidencia.getReportes().stream()
                .map(Reporte::getFotoUrl)
                .filter(url -> url != null && !url.isBlank())
                .findFirst()
                .orElse(null);
    }
}
