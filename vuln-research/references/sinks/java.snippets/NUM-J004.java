class FooName { // NO Comparable — JEP 180 treeification fails
    public int hashCode() { return name.hashCode(); }
}
Map<FooName, String> m = new HashMap<>();
for (FooName c : generateCollisions(1_000_000))
    m.put(c, null); // O(n) bucket → CPU 100%
