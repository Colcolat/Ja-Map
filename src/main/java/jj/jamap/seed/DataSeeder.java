package jj.jamap.seed;

import java.math.BigDecimal;
import java.time.Instant;
import java.time.temporal.ChronoUnit;
import java.util.List;
import jj.jamap.domain.entity.Incidencia;
import jj.jamap.domain.entity.Reporte;
import jj.jamap.domain.entity.Usuario;
import jj.jamap.domain.enums.EstadoIncidencia;
import jj.jamap.domain.enums.OrigenReporte;
import jj.jamap.domain.enums.RolUsuario;
import jj.jamap.domain.enums.TipoIncidencia;
import jj.jamap.repository.IncidenciaRepository;
import jj.jamap.repository.UsuarioRepository;
import jj.jamap.service.IncidenciaService;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.boot.CommandLineRunner;
import org.springframework.context.annotation.Profile;
import org.springframework.stereotype.Component;
import org.springframework.transaction.annotation.Transactional;

/**
 * Carga datos sinteticos de Merida en perfil dev de forma idempotente (solo si las tablas estan vacias).
 */
@Component
@Profile("dev")
public class DataSeeder implements CommandLineRunner {

    private static final Logger log = LoggerFactory.getLogger(DataSeeder.class);

    private static final String UID_CIUDADANO_1 = "demo-ciudadano-01";
    private static final String UID_CIUDADANO_2 = "demo-ciudadano-02";
    private static final String UID_CUADRILLA_1 = "demo-cuadrilla-01";
    private static final String UID_ADMIN_1 = "demo-admin-01";

    private final UsuarioRepository usuarioRepository;
    private final IncidenciaRepository incidenciaRepository;

    public DataSeeder(UsuarioRepository usuarioRepository, IncidenciaRepository incidenciaRepository) {
        this.usuarioRepository = usuarioRepository;
        this.incidenciaRepository = incidenciaRepository;
    }

    @Override
    @Transactional
    public void run(String... args) {
        seedUsuarios();
        seedIncidencias();
    }

    private void seedUsuarios() {
        if (usuarioRepository.count() > 0) {
            return;
        }
        List<Usuario> usuarios = List.of(
                new Usuario(UID_CIUDADANO_1, "ciudadano1@jamap.local", "Carlos Pech", RolUsuario.CIUDADANO),
                new Usuario(UID_CIUDADANO_2, "ciudadano2@jamap.local", "Sofia Canul", RolUsuario.CIUDADANO),
                new Usuario(UID_CUADRILLA_1, "cuadrilla1@jamap.local", "Cuadrilla Norte 01", RolUsuario.CUADRILLA),
                new Usuario(UID_ADMIN_1, "admin@jamap.local", "Coordinacion JaMap", RolUsuario.ADMIN)
        );
        usuarioRepository.saveAll(usuarios);
        log.info("DataSeeder: {} usuarios de prueba creados.", usuarios.size());
    }

