package jj.jamap.repository;

import java.util.List;
import jj.jamap.domain.entity.Incidencia;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.JpaSpecificationExecutor;

/**
 * Repositorio JPA para incidencias; incluye JpaSpecificationExecutor para filtros dinamicos.
 */
public interface IncidenciaRepository extends JpaRepository<Incidencia, Long>, JpaSpecificationExecutor<Incidencia> {

    List<Incidencia> findByAsignadoA(String asignadoA);
}
