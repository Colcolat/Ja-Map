package jj.jamap.domain.entity;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.EnumType;
import jakarta.persistence.Enumerated;
import jakarta.persistence.FetchType;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.JoinColumn;
import jakarta.persistence.ManyToOne;
import jakarta.persistence.PrePersist;
import jakarta.persistence.Table;
import java.time.Instant;
import jj.jamap.domain.enums.OrigenReporte;

/**
 * Representa un reporte individual enviado por un ciudadano o importado desde historicos.
 */
@Entity
@Table(name = "reportes")
public class Reporte {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "incidencia_id")
    private Incidencia incidencia;

    @Column(name = "uid_ciudadano", length = 128)
    private String uidCiudadano;

    @Column(name = "foto_url", length = 500)
    private String fotoUrl;

    @Column(length = 1000)
    private String comentario;

    @Column(name = "direccion_capturada", length = 300)
    private String direccionCapturada;

    private Double latitud;

    private Double longitud;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 20)
    private OrigenReporte origen = OrigenReporte.APP;

    @Column(name = "fecha_reporte", nullable = false)
    private Instant fechaReporte;

    public Reporte() {
    }

    @PrePersist
    void prePersist() {
        if (this.origen == null) {
            this.origen = OrigenReporte.APP;
        }
        if (this.fechaReporte == null) {
            this.fechaReporte = Instant.now();
        }
    }

    public Long getId() {
        return id;
    }

    public void setId(Long id) {
        this.id = id;
    }

    public Incidencia getIncidencia() {
        return incidencia;
    }

    public void setIncidencia(Incidencia incidencia) {
        this.incidencia = incidencia;
    }

    public String getUidCiudadano() {
        return uidCiudadano;
    }

    public void setUidCiudadano(String uidCiudadano) {
        this.uidCiudadano = uidCiudadano;
    }

    public String getFotoUrl() {
        return fotoUrl;
    }

    public void setFotoUrl(String fotoUrl) {
        this.fotoUrl = fotoUrl;
    }

    public String getComentario() {
        return comentario;
    }

    public void setComentario(String comentario) {
        this.comentario = comentario;
    }

    public String getDireccionCapturada() {
        return direccionCapturada;
    }

    public void setDireccionCapturada(String direccionCapturada) {
        this.direccionCapturada = direccionCapturada;
    }

    public Double getLatitud() {
        return latitud;
    }

    public void setLatitud(Double latitud) {
        this.latitud = latitud;
    }

    public Double getLongitud() {
        return longitud;
    }

    public void setLongitud(Double longitud) {
        this.longitud = longitud;
    }

    public OrigenReporte getOrigen() {
        return origen;
    }

    public void setOrigen(OrigenReporte origen) {
        this.origen = origen;
    }

    public Instant getFechaReporte() {
        return fechaReporte;
    }

    public void setFechaReporte(Instant fechaReporte) {
        this.fechaReporte = fechaReporte;
    }
}
