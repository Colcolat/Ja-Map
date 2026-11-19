package jj.jamap.dto;

import jakarta.validation.constraints.DecimalMax;
import jakarta.validation.constraints.DecimalMin;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;
import jj.jamap.domain.enums.TipoIncidencia;

/**
 * Payload validado para crear un reporte ciudadano (POST /api/reportes).
 */
public record CrearReporteRequest(
        @NotNull(message = "El tipo de incidencia es obligatorio.")
        TipoIncidencia tipo,

        @NotNull(message = "La latitud es obligatoria.")
        @DecimalMin(value = "-90.0", message = "La latitud debe estar entre -90 y 90.")
        @DecimalMax(value = "90.0", message = "La latitud debe estar entre -90 y 90.")
        Double latitud,

        @NotNull(message = "La longitud es obligatoria.")
        @DecimalMin(value = "-180.0", message = "La longitud debe estar entre -180 y 180.")
        @DecimalMax(value = "180.0", message = "La longitud debe estar entre -180 y 180.")
        Double longitud,

        @Size(max = 500, message = "La URL de la foto no puede exceder 500 caracteres.")
        String fotoUrl,

        @Size(max = 1000, message = "El comentario no puede exceder 1000 caracteres.")
        String comentario,

        @Size(max = 300, message = "La direccion capturada no puede exceder 300 caracteres.")
        String direccionCapturada,

        @Size(max = 150, message = "La calle no puede exceder 150 caracteres.")
        String calle,

        @Size(max = 30, message = "El numero no puede exceder 30 caracteres.")
        String numero,

        @Size(max = 100, message = "El cruzamiento 1 no puede exceder 100 caracteres.")
        String cruzamiento1,

        @Size(max = 100, message = "El cruzamiento 2 no puede exceder 100 caracteres.")
        String cruzamiento2,

        @Size(max = 120, message = "La colonia no puede exceder 120 caracteres.")
        String colonia
) {}
