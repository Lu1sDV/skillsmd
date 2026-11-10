# Crypto Memory-Safety Sink Categories: Advanced & Obscure

> Comprehensive research on memory safety issues in cryptographic implementations.
> Researched 2026-05-14. Sources include OpenSSL advisories, GitHub commits, NVD entries,
> and the Marvin Attack research (Hubert Kario, Red Hat).

---

## 1. Integer Overflows in Crypto Length Parameters

### 1a. CVE-2021-23840 — EVP_CipherUpdate/EVP_EncryptUpdate Integer Overflow

- **CVE URL**: https://nvd.nist.gov/vuln/detail/CVE-2021-23840
- **Advisory**: https://openssl-library.org/news/secadv/20210216.txt
- **Severity**: Low (OpenSSL), CWE-190 Integer Overflow
- **Vulnerable function**: `evp_EncryptDecryptUpdate()` in `crypto/evp/evp_enc.c`
- **Affected versions**: OpenSSL 1.1.1i and below, 1.0.2x and below
- **Reported by**: Paul Kehrer (2020-12-13), fixed by Matt Caswell

**Code Pattern — The Vulnerable Logic (pre-fix)**:

In `crypto/evp/evp_enc.c`, the function `evp_EncryptDecryptUpdate()` computes the
output length by first consuming partial-block data from the context buffer, then
processing the remaining full blocks. The output length calculation divides
remaining input by block size (`bl`):

```c
// VULNERABLE: no overflow check before computing output length
j = bl - i;                    // bytes to fill partial block
memcpy(&(ctx->buf[i]), in, j);
inl -= j;
in += j;
// ... inl is now a multiple of bl, and is added to output length
// If inl is close to INT_MAX, the computation can overflow
```

The overflow manifests when `inl` (the input length passed by the caller) is near
`INT_MAX`. Since `inl` is `int`, passing `INT_MAX` or `INT_MAX - bl + 1` causes
the internal block-aligned computation `(inl - j) & ~(bl - 1)` to wrap around,
producing a negative `outl` value while returning success (1).

**The Fix (commit 6a51b9e1d0)**:

```c
// FIX: check for overflow before computing output
if (((inl - j) & ~(bl - 1)) > INT_MAX - bl) {
    EVPerr(EVP_F_EVP_ENCRYPTDECRYPTUPDATE, EVP_R_OUTPUT_WOULD_OVERFLOW);
    return 0;
}
```

And in `EVP_DecryptUpdate`, which can call `evp_EncryptDecryptUpdate`:

```c
if ((inl & ~(b - 1)) > INT_MAX - b) {
    EVPerr(EVP_F_EVP_DECRYPTUPDATE, EVP_R_OUTPUT_WOULD_OVERFLOW);
    return 0;
}
```

**How it enables buffer overflow**: The application allocates a buffer based on
the (incorrect, negative or small) `outl` value, but the actual data written
exceeds it. This is a heap corruption.

**Detection signature**:

```
Pattern: Multiplication/addition of user-controlled length with block size
         without overflow guard before buffer size computation
grep:    '(inl|len|size)\s*[-+*&|]\s*(bl|block_size|BSIZE)'
         (without prior check for INT_MAX or SIZE_MAX)
Location: any crypto library's encrypt/decrypt update path
```

---

### 1b. CVE-2016-2105 — EVP_EncodeUpdate Heap Corruption

- **CVE URL**: https://nvd.nist.gov/vuln/detail/CVE-2016-2105
- **Fix commit**: https://github.com/openssl/openssl/commit/5b814481f3573fa9677f3a31ee51322e2a22ee6a
- **Severity**: Low, CWE-190 Integer Overflow
- **Vulnerable function**: `EVP_EncodeUpdate()` in `crypto/evp/encode.c`

**Code Pattern — The Vulnerable Logic**:

```c
// VULNERABLE: integer overflow in length comparison (commit 5b81448)
if ((ctx->num + inl) < ctx->length) {
    // ctx->num and inl are both int; if ctx->num is large (e.g., 46)
    // and inl is near INT_MAX, the addition wraps to a small value
    // or negative, bypassing this check
    memcpy(&(ctx->enc_data[ctx->num]), in, inl);
    ctx->num += inl;
    return;
}
```

**The Fix**:

```c
// FIX: reorder comparison to avoid overflow
if (ctx->length - ctx->num > inl) {
    memcpy(&(ctx->enc_data[ctx->num]), in, inl);
    ctx->num += inl;
    return;
}
```

**Exploitation**: Attacker supplies very large `inl` (e.g., `INT_MAX - 45`).
`ctx->num + inl` wraps. The length check passes incorrectly. The `memcpy` with
`inl` past the end of `enc_data` causes heap corruption. Internally used by
`PEM_write_bio*` functions for Base64 encoding.

**Detection signature**:

