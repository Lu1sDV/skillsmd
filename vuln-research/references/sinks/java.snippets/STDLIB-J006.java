JavaCompiler compiler = ToolProvider.getSystemJavaCompiler();
compiler.run(null, null, null, attackerControlledJavaSourceFile);
