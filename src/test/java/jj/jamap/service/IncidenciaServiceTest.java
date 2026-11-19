package jj.jamap.service;

import static org.assertj.core.api.Assertions.assertThat;

import java.time.Instant;
import java.time.temporal.ChronoUnit;
import org.junit.jupiter.api.Test;

class IncidenciaServiceTest {

    @Test
    void calcularPrioridadCombinaReportesYDiasAbierta() {
        Instant haceCincoDias = Instant.now().minus(5, ChronoUnit.DAYS);

        int prioridad = IncidenciaService.calcularPrioridad(3, haceCincoDias);

        assertThat(prioridad).isEqualTo(40); // 3*10 + 5*2
    }

    @Test
    void calcularPrioridadNoSuperaCien() {
        Instant haceTreintaDias = Instant.now().minus(30, ChronoUnit.DAYS);

        int prioridad = IncidenciaService.calcularPrioridad(12, haceTreintaDias);

        assertThat(prioridad).isEqualTo(100);
    }

    @Test
    void calcularPrioridadToleraValoresNulosONegativos() {
        Instant futuro = Instant.now().plus(2, ChronoUnit.DAYS);

        assertThat(IncidenciaService.calcularPrioridad(1, null)).isEqualTo(10);
        assertThat(IncidenciaService.calcularPrioridad(-3, futuro)).isEqualTo(0);
    }
}
