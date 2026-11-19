package jj.jamap.controller;

import static org.hamcrest.Matchers.hasSize;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.delete;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.put;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import java.math.BigDecimal;
import java.time.Instant;
import jj.jamap.domain.entity.Incidencia;
import jj.jamap.domain.entity.Reporte;
import jj.jamap.domain.enums.EstadoIncidencia;
import jj.jamap.domain.enums.OrigenReporte;
import jj.jamap.domain.enums.TipoIncidencia;
import jj.jamap.repository.IncidenciaRepository;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.webmvc.test.autoconfigure.AutoConfigureMockMvc;
import org.springframework.http.MediaType;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.transaction.annotation.Transactional;

@SpringBootTest
@AutoConfigureMockMvc
@Transactional
class IncidenciaControllerIntegrationTest {

    @Autowired
    private MockMvc mockMvc;

    @Autowired
    private IncidenciaRepository incidenciaRepository;

    private Incidencia incidenciaCentro;
    private Incidencia incidenciaAltabrisa;

    @BeforeEach
    void setUp() {
        incidenciaCentro = crearYGuardar(
                TipoIncidencia.FUGA_VIA_PUBLICA,
                EstadoIncidencia.ABIERTA,
                "Calle 60",
                "Centro",
                65
        );
        incidenciaAltabrisa = crearYGuardar(
                TipoIncidencia.BAJA_PRESION,
                EstadoIncidencia.ASIGNADA,
                "Calle 7",
                "Altabrisa",
                25
        );
    }

    @Test
    void listarFiltraPorTipoEstadoYBusquedaLibre() throws Exception {
        mockMvc.perform(get("/incidencias")
                        .param("tipo", "FUGA_VIA_PUBLICA")
                        .param("estado", "ABIERTA")
                        .param("q", "calle 60"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.content", hasSize(1)))
                .andExpect(jsonPath("$.content[0].id").value(incidenciaCentro.getId()))
                .andExpect(jsonPath("$.content[0].colonia").value("Centro"))
                .andExpect(jsonPath("$.content[0].totalReportes").value(1))
                .andExpect(jsonPath("$.totalElements").value(1));
    }

    @Test
    void listarOrdenaPorPrioridadDescendenteYRespetaPaginacion() throws Exception {
        mockMvc.perform(get("/incidencias")
                        .param("page", "0")
                        .param("size", "1"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.content", hasSize(1)))
                .andExpect(jsonPath("$.content[0].id").value(incidenciaCentro.getId()))
                .andExpect(jsonPath("$.totalElements").value(2))
                .andExpect(jsonPath("$.totalPages").value(2))
                .andExpect(jsonPath("$.last").value(false));
    }

    @Test
    void obtenerDetalleDevuelveIncidenciaConReportes() throws Exception {
        mockMvc.perform(get("/incidencias/{id}", incidenciaCentro.getId()))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.id").value(incidenciaCentro.getId()))
                .andExpect(jsonPath("$.calle").value("Calle 60"))
                .andExpect(jsonPath("$.reportes", hasSize(1)))
                .andExpect(jsonPath("$.reportes[0].uidCiudadano").value("uid-test-1"));
    }

    @Test
    void obtenerDetalleInexistenteDevuelve404() throws Exception {
        mockMvc.perform(get("/incidencias/999999"))
                .andExpect(status().isNotFound())
                .andExpect(jsonPath("$.status").value(404));
    }

    @Test
    void listarConEnumInvalidoDevuelve400() throws Exception {
        mockMvc.perform(get("/incidencias").param("tipo", "NO_EXISTE"))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.status").value(400));
    }

    @Test
    void actualizarModificaCamposYAsignaFechaCierreAlCerrar() throws Exception {
        String body = """
                {
                  "tipo": "FUGA_VIA_PUBLICA",
                  "estado": "CERRADA",
                  "latitud": 20.9675,
                  "longitud": -89.6237,
                  "calle": "Calle 60",
                  "numero": "485",
                  "cruzamiento1": "55",
                  "cruzamiento2": "57",
                  "colonia": "Centro",
                  "prioridad": 80,
                  "costoEstimado": 3250.50,
                  "asignadoA": "cuadrilla-1",
                  "fotoEvidenciaUrl": "https://example.com/evidencia.jpg"
                }
                """;

        mockMvc.perform(put("/incidencias/{id}", incidenciaCentro.getId())
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(body))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.estado").value("CERRADA"))
                .andExpect(jsonPath("$.prioridad").value(80))
                .andExpect(jsonPath("$.fechaCierre").isNotEmpty());
    }

    @Test
    void actualizarConDatosInvalidosDevuelve400ConDetalles() throws Exception {
        String bodyInvalido = """
                {
                  "estado": "ABIERTA",
                  "prioridad": 150
                }
                """;

        mockMvc.perform(put("/incidencias/{id}", incidenciaAltabrisa.getId())
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(bodyInvalido))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.details.tipo").exists())
                .andExpect(jsonPath("$.details.prioridad").exists());
    }

    @Test
    void eliminarBorraIncidenciaYDevuelve204() throws Exception {
        mockMvc.perform(delete("/incidencias/{id}", incidenciaAltabrisa.getId()))
                .andExpect(status().isNoContent());

        mockMvc.perform(get("/incidencias/{id}", incidenciaAltabrisa.getId()))
                .andExpect(status().isNotFound());
    }

    private Incidencia crearYGuardar(
            TipoIncidencia tipo,
            EstadoIncidencia estado,
            String calle,
            String colonia,
            int prioridad
    ) {
        Incidencia incidencia = new Incidencia();
        incidencia.setTipo(tipo);
        incidencia.setEstado(estado);
        incidencia.setLatitud(20.97);
        incidencia.setLongitud(-89.62);
        incidencia.setCalle(calle);
        incidencia.setColonia(colonia);
        incidencia.setPrioridad(prioridad);
        incidencia.setCostoEstimado(new BigDecimal("1500.00"));
        incidencia.setFechaApertura(Instant.now());

        Reporte reporte = new Reporte();
        reporte.setUidCiudadano("uid-test-1");
        reporte.setComentario("Reporte de prueba");
        reporte.setDireccionCapturada(calle + ", " + colonia);
        reporte.setFotoUrl("https://placehold.co/600x400?text=Test");
        reporte.setOrigen(OrigenReporte.APP);
        incidencia.agregarReporte(reporte);

        return incidenciaRepository.saveAndFlush(incidencia);
    }
}
