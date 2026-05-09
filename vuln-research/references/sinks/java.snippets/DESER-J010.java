SerializedLambda forged = new SerializedLambda(
    capturingClass, "Ljava/lang/Runnable;", "run", "()V",
    MethodHandleInfo.REF_invokeStatic, capturingClass,
    "privateMethod", "()V", "()V", new Object[0]);
// Deserialization calls capturingClass.privateMethod()!
