String path = Path.of(targetDir, ze.getName()).normalize().toFile().getAbsolutePath();
// BUG: "/tmp/zipSlip_evil/file".startsWith("/tmp/zipSlip") == TRUE!
if (!path.startsWith(targetDir)) { throw ... }
