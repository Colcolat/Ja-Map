package jj.jamap.dto;

import java.time.Instant;
import jj.jamap.domain.entity.Incidencia;
import jj.jamap.domain.entity.Reporte;
import jj.jamap.domain.enums.EstadoIncidencia;
import jj.jamap.domain.enums.OrigenReporte;
import jj.jamap.domain.enums.TipoIncidencia;

/**
 * Reporte del ciudadano enriquecido con el estado actual de su incidencia asociada.
 */
public record MiReporteResponse(
        Long reporteId,
        String fotoUrl,
        String comentario,
        String direccionCapturada,
        Double latitud,
        Double longitud,
        OrigenReporte origen,
        Instant fechaReporte,
        Long incidenciaId,
        TipoIncidencia tipo,
        EstadoIncidencia estado,
        Integer prioridad,
        String calle,
        String colonia
) {

    public static MiReporteResponse from(Reporte reporte) {
        Incidencia incidencia = reporte.getIncidencia();
        return new MiReporteResponse(
                reporte.getId(),
                reporte.getFotoUrl(),
                reporte.getComentario(),
                reporte.getDireccionCapturada(),
                reporte.getLatitud(),
                reporte.getLongitud(),
                reporte.getOrigen(),
                reporte.getFechaReporte(),
                incidencia != null ? incidencia.getId() : null,
                incidencia != null ? incidencia.getTipo() : null,
                incidencia != null ? incidencia.getEstado() : null,
                incidencia != null ? incidencia.getPrioridad() : null,
                incidencia != null ? incidencia.getCalle() : null,
                incidencia != null ? incidencia.getColonia() : null
        );
    }
}
