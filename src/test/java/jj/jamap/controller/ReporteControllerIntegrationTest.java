package jj.jamap.controller;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.within;
import static org.hamcrest.Matchers.hasSize;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import jj.jamap.domain.entity.Incidencia;
import jj.jamap.domain.enums.EstadoIncidencia;
import jj.jamap.domain.enums.TipoIncidencia;
import jj.jamap.repository.IncidenciaRepository;
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
class ReporteControllerIntegrationTest {

    @Autowired
    private MockMvc mockMvc;

    @Autowired
    private IncidenciaRepository incidenciaRepository;

    @Test
    void crearReporteDeduplicaMismoTipoDentroDe50MetrosYRecalculaCentroideYPrioridad() throws Exception {
        String primerReporte = """
                {
                  "tipo": "FUGA_VIA_PUBLICA",
                  "latitud": 20.96740,
                  "longitud": -89.62370,
                  "fotoUrl": "https://example.com/foto1.jpg",
                  "comentario": "Fuga en la esquina",
                  "direccionCapturada": "Calle 60 #485 x 55 y 57, Centro",
                  "calle": "Calle 60",
                  "colonia": "Centro"
                }
                """;

        // 1. Primer reporte: crea nueva incidencia
        mockMvc.perform(post("/reportes")
                        .header("X-User-Uid", "uid-ana")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(primerReporte))
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.resultado").value("NUEVO"))
                .andExpect(jsonPath("$.distanciaMetros").doesNotExist())
                .andExpect(jsonPath("$.incidencia.totalReportes").value(1))
                .andExpect(jsonPath("$.incidencia.prioridad").value(10));

        // 2. Segundo reporte a ~22m con mismo tipo: se vincula a la existente
        String segundoReporte = """
                {
                  "tipo": "FUGA_VIA_PUBLICA",
                  "latitud": 20.96760,
                  "longitud": -89.62370,
                  "fotoUrl": "https://example.com/foto2.jpg",
                  "comentario": "Confirmo misma fuga",
                  "direccionCapturada": "C. 60 x 55 y 57"
                }
                """;

        mockMvc.perform(post("/reportes")
                        .header("X-User-Uid", "uid-luis")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(segundoReporte))
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.resultado").value("VINCULADO"))
                .andExpect(jsonPath("$.distanciaMetros").isNumber())
                .andExpect(jsonPath("$.incidencia.totalReportes").value(2))
                .andExpect(jsonPath("$.incidencia.prioridad").value(20));

        // Verificar que solo hay 1 incidencia y su centroide es el promedio (20.96750, -89.62370)
        assertThat(incidenciaRepository.count()).isEqualTo(1);
        Incidencia agrupada = incidenciaRepository.findAll().getFirst();
        assertThat(agrupada.getLatitud()).isCloseTo(20.96750, within(0.00001));
        assertThat(agrupada.getLongitud()).isCloseTo(-89.62370, within(0.00001));
    }

    @Test
    void crearReporteNoDeduplicaSiEsOtroTipoOSiLaIncidenciaEstaCerrada() throws Exception {
        // Incidencia CERRADA exactamente en el mismo punto y del mismo tipo
        Incidencia cerrada = new Incidencia();
        cerrada.setTipo(TipoIncidencia.FUGA_VIA_PUBLICA);
        cerrada.setEstado(EstadoIncidencia.CERRADA);
        cerrada.setLatitud(20.96740);
        cerrada.setLongitud(-89.62370);
        cerrada.setColonia("Centro");
        incidenciaRepository.saveAndFlush(cerrada);

        String reporteMismoPunto = """
                {
                  "tipo": "FUGA_VIA_PUBLICA",
                  "latitud": 20.96740,
                  "longitud": -89.62370,
                  "comentario": "Volvio a abrirse fuga"
                }
                """;

        mockMvc.perform(post("/reportes")
                        .header("X-User-Uid", "uid-ana")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(reporteMismoPunto))
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.resultado").value("NUEVO"));

        // Mismo punto pero tipo distinto: tambien debe crear NUEVO
        String reporteOtroTipo = """
                {
                  "tipo": "BAJA_PRESION",
                  "latitud": 20.96740,
                  "longitud": -89.62370,
                  "comentario": "Baja presion en la misma cuadra"
                }
                """;

        mockMvc.perform(post("/reportes")
                        .header("X-User-Uid", "uid-ana")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(reporteOtroTipo))
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.resultado").value("NUEVO"));

        assertThat(incidenciaRepository.count()).isEqualTo(3);
    }

    @Test
    void buscarCercanasOrdenaPorDistanciaYExcluyeCerradasYLejanas() throws Exception {
        Incidencia muyCercana = guardarIncidencia(TipoIncidencia.FUGA_VIA_PUBLICA, EstadoIncidencia.ABIERTA, 20.96750, -89.62370, "Muy cercana");
        Incidencia cercana = guardarIncidencia(TipoIncidencia.BAJA_PRESION, EstadoIncidencia.ASIGNADA, 20.96775, -89.62370, "Cercana");
        guardarIncidencia(TipoIncidencia.FUGA_VIA_PUBLICA, EstadoIncidencia.CERRADA, 20.96745, -89.62370, "Cerrada");
        guardarIncidencia(TipoIncidencia.FUGA_VIA_PUBLICA, EstadoIncidencia.ABIERTA, 21.01810, -89.58440, "Lejana");

        mockMvc.perform(get("/incidencias/cercanas")
                        .param("lat", "20.96745")
                        .param("lng", "-89.62370")
                        .param("radio", "50"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$", hasSize(2)))
                .andExpect(jsonPath("$[0].incidencia.id").value(muyCercana.getId()))
                .andExpect(jsonPath("$[1].incidencia.id").value(cercana.getId()));
    }

    @Test
    void buscarCercanasConRadioInvalidoDevuelve400() throws Exception {
        mockMvc.perform(get("/incidencias/cercanas")
                        .param("lat", "20.96745")
                        .param("lng", "-89.62370")
                        .param("radio", "-10"))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.status").value(400));
    }

    @Test
    void listarMiosDevuelveSoloReportesDelCiudadanoConEstadoDeIncidencia() throws Exception {
        String body = """
                {
                  "tipo": "SIN_SERVICIO",
                  "latitud": 21.02890,
                  "longitud": -89.64580,
                  "comentario": "Sin agua en casa",
                  "calle": "Calle 50",
                  "colonia": "Francisco de Montejo"
                }
                """;

        mockMvc.perform(post("/reportes")
                        .header("X-User-Uid", "uid-maria")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(body))
                .andExpect(status().isCreated());

        mockMvc.perform(get("/reportes/mios").header("X-User-Uid", "uid-maria"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$", hasSize(1)))
                .andExpect(jsonPath("$[0].tipo").value("SIN_SERVICIO"))
                .andExpect(jsonPath("$[0].estado").value("ABIERTA"))
                .andExpect(jsonPath("$[0].colonia").value("Francisco de Montejo"));

        mockMvc.perform(get("/reportes/mios").header("X-User-Uid", "uid-otro"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$", hasSize(0)));
    }

    private Incidencia guardarIncidencia(
            TipoIncidencia tipo,
            EstadoIncidencia estado,
            double lat,
            double lng,
            String colonia
    ) {
        Incidencia incidencia = new Incidencia();
        incidencia.setTipo(tipo);
        incidencia.setEstado(estado);
        incidencia.setLatitud(lat);
        incidencia.setLongitud(lng);
        incidencia.setColonia(colonia);
        return incidenciaRepository.saveAndFlush(incidencia);
    }
}
