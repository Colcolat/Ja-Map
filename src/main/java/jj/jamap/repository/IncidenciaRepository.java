package jj.jamap.repository;

import java.util.List;
import jj.jamap.domain.entity.Incidencia;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.JpaSpecificationExecutor;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

/**
 * Repositorio JPA para incidencias; incluye filtros dinamicos y consultas geoespaciales Haversine.
 */
public interface IncidenciaRepository extends JpaRepository<Incidencia, Long>, JpaSpecificationExecutor<Incidencia> {

    List<Incidencia> findByAsignadoA(String asignadoA);

    @Query(value = """
            SELECT i.* FROM incidencias i
            WHERE i.estado <> 'CERRADA'
              AND i.latitud IS NOT NULL
              AND i.longitud IS NOT NULL
              AND (
                6371000 * ACOS(
                  LEAST(1.0, GREATEST(-1.0,
                    COS(RADIANS(:lat)) * COS(RADIANS(i.latitud))
                    * COS(RADIANS(i.longitud) - RADIANS(:lng))
                    + SIN(RADIANS(:lat)) * SIN(RADIANS(i.latitud))
                  ))
                )
              ) <= :radioMetros
            ORDER BY (
                6371000 * ACOS(
                  LEAST(1.0, GREATEST(-1.0,
                    COS(RADIANS(:lat)) * COS(RADIANS(i.latitud))
                    * COS(RADIANS(i.longitud) - RADIANS(:lng))
                    + SIN(RADIANS(:lat)) * SIN(RADIANS(i.latitud))
                  ))
                )
            ) ASC
            """, nativeQuery = true)
    List<Incidencia> findCercanasAbiertas(
            @Param("lat") double lat,
            @Param("lng") double lng,
            @Param("radioMetros") double radioMetros
    );

    @Query(value = """
            SELECT i.* FROM incidencias i
            WHERE i.estado <> 'CERRADA'
              AND i.tipo = :tipo
              AND i.latitud IS NOT NULL
              AND i.longitud IS NOT NULL
              AND (
                6371000 * ACOS(
                  LEAST(1.0, GREATEST(-1.0,
                    COS(RADIANS(:lat)) * COS(RADIANS(i.latitud))
                    * COS(RADIANS(i.longitud) - RADIANS(:lng))
                    + SIN(RADIANS(:lat)) * SIN(RADIANS(i.latitud))
                  ))
                )
              ) <= :radioMetros
            ORDER BY (
                6371000 * ACOS(
                  LEAST(1.0, GREATEST(-1.0,
                    COS(RADIANS(:lat)) * COS(RADIANS(i.latitud))
                    * COS(RADIANS(i.longitud) - RADIANS(:lng))
                    + SIN(RADIANS(:lat)) * SIN(RADIANS(i.latitud))
                  ))
                )
            ) ASC
            """, nativeQuery = true)
    List<Incidencia> findCercanasAbiertasPorTipo(
            @Param("lat") double lat,
            @Param("lng") double lng,
            @Param("radioMetros") double radioMetros,
            @Param("tipo") String tipo
    );
}