```
Pattern: (a + b) < limit   where a, b, limit are all the same signed integer type
Fix:     limit - a > b      (reordering to prevent overflow)
grep:    '\(\w+\s*\+\s*\w+\)\s*[<>]\s*\w+'
Location: any function dealing with buffer fill/accumulator patterns
```

---

### 1c. CVE-2016-2106 — EVP_EncryptUpdate Heap Corruption

- **CVE URL**: https://nvd.nist.gov/vuln/detail/CVE-2016-2106
- **Fix commit**: https://github.com/openssl/openssl/commit/3f3582139fbb259a1c3cbb0a25236500a409bf26
- **Severity**: Low, CWE-189 Numeric Errors
- **Vulnerable function**: `EVP_EncryptUpdate()` in `crypto/evp/evp_enc.c`

**Code Pattern**: The same internal `evp_EncryptDecryptUpdate` function (see
CVE-2021-23840). The vulnerability is an integer overflow in the output length
calculation when the caller passes a very large `inl` after a previous call that
left a partial block in the context buffer.

**Specific path**: After `EVP_EncryptInit()` is called, if the first
`EVP_EncryptUpdate()` call leaves partial data in `ctx->buf`, a subsequent call
with huge `inl` causes overflow in the length arithmetic inside the else-branch
of `evp_EncryptDecryptUpdate`.

**The Fix** (1.0.2 era): Added an explicit overflow check — `inl` is compared
against `INT_MAX` before being used in length computation.

**Detection signature**:

```
Pattern: Chaining two calls to encrypt/decrypt update where the second
         can receive attacker-controlled length — check that all internal
         length arithmetic is overflow-safe
grep:    any function computing (n_blocks * block_size) or (n & ~(bs-1)) + bs
         without prior size_t cast or overflow bounds check
```

---

## 2. OpenSSL SM2 Decryption Buffer Overflow (CVE-2021-3711)

- **CVE URL**: https://nvd.nist.gov/vuln/detail/CVE-2021-3711
- **Advisory**: https://openssl-library.org/news/secadv/20210824.txt
- **Fix commit**: https://github.com/openssl/openssl/commit/59f5e75f3bced8fc0e130d72a3f582cf7b480b46
- **Severity**: High, CWE-120 Buffer Copy Without Size Check
- **Vulnerable function**: `sm2_plaintext_size()` in `crypto/sm2/sm2_crypt.c`
- **Affected versions**: OpenSSL 1.1.1-1.1.1k
- **Reported by**: John Ouyang (2021-08-12), fixed by Matt Caswell

**The Two-Call Pattern**:

```c
// STEP 1: Application calls EVP_PKEY_decrypt() with out=NULL to get size
EVP_PKEY_decrypt(ctx, NULL, &outlen, in, inlen);
// outlen is now set to the "required" buffer size

// STEP 2: Application allocates buffer and calls again
unsigned char *out = malloc(outlen);   // allocates based on step 1
EVP_PKEY_decrypt(ctx, out, &outlen, in, inlen);
// BOOM: writes up to 62 bytes past out if outlen was underestimated
```

**Vulnerable Code (pre-fix)**:

```c
// crypto/sm2/sm2_crypt.c — OLD sm2_plaintext_size()
int sm2_plaintext_size(const EC_KEY *key, const EVP_MD *digest,
                       size_t msg_len, size_t *pt_size)
{
    const size_t field_size = ec_field_size(EC_KEY_get0_group(key));
    const int md_size = EVP_MD_size(digest);
    size_t overhead;

    overhead = 10 + 2 * field_size + (size_t)md_size;
    if (msg_len <= overhead) {
        SM2err(SM2_F_SM2_PLAINTEXT_SIZE, SM2_R_INVALID_ENCODING);
        return 0;
    }
    *pt_size = msg_len - overhead;  // BUG: UNDERESTIMATES
    return 1;
}
```

The bug: `sm2_plaintext_size()` **estimates** the plaintext size using algebraic
computation (`msg_len - overhead`) rather than **parsing** the actual ciphertext
structure to get the real `C2` payload length. A malicious attacker can
construct an SM2 ciphertext where the `C2` component is larger than what
`msg_len - overhead` predicts, causing the second `EVP_PKEY_decrypt` call to
write up to 62 bytes past the allocated buffer.

**The Fix**:

```c
// NEW sm2_plaintext_size() — PARSE don't ESTIMATE
int sm2_plaintext_size(const unsigned char *ct, size_t ct_size,
                       size_t *pt_size)
{
    struct SM2_Ciphertext_st *sm2_ctext = NULL;
    sm2_ctext = d2i_SM2_Ciphertext(NULL, &ct, ct_size);
    if (sm2_ctext == NULL) {
        SM2err(SM2_F_SM2_PLAINTEXT_SIZE, SM2_R_INVALID_ENCODING);
        return 0;
    }
    *pt_size = sm2_ctext->C2->length;  // CORRECT: actual payload size
    SM2_Ciphertext_free(sm2_ctext);
    return 1;
}
```

