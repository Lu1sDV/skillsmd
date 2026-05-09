@SafeVarargs
public static <T> T[] toArray(T... elements) { return elements; }
List<String>[] lists = toArray(new ArrayList<String>());
Object[] arr = lists;
arr[0] = new ArrayList<Integer>(); // SILENTLY SUCCEEDS — no ArrayStoreException!
List<String> confused = lists[0]; // confused.get(0) returns Integer → ClassCastException
