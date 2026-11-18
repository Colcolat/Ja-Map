package jj.jamap.repository;

import static org.assertj.core.api.Assertions.assertThat;

import java.util.List;
import jj.jamap.domain.entity.Incidencia;
import jj.jamap.domain.entity.Reporte;
import jj.jamap.domain.entity.Usuario;
import jj.jamap.domain.enums.EstadoIncidencia;
import jj.jamap.domain.enums.OrigenReporte;
import jj.jamap.domain.enums.RolUsuario;
import jj.jamap.domain.enums.TipoIncidencia;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.transaction.annotation.Transactional;

@SpringBootTest
@Transactional
class DomainPersistenceTest {

    @Autowired
    private IncidenciaRepository incidenciaRepository;

    @Autowired
    private ReporteRepository reporteRepository;

    @Autowired
    private UsuarioRepository usuarioRepository;

    @Test
    void persistsIncidenciaWithLinkedReporteAndDefaults() {
        Incidencia incidencia = new Incidencia();
        incidencia.setTipo(TipoIncidencia.FUGA_VIA_PUBLICA);
        incidencia.setLatitud(20.967370);
        incidencia.setLongitud(-89.623740);
        incidencia.setCalle("Calle 60");
        incidencia.setNumero("123");
        incidencia.setCruzamiento1("45");
        incidencia.setCruzamiento2("47");
        incidencia.setColonia("Centro");

        Reporte reporte = new Reporte();
        reporte.setUidCiudadano("firebase-uid-001");
        reporte.setComentario("Fuga fuerte en la esquina");
        reporte.setDireccionCapturada("Calle 60 #123 x 45 y 47, Centro");
        reporte.setLatitud(20.967370);
        reporte.setLongitud(-89.623740);

        incidencia.agregarReporte(reporte);

        Incidencia saved = incidenciaRepository.saveAndFlush(incidencia);

        assertThat(saved.getId()).isNotNull();
        assertThat(saved.getEstado()).isEqualTo(EstadoIncidencia.ABIERTA);
        assertThat(saved.getPrioridad()).isEqualTo(0);
        assertThat(saved.getFechaApertura()).isNotNull();
        assertThat(saved.getReportes()).hasSize(1);

        List<Reporte> reportesUsuario = reporteRepository.findByUidCiudadanoOrderByFechaReporteDesc("firebase-uid-001");
        assertThat(reportesUsuario).hasSize(1);
        assertThat(reportesUsuario.getFirst().getOrigen()).isEqualTo(OrigenReporte.APP);
        assertThat(reportesUsuario.getFirst().getFechaReporte()).isNotNull();
        assertThat(reportesUsuario.getFirst().getIncidencia().getId()).isEqualTo(saved.getId());
        assertThat(reporteRepository.countByIncidenciaId(saved.getId())).isEqualTo(1L);
    }

    @Test
    void persistsUsuarioWithDefaultCitizenRole() {
        Usuario usuario = new Usuario("firebase-uid-002", "ciudadano@jamap.test", "Ana Pech", null);

        usuarioRepository.saveAndFlush(usuario);

        Usuario found = usuarioRepository.findByEmail("ciudadano@jamap.test").orElseThrow();
        assertThat(found.getUid()).isEqualTo("firebase-uid-002");
        assertThat(found.getRol()).isEqualTo(RolUsuario.CIUDADANO);
    }
}