    private void seedIncidencias() {
        if (incidenciaRepository.count() > 0) {
            return;
        }

        List<Incidencia> incidencias = List.of(
                // 1. Centro (Calle 60) - 5 reportes (alta prioridad)
                crearIncidencia(
                        TipoIncidencia.FUGA_VIA_PUBLICA, EstadoIncidencia.ABIERTA,
                        20.96745, -89.62371, "Calle 60", "485", "55", "57", "Centro",
                        8, new BigDecimal("4200.00"), null, null,
                        List.of(
                                reporte(UID_CIUDADANO_1, "Fuga abundante brotando del pavimento", "Calle 60 #485 x 55 y 57, Centro", 20.96742, -89.62370, OrigenReporte.APP, 8, 1),
                                reporte(UID_CIUDADANO_2, "El agua ya corre hasta la esquina de la 57", "C. 60 x 55 y 57 Centro", 20.96748, -89.62373, OrigenReporte.APP, 7, 2),
                                reporte(UID_CIUDADANO_1, "Sigue saliendo mucha agua por la mañana", "Calle 60 No. 485", 20.96746, -89.62369, OrigenReporte.APP, 5, 3),
                                reporte(null, "Reporte historico duplicado misma cuadra", "calle 60 485 por 55 y 57", 20.96744, -89.62372, OrigenReporte.HISTORICO, 4, 4),
                                reporte(UID_CIUDADANO_2, "Se formo charco grande frente al local", "Calle 60 #485, Centro", 20.96745, -89.62371, OrigenReporte.APP, 2, 5)
                        )
                ),
                // 2. Centro (duplicado intencional cercano ~35m del #1 para probar fusion en Fase B3)
                crearIncidencia(
                        TipoIncidencia.FUGA_VIA_PUBLICA, EstadoIncidencia.ABIERTA,
                        20.96775, -89.62368, "Calle 60", "479", "55", "57", "Centro",
                        3, new BigDecimal("1800.00"), null, null,
                        List.of(
                                reporte(UID_CIUDADANO_2, "Posible misma linea rota metros mas adelante", "Calle 60 #479 x 55 y 57", 20.96775, -89.62368, OrigenReporte.APP, 3, 6),
                                reporte(null, "Fuga reportada por telefono en la misma acera", "C. 60 x 55 y 57", 20.96773, -89.62369, OrigenReporte.HISTORICO, 2, 7)
                        )
                ),
                // 3. Garcia Gineres - 4 reportes, asignada a cuadrilla
                crearIncidencia(
                        TipoIncidencia.FUGA_TOMA_DOMICILIARIA, EstadoIncidencia.ASIGNADA,
                        20.98520, -89.63195, "Calle 21", "114", "26", "28", "Garcia Gineres",
                        6, new BigDecimal("2650.00"), UID_CUADRILLA_1, null,
                        List.of(
                                reporte(UID_CIUDADANO_1, "Toma rota junto al medidor", "Calle 21 #114 x 26 y 28, Garcia Gineres", 20.98519, -89.63196, OrigenReporte.APP, 6, 8),
                                reporte(UID_CIUDADANO_2, "Escurrimiento continuo sobre la banqueta", "C. 21 114 por 26 y 28", 20.98521, -89.63194, OrigenReporte.APP, 5, 9),
                                reporte(UID_CIUDADANO_1, "Sigue perdiendo presion la cuadra", "Calle 21 x 26 y 28", 20.98520, -89.63195, OrigenReporte.APP, 3, 10),
                                reporte(null, "Folio previo sin atender", "calle 21 No. 114 Garcia Gineres", 20.98520, -89.63195, OrigenReporte.HISTORICO, 2, 11)
                        )
                ),
                // 4. Francisco de Montejo - 4 reportes, en reparacion
                crearIncidencia(
                        TipoIncidencia.SIN_SERVICIO, EstadoIncidencia.EN_REPARACION,
                        21.02890, -89.64580, "Calle 50", "320", "41", "43", "Francisco de Montejo",
                        5, new BigDecimal("5400.00"), UID_CUADRILLA_1, null,
                        List.of(
                                reporte(UID_CIUDADANO_1, "Sin agua en toda la manzana desde ayer", "Calle 50 #320 x 41 y 43, Fco de Montejo", 21.02888, -89.64582, OrigenReporte.APP, 5, 12),
                                reporte(UID_CIUDADANO_2, "Tampoco tenemos agua en la esquina", "Calle 50 x 41 y 43", 21.02892, -89.64579, OrigenReporte.APP, 4, 13),
                                reporte(UID_CIUDADANO_1, "Vecinos confirman corte total", "C. 50 No. 320 Fco Montejo", 21.02890, -89.64580, OrigenReporte.APP, 3, 14),
                                reporte(UID_CIUDADANO_2, "Seguimos sin suministro", "Calle 50 #320", 21.02890, -89.64579, OrigenReporte.APP, 1, 15)
                        )
                ),
                // 5. Altabrisa - 3 reportes, abierta
                crearIncidencia(
                        TipoIncidencia.BAJA_PRESION, EstadoIncidencia.ABIERTA,
                        21.01810, -89.58440, "Calle 7", "210", "22", "24", "Altabrisa",
                        4, new BigDecimal("1900.00"), null, null,
                        List.of(
                                reporte(UID_CIUDADANO_2, "El agua no sube al tinaco desde hace dias", "Calle 7 #210 x 22 y 24, Altabrisa", 21.01811, -89.58439, OrigenReporte.APP, 4, 16),
                                reporte(UID_CIUDADANO_1, "Presion muy debil en horas pico", "C. 7 x 22 y 24 Altabrisa", 21.01809, -89.58441, OrigenReporte.APP, 2, 17),
                                reporte(null, "Reporte telefonico baja presion", "Calle 7 No. 210", 21.01810, -89.58440, OrigenReporte.HISTORICO, 1, 18)
                        )
                ),
                // 6. Pensiones - 3 reportes, abierta
                crearIncidencia(
                        TipoIncidencia.FUGA_VIA_PUBLICA, EstadoIncidencia.ABIERTA,
                        20.98960, -89.64990, "Calle 11", "412", "54", "56", "Pensiones",
                        7, new BigDecimal("3500.00"), null, null,
                        List.of(
                                reporte(UID_CIUDADANO_1, "Grieta en calle con chorro constante", "Calle 11 #412 x 54 y 56, Pensiones", 20.98961, -89.64989, OrigenReporte.APP, 7, 19),
                                reporte(UID_CIUDADANO_2, "Agua limpia desperdiciandose todo el dia", "C. 11 412 por 54 y 56", 20.98959, -89.64991, OrigenReporte.APP, 5, 20),
                                reporte(UID_CIUDADANO_1, "Ya se hundio un poco el asfalto", "Calle 11 x 54 y 56 Pensiones", 20.98960, -89.64990, OrigenReporte.APP, 2, 21)
                        )
                ),
                // 7. Itzimna - 2 reportes, cerrada con evidencia
                crearIncidencia(
                        TipoIncidencia.FUGA_TOMA_DOMICILIARIA, EstadoIncidencia.CERRADA,
                        20.98790, -89.61320, "Calle 19", "98", "18", "20", "Itzimna",
                        10, new BigDecimal("1500.00"), UID_CUADRILLA_1,
                        "https://placehold.co/800x600/16a34a/ffffff?text=Evidencia+Cierre+Itzimna",
                        List.of(
                                reporte(UID_CIUDADANO_2, "Fuga en tuberia de entrada", "Calle 19 #98 x 18 y 20, Itzimna", 20.98790, -89.61321, OrigenReporte.APP, 10, 22),
                                reporte(UID_CIUDADANO_1, "Confirmado desperdicio en banqueta", "C. 19 x 18 y 20", 20.98790, -89.61319, OrigenReporte.APP, 9, 23)
                        )
                ),
                // 8. Chuburna de Hidalgo - 3 reportes, asignada
                crearIncidencia(
                        TipoIncidencia.FUGA_VIA_PUBLICA, EstadoIncidencia.ASIGNADA,
                        21.00850, -89.63710, "Calle 21", "155", "20", "22", "Chuburna de Hidalgo",
                        5, new BigDecimal("3100.00"), UID_CUADRILLA_1, null,
                        List.of(
                                reporte(UID_CIUDADANO_1, "Fuga junto al parque de Chuburna", "Calle 21 #155 x 20 y 22, Chuburna", 21.00849, -89.63711, OrigenReporte.APP, 5, 24),
                                reporte(UID_CIUDADANO_2, "Encharcamiento en paso peatonal", "C. 21 x 20 y 22 Chuburna", 21.00851, -89.63709, OrigenReporte.APP, 3, 25),
                                reporte(null, "Duplicado historico zona parque", "calle 21 155 Chuburna", 21.00850, -89.63710, OrigenReporte.HISTORICO, 2, 26)
                        )
                ),
                // 9. Montes de Ame - 2 reportes, abierta
                crearIncidencia(
                        TipoIncidencia.BAJA_PRESION, EstadoIncidencia.ABIERTA,
                        21.03720, -89.60750, "Calle 24", "301", "55", "57", "Montes de Ame",
                        3, new BigDecimal("1400.00"), null, null,
                        List.of(
                                reporte(UID_CIUDADANO_2, "Muy poca presion por las tardes", "Calle 24 #301 x 55 y 57, Montes de Ame", 21.03720, -89.60750, OrigenReporte.APP, 3, 27),
                                reporte(UID_CIUDADANO_1, "Mismo problema en casas vecinas", "Calle 24 x 55 y 57", 21.03721, -89.60749, OrigenReporte.APP, 1, 28)
                        )
                ),
                // 10. San Ramon Norte - 2 reportes, en reparacion
                crearIncidencia(
                        TipoIncidencia.FUGA_TOMA_DOMICILIARIA, EstadoIncidencia.EN_REPARACION,
                        21.02410, -89.60380, "Calle 35", "245", "30", "32", "San Ramon Norte",
                        4, new BigDecimal("2100.00"), UID_CUADRILLA_1, null,
                        List.of(
                                reporte(UID_CIUDADANO_1, "Valvula filtrando agua limpia", "Calle 35 #245 x 30 y 32, San Ramon Norte", 21.02410, -89.60380, OrigenReporte.APP, 4, 29),
                                reporte(UID_CIUDADANO_2, "Agua corriendo por la calle 35", "C. 35 No. 245", 21.02411, -89.60381, OrigenReporte.APP, 2, 30)
                        )
                ),
                // 11. Montecristo - 2 reportes, abierta
                crearIncidencia(
                        TipoIncidencia.SIN_SERVICIO, EstadoIncidencia.ABIERTA,
                        21.01950, -89.59670, "Calle 12", "180", "1D", "3", "Montecristo",
                        2, new BigDecimal("2900.00"), null, null,
                        List.of(
                                reporte(UID_CIUDADANO_2, "Corte inesperado desde la madrugada", "Calle 12 #180 x 1D y 3, Montecristo", 21.01950, -89.59670, OrigenReporte.APP, 2, 31),
                                reporte(UID_CIUDADANO_1, "Sin servicio en toda la privada", "Calle 12 x 1D y 3 Montecristo", 21.01949, -89.59671, OrigenReporte.APP, 1, 32)
                        )
                ),
                // 12. Campestre - 2 reportes, abierta
                crearIncidencia(
                        TipoIncidencia.FUGA_VIA_PUBLICA, EstadoIncidencia.ABIERTA,
                        21.00440, -89.61790, "Calle 36", "140", "17", "19", "Campestre",
                        6, new BigDecimal("3800.00"), null, null,
                        List.of(
                                reporte(UID_CIUDADANO_1, "Brotando agua cerca de la glorieta", "Calle 36 #140 x 17 y 19, Campestre", 21.00440, -89.61790, OrigenReporte.APP, 6, 33),
                                reporte(null, "Reporte historico Campestre", "C. 36 140 por 17 y 19", 21.00441, -89.61789, OrigenReporte.HISTORICO, 4, 34)
                        )
                ),
                // 13. Jesus Carranza - 2 reportes, cerrada
                crearIncidencia(
                        TipoIncidencia.BAJA_PRESION, EstadoIncidencia.CERRADA,
                        20.98580, -89.60790, "Calle 37", "260", "34", "36", "Jesus Carranza",
                        12, new BigDecimal("1200.00"), UID_CUADRILLA_1,
                        "https://placehold.co/800x600/16a34a/ffffff?text=Evidencia+Cierre+Carranza",
                        List.of(
                                reporte(UID_CIUDADANO_2, "Presion casi nula en la mañana", "Calle 37 #260 x 34 y 36, Jesus Carranza", 20.98580, -89.60790, OrigenReporte.APP, 12, 35),
                                reporte(UID_CIUDADANO_1, "Reportado tambien por vecino", "C. 37 x 34 y 36", 20.98581, -89.60791, OrigenReporte.APP, 11, 36)
                        )
                ),
                // 14. Miguel Aleman - 2 reportes, asignada
                crearIncidencia(
                        TipoIncidencia.FUGA_TOMA_DOMICILIARIA, EstadoIncidencia.ASIGNADA,
                        20.99490, -89.59940, "Calle 29", "195", "24", "26", "Miguel Aleman",
                        3, new BigDecimal("1750.00"), UID_CUADRILLA_1, null,
                        List.of(
                                reporte(UID_CIUDADANO_1, "Fuga en conexion frente a escuela", "Calle 29 #195 x 24 y 26, Miguel Aleman", 20.99490, -89.59940, OrigenReporte.APP, 3, 37),
                                reporte(UID_CIUDADANO_2, "Continua saliendo agua limpia", "Calle 29 No. 195 Miguel Aleman", 20.99491, -89.59939, OrigenReporte.APP, 2, 38)
                        )
                ),
                // 15. Las Americas - 2 reportes, abierta
                crearIncidencia(
                        TipoIncidencia.SIN_SERVICIO, EstadoIncidencia.ABIERTA,
                        21.05980, -89.66210, "Calle 59", "812", "104", "106", "Las Americas",
                        1, new BigDecimal("2400.00"), null, null,
                        List.of(
                                reporte(UID_CIUDADANO_2, "Sin agua en etapa 2", "Calle 59 #812 x 104 y 106, Las Americas", 21.05980, -89.66210, OrigenReporte.APP, 1, 39),
                                reporte(UID_CIUDADANO_1, "Tampoco cae agua en la calle 59", "C. 59 x 104 y 106 Las Americas", 21.05982, -89.66208, OrigenReporte.APP, 1, 40)
                        )
                ),
                // 16. Mejorada - 2 reportes, abierta
                crearIncidencia(
                        TipoIncidencia.FUGA_VIA_PUBLICA, EstadoIncidencia.ABIERTA,
                        20.96880, -89.61720, "Calle 59", "440", "50", "52", "Mejorada",
                        5, new BigDecimal("2800.00"), null, null,
                        List.of(
                                reporte(UID_CIUDADANO_1, "Fuga en esquina cerca del parque Mejorada", "Calle 59 #440 x 50 y 52, Mejorada", 20.96880, -89.61720, OrigenReporte.APP, 5, 41),
                                reporte(null, "Registro historico Centro-Mejorada", "calle 59 x 50 y 52", 20.96879, -89.61721, OrigenReporte.HISTORICO, 3, 42)
                        )
                )
        );

        incidenciaRepository.saveAll(incidencias);
        int totalReportes = incidencias.stream().mapToInt(i -> i.getReportes().size()).sum();
        log.info("DataSeeder: {} incidencias y {} reportes de Merida cargados.", incidencias.size(), totalReportes);
    }

