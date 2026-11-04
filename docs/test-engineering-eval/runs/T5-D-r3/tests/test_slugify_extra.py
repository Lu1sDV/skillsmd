import pytest
from slugify import slugify


def test_default_max_length_is_50():
    assert slugify("a" * 80) == "a" * 50
    assert slugify("a" * 50) == "a" * 50


def test_default_truncation_strips_trailing_hyphen():
    # hyphen would land at index 49 (the 50th char)
    assert slugify("a" * 49 + " bbb") == "a" * 49


@pytest.mark.parametrize("text,n,want", [
    ("abc", 0, ""),
    ("-abc", 1, "a"),
    ("a b", 1, "a"),
    ("a b", 2, "a"),
    ("a b", 3, "a-b"),
    ("abc", 100, "abc"),
])
def test_truncation_edges(text, n, want):
    assert slugify(text, n) == want


@pytest.mark.parametrize("n", [0, 1, 3, 4, 5, 10])
def test_never_exceeds_max_or_ends_with_hyphen(n):
    out = slugify("ab cd ef gh ij", n)
    assert len(out) <= n
    assert not out.startswith("-") and not out.endswith("-")


@pytest.mark.parametrize("text,want", [
    ("ÀÉÎÕÜ", "aeiou"),
    ("naïve façade", "naive-facade"),
    ("ﬁne", "fine"),          # NFKD ligature
    ("ＡＢＣ１２３", "abc123"),  # fullwidth
    ("x\tY\nZ", "x-y-z"),
    ("UPPER lower MiXeD", "upper-lower-mixed"),
    ("a1b2", "a1b2"),
    ("日本語", ""),
    ("e\u0301", "e"),         # combining accent
    ("a\u00a0b", "a-b"),      # NBSP -> space via NFKD
])
def test_unicode_and_whitespace(text, want):
    assert slugify(text) == want


def test_idempotent():
    s = slugify("  Café -- Münster!! 66 ")
    assert slugify(s) == s


def test_returns_ascii_lowercase_charset():
    import re
    assert re.fullmatch(r"[a-z0-9]+(-[a-z0-9]+)*|", slugify("Zoë's \u2603 test, ñ & co."))


# Spec: "Each run of non-alphanumeric characters becomes one hyphen".
# Non-ASCII punctuation/symbols are non-alphanumeric but the implementation
# deletes them during ASCII encoding, gluing words together.
@pytest.mark.xfail(strict=True, reason="non-ASCII punctuation dropped instead of becoming a hyphen")
@pytest.mark.parametrize("text,want", [
    ("a\u2013b", "a-b"),       # en dash
    ("Hello\u2014World", "hello-world"),  # em dash
    ("price\u20acfive", "price-five"),
    ("a\u201cb\u201d c", "a-b-c"),
])
def test_non_ascii_punctuation_is_separator(text, want):
    assert slugify(text) == want


# Negative max_length: slicing with a negative index chops from the end.
@pytest.mark.xfail(strict=True, reason="negative max_length slices from the end instead of yielding/raising")
def test_negative_max_length_does_not_return_content():
    assert slugify("abcdef", -1) == ""
