package jj.jamap.dto;

import java.math.BigDecimal;
import java.time.Instant;
import java.util.Comparator;
import java.util.List;
import jj.jamap.domain.entity.Incidencia;
import jj.jamap.domain.enums.EstadoIncidencia;
import jj.jamap.domain.enums.TipoIncidencia;

/**
 * Vista detallada de una incidencia incluyendo todos sus reportes vinculados.
 */
public record IncidenciaDetalleResponse(
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
        String imageUrl,
        String fotoEvidenciaUrl,
        Instant fechaApertura,
        Instant fechaCierre,
        int totalReportes,
        List<ReporteResponse> reportes
) {

    public static IncidenciaDetalleResponse from(Incidencia incidencia) {
        List<ReporteResponse> reportesOrdenados = incidencia.getReportes().stream()
                .sorted(Comparator.comparing(
                        jj.jamap.domain.entity.Reporte::getFechaReporte,
                        Comparator.nullsLast(Comparator.reverseOrder())
                ))
                .map(ReporteResponse::from)
                .toList();

        return new IncidenciaDetalleResponse(
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
                incidencia.getImageUrl(),
                incidencia.getFotoEvidenciaUrl(),
                incidencia.getFechaApertura(),
                incidencia.getFechaCierre(),
                reportesOrdenados.size(),
                reportesOrdenados
        );
    }
}