    private Incidencia crearIncidencia(
            TipoIncidencia tipo,
            EstadoIncidencia estado,
            Double lat,
            Double lng,
            String calle,
            String numero,
            String cruzamiento1,
            String cruzamiento2,
            String colonia,
            int diasAtras,
            BigDecimal costoEstimado,
            String asignadoA,
            String fotoEvidenciaUrl,
            List<Reporte> reportes
    ) {
        Instant apertura = Instant.now().minus(diasAtras, ChronoUnit.DAYS);
        Incidencia incidencia = new Incidencia();
        incidencia.setTipo(tipo);
        incidencia.setEstado(estado);
        incidencia.setLatitud(lat);
        incidencia.setLongitud(lng);
        incidencia.setCalle(calle);
        incidencia.setNumero(numero);
        incidencia.setCruzamiento1(cruzamiento1);
        incidencia.setCruzamiento2(cruzamiento2);
        incidencia.setColonia(colonia);
        incidencia.setCostoEstimado(costoEstimado);
        incidencia.setAsignadoA(asignadoA);
        incidencia.setFotoEvidenciaUrl(fotoEvidenciaUrl);
        incidencia.setFechaApertura(apertura);
        if (estado == EstadoIncidencia.CERRADA) {
            incidencia.setFechaCierre(Instant.now().minus(1, ChronoUnit.DAYS));
        }
        for (Reporte reporte : reportes) {
            incidencia.agregarReporte(reporte);
        }
        if (fotoEvidenciaUrl != null && !fotoEvidenciaUrl.isBlank()) {
            incidencia.setImageUrl(fotoEvidenciaUrl);
        } else if (!reportes.isEmpty()) {
            incidencia.setImageUrl(reportes.getFirst().getFotoUrl());
        }
        incidencia.setPrioridad(IncidenciaService.calcularPrioridad(reportes.size(), apertura));
        return incidencia;
    }

    private Reporte reporte(
            String uidCiudadano,
            String comentario,
            String direccionCapturada,
            Double lat,
            Double lng,
            OrigenReporte origen,
            int diasAtras,
            int fotoNumero
    ) {
        Reporte reporte = new Reporte();
        reporte.setUidCiudadano(uidCiudadano);
        reporte.setComentario(comentario);
        reporte.setDireccionCapturada(direccionCapturada);
        reporte.setLatitud(lat);
        reporte.setLongitud(lng);
        reporte.setOrigen(origen);
        reporte.setFechaReporte(Instant.now().minus(diasAtras, ChronoUnit.DAYS));
        reporte.setFotoUrl("https://placehold.co/800x600/0284c7/ffffff?text=JaMap+Reporte+" + fotoNumero);
        return reporte;
    }
}