The call site was also updated to pass the ciphertext buffer directly instead of
derived parameters:

```c
// In pkey_sm2_decrypt():
if (out == NULL) {
-   if (!sm2_plaintext_size(ec, md, inlen, outlen))
+   if (!sm2_plaintext_size(in, inlen, outlen))
        return -1;
}
```

**Detection signature**:

```
Pattern: First call to a decrypt function with NULL out returns an estimated
         size based on algebraic derivation rather than parsing the actual
         ciphertext structure
grep:    Look for two-call patterns where the sizing function computes
         'msg_len - overhead' or similar arithmetic instead of extracting
         a length field from the serialized ciphertext
Key risk: Any EVP_PKEY_decrypt wrapper that estimates rather than parses
```

---

## 3. DES OFB/CFB Buffer Over-Read (OpenSSL Issue #30284)

- **Issue URL**: https://github.com/openssl/openssl/issues/30284
- **Severity**: Low (information disclosure — stack data leak into ciphertext)
- **CVE**: No CVE assigned (desktop issue, not yet upstream-fixed at time of research)
- **Vulnerable functions** (4 files):
  - `DES_ede3_ofb64_encrypt()` in `crypto/des/ofb64ede.c`
  - `DES_ede3_cfb64_encrypt()` in `crypto/des/cfb64ede.c`
  - `DES_ofb64_encrypt()` in `crypto/des/ofb64enc.c`
  - `DES_cfb64_encrypt()` in `crypto/des/cfb64enc.c`

**Root Cause — Missing Validation in `set_params`**:

```c
// providers/implementations/ciphers/ciphercommon.c:646-654
if (p->num != NULL) {
    unsigned int num;
    if (!OSSL_PARAM_get_uint(p->num, &num)) {
        ERR_raise(ERR_LIB_PROV, PROV_R_FAILED_TO_GET_PARAMETER);
        return 0;
    }
    ctx->num = num;  // BUG: No range check! Accepts any unsigned int.
}
```

For DES (8-byte block), `num` should be in `[0, 7]`. No validation is performed.

**How the OOB read triggers**:

```c
// crypto/des/ofb64ede.c:27-59
void DES_ede3_ofb64_encrypt(... int *num)
{
    register int n = *num;    // BUG: reads num directly, NO masking
    DES_cblock d;             // 8 bytes on stack
    ...
    while (l--) {
        if (n == 0) {
            // regenerate keystream into d[0..7]
        }
        *(out++) = *(in++) ^ d[n];   // OOB read when n >= 8
        n = (n + 1) & 0x07;          // masked only AFTER the read
    }
}
```

The masking `& 0x07` at line 59 only applies AFTER the first read. On the first
iteration with `n >= 8`, `d[n]` reads past the 8-byte stack buffer, leaking
stack data into ciphertext output.

**Full call chain**:

```
EVP_CIPHER_CTX_set_params(ctx, params)
  → ossl_cipher_generic_set_ctx_params()
    → ossl_cipher_common_set_ctx_params()
      → ctx->num = num;               // arbitrary, no check

EVP_EncryptUpdate(ctx, out, &outlen, in, inl)
  → ossl_cipher_generic_stream_update()
    → ossl_cipher_hw_tdes_ofb(ctx, ...)
      → DES_ede3_ofb64_encrypt(..., &num)
        → d[num]                       // STACK OOB READ
```

**Fix (Option A — API boundary)**:

```c
if (p->num != NULL) {
    unsigned int num;
    if (!OSSL_PARAM_get_uint(p->num, &num)) { ... return 0; }
+   if (ctx->blocksize > 0 && num >= (unsigned int)ctx->blocksize) {
+       ERR_raise(ERR_LIB_PROV, PROV_R_FAILED_TO_GET_PARAMETER);
+       return 0;
+   }
    ctx->num = num;
}
```

**Fix (Option B — defense in depth)**:

```c
-   register int n = *num;
+   register int n = *num & 0x07;     // mask on entry
```

**Detection signature**:

```
Pattern: CIPHER_CTX parameter setter that stores an integer (like 'num')
         without comparing to blocksize
Pattern: XOR-based stream cipher inner loop reads d[num] where num is
         masked/updated AFTER the read, not before
grep:    'ctx->num\s*=\s*num' without preceding 'if (num >= blocksize)'
         in any EVP_CIPHER_CTX_set_params provider implementation
grep:    'd\[n\]' in OFB/CFB loops where 'n = (n+1) & mask' follows
         the array access on the same loop iteration
```

---

## 4. Blowfish OFB64 Negative Index (OpenSSL Issue #18751)

- **Issue URL**: https://github.com/openssl/openssl/issues/18751
- **Severity**: Low (negative array index, potentially OOB)
- **Vulnerable function**: `BF_ofb64_encrypt()` in `crypto/bf/bf_ofb64.c`

