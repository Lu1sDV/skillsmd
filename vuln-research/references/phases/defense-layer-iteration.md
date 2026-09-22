# Defense Layer Iteration — Phase L7 Exploitability Gate

Load this file when a defense layer blocks exploitation during Phase L7 (Exploitability Gate). Treat the defense itself as a new attack surface, apply the methodology recursively layer by layer, and chain the results into a full-chain exploit.

---

### Defense Layer Iteration

When a defense layer blocks exploitation, don't stop — treat it as **a new iteration of the same problem**:

1. **Identify the defense boundary** — sandbox, hardened allocator, kernel separation, WAF, hypervisor
2. **Treat the defense itself as a new attack surface** — it's software too, with its own bugs
3. **Apply the same methodology recursively** — sweep or audit the defense layer's code for bypasses
4. **Chain across boundaries** — vuln in app + sandbox escape + kernel bug = full-chain exploit

Layered defenses (hardened allocators, sandboxes, user/kernel barriers, virtualization) are iterated versions of the same problem. Agents can generate full-chain exploits by solving each layer independently and composing the results.
