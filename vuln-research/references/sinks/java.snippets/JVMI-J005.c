// JVMTI agent: ClassFileLoadHook intercepts ALL loaded classes
void JNICALL ClassFileLoadHook(jvmtiEnv*, JNIEnv*, jclass, jobject,
    const char* name, ...) {
    if (name && strstr(name, "java/lang/SecurityManager"))
        // Patch checkPermission to always return
}