**Root Cause — `EVP_CIPHER_CTX_get_num` can return -1**:

```c
// crypto/evp/evp_lib.c — get_num can return -1
int EVP_CIPHER_CTX_get_num(const EVP_CIPHER_CTX *ctx)
{
    // ... under certain conditions, returns -1 (uninitialized)
}
```

**The vulnerable call chain**:

```c
// include/crypto/evp.h (internal dispatch)
static int bf_ofb_cipher(...) {
    int num = EVP_CIPHER_CTX_get_num(ctx);  // may be -1
    BF_ofb64_encrypt(in, out, (long)EVP_MAXCHUNK,
                     &EVP_C_DATA(kstruct,ctx)->ksched,
                     ctx->iv, &num);        // -1 passed through!
    // num is not checked for negative before being passed
}
```

**The vulnerable function**:

```c
// crypto/bf/bf_ofb64.c
void BF_ofb64_encrypt(const unsigned char *in, unsigned char *out,
                      long length, const BF_KEY *schedule,
                      unsigned char *ivec, int *num) {
    register int n = *num;         // n = -1 (negative!)
    unsigned char d[8];            // 8-byte stack buffer
    ...
    while (l--) {
        if (n == 0) { /* regenerate */ }
        *(out++) = *(in++) ^ d[n]; // d[-1]: OOB / negative index
        n = (n + 1) & 0x07;
    }
}
```

When `n = -1`, the access `d[n]` reads `d[-1]`, which is before the stack array.
This could leak stack data or crash.

**The masking at line end `(n + 1) & 0x07` does NOT help** because:
- `(-1 + 1) & 0x07 = 0 & 0x07 = 0` — the NEXT iteration would be safe
- But the FIRST iteration with `n = -1` accesses `d[-1]` before the mask

**Detection signature**:

```
Pattern: EVP_CIPHER_CTX_get_num() return value used without negative check
grep:    'num\s*=\s*EVP_CIPHER_CTX_get_num' or 'get_num(ctx)'
         without subsequent 'if (num < 0)' or 'if (num >= 0)'
Pattern: OFB/CFB inner loops where *num is deference directly without
         masking or range check before first array access
grep:    'n\s*=\s*\*num' followed by array access 'd\[n\]' before any
         'n = n & mask' or 'n %= blocksize' operation
```

---

## 5. MDC2 Integer Overflow (CVE-2016-6303)

- **CVE URL**: https://nvd.nist.gov/vuln/detail/CVE-2016-6303
- **Fix commit**: https://github.com/openssl/openssl/commit/55d83bf7c10c7b205fffa23fa7c3977491e56c07
- **Severity**: Low, CWE-787 Out-of-bounds Write
- **Vulnerable function**: `MDC2_Update()` in `crypto/mdc2/mdc2dgst.c`
- **Affected versions**: OpenSSL before 1.1.0
- **Reported by**: Shi Lei (Gear Team, Qihoo 360 Inc.)

**Vulnerable Code (pre-fix)**:

```c
// crypto/mdc2/mdc2dgst.c
int MDC2_Update(MDC2_CTX *c, const unsigned char *in, size_t len)
{
    i = c->num;
    if (i != 0) {
        if (i + len < MDC2_BLOCK) {    // BUG: integer overflow!
            /* partial block */
            memcpy(&(c->data[i]), in, len);
            c->num += (int)len;
            return 1;
        }
        // ...
    }
}
```

**How the overflow manifests**: `i` is the number of bytes already in the
partial block buffer (0-7). `len` is attacker-controlled and can be `SIZE_MAX`
or near it. `i + len` wraps around to a small value, bypassing the `<
MDC2_BLOCK` check. The `memcpy` then writes `SIZE_MAX` bytes from `in` into
the 8-byte `c->data` buffer, causing catastrophic heap corruption.

**The Fix**:

```c
-       if (i + len < MDC2_BLOCK) {
+       if (len < MDC2_BLOCK - i) {   // reorder to prevent overflow
```

**Detection signature**:

```
Pattern: (accumulated + new) < BLOCK_SIZE   where accumulator is small
         int and new is size_t — overflow when new is near SIZE_MAX
Fix:     new < BLOCK_SIZE - accumulated     (safe reordering)
grep:    '\(\w+->num\s*\+\s*\w+\)\s*<\s*\w*BLOCK'
         or '(ctx->num + inl) < ctx->block_size'
```

---

## 6. ASN.1 Parsing Vulnerabilities in Crypto Contexts

### 6a. CVE-2016-2108 — Negative Zero ASN.1 Integer Buffer Underflow

- **CVE URL**: https://nvd.nist.gov/vuln/detail/CVE-2016-2108
- **Fix commit**: https://github.com/openssl/openssl/commit/3661bb4e7934668bd99ca777ea8b30eedfafa871 (1.0.2)
- **Fix commit 2**: https://github.com/openssl/openssl/commit/f5da52e308a6aeea6d5f3df98c4da295d7e9cc27 (related)
- **Severity**: High, CWE-119 Buffer Underflow → Memory Corruption
- **Vulnerable function**: `i2c_ASN1_INTEGER()` in `crypto/asn1/a_int.c`
- **Reported by**: David Benjamin (Google), Huzaifa Sidhpurwala (Red Hat), Hanno Böck

