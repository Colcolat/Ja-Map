package jj.jamap.domain.entity;

import jakarta.persistence.CascadeType;
import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.EnumType;
import jakarta.persistence.Enumerated;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.OneToMany;
import jakarta.persistence.PrePersist;
import jakarta.persistence.Table;
import java.math.BigDecimal;
import java.time.Instant;
import java.util.ArrayList;
import java.util.List;
import jj.jamap.domain.enums.EstadoIncidencia;
import jj.jamap.domain.enums.TipoIncidencia;

/**
 * Representa una incidencia agrupada que concentra uno o mas reportes cercanos del mismo tipo.
 */
@Entity
@Table(name = "incidencias")
public class Incidencia {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 40)
    private TipoIncidencia tipo;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 25)
    private EstadoIncidencia estado = EstadoIncidencia.ABIERTA;

    private Double latitud;

    private Double longitud;

    @Column(length = 150)
    private String calle;

    @Column(length = 30)
    private String numero;

    @Column(length = 100)
    private String cruzamiento1;

    @Column(length = 100)
    private String cruzamiento2;

    @Column(length = 120)
    private String colonia;

    @Column(nullable = false)
    private Integer prioridad = 0;

    @Column(name = "costo_estimado", precision = 10, scale = 2)
    private BigDecimal costoEstimado;

    @Column(name = "asignado_a", length = 128)
    private String asignadoA;

    @Column(name = "foto_evidencia_url", length = 500)
    private String fotoEvidenciaUrl;

    @Column(name = "fecha_apertura", nullable = false)
    private Instant fechaApertura;

    @Column(name = "fecha_cierre")
    private Instant fechaCierre;

    @OneToMany(mappedBy = "incidencia", cascade = CascadeType.ALL, orphanRemoval = true)
    private List<Reporte> reportes = new ArrayList<>();

    public Incidencia() {
    }

    @PrePersist
    void prePersist() {
        if (this.estado == null) {
            this.estado = EstadoIncidencia.ABIERTA;
        }
        if (this.prioridad == null) {
            this.prioridad = 0;
        }
        if (this.fechaApertura == null) {
            this.fechaApertura = Instant.now();
        }
    }

    /**
     * Vincula un reporte manteniendo sincronizados ambos lados de la relacion bidireccional.
     */
    public void agregarReporte(Reporte reporte) {
        this.reportes.add(reporte);
        reporte.setIncidencia(this);
    }

    /**
     * Desvincula un reporte manteniendo sincronizados ambos lados de la relacion bidireccional.
     */
    public void removerReporte(Reporte reporte) {
        this.reportes.remove(reporte);
        reporte.setIncidencia(null);
    }

    public Long getId() {
        return id;
    }

    public void setId(Long id) {
        this.id = id;
    }

    public TipoIncidencia getTipo() {
        return tipo;
    }

    public void setTipo(TipoIncidencia tipo) {
        this.tipo = tipo;
    }

    public EstadoIncidencia getEstado() {
        return estado;
    }

    public void setEstado(EstadoIncidencia estado) {
        this.estado = estado;
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

    public String getCalle() {
        return calle;
    }

    public void setCalle(String calle) {
        this.calle = calle;
    }

    public String getNumero() {
        return numero;
    }

    public void setNumero(String numero) {
        this.numero = numero;
    }

    public String getCruzamiento1() {
        return cruzamiento1;
    }

    public void setCruzamiento1(String cruzamiento1) {
        this.cruzamiento1 = cruzamiento1;
    }

    public String getCruzamiento2() {
        return cruzamiento2;
    }

    public void setCruzamiento2(String cruzamiento2) {
        this.cruzamiento2 = cruzamiento2;
    }

    public String getColonia() {
        return colonia;
    }

    public void setColonia(String colonia) {
        this.colonia = colonia;
    }

    public Integer getPrioridad() {
        return prioridad;
    }

    public void setPrioridad(Integer prioridad) {
        this.prioridad = prioridad;
    }

    public BigDecimal getCostoEstimado() {
        return costoEstimado;
    }

    public void setCostoEstimado(BigDecimal costoEstimado) {
        this.costoEstimado = costoEstimado;
    }

    public String getAsignadoA() {
        return asignadoA;
    }

    public void setAsignadoA(String asignadoA) {
        this.asignadoA = asignadoA;
    }

    public String getFotoEvidenciaUrl() {
        return fotoEvidenciaUrl;
    }

    public void setFotoEvidenciaUrl(String fotoEvidenciaUrl) {
        this.fotoEvidenciaUrl = fotoEvidenciaUrl;
    }

    public Instant getFechaApertura() {
        return fechaApertura;
    }

    public void setFechaApertura(Instant fechaApertura) {
        this.fechaApertura = fechaApertura;
    }

    public Instant getFechaCierre() {
        return fechaCierre;
    }

    public void setFechaCierre(Instant fechaCierre) {
        this.fechaCierre = fechaCierre;
    }

    public List<Reporte> getReportes() {
        return reportes;
    }

    public void setReportes(List<Reporte> reportes) {
        this.reportes = reportes;
    }
}
