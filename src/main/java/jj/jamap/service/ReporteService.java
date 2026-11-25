package jj.jamap.service;

import java.time.Instant;
import java.util.List;
import jj.jamap.domain.entity.Incidencia;
import jj.jamap.domain.entity.Reporte;
import jj.jamap.domain.enums.EstadoIncidencia;
import jj.jamap.domain.enums.OrigenReporte;
import jj.jamap.dto.CrearReporteRequest;
import jj.jamap.dto.CrearReporteResponse;
import jj.jamap.dto.IncidenciaResumenResponse;
import jj.jamap.dto.MiReporteResponse;
import jj.jamap.dto.ReporteResponse;
import jj.jamap.repository.IncidenciaRepository;
import jj.jamap.repository.ReporteRepository;
import jj.jamap.util.GeoUtils;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

/**
 * Logica de negocio para crear reportes con deduplicacion geoespacial y consultar reportes del ciudadano.
 */
@Service
@Transactional(readOnly = true)
public class ReporteService {

    private static final String RESULTADO_NUEVO = "NUEVO";
    private static final String RESULTADO_VINCULADO = "VINCULADO";

    private final IncidenciaRepository incidenciaRepository;
    private final ReporteRepository reporteRepository;
    private final double radioDedupMetros;

    public ReporteService(
            IncidenciaRepository incidenciaRepository,
            ReporteRepository reporteRepository,
            @Value("${app.dedup.radio-metros:50}") double radioDedupMetros
    ) {
        this.incidenciaRepository = incidenciaRepository;
        this.reporteRepository = reporteRepository;
        this.radioDedupMetros = radioDedupMetros;
    }

    /**
     * Crea un reporte: si existe una incidencia abierta del mismo tipo dentro del radio configurado,
     * lo vincula y recalcula centroide y prioridad; de lo contrario crea una nueva incidencia.
     */
    @Transactional
    public CrearReporteResponse crearReporte(CrearReporteRequest request, String uidCiudadano) {
        Reporte nuevoReporte = construirReporte(request, uidCiudadano);

        List<Incidencia> candidatas = incidenciaRepository.findCercanasAbiertasPorTipo(
                request.latitud(),
                request.longitud(),
                radioDedupMetros,
                request.tipo().name()
        );

        if (!candidatas.isEmpty()) {
            Incidencia existente = candidatas.getFirst();
            double distancia = GeoUtils.redondearDosDecimales(
                    GeoUtils.distanciaMetros(
                            request.latitud(),
                            request.longitud(),
                            existente.getLatitud(),
                            existente.getLongitud()
                    )
            );
            existente.agregarReporte(nuevoReporte);
            if ((existente.getImageUrl() == null || existente.getImageUrl().isBlank())
                    && request.fotoUrl() != null && !request.fotoUrl().isBlank()) {
                existente.setImageUrl(request.fotoUrl());
            }
            IncidenciaService.recalcularMetricas(existente);
            Incidencia guardada = incidenciaRepository.saveAndFlush(existente);

            return new CrearReporteResponse(
                    RESULTADO_VINCULADO,
                    distancia,
                    ReporteResponse.from(nuevoReporte),
                    IncidenciaResumenResponse.from(guardada)
            );
        }

        Incidencia nuevaIncidencia = construirIncidenciaNueva(request);
        nuevaIncidencia.agregarReporte(nuevoReporte);
        IncidenciaService.recalcularMetricas(nuevaIncidencia);
        Incidencia guardada = incidenciaRepository.saveAndFlush(nuevaIncidencia);

        return new CrearReporteResponse(
                RESULTADO_NUEVO,
                null,
                ReporteResponse.from(nuevoReporte),
                IncidenciaResumenResponse.from(guardada)
        );
    }

    public List<MiReporteResponse> listarMios(String uidCiudadano) {
        return reporteRepository.findByUidCiudadanoOrderByFechaReporteDesc(uidCiudadano).stream()
                .map(MiReporteResponse::from)
                .toList();
    }

    private Reporte construirReporte(CrearReporteRequest request, String uidCiudadano) {
        Reporte reporte = new Reporte();
        reporte.setUidCiudadano(uidCiudadano);
        reporte.setFotoUrl(request.fotoUrl());
        reporte.setComentario(request.comentario());
        reporte.setDireccionCapturada(request.direccionCapturada());
        reporte.setLatitud(request.latitud());
        reporte.setLongitud(request.longitud());
        reporte.setOrigen(OrigenReporte.APP);
        reporte.setFechaReporte(Instant.now());
        return reporte;
    }

    private Incidencia construirIncidenciaNueva(CrearReporteRequest request) {
        Incidencia incidencia = new Incidencia();
        incidencia.setTipo(request.tipo());
        incidencia.setEstado(EstadoIncidencia.ABIERTA);
        incidencia.setLatitud(request.latitud());
        incidencia.setLongitud(request.longitud());
        incidencia.setCalle(request.calle());
        incidencia.setNumero(request.numero());
        incidencia.setCruzamiento1(request.cruzamiento1());
        incidencia.setCruzamiento2(request.cruzamiento2());
        incidencia.setColonia(request.colonia());
        incidencia.setImageUrl(request.fotoUrl());
        incidencia.setFechaApertura(Instant.now());
        return incidencia;
    }
}