**The Two-Bug Chain**:

**Bug 1** — Negative zero mishandling:
```c
// i2c_ASN1_INTEGER — OLD code
// Problem: a "negative zero" ASN1_INTEGER (type=NEG_INTEGER, data=[0x00])
// causes the encoder to go into an infinite loop stripping "leading" zeros
while (!*n) {      // *n == 0 → infinite loop! Buffer underrun on p
    *(p--) = 0;
    n--;
    i--;
}
```

**Bug 2** — Large universal tag misinterpreted as negative zero:
`d2i_ASN1_TYPE` can misinterpret a large universal tag as a `V_ASN1_NEG_INTEGER`
with zero value, creating a "negative zero" that triggers Bug 1.

```c
// The Fix for Bug 1:
-   while (!*n) {
+   while (!*n && i > 1) {    // bound the loop with length check
        *(p--) = 0;
        n--;
        i--;
    }

// Additional fix: handle zero correctly
+   if (ret == 1 && i == 0)
+       neg = 0;               // zero is never negative
```

```c
// The Fix for Bug 2 — stop distinguishing NEG_INTEGER/NEG_ENUMERATED
// in the ASN.1 type dispatch (commit f5da52e):
-   case V_ASN1_INTEGER:
-   case V_ASN1_NEG_INTEGER:
+   case V_ASN1_INTEGER:         // just one case now
    case V_ASN1_ENUMERATED:
-   case V_ASN1_NEG_ENUMERATED:
```

And in `BN_to_ASN1_INTEGER`:
```c
-   if (BN_is_negative(bn))
+   if (BN_is_negative(bn) && !BN_is_zero(bn))
        ret->type = V_ASN1_NEG_INTEGER;
```

**Exploitation vector**: An attacker crafts an ASN.1 structure with an `ANY`
field containing a large universal tag → parser creates a "negative zero"
`ASN1_INTEGER` → application re-encodes it → `i2c_ASN1_INTEGER` underflows the
output buffer, corrupting memory. X509 certificate parsing + re-encoding is a
known vulnerable path.

**Detection signature**:

```
Pattern: while (*ptr == 0) or while (!*ptr) decrementing a pointer
         without a length/remaining guard
grep:    'while\s*\(\s*!\s*\*\w+\s*\)'   (zero-stripping loop without bounds)
Pattern: BN_to_ASN1_INTEGER setting NEG_INTEGER type on zero BNs
Pattern: ASN1_TYPE dispatch that treats NEG_INTEGER / NEG_ENUMERATED
         as semantically distinct from their positive counterparts
```

---

### 6b. CVE-2021-3712 — ASN.1 String Non-NUL-Terminated Read Overrun

- **CVE URL**: https://nvd.nist.gov/vuln/detail/CVE-2021-3712
- **Advisory**: https://openssl-library.org/news/secadv/20210824.txt
- **Fix commits**: https://github.com/openssl/openssl/commit/d9d838ddc (first),
  https://github.com/openssl/openssl/commit/94d23fcff9b (second),
  https://github.com/openssl/openssl/commit/ccb0a11145 (third)
- **Severity**: Moderate, CWE-125 Out-of-bounds Read
- **Affected functions**: `X509_aux_print()`, `X509_CERT_AUX_print()`,
  `X509_get1_email()`, `X509_REQ_get1_email()`, `X509_get1_ocsp()`,
  name constraints processing, and others
- **Affected versions**: OpenSSL 1.1.1-1.1.1k, 1.0.2-1.0.2y
- **Reported by**: Ingo Schwarze (first instance), David Benjamin (additional)

**The Core Problem**: `ASN1_STRING` has `data` (byte buffer) and `length`
(explicit length). Unlike C strings, NUL-termination is NOT guaranteed when
constructed via `ASN1_STRING_set0()` or by directly setting `data`/`length`.
However, many OpenSSL printing and processing functions assume NUL-termination.

**Vulnerable Pattern (pre-fix)**:

```c
// X509_aux_print() in crypto/x509/x509_aux.c — OLD
alias = X509_alias_get0(x, NULL);        // length ignored!
if (alias)
    BIO_printf(out, "%*sAlias: %s\n", indent, "", alias);
    // %s reads until NUL → if alias->data is not NUL-terminated,
    // reads past alias->length into adjacent memory
```

```c
// X509_CERT_AUX_print() — OLD
if (aux->alias)
    BIO_printf(out, "%*sAlias: %s\n", indent, "", aux->alias->data);
    // Same bug: %s without length bound
```

**The Fix**:

