package jj.jamap.repository;

import java.util.Optional;
import jj.jamap.domain.entity.Usuario;
import org.springframework.data.jpa.repository.JpaRepository;

/**
 * Repositorio JPA para usuarios identificados por su UID de Firebase.
 */
public interface UsuarioRepository extends JpaRepository<Usuario, String> {

    Optional<Usuario> findByEmail(String email);
}
