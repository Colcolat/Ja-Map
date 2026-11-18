package jj.jamap.exception;

/**
 * Excepcion lanzada cuando un recurso solicitado no existe en la base de datos.
 */
public class ResourceNotFoundException extends RuntimeException {

    public ResourceNotFoundException(String message) {
        super(message);
    }

    public ResourceNotFoundException(String resourceName, Object id) {
        super(resourceName + " no encontrado con id: " + id);
    }
}
