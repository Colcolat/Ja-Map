package jj.jamap.dto;

import java.time.Instant;
import jj.jamap.domain.entity.Reporte;
import jj.jamap.domain.enums.OrigenReporte;

/**
 * Representacion JSON de un reporte individual vinculado a una incidencia.
 */
public record ReporteResponse(
        Long id,
        String uidCiudadano,
        String fotoUrl,
        String comentario,
        String direccionCapturada,
        Double latitud,
        Double longitud,
        OrigenReporte origen,
        Instant fechaReporte
) {

    public static ReporteResponse from(Reporte reporte) {
        return new ReporteResponse(
                reporte.getId(),
                reporte.getUidCiudadano(),
                reporte.getFotoUrl(),
                reporte.getComentario(),
                reporte.getDireccionCapturada(),
                reporte.getLatitud(),
                reporte.getLongitud(),
                reporte.getOrigen(),
                reporte.getFechaReporte()
        );
    }
}
