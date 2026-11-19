package jj.jamap.util;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.within;

import java.util.List;
import java.util.Optional;
import jj.jamap.domain.entity.Reporte;
import org.junit.jupiter.api.Test;

class GeoUtilsTest {

    @Test
    void distanciaEntreMismoPuntoEsCero() {
        double distancia = GeoUtils.distanciaMetros(20.96745, -89.62371, 20.96745, -89.62371);

        assertThat(distancia).isCloseTo(0.0, within(0.001));
    }

    @Test
    void distanciaEntreDosPuntosCercanosEnCentroMeridaEsAproximadamente33Metros() {
        double distancia = GeoUtils.distanciaMetros(20.96745, -89.62371, 20.96775, -89.62368);

        assertThat(distancia).isBetween(30.0, 38.0);
    }

    @Test
    void distanciaEntreCentroYAltabrisaSuperaCincoKilometros() {
        double distancia = GeoUtils.distanciaMetros(20.96745, -89.62371, 21.01810, -89.58440);

        assertThat(distancia).isGreaterThan(5000.0);
    }

    @Test
    void calcularCentroidePromediaSoloReportesConCoordenadasValidas() {
        Reporte r1 = new Reporte();
        r1.setLatitud(20.96700);
        r1.setLongitud(-89.62300);

        Reporte r2 = new Reporte();
        r2.setLatitud(20.96720);
        r2.setLongitud(-89.62340);

        Reporte sinCoords = new Reporte();

        Optional<GeoUtils.Coordenada> centroide = GeoUtils.calcularCentroide(List.of(r1, r2, sinCoords));

        assertThat(centroide).isPresent();
        assertThat(centroide.get().latitud()).isCloseTo(20.96710, within(0.00001));
        assertThat(centroide.get().longitud()).isCloseTo(-89.62320, within(0.00001));
    }
}
