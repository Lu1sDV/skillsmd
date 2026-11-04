import pytest
from slugify import slugify


def test_slugify_default_max_length_is_50():
    assert slugify("a" * 60) == "a" * 50


def test_slugify_default_truncation_never_leaves_trailing_hyphen():
    # "x-y-y-..." has a hyphen at index 49 (0-based) of the untruncated slug.
    text = "x" + " y" * 40
    out = slugify(text)
    assert len(out) <= 50 and not out.endswith("-")
    assert out == ("x" + "-y" * 25)[:49]


def test_slugify_max_length_zero_returns_empty():
    assert slugify("abc", 0) == ""


def test_slugify_truncation_exactly_before_hyphen_drops_it():
    assert slugify("ab cd", 2) == "ab"
    assert slugify("ab cd", 3) == "ab"


@pytest.mark.parametrize("text,want", [
    ("A\u0301 b", "a-b"),          # combining accent
    ("a\u00a0b", "a-b"),           # non-breaking space is a separator
    ("a\tb\nc", "a-b-c"),
    ("\ufb01x", "fix"),            # NFKD ligature expansion
    ("日本語 x", "x"),              # non-ASCII-only characters vanish
    ("ABC123", "abc123"),
    ("a.b,c/d", "a-b-c-d"),
])
def test_slugify_unicode_and_whitespace(text, want):
    assert slugify(text) == want


def test_slugify_is_idempotent():
    s = slugify("  Café -- Münster & Co. ")
    assert slugify(s) == s


# SPEC: "Each run of non-alphanumeric characters becomes one hyphen."
# A non-ASCII symbol between words is non-alphanumeric, but the code strips it
# (encode ascii/ignore) before the hyphen substitution, gluing the words together.
@pytest.mark.xfail(strict=True, reason="defect: non-ASCII symbols are dropped instead of becoming a hyphen")
@pytest.mark.parametrize("text,want", [
    ("a€b", "a-b"),
    ("a·b", "a-b"),
])
def test_slugify_nonascii_symbol_between_words_becomes_hyphen(text, want):
    assert slugify(text) == want