```c
// X509_aux_print() — FIXED
alias = X509_alias_get0(x, &i);          // get length too
if (alias)
    BIO_printf(out, "%*sAlias: %.*s\n", indent, "", i, alias);
    // %.*s with explicit length — no NUL dependency
```

```c
// X509_CERT_AUX_print() — FIXED
if (aux->alias)
    BIO_printf(out, "%*sAlias: %.*s\n", indent, "",
               aux->alias->length, aux->alias->data);
```

**Additional fix**: Guard against zero-length base point data in EC parameters:
```c
// EC_GROUP_new_from_ecparameters() — added null + length check
if (params->order == NULL
    || params->base == NULL
    || params->base->data == NULL
    || params->base->length == 0) {    // NEW: length zero check
    ECerr(...);
    goto err;
}
```

**Detection signature**:

```
Pattern: %s format specifier on ASN1_STRING->data without using %.*s
         or without separately passing ASN1_STRING->length
grep:    'BIO_printf\(.*%s.*->data\)'  or 'printf\(.*%s.*->data\)'
         in ASN.1 processing code
Pattern: ASN1_STRING_set0() followed by printing/processing without
         NUL-termination guarantee
Pattern: Direct assignment to ASN1_STRING->data and ->length without
         subsequent call to ASN1_STRING_set()
```

---

## 7. Side-Channel from Memory Access Patterns in Crypto

### 7a. Cache-Timing on T-Table AES Implementations

- **Classic paper**: Bernstein, "Cache-timing attacks on AES" (2005)
  http://cr.yp.to/antiforgery/cachetiming-20050414.pdf
- **Pattern**: T-table lookups in AES (Te0-Te3) depend on key and plaintext bytes

**Vulnerable Code Pattern**:

```c
// Traditional T-table AES (variable-time, cache-leaking)
// crypto/aes/aes_core.c — OpenSSL legacy implementation
static const u32 Te0[256] = { /* ... */ };
static const u32 Te1[256] = { /* ... */ };
static const u32 Te2[256] = { /* ... */ };
static const u32 Te3[256] = { /* ... */ };

void AES_encrypt(const unsigned char *in, unsigned char *out,
                 const AES_KEY *key) {
    // Each T-table lookup depends on (key XOR plaintext):
    s0 = Te0[(t >> 24) & 0xff] ^      // index = key-dependent byte
         Te1[(t >> 16) & 0xff] ^
         Te2[(t >>  8) & 0xff] ^
         Te3[(t      ) & 0xff];
    // Attacker can observe WHICH cache line is loaded → recover key
}
```

**Specific patterns that create variable-time behavior**:

| Pattern | Example | Leakage |
|---------|---------|---------|
| Secret-dependent table index | `table[key[i] ^ plain[i]]` | Cache line accessed reveals byte |
| Secret-dependent conditional branch | `if (secret_bit) { ... }` | Branch predictor state + timing |
| Secret-dependent loop count | `while (bits--) { ... }` on secret exponent | Iteration count via timing |
| Early-terminating comparison | `if (a[i] != b[i]) return 0;` | Timing reveals first mismatch |
| Variable shift count | `x >> secret_amount` | Microcode loop on some CPUs |
| Integer division by secret | `x / secret_modulus` | Data-dependent timing |

### 7b. CVE-2018-0737 — RSA Keygen BN_FLG_CONSTTIME Missing

- **CVE URL**: https://nvd.nist.gov/vuln/detail/CVE-2018-0737
- **Fix commit (1.1.0)**: https://github.com/openssl/openssl/commit/6939eab03a6e23d2bd2c3f5e34fe1d48e542e787
- **Fix commit (1.0.2)**: https://github.com/openssl/openssl/commit/349a41da1ad88ad87825414752a8ff5fdd6a6c3f
- **Severity**: Low, Cache-timing side channel
- **Vulnerable function**: `rsa_builtin_keygen()` in `crypto/rsa/rsa_gen.c`
- **Reported by**: Alejandro Cabrera Aldaya, Billy Brumley, Cesar Pereida Garcia,
  Luis Manuel Alvarez Tapia

**Code Pattern**:

```c
// crypto/rsa/rsa_gen.c — rsa_builtin_keygen (VULNERABLE)
static int rsa_builtin_keygen(RSA *rsa, int bits, BIGNUM *e_value, ...)
{
    // ...
    if (BN_copy(rsa->e, e_value) == NULL)
        goto err;
    // BUG: BN_FLG_CONSTTIME NOT set on rsa->p and rsa->q!
    BN_set_flags(r2, BN_FLG_CONSTTIME);  // r2 has it, but p,q don't
    /* generate p and q */
    for (;;) {
        // BN_generate_prime_ex → modular arithmetic on p,q
        // without CONSTTIME flag → variable-time Montgomery operations
    }
}
```

**The Fix**:

