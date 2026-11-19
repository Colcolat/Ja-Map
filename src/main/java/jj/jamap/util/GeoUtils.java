package jj.jamap.util;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.util.List;
import java.util.Optional;
import jj.jamap.domain.entity.Reporte;

/**
 * Utilidades geoespaciales: distancia Haversine en metros y calculo de centroide.
 */
public final class GeoUtils {

    private static final double RADIO_TIERRA_METROS = 6_371_000.0;

    public record Coordenada(double latitud, double longitud) {}

    private GeoUtils() {
    }

    /**
     * Calcula la distancia en metros entre dos coordenadas geograficas usando la formula Haversine.
     */
    public static double distanciaMetros(double lat1, double lng1, double lat2, double lng2) {
        double dLat = Math.toRadians(lat2 - lat1);
        double dLng = Math.toRadians(lng2 - lng1);
        double sinLat = Math.sin(dLat / 2.0);
        double sinLng = Math.sin(dLng / 2.0);
        double a = sinLat * sinLat
                + Math.cos(Math.toRadians(lat1)) * Math.cos(Math.toRadians(lat2)) * sinLng * sinLng;
        double c = 2.0 * Math.atan2(Math.sqrt(a), Math.sqrt(Math.max(0.0, 1.0 - a)));
        return RADIO_TIERRA_METROS * c;
    }

    /**
     * Calcula el promedio geografico (centroide) de los reportes que tengan coordenadas validas.
     */
    public static Optional<Coordenada> calcularCentroide(List<Reporte> reportes) {
        if (reportes == null || reportes.isEmpty()) {
            return Optional.empty();
        }

        double sumaLat = 0.0;
        double sumaLng = 0.0;
        int conteo = 0;

        for (Reporte reporte : reportes) {
            if (reporte.getLatitud() != null && reporte.getLongitud() != null) {
                sumaLat += reporte.getLatitud();
                sumaLng += reporte.getLongitud();
                conteo++;
            }
        }

        if (conteo == 0) {
            return Optional.empty();
        }

        return Optional.of(new Coordenada(sumaLat / conteo, sumaLng / conteo));
    }

    public static double redondearDosDecimales(double valor) {
        return BigDecimal.valueOf(valor)
                .setScale(2, RoundingMode.HALF_UP)
                .doubleValue();
    }
}
