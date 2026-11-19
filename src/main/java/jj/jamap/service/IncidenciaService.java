package jj.jamap.service;

import java.time.Instant;
import java.time.temporal.ChronoUnit;
import jj.jamap.domain.entity.Incidencia;
import jj.jamap.domain.enums.EstadoIncidencia;
import jj.jamap.domain.enums.TipoIncidencia;
import jj.jamap.dto.ActualizarIncidenciaRequest;
import jj.jamap.dto.IncidenciaDetalleResponse;
import jj.jamap.dto.IncidenciaResumenResponse;
import jj.jamap.dto.PageResponse;
import jj.jamap.exception.ResourceNotFoundException;
import jj.jamap.repository.IncidenciaRepository;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.domain.Specification;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

/**
 * Logica de negocio para consulta, edicion y eliminacion de incidencias.
 */
@Service
@Transactional(readOnly = true)
public class IncidenciaService {

    private final IncidenciaRepository incidenciaRepository;

    public IncidenciaService(IncidenciaRepository incidenciaRepository) {
        this.incidenciaRepository = incidenciaRepository;
    }

    public PageResponse<IncidenciaResumenResponse> listar(
            TipoIncidencia tipo,
            EstadoIncidencia estado,
            String colonia,
            String q,
            Pageable pageable
    ) {
        Specification<Incidencia> spec = IncidenciaSpecifications.conFiltros(tipo, estado, colonia, q);
        Page<IncidenciaResumenResponse> page = incidenciaRepository.findAll(spec, pageable)
                .map(IncidenciaResumenResponse::from);
        return PageResponse.from(page);
    }

    public IncidenciaDetalleResponse obtenerDetalle(Long id) {
        Incidencia incidencia = buscarPorIdOLanzar(id);
        return IncidenciaDetalleResponse.from(incidencia);
    }

    @Transactional
    public IncidenciaDetalleResponse actualizar(Long id, ActualizarIncidenciaRequest request) {
        Incidencia incidencia = buscarPorIdOLanzar(id);

        incidencia.setTipo(request.tipo());
        incidencia.setEstado(request.estado());
        incidencia.setLatitud(request.latitud());
        incidencia.setLongitud(request.longitud());
        incidencia.setCalle(request.calle());
        incidencia.setNumero(request.numero());
        incidencia.setCruzamiento1(request.cruzamiento1());
        incidencia.setCruzamiento2(request.cruzamiento2());
        incidencia.setColonia(request.colonia());
        if (request.prioridad() != null) {
            incidencia.setPrioridad(request.prioridad());
        }
        incidencia.setCostoEstimado(request.costoEstimado());
        incidencia.setAsignadoA(request.asignadoA());
        incidencia.setFotoEvidenciaUrl(request.fotoEvidenciaUrl());

        if (request.estado() == EstadoIncidencia.CERRADA && incidencia.getFechaCierre() == null) {
            incidencia.setFechaCierre(Instant.now());
        } else if (request.estado() != EstadoIncidencia.CERRADA) {
            incidencia.setFechaCierre(null);
        }

        Incidencia guardada = incidenciaRepository.save(incidencia);
        return IncidenciaDetalleResponse.from(guardada);
    }

    @Transactional
    public void eliminar(Long id) {
        Incidencia incidencia = buscarPorIdOLanzar(id);
        incidenciaRepository.delete(incidencia);
    }

    /**
     * Formula de prioridad: min(100, reportes * 10 + diasAbierta * 2).
     */
    public static int calcularPrioridad(int totalReportes, Instant fechaApertura) {
        int reportesValidos = Math.max(0, totalReportes);
        long diasAbierta = fechaApertura == null
                ? 0
                : Math.max(0, ChronoUnit.DAYS.between(fechaApertura, Instant.now()));
        long puntaje = (long) reportesValidos * 10 + diasAbierta * 2;
        return (int) Math.min(100, puntaje);
    }

    private Incidencia buscarPorIdOLanzar(Long id) {
        return incidenciaRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("Incidencia", id));
    }
}