```c
+   BN_set_flags(rsa->p, BN_FLG_CONSTTIME);
+   BN_set_flags(rsa->q, BN_FLG_CONSTTIME);
    BN_set_flags(r2, BN_FLG_CONSTTIME);
```

Without `BN_FLG_CONSTTIME`, the big-number library uses standard (variable-time)
Montgomery multiplication. An attacker measuring cache timing during key
generation can recover the private key.

### 7c. CVE-2016-2178 — DSA Signing Non-Constant-Time Code Path

- **CVE URL**: https://nvd.nist.gov/vuln/detail/CVE-2016-2178
- **Advisory**: https://openssl-library.org/news/secadv/20160922.txt
- **Severity**: Low, Cache-timing → private DSA key recovery
- **Vulnerable function**: DSA signing in `crypto/dsa/dsa_ossl.c`
- **Reported by**: César Pereida (Aalto), Billy Brumley (Tampere), Yuval Yarom

**The pattern**: The DSA signing code had a `BN_FLG_CONSTTIME` flag that was set
but not consistently propagated through all internal operations, causing a
non-constant-time code path for certain operations. An attacker measuring
cache-timing during DSA signing could recover the private key.

### 7d. CVE-2022-4304 — RSA Decryption Timing Oracle (Marvin Attack)

