package jj.jamap.domain.entity;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.EnumType;
import jakarta.persistence.Enumerated;
import jakarta.persistence.Id;
import jakarta.persistence.PrePersist;
import jakarta.persistence.Table;
import jj.jamap.domain.enums.RolUsuario;

/**
 * Representa a un usuario autenticado con Firebase Authentication y su rol en Ja'Map.
 */
@Entity
@Table(name = "usuarios")
public class Usuario {

    @Id
    @Column(length = 128)
    private String uid;

    @Column(nullable = false, unique = true, length = 150)
    private String email;

    @Column(length = 150)
    private String nombre;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 20)
    private RolUsuario rol = RolUsuario.CIUDADANO;

    public Usuario() {
    }

    public Usuario(String uid, String email, String nombre, RolUsuario rol) {
        this.uid = uid;
        this.email = email;
        this.nombre = nombre;
        this.rol = rol != null ? rol : RolUsuario.CIUDADANO;
    }

    @PrePersist
    void prePersist() {
        if (this.rol == null) {
            this.rol = RolUsuario.CIUDADANO;
        }
    }

    public String getUid() {
        return uid;
    }

    public void setUid(String uid) {
        this.uid = uid;
    }

    public String getEmail() {
        return email;
    }

    public void setEmail(String email) {
        this.email = email;
    }

    public String getNombre() {
        return nombre;
    }

    public void setNombre(String nombre) {
        this.nombre = nombre;
    }

    public RolUsuario getRol() {
        return rol;
    }

    public void setRol(RolUsuario rol) {
        this.rol = rol;
    }
}
