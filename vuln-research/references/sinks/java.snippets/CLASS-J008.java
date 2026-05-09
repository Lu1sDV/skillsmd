public interface SecuredRepository<T> {
    @PreAuthorize("hasRole('ADMIN')")  // MISSED by annotation resolver
    T findById(Long id);
}
public class UserRepository implements SecuredRepository<User> {
    public User findById(Long id) { return data; } // NO auth check!
}
