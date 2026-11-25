package jj.jamap.dto;

import jakarta.validation.constraints.DecimalMax;
import jakarta.validation.constraints.DecimalMin;
import jakarta.validation.constraints.Max;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;
import java.math.BigDecimal;
import jj.jamap.domain.enums.EstadoIncidencia;
import jj.jamap.domain.enums.TipoIncidencia;

/**
 * Payload validado para editar los datos de una incidencia (PUT /api/incidencias/{id}).
 */
public record ActualizarIncidenciaRequest(
        @NotNull(message = "El tipo de incidencia es obligatorio.")
        TipoIncidencia tipo,

        @NotNull(message = "El estado de la incidencia es obligatorio.")
        EstadoIncidencia estado,

        @DecimalMin(value = "-90.0", message = "La latitud debe estar entre -90 y 90.")
        @DecimalMax(value = "90.0", message = "La latitud debe estar entre -90 y 90.")
        Double latitud,

        @DecimalMin(value = "-180.0", message = "La longitud debe estar entre -180 y 180.")
        @DecimalMax(value = "180.0", message = "La longitud debe estar entre -180 y 180.")
        Double longitud,

        @Size(max = 150, message = "La calle no puede exceder 150 caracteres.")
        String calle,

        @Size(max = 30, message = "El numero no puede exceder 30 caracteres.")
        String numero,

        @Size(max = 100, message = "El cruzamiento 1 no puede exceder 100 caracteres.")
        String cruzamiento1,

        @Size(max = 100, message = "El cruzamiento 2 no puede exceder 100 caracteres.")
        String cruzamiento2,

        @Size(max = 120, message = "La colonia no puede exceder 120 caracteres.")
        String colonia,

        @Min(value = 0, message = "La prioridad debe estar entre 0 y 100.")
        @Max(value = 100, message = "La prioridad debe estar entre 0 y 100.")
        Integer prioridad,

        @DecimalMin(value = "0.0", message = "El costo estimado no puede ser negativo.")
        BigDecimal costoEstimado,

        @Size(max = 128, message = "El UID asignado no puede exceder 128 caracteres.")
        String asignadoA,

        @Size(max = 500, message = "La URL de evidencia no puede exceder 500 caracteres.")
        String fotoEvidenciaUrl,

        @Size(max = 500, message = "La URL de imagen no puede exceder 500 caracteres.")
        String imageUrl
) {}
