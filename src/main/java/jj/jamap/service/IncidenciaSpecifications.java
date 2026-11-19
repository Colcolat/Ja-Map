package jj.jamap.service;

import jakarta.persistence.criteria.Predicate;
import java.util.ArrayList;
import java.util.List;
import jj.jamap.domain.entity.Incidencia;
import jj.jamap.domain.enums.EstadoIncidencia;
import jj.jamap.domain.enums.TipoIncidencia;
import org.springframework.data.jpa.domain.Specification;

/**
 * Construye predicados JPA dinamicos para filtrar incidencias por tipo, estado, colonia y busqueda libre.
 */
public final class IncidenciaSpecifications {

    private IncidenciaSpecifications() {
    }

    public static Specification<Incidencia> conFiltros(
            TipoIncidencia tipo,
            EstadoIncidencia estado,
            String colonia,
            String queryTexto
    ) {
        return (root, query, cb) -> {
            List<Predicate> predicates = new ArrayList<>();

            if (tipo != null) {
                predicates.add(cb.equal(root.get("tipo"), tipo));
            }
            if (estado != null) {
                predicates.add(cb.equal(root.get("estado"), estado));
            }
            if (colonia != null && !colonia.isBlank()) {
                String patronColonia = "%" + colonia.trim().toLowerCase() + "%";
                predicates.add(cb.like(cb.lower(root.get("colonia")), patronColonia));
            }
            if (queryTexto != null && !queryTexto.isBlank()) {
                String patron = "%" + queryTexto.trim().toLowerCase() + "%";
                Predicate enCalle = cb.like(cb.lower(root.get("calle")), patron);
                Predicate enColonia = cb.like(cb.lower(root.get("colonia")), patron);
                predicates.add(cb.or(enCalle, enColonia));
            }

            return cb.and(predicates.toArray(Predicate[]::new));
        };
    }
}
