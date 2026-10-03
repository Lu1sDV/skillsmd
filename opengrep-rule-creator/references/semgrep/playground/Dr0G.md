# Upstream Semgrep playground: Dr0G

> Historical/upstream Semgrep example; NOT an OpenGrep compatibility promise. Downloaded 2026-10-03; not executed.

Source: [Dr0G](https://semgrep.dev/embed/editor?snippet=Dr0G). [Raw API response](Dr0G.json).

## Rule definition

```json
{
  "rules": [
    {
      "id": "docs-value-in-message-example",
      "patterns": [
        {
          "pattern": "byte[] buf = new byte[$X];"
        },
        {
          "metavariable-comparison": {
            "metavariable": "$X",
            "comparison": "$X < 2048"
          }
        }
      ],
      "message": "Buffer size value($X) is too small, should be at least 2048",
      "languages": [
        "java"
      ],
      "severity": "WARNING"
    }
  ]
}
```

## Test case 1

```text
import java.io.FileInputStream

public class Test {

    public static void read(String file, Signature sign) { 
        int size = 512;
        in = new FileInputStream(file);
        byte[] buf = new byte[size];
        int len;
        while ((len = in.read(buf)) != -1) {
            sign.update(buf, 0, len);
        }    

    }
}
```

Case metadata:

```json
{
  "filename": null,
  "language": "java",
  "highlights": []
}
```
