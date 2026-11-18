package jj.jamap.repository;

import java.util.List;
import jj.jamap.domain.entity.Reporte;
import org.springframework.data.jpa.repository.JpaRepository;

/**
 * Repositorio JPA para reportes individuales de ciudadanos e historicos.
 */
public interface ReporteRepository extends JpaRepository<Reporte, Long> {

    List<Reporte> findByUidCiudadanoOrderByFechaReporteDesc(String uidCiudadano);

    long countByIncidenciaId(Long incidenciaId);
}
