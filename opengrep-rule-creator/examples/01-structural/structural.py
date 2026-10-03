# STATIC SCANNER INPUT: never execute this file.
# Application policy: newly generated PBKDF2-HMAC-SHA256 password hashes use
# >=600,000 iterations. This is a lab policy, not a universal performance setting.
import hashlib
from cryptography.hazmat.primitives import hashes
from cryptography.hazmat.primitives.kdf.pbkdf2 import PBKDF2HMAC


def hash_password(password, salt):
    # Positive A: hashlib branch binds algorithm text and the fourth argument.
    # ruleid: lab-python-weak-password-kdf
    return hashlib.pbkdf2_hmac("sha256", password, salt, 100_000, dklen=32)


def create_password_record(password, salt):
    rounds = 200_000
    # Positive B: constant propagation resolves rounds; focus reports this usage.
    # A one-token autofix would disagree with the count returned as hash metadata.
    # ruleid: lab-python-weak-password-kdf
    derived = hashlib.pbkdf2_hmac('sha256', password, salt, rounds)
    return derived, rounds


def derive_password_key(password, salt):
    # Positive C: cryptography branch filters an AST constructor, not its spelling.
    # The annotation is above iterations because focus reports that value's line.
    return PBKDF2HMAC(
        algorithm=hashes.SHA256(),
        salt=salt,
        # ruleid: lab-python-weak-password-kdf
        iterations=599_999,
        length=32,
    ).derive(password)


def hash_password_boundaries(password, salt, runtime_rounds):
    # Boundary equality is compliant; > threshold is compliant too.
    # ok: lab-python-weak-password-kdf
    hashlib.pbkdf2_hmac("sha256", password, salt, 600_000)
    # ok: lab-python-weak-password-kdf
    hashlib.pbkdf2_hmac("sha256", password, salt, 900_000)
    # Invalid counts raise instead of creating a weak derived key: another rule's job.
    # ok: lab-python-weak-password-kdf
    hashlib.pbkdf2_hmac("sha256", password, salt, 0)
    # SHA512 needs its own cost policy; this does not declare 100 iterations safe.
    # ok: lab-python-weak-password-kdf
    hashlib.pbkdf2_hmac("sha512", password, salt, 100)
    # Unknown runtime values are outside this static numeric check, not known safe.
    # ok: lab-python-weak-password-kdf
    hashlib.pbkdf2_hmac("sha256", password, salt, runtime_rounds)
    # Same numeric boundary for the second API and different keyword ordering.
    # ok: lab-python-weak-password-kdf
    PBKDF2HMAC(iterations=600_000, length=32, algorithm=hashes.SHA256(), salt=salt)
    # Constructor filtering prevents a spelling-only match on any hash object.
    # ok: lab-python-weak-password-kdf
    PBKDF2HMAC(iterations=100, length=32, algorithm=hashes.SHA512(), salt=salt)


def verify_password(password, salt, stored_digest):
    # Verification must reproduce a stored legacy hash before a separate rehash.
    # This rule scopes to generation entrypoints; changing this count would lock
    # users out. Naming alone is not proof: audit entrypoints before using the fix.
    # ok: lab-python-weak-password-kdf
    return hashlib.pbkdf2_hmac("sha256", password, salt, 100_000) == stored_digest