- **CVE URL**: (see advisory) https://openssl-library.org/news/secadv/20230207.txt
- **Severity**: Moderate
- **Affected**: All RSA padding modes (PKCS#1 v1.5, OAEP, RSASVE)
- **Reported by**: Hubert Kario (Red Hat), 2020-2022
- **Research**: https://people.redhat.com/~hkario/marvin/

**The vulnerability chain**:
1. OpenSSL's BIGNUM Montgomery multiplication is not fully constant-time
2. Timing differences in modular exponentiation depend on secret key bits
3. These differences propagate through all RSA padding modes
4. An attacker sending many trial ciphertexts and measuring response times
   can distinguish valid PKCS#1 v1.5 padding from invalid — enabling
   Bleichenbacher-style adaptive chosen-ciphertext decryption

**Detection signatures for cache-timing in code audits**:

```
Pattern: Table lookup where index is key/plaintext-derived:
    sbox[key[i] ^ plaintext[i]]
    T0[(state >> 24) & 0xff]  (in T-table implementations)

Pattern: Conditional branching on secret data:
    if (secret_byte == 0) { ... } else { ... }

Pattern: Loop bound is a secret (e.g., modular exponent):
    while (exponent_bits--) { if (exponent & 1) { ... } }

Pattern: BN_mod_exp or BN_mod_mul without BN_FLG_CONSTTIME set

Pattern: memcmp / CRYPTO_memcmp used in MAC/padding verification
         (should use constant-time CRYPTO_memcmp or equivalent)

Pattern: Integer comparison short-circuits:
    if (memcmp(a, b, len) == 0)  → leaks position of first mismatch

Pattern: Large-integer operations (mpn_*, bn_*) that use
         data-dependent branching for normalization, reduction
```

---

## 8. Buffer Handling in Crypto APIs — Return Size Mismatches

### 8a. RSA Decryption Returning More Bytes Than Advertised

- **CVE-2020-25657**: https://nvd.nist.gov/vuln/detail/CVE-2020-25657
  (M2Crypto Bleichenbacher timing in RSA decryption API)
- **Related CVE-2023-50781**: M2Crypto incomplete fix
- **Related CVE-2020-25659, CVE-2023-50782**: pyca/cryptography same pattern

**The generic problem**: RSA decryption APIs (PKCS#1 v1.5) have a structural
buffer size mismatch:

1. The decrypted message length is `k` bytes (RSA modulus size, e.g., 256 for 2048-bit)
2. After PKCS#1 v1.5 padding stripping, the actual plaintext is shorter (e.g., 48 bytes for TLS pre-master secret)
3. Different implementations return different sizes:
   - Some return `k` (the full decrypted buffer including stripped padding)
   - Some return `payload_len` (only the payload)
   - Some return negative/error codes for padding errors

**Vulnerable pattern**: When an API returns `k` (full buffer size) but the
application allocates based on expected plaintext size:

```c
// Example vulnerable pattern:
int outlen;
unsigned char *buf = malloc(RSA_size(rsa));  // allocates for modulus size
EVP_PKEY_decrypt(ctx, buf, &outlen, in, inlen);
// outlen might be less than RSA_size(), but what if:
// - The API returns outlen = k (full size)?
// - The application uses outlen to determine further processing?
// - A different padding mode returns a different size than expected?
```

**OpenSSL-specific pattern for two-call APIs**:

```c
// Step 1: get size
EVP_PKEY_decrypt(ctx, NULL, &outlen, in, inlen);
// outlen now contains the expected plaintext size

// Step 2: allocate and decrypt
unsigned char *out = malloc(outlen);
EVP_PKEY_decrypt(ctx, out, &outlen, in, inlen);
```

The SM2 CVE-2021-3711 (see section 2) is the canonical example of this class:
the size query and the actual operation disagree.

### 8b. RSA Decryption Write Beyond Buffer via Padding Oracle Interaction

**Pattern**: When an RSA decryption function writes `k` bytes (modulus size)
into a buffer that the caller allocated for `expected_plaintext_size` (smaller
than `k`), the write overflows.

**Specific code pattern (example from OpenSSL before constant-time fixes)**:

```c
// PKCS#1 v1.5 unpadding — OLD pattern
int RSA_padding_check_PKCS1_type_2(unsigned char *to, int tlen,
                                   const unsigned char *from, int flen,
                                   int num) {
    // to = output buffer (allocated by caller, expects payload_len)
    // from = decrypted block (RSA modulus size)
    // If padding is valid, copies payload to 'to'
    // If payload is larger than tlen → overflows 'to'!
}
```

**Detection signature**:

```
Pattern: The "two-call" pattern (first call NULL to get size, second call
         with actual buffer) where the sizing function and the execution
         function use different logic (estimate vs. actual parse)

Pattern: RSA_padding_check_* functions where output buffer size (tlen)
         is smaller than input buffer size (flen) and no explicit bound
         check prevents copying more than tlen bytes

Pattern: EVP_PKEY_decrypt or RSA_private_decrypt where:
         - First call with out=NULL sets *outlen
         - Second call writes more than *outlen bytes
         (check by comparing the two code paths)

Pattern: Any crypto API that returns data without requiring caller to
         specify maximum output size on entry — "trust the API" anti-pattern
```

### 8c. BN_bn2dec OOB Write (CVE-2016-2182)

- **Advisory**: https://openssl-library.org/news/secadv/20160922.txt
- **Severity**: Low
- **Vulnerable function**: `BN_bn2dec()` — unchecked `BN_div_word()` return

**Pattern**: `BN_bn2dec()` converts a BIGNUM to decimal string. It calls
`BN_div_word()` in a loop without checking the return value. An overly large
BIGNUM can cause OOB write on the output buffer.

**Detection signature**:

```
Pattern: Loop calling BN_div_word() without checking the return value
Pattern: Conversion functions (bn2dec, bn2hex, bn2bin) that allocate based
         on BN_num_bytes() but write based on arithmetic iteration
```

---

## Summary: Detection Patterns for Code Auditing

### Quick-Audit grep Patterns

| Category | grep/ast-grep Pattern | What It Finds |
|----------|----------------------|---------------|
| Integer overflow in length | `(a + b) < BLOCK_SIZE` where both are signed int | Unsafe addition before comparison |
| Integer overflow in length | `(len - j) & ~(bl - 1)` without overflow guard | Output length wrap-around |
| Output overflow | `((inl ...) ... bl)` without `> INT_MAX` check | CVE-2021-23840 class |
| Size mismatch | First `EVP_PKEY_decrypt` NULL → `*outlen = msg_len - overhead` | Estimated vs. parsed size |
| Unchecked num param | `ctx->num = num` without `num >= blocksize` check | DES OFB OOB read class |
| Negative num | `get_num(ctx)` without `< 0` check | Blowfish negative index |
| NUL-termination assumption | `%s` on `->data` without `%.*s` + `->length` | ASN.1 string overread |
| Zero-stripping loop | `while (!*p)` without `&& remaining > 0` guard | ASN.1 negative zero |
| Missing CONSTTIME | `BN_mod_exp` without `BN_FLG_CONSTTIME` set on operands | RSA/DSA keygen timing |
| Secret-dependent table | `table[secret ^ plain]` in cipher inner loop | AES T-table cache leak |
| Secret conditional | `if (secret_bit)` in cryptographic processing | Branch timing leak |
| PKCS#1 unbounded copy | `to[tlen]` written with `flen > tlen` | RSA padding overflow |

### Structural Anti-Patterns

1. **Estimate-don't-parse**: Computing buffer size algebraically instead of
   extracting the actual length from the serialized format (SM2, ASN.1)

2. **Check-after-use**: Validating `num` or `n` after the first array access
   rather than before (DES OFB, Blowfish OFB)

3. **Trust-the-NUL**: Using C string functions (`%s`, `strlen`, `strcpy`) on
   `ASN1_STRING->data` without verifying NUL-termination

4. **Trust-the-flag**: Setting `BN_FLG_CONSTTIME` on some operands but not all
   in a multi-operand modular exponentiation

5. **Signed-arithmetic**: Using `int` for buffer length calculations in crypto
   APIs where `size_t` should be used (pre-3.0 OpenSSL pattern)

6. **Static-overflow**: `(ctx->num + inl) < limit` pattern where both operands
   are signed integers and the addition can wrap

---

*Sources: OpenSSL Security Advisories (2016-2023), OpenSSL GitHub repository commits,
NVD entries, Hubert Kario's Marvin Attack research (2023), and GitHub Issues #30284/#18751.*
