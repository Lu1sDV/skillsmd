# SSRF Prevention Reference

## URL Validation (Python)

```python
import ipaddress
import socket
from urllib.parse import urlparse

BLOCKED_NETWORKS = [
    ipaddress.ip_network('10.0.0.0/8'),
    ipaddress.ip_network('172.16.0.0/12'),
    ipaddress.ip_network('192.168.0.0/16'),
    ipaddress.ip_network('127.0.0.0/8'),
    ipaddress.ip_network('169.254.0.0/16'),     # Link-local (metadata)
    ipaddress.ip_network('100.64.0.0/10'),      # Carrier-grade NAT
    ipaddress.ip_network('::1/128'),
    ipaddress.ip_network('fc00::/7'),
    ipaddress.ip_network('fe80::/10'),
]

def validate_url(url: str) -> bool:
    parsed = urlparse(url)

    # 1. Scheme allowlist
    if parsed.scheme not in ('http', 'https'):
        raise ValueError(f"Blocked scheme: {parsed.scheme}")

    # 2. Require hostname
    hostname = parsed.hostname
    if not hostname:
        raise ValueError("No hostname in URL")

    # 3. Resolve DNS and check against blocked networks
    try:
        resolved_ips = socket.getaddrinfo(hostname, parsed.port or 443)
    except socket.gaierror:
        raise ValueError(f"Cannot resolve: {hostname}")

    for family, type_, proto, canonname, sockaddr in resolved_ips:
        ip = ipaddress.ip_address(sockaddr[0])
        for network in BLOCKED_NETWORKS:
            if ip in network:
                raise ValueError(
                    f"Blocked: {hostname} resolves to private IP {ip}"
                )
    return True
```

## Cloud Metadata Protection

```bash
# AWS: Require IMDSv2 (token-based) -- blocks SSRF because
# attacker can't set the required PUT header through SSRF
aws ec2 modify-instance-metadata-options \
  --instance-id i-1234567890 \
  --http-tokens required \
  --http-endpoint enabled

# Network-level: Block metadata IP in firewall rules
iptables -A OUTPUT -d 169.254.169.254 -j DROP
# Better: use IMDSv2 + application-level URL validation
```

## Architecture-Level Defenses

1. **Network Segmentation**: Don't let web servers reach internal services directly. Use a dedicated proxy/gateway for outbound requests.
2. **Dedicated Fetcher Service**: Isolated microservice with its own network policy, domain allowlist, response size limits, and timeouts.
3. **DNS Resolution Pinning**: Resolve DNS before making the request. Use the resolved IP for the actual connection. Prevents DNS rebinding.
4. **Disable Unnecessary Protocols**: Block gopher://, file://, dict://, ftp://. Allow only http://, https://.
