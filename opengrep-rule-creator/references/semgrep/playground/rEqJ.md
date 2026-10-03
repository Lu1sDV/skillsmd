# Upstream Semgrep playground: rEqJ

> Historical/upstream Semgrep example; NOT an OpenGrep compatibility promise. Downloaded 2026-10-03; not executed.

Source: [rEqJ](https://semgrep.dev/embed/editor?snippet=rEqJ). [Raw API response](rEqJ.json).

## Rule definition

```json
{
  "rules": [
    {
      "id": "docs-skip-tls-verify-cluster",
      "languages": [
        "yaml"
      ],
      "message": "Cluster is disabling TLS certificate verification when communicating with\nthe server. This makes your HTTPS connections insecure. Remove the\n'insecure-skip-tls-verify: true' key to secure communication.\n",
      "metadata": {
        "references": [
          "https://kubernetes.io/docs/reference/config-api/client-authentication.v1beta1/#client-authentication-k8s-io-v1beta1-Cluster"
        ]
      },
      "pattern": "cluster:\n  ...\n  insecure-skip-tls-verify: true\n",
      "severity": "WARNING"
    }
  ]
}
```

## Test case 1

```text
apiVersion: v1
clusters:
- cluster:
    server: https://192.168.0.100:8443
    insecure-skip-tls-verify: true
  name: minikube1
```

Case metadata:

```json
{
  "filename": null,
  "language": "yaml",
  "highlights": []
}
```
