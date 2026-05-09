public interface UserRepository extends MongoRepository<User, String> {
    @Query("{ 'name' : ?#{?0} }") // VULNERABLE: SpEL in ?0 syntax
    List<User> findByName(String name);
    // name = T(java.lang.Runtime).getRuntime().exec('id')
}
