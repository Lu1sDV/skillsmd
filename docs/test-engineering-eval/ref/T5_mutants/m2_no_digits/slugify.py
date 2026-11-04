"""URL slugs."""
import re
import unicodedata


def slugify(text: str, max_length: int = 50) -> str:
    """Lowercase ASCII slug.

    Accents are stripped (e-acute becomes e). Each run of non-alphanumeric
    characters becomes one hyphen, with no leading or trailing hyphen. The result
    is truncated to max_length without leaving a trailing hyphen.
    """
    ascii_text = unicodedata.normalize("NFKD", text).encode("ascii", "ignore").decode("ascii")
    slug = re.sub(r"[^a-z]+", "-", ascii_text.lower()).strip("-")
    return slug[:max_length].rstrip("-")
